------------------------------------------------------------------------------------------------
-- Model Name 	:	Message Pack Decoder
-- File Name	:	mp_dec.vhd
-- Generated	:	19.11.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Message Pack (MP) Decoder receives parallel transmission, and
--				split it into blocks:
--				(1) SOF 	- Start of Frame
--				(2) Type 	- Type of transmission
--				(3) Address	- Address to write to
--				(4) Length 	- Data block length (-1, according to generic parameter)
--				(5) CRC 	- CRC, calculated from TYPE to DATA block (inclusive)
--				(6) EOF 	- End of Frame
--
--				At end of transmission, and MP_DONE flag will be rised, and the
--				Type, Address, Length and CRC registers value will be valid.
--				In case received CRC value is different from CRC calculated value,
--				an 'crr_err' flag will be raised.
--
--				When data is valid, 'write_en' flag is being rised, together with
--				an address to the RAM.
--
--				Problematic SOF words:
--				Suppose SOF = 0xAABBCC.
--				A message of 0xAABBAABBCC... will be decode correctly by the MP decoder.
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		20.11.2010	Beeri Schreiber		Creation
--			1.01		18.12.2010	Beeri Schreiber		(1) crc_reg port was removed
--														(2) CRC processes where changed
--														(3) init_sof_eof_proc is changed to
--															'generate' statement
--			1.02		07.02.2011	Beeri Schreiber		(1) Blocks where converted to Shift Registers
--														(2) Maximum function has been added
--			1.03		25.02.2011	Beeri Schreiber		(1) General_err flag has been deleted
--			1.04		13.08.2011	Beeri Schreiber		CRC_ERR is asserted also when MP_DONE
--														is asserted.
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity mp_dec is
   generic (
				reset_polarity_g	:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
				len_dec1_g			:	boolean := true;	--TRUE - Recieved length is decreased by 1 ,to save 1 bit
															--FALSE - Recieved length is the actual length
				
				sof_d_g				:	positive := 1;		--SOF Depth
				type_d_g			:	positive := 1;		--Type Depth
				addr_d_g			:	positive := 3;		--Address Depth
				len_d_g				:	positive := 2;		--Length Depth
				crc_d_g				:	positive := 1;		--CRC Depth
				eof_d_g				:	positive := 1;		--EOF Depth
						
				sof_val_g			:	natural := 100;		-- (64h) SOF block value. Upper block is MSB
				eof_val_g			:	natural := 200;		-- (C8h) EOF block value. Upper block is MSB
				
				width_g				:	positive := 8		--Data Width (UART = 8 bits)
           );
   port
   	   (
				--Inputs
				clk			:	in std_logic; 	--Clock
				rst			:	in std_logic;	--Reset
				din			:	in std_logic_vector (width_g - 1 downto 0); --Input data_d_g
				valid		:	in std_logic;	--Data valid
				
				--Message Pack Status
				mp_done		:	out std_logic;	--Message Pack has been recieved
				eof_err		:	out std_logic;	--EOF has not found
				crc_err		:	out std_logic;	--CRC error
				
				--Registers
				type_reg	:	out std_logic_vector (width_g * type_d_g - 1 downto 0);
				addr_reg	:	out std_logic_vector (width_g * addr_d_g - 1 downto 0);
				len_reg		:	out std_logic_vector (width_g * len_d_g - 1 downto 0);

				--CRC / CheckSum
				data_crc_val:	out std_logic; --'1' when new data for CRC is valid, '0' otherwise
				data_crc	:	out std_logic_vector (width_g - 1 downto 0); --Data to be calculated by CRC
				reset_crc	:	out std_logic; --'1' to reset CRC value
				req_crc		:	out std_logic; --'1' to request for current caluclated CRC
				crc_in		:	in std_logic_vector (width_g * crc_d_g -1 downto 0); --CRC value
				crc_in_val	:	in std_logic;  --'1' when CRC is valid
				
				--Data (Payload)
				write_en	:	out std_logic; --'1' = Data is available (width_g length)
				write_addr	:	out std_logic_vector (width_g * len_d_g - 1 downto 0); --RAM Address
				dout		:	out std_logic_vector (width_g - 1 downto 0) --Data to RAM
   	   );
end entity mp_dec;

architecture rtl_mp_dec of mp_dec is

------------------	Types	--------------------

--State Machine
type mp_dec_states is (
					sof_st,		--Recieve SOF
					type_st,	--Recieve Type
					addr_st,	--Recieve Address
					len_st,		--Recieve data length
					data_st,	--Recieve Data (Payload)
					crc_st, 	--Recieve CRC
					eof_st		--Recieve EOF
				);


------------------  CONSTANTS ------------------
constant sof_blk_c	:	std_logic_vector (width_g * sof_d_g - 1 downto 0) := conv_std_logic_vector (sof_val_g, width_g * sof_d_g);	--SOF Block
constant zeros_c	:	std_logic_vector (width_g - 1 downto 0) := (others => '0');	--Zeros

------------------  FUNCTIONS-------------------

--------------------------------------
------- Function maximum -------------
--------------------------------------
-- The function returns the maximum
-- value between two positive numbers
--------------------------------------
function maximum ( left, right : positive) return positive is
begin  -- function max
	if left > right then 
		return left;
	else 
		return right;
	end if;
end function maximum;

------------------  SIGNALS AND VARIABLES ------

--Blocks
signal type_blk		:	std_logic_vector (width_g * type_d_g - 1 downto 0);	--Type Block
signal addr_blk		:	std_logic_vector (width_g * addr_d_g - 1 downto 0);	--Address Block
signal len_blk		:	std_logic_vector (width_g * len_d_g - 1 downto 0);	--Length block
signal crc_blk		:	std_logic_vector (width_g * crc_d_g - 1 downto 0); 	--CRC Block
signal eof_blk		:	std_logic_vector (width_g * eof_d_g - 1 downto 0);	--EOF Blcok
	
signal w_addr 		:	natural range 0 to 2**(len_d_g*width_g) - 1;		--Address to write to RAM
signal blk_pos		:	positive range 1 to maximum(sof_d_g, maximum (type_d_g, maximum (addr_d_g, maximum(len_d_g, maximum(crc_d_g, eof_d_g)))));	--Current position (depth) in block

signal sof_sr		:	std_logic_vector (width_g * (sof_d_g - 1) downto 0);		--Shift Register of SOF
signal sof_sr_cnt	:	natural range 0 to sof_d_g - 1;								--Shift register elements counter

--FSM
signal cur_st		:	mp_dec_states; 	--Current state
signal tx_regs		:	std_logic;		--Transmit registers
signal crc_err_i	:	std_logic; 		--Internal CRC error signal

------------------  Design ----------------------
begin
	
	crc_err_signal_proc:
	crc_err	<= 	crc_err_i;

	---------------------------------------------------
	-----------  Process fsm_proc ---------------------
	---------------------------------------------------
	-- The process is the main FSM of the message pack
	-- decoder.
	-- It waits for SOF, then recieves all blocks.
	-- In case EOF error has been detected - a flag
	-- will be rised for one clock.
	-- When MessagePack has been fully recieved, a
	-- tx_regs flags will be rised, to store data
	-- into the registers
	---------------------------------------------------
	fsm_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			--FSM
			cur_st 		<= sof_st;
			blk_pos 	<= 1;
			req_crc		<= '0';
	
			--Flags	
			tx_regs 	<= '0';	--Registers are not available
			eof_err 	<= '0';	--EOF error - turn off
			
			--Blocks
			type_blk	<= (others => '0');
			addr_blk	<= (others => '0');
			len_blk	    <= (others => '0');
			crc_blk	    <= (others => '0');
			
		elsif rising_edge(clk) then
			req_crc	<= '0';
			--Flags
			tx_regs <= '0';			--Registers are not available
			eof_err <= '0';			--EOF error - turn off
			
			--Valid Data
			if (valid = '1') then --New data has been recieved
				case cur_st is
					when sof_st =>
						--Check if current transmission is part of SOF
						if (sof_d_g > 1) then
							if (sof_sr (width_g * (sof_d_g - 1) - 1 downto 0) = sof_blk_c (width_g * sof_d_g - 1 downto width_g))
								and (din = sof_blk_c (width_g - 1 downto 0))
								and (sof_sr_cnt = sof_d_g - 1) then
								cur_st 	<= type_st;		--Switch to next block recieve
							else
								cur_st 	<= sof_st;		--Stay at SOF state
							end if;
						
						else
							if (din = sof_blk_c (width_g - 1 downto 0)) then
								cur_st 	<= type_st;		--Switch to next block recieve
							else
								cur_st 	<= sof_st;		--Stay at SOF state
							end if;
						end if;
						
						blk_pos <= 1;					--Prepare block position at start of next block

					when type_st =>
						if (type_d_g = 1) then
							type_blk <= din;
						else
							type_blk(type_d_g * width_g - 1 downto 0) <= type_blk((type_d_g -1) * width_g - 1 downto 0) & din;
						end if;
						if (blk_pos = type_d_g) then	--Type block has been fully transmitted
							blk_pos <= 1;			--Prepare block position at start of next block
							cur_st 	<= addr_st;		--Switch to next block recieve
						else
							blk_pos <= blk_pos + 1;	--Increment position in block
							cur_st 	<= type_st;		--Stay at current block
						end if;
						
					when addr_st =>
						if (addr_d_g = 1) then
							addr_blk <= din;
						else
							addr_blk(addr_d_g * width_g - 1 downto 0) <= addr_blk((addr_d_g -1) * width_g - 1 downto 0) & din;
						end if;
						if (blk_pos = addr_d_g) then--Type block has been fully transmitted
							blk_pos		<= 1;		--Prepare block position at start of next block
							cur_st  	<= len_st;	--Switch to next block recieve
						else
							blk_pos 	<= blk_pos + 1;		--Increment position in block
							cur_st 		<= addr_st;			--Stay at current block
						end if;
					
					when len_st =>
						if (len_d_g = 1) then
							len_blk <= din;
						else
							len_blk(len_d_g * width_g - 1 downto 0) <= len_blk((len_d_g -1) * width_g - 1 downto 0) & din;
						end if;
						if blk_pos 	= len_d_g then	--Length has been fully transmitted
							blk_pos <= 1;			--Prepare block position at start of next block
							cur_st 	<= data_st;		--Switch to next block recieve
						else
							blk_pos <= blk_pos + 1;	--Increment position in block
							cur_st 	<= len_st;		--Stay at current block
						end if;
						
					when data_st =>
						blk_pos 	<= 1;				--Prepare block position at start of next block
						if ((w_addr + 1 = conv_integer(len_blk)) and (not len_dec1_g)) 
							or (w_addr + 1 > conv_integer(len_blk) and len_dec1_g) then --Data has been fully transmitted
							cur_st 	<= crc_st;		--Switch to next block recieve
						else
							cur_st 	<= data_st;		--Stay at current block
						end if;
						
					when crc_st =>
						if (crc_d_g = 1) then
							crc_blk <= din;
						else
							crc_blk(crc_d_g * width_g - 1 downto 0) <= crc_blk((crc_d_g -1) * width_g - 1 downto 0) & din;
						end if;
						if (blk_pos = crc_d_g) then	--CRC block has been fully transmitted
							blk_pos <= 1;			--Prepare block position at start of next block
							cur_st 	<= eof_st;		--Switch to next block recieve
							req_crc <= '1';			--Request for CRC from CRC IF
						else
							blk_pos <= blk_pos + 1;	--Increment position in block
							cur_st 	<= crc_st;		--Stay at current block
						end if;
					
					when eof_st =>
						--Check if current transmission is part of EOF
						if (din = eof_blk(width_g - 1 downto 0)) then --Found part of EOF block
							--Check if all EOF block has been recieved. If so - switch to SOF block
							if (blk_pos = eof_d_g) then --EOF block has been transmitted
								cur_st 	<= sof_st;		--Switch to next block recieve
								blk_pos <= 1;			--Prepare block position at start of next block
								tx_regs <= '1';			--Enable register transmission
							else
								blk_pos <= blk_pos + 1;	--Increment position in block
								cur_st 	<= eof_st;		--Stay at SOF state
							end if;
						else							--EOF mismatch
							blk_pos 	<= 1;			--Prepare block position at start of next block
							eof_err		<= '1';			--Rise EOF error flag
							cur_st 		<= sof_st;		--Switch to SOF block
						end if;
						
					when others =>	--This should never happen, since all states are covered
						report "Time: " & time'image(now) & ",UART Message Pack Decoder - Unimplemented state is being executed in FSM"
						severity error;
					
				end case;
			end if;
		end if;
	end process fsm_proc;
	
	---------------------------------------------------
	-----------  Process eof_blk_proc -----------------
	---------------------------------------------------
	-- The process initilize the eof_blk, according
	-- to the generic parameter, and shift it right
	-- at 'eof_st'
	---------------------------------------------------
	eof_blk_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then	--System reset
			eof_blk <= (others => '0');
		elsif rising_edge(clk) then
			if (valid = '1') then
				if (cur_st = crc_st) and (blk_pos = crc_d_g) then
					eof_blk <= conv_std_logic_vector(eof_val_g, eof_d_g * width_g);  --Prepare EOF Block reference
				elsif (cur_st = eof_st) and (din = eof_blk(width_g - 1 downto 0)) and (eof_d_g > 1) then
					eof_blk(eof_d_g * width_g - 1 downto 0) <= zeros_c & eof_blk (eof_d_g * width_g - 1 downto (eof_d_g - 1 ) * width_g);	--Shift left
				else
					eof_blk <= eof_blk;			--Keep last value
				end if;
			else
				eof_blk <= eof_blk;				--Keep last value
			end if;
		end if;
	end process eof_blk_proc;
	
	---------------------------------------------------
	-----------  Process data_proc --------------------
	---------------------------------------------------
	-- The process transmit data (payload) to RAM.
	-- write_en is being rised when data is valid.
	---------------------------------------------------
	data_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --System reset
			write_en 	<= '0';
			w_addr 		<= 0;
			dout		<= (others => '0');
			write_addr	<= (others => '0');
		
		elsif rising_edge (clk) then
			write_en <= '0';
			if (cur_st /= data_st) then 	--Current state is not data state.
				w_addr <= 0;
			elsif valid = '1' then 			-- Valid data
				write_addr 	<= conv_std_logic_vector(w_addr, width_g * len_d_g); --Address to RAM
				dout 		<= din;
				write_en 	<= '1'; 		--Enable writing to RAM
				w_addr 		<= w_addr + 1; 	--Increment RAM address for next data transmission
			end if;
		end if;
	end process data_proc;

	---------------------------------------------------
	-----------  Process crc_reset_proc ---------------
	---------------------------------------------------
	-- The process resets the CRC value, in case of 
	-- system reset or start of message pack.
	---------------------------------------------------
	crc_reset_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then -- Reset
			reset_crc		<= '1'; 	-- Reset the CRC value
		elsif rising_edge (clk) then
			if (cur_st = sof_st) and (valid = '1') then
				reset_crc	<= '1'; 	-- Reset the CRC value
			else
				reset_crc	<= '0';
			end if;
		end if;
	end process crc_reset_proc;

	---------------------------------------------------
	-----------  Process crc_data_valid_proc ----------
	---------------------------------------------------
	-- The process rises the valid data for CRC signal, 
	-- when data is valid.
	---------------------------------------------------
	crc_data_valid_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then -- Reset
			data_crc_val<= '0'; 		-- Data is not valid for CRC calculation
		elsif rising_edge (clk) then
			if (valid = '1') and (cur_st = type_st or cur_st = addr_st or cur_st = len_st or cur_st = data_st) then
				data_crc_val <= '1';	-- Data is valid for CRC calculation
			else
				data_crc_val <= '0';	-- Data is not valid for CRC calculation
			end if;
		end if;
	end process crc_data_valid_proc;

	---------------------------------------------------
	-----------  Process crc_data_proc ----------------
	---------------------------------------------------
	-- The process transmits valid data into the CRC
	-- block.
	---------------------------------------------------
	crc_data_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then -- Reset
			data_crc	<= (others => '0');
		elsif rising_edge (clk) then
			if (valid = '1') and (cur_st = type_st or cur_st = addr_st or cur_st = len_st or cur_st = data_st) then
				data_crc	<= din;		--Transmit data for CRC
			else
				data_crc	<= (others => '0');
			end if;
		end if;
	end process crc_data_proc;
	
	---------------------------------------------------
	-----------  Process crc_err_proc -----------------
	---------------------------------------------------
	-- The process rises the CRC Error flag in case of
	-- CRC error.
	---------------------------------------------------
	crc_err_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then -- Reset
			crc_err_i	<= '0';			-- Reset CRC error
		elsif rising_edge (clk) then
			if (cur_st = eof_st) and (crc_in_val = '1') and (crc_in /= crc_blk) then
				crc_err_i	<= '1';		-- CRC Error
			elsif (cur_st = sof_st) then
				crc_err_i	<= '0';		-- Clear CRC
			else
				crc_err_i	<=	crc_err_i;
			end if;
		end if;
	end process crc_err_proc;
	
	---------------------------------------------------
	-----------  Process regs_proc --------------------
	---------------------------------------------------
	-- The process transmit the Type, Address, Length
	-- and CRC registers, together with the 'mp_done'
	-- flag.
	---------------------------------------------------
	reg_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then  --System reset
			mp_done 	<= '0';
			type_reg	<= (others => '0');
			addr_reg	<= (others => '0');
			len_reg		<= (others => '0');
		
		elsif rising_edge (clk) then
			if (tx_regs = '1') then --Message pack is OK. Transmit registers
				
				--Enter data to registers
				--Type register
				type_reg <= type_blk;
				
				--Address register
				addr_reg <= addr_blk;

				--Length register
				len_reg <= len_blk;
				
				--Done
				mp_done <= '1'; --Valid Message Pack
				
			else
				mp_done <= '0'; --Message is not ready
			end if;
		end if;

	end process reg_proc;
	
	---------------------------------------------------
	-----------  Process sof_sr_proc ------------------
	---------------------------------------------------
	-- The process generates the SOF Shift Register,
	-- according to the input data, and increments
	-- the current number of elements in the SR.
	---------------------------------------------------
	sof_sr_proc_gen1:
	if (sof_d_g > 1) generate
		sof_sr_proc : process (clk, rst)
		begin
			if (rst = reset_polarity_g) then 		--System reset
				sof_sr		<= (others => '0');		--Not required, but looks better at simulation
				sof_sr_cnt	<= 0;					--Zero SR counter
			elsif rising_edge (clk) then
				if (valid = '1') then 
					if (cur_st = sof_st) then
						if (sof_d_g = 2) then 			--Data In only	
							sof_sr (width_g * (sof_d_g - 1) - 1 downto 0) <= din;
						else 							--Shift left & Data In
							sof_sr (width_g * (sof_d_g - 1) - 1 downto 0) <= sof_sr (width_g * (sof_d_g - 2) - 1 downto 0) & din;
						end if;
						
						if (sof_sr_cnt < sof_d_g - 1) then
							sof_sr_cnt <= sof_sr_cnt + 1;	--Increment SR counter
						else
							sof_sr_cnt <= sof_sr_cnt;		--Keep last value
						end if;
					else
						sof_sr_cnt	<= 0;					--Zero SR counter
						sof_sr		<= sof_sr;				
					end if;
				else
					sof_sr_cnt	<= sof_sr_cnt; 	--Keep last value
					sof_sr		<= sof_sr;		--Keep last value
				end if;
			end if;
		end process sof_sr_proc;
	end generate sof_sr_proc_gen1;
	
end architecture rtl_mp_dec;		