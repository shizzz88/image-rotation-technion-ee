------------------------------------------------------------------------------------------------
-- Model Name 	:	Message Pack Encoder
-- File Name	:	mp_enc.vhd
-- Generated	:	27.11.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
--				The Message Pack Encoder receives data from Type, Address and Length registers,
--				and data from RAM, calculates CRC for them, and transmit it as a message pack.
--				
--			* Output Data Valid Signal:
--				Data is being transmitted when 'fifo_full' flag is not raised by the data
--				target (FIFO). Then 'data_valid' is being raised for 1 clock, then it is being changed
--				to '0'. 'data_valid' will be raised again in case FIFO will not be full.
--
--			* Message Pack Structure:
--				(1) SOF 	- Start of Frame
--				(2) Type 	- Type of transmission
--				(3) Address	- Address to write to
--				(4) Lengh 	- Data block length (-1, according to generic parameter)
--				(5) CRC 	- CRC, calculated from TYPE to DATA block (inclusive)
--				(6) EOF 	- End of Frame
--
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		27.11.2010	Beeri Schreiber		Creation
--			1.01		18.12.2010	Beeri Schreiber		(1) init_sof_eof_proc is changed to
--															'generate' statement
--														(2) CRC processes where changed
--			1.02		07.02.2011	Beeri Schreiber		(1) Blocks where converted to Shift Registers
--														(2) Maximum function has been added
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)  
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity mp_enc is
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
				clk			:	in std_logic; 											--Clock
				rst			:	in std_logic; 											--Reset
				fifo_full	:	in std_logic;											--When '0' - Can receive data, When '1' - FIFO Full
				
				--Message Pack
				mp_done		:	out std_logic;											--Message Pack has been transmitted
				dout		:	out std_logic_vector (width_g - 1 downto 0); 			--Output data
				dout_valid	:	out std_logic;											--Output data is valid .Goes to 'write_en' of FIFO
				
				--Registers
				reg_ready	:	in std_logic; 											--Registers are ready for reading. MP Encoder can start transmitting
				type_reg	:	in std_logic_vector (width_g * type_d_g - 1 downto 0);	--Type register
				addr_reg	:	in std_logic_vector (width_g * addr_d_g - 1 downto 0);	--Address register
				len_reg		:	in std_logic_vector (width_g * len_d_g - 1 downto 0);	--Length Register
				
				--CRC / CheckSum
				data_crc_val:	out std_logic; 											--'1' when new data for CRC is valid, '0' otherwise
				data_crc	:	out std_logic_vector (width_g - 1 downto 0); 			--Data to be calculated by CRC
				reset_crc	:	out std_logic; 											--'1' to reset CRC value
				req_crc		:	out std_logic; 											--'1' to request for current caluclated CRC
				crc_in		:	in std_logic_vector (width_g * crc_d_g -1 downto 0); 	--CRC value
				crc_in_val	:	in std_logic;  											--'1' when CRC is valid
				
				--Data (Payload)
				din			:	in std_logic_vector (width_g - 1 downto 0); 			--Input from RAM
				din_valid	:	in std_logic;											--Data from RAM is valid
				read_addr_en:	out std_logic;											--Output RAM address is valid
				read_addr	:	out std_logic_vector (width_g * len_d_g - 1 downto 0) 	--RAM Address
   	   );
end entity mp_enc;

architecture rtl_mp_enc of mp_enc is

------------------	Types	--------------------

--State Machine
type mp_encoder_states is (
					idle_st,	--Idle.
					sof_st,		--Transmit SOF
					type_st,	--Transmit Type
					addr_st,	--Transmit Address
					len_st,		--Transmit data length
					data_st,	--Transmit Data (Payload)
					reg_crc_st,	--Register the CRC value from the CRC IF (Interface)
					crc_st, 	--Transmit CRC
					eof_st		--Transmit EOF
				);

------------------  CONSTANTS ------------------
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
signal sof_blk		:	std_logic_vector (width_g * type_d_g - 1 downto 0);	--SOF Block
signal type_blk		:	std_logic_vector (width_g * type_d_g - 1 downto 0);	--Type Block
signal addr_blk		:	std_logic_vector (width_g * addr_d_g - 1 downto 0);	--Address Block
signal len_blk		:	std_logic_vector (width_g * len_d_g - 1 downto 0);	--Length block
signal crc_blk		:	std_logic_vector (width_g * crc_d_g - 1 downto 0); 	--CRC Block
signal eof_blk		:	std_logic_vector (width_g * eof_d_g - 1 downto 0);	--EOF Block

--RAM
signal ram_addr_i:	std_logic_vector (width_g * len_d_g - 1 downto 0); 		--RAM Address

--FSM
signal cur_st		:	mp_encoder_states; 									--Current state
signal blk_pos		:	positive range 1 to maximum(sof_d_g, maximum (type_d_g, maximum (addr_d_g, maximum(len_d_g, maximum(crc_d_g, eof_d_g)))));	--Current position (depth) in block
signal dout_valid_i	:	std_logic;											--Internal data_valid
signal len_data		:	std_logic_vector (width_g * len_d_g - 1 downto 0);	--Data length

--CRC Flags
signal crc_ack_i	:	std_logic;											--Internal CRC has been acknowledged from CRC block

------------------  Design ----------------------
begin

	read_addr_internal_proc:
	read_addr 	<= ram_addr_i; 		--RAM address
	
	dout_valid_internal_proc:
	dout_valid	<= dout_valid_i;	--Output data is valid
	
	---------------------------------------------------
	-----------  Process fsm_proc ---------------------
	---------------------------------------------------
	-- The process is the main FSM of the message pack
	-- Encoder.
	-- It waits for registers and RAM to be ready, and
	-- then, at every 'fifo_full = '0' from FIFO - 
	-- transmits the relevant block, by order.
	---------------------------------------------------
	fsm_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then --Reset
			--FSM
			cur_st 	<= idle_st;
			blk_pos <= 1;
			len_data<= (others => '0');
			
			--RAM
			ram_addr_i 		<= (others => '0');
			read_addr_en	<= '0';						--Address to RAM is not valid
			
			--Reset Outputs
			dout		<= (others => '0');	--Output Data
			dout_valid_i<= '0'; 			--Data is not valid
			
			--Blocks
			sof_blk 	<= (others => '0');
			type_blk 	<= (others => '0');
			addr_blk 	<= (others => '0');
			len_blk 	<= (others => '0');
			eof_blk 	<= (others => '0');
		
		elsif rising_edge(clk) then
			
			--Request data from MP Encoder
			if (fifo_full = '0') and (dout_valid_i = '0') then --Request for new data
				case cur_st is
					when idle_st =>
						read_addr_en	<= '0';						--Address to RAM is not valid
						ram_addr_i		<= (others => '0');			--ZERO address to RAM
						dout_valid_i 	<= '0';						--Output data is not valid
						if (reg_ready = '1') then --When Registers are ready - Aquire registers value
							--Initilize SOF end EOF Shift Registers
							sof_blk <= conv_std_logic_vector(sof_val_g, sof_d_g * width_g); 
							eof_blk <= conv_std_logic_vector(eof_val_g, eof_d_g * width_g); 
						
							--Insert Type value from Type Register into Type block
							type_blk <= type_reg;

							--Insert Address value from Address Register into Address block
							addr_blk <= addr_reg;
							
							--Insert Length value from Address Register into Length block
							len_blk <= len_reg;
							len_data<= len_reg;
							
							--Switch to next state
							cur_st <= sof_st;
						
						else
							cur_st <= idle_st; --RAM and registers are not valid yet
						end if;
						
					when sof_st =>
						--Transmit SOF
						dout 		<= sof_blk (sof_d_g * width_g - 1 downto (sof_d_g - 1) * width_g); 	--Transmit SOF
						dout_valid_i<= '1';																--Data is valid
						read_addr_en<= '0';																--Address to RAM is not valid
						ram_addr_i	<= (others => '0');													--Zero Address to RAM
														
						if (sof_d_g > 1) then															--Shift Left the Shift Register
							sof_blk (sof_d_g * width_g - 1 downto 0) <= sof_blk ((sof_d_g - 1) * width_g - 1 downto 0) & zeros_c;
						end if;

						--Check if all SOF block has been transmitted. If so - switch to next block
						if (blk_pos = sof_d_g) then --SOF block has been transmitted
							cur_st <= type_st;		--Switch to next block transmit
							blk_pos <= 1;			--Prepare block position at start of next block
						else
							blk_pos <= blk_pos + 1;	--Increment position in SOF block
							cur_st <= sof_st;		--Stay at SOF state
						end if;
						
					when type_st =>
						--Transmit Type
						dout 		<= type_blk (type_d_g * width_g - 1 downto (type_d_g - 1) * width_g); 	--Transmit Type
						dout_valid_i<= '1';									--Data is valid
						read_addr_en<= '0';									--Address to RAM is not valid
						ram_addr_i	<= (others => '0');						--Zero Address to RAM

						if (type_d_g > 1) then								--Shift Left the Shift Register
							type_blk (type_d_g * width_g - 1 downto 0) <= type_blk ((type_d_g - 1) * width_g - 1 downto 0) & zeros_c;
						end if;
						
						--Check if all Type block has been transmitted. If so - switch to next block
						if (blk_pos = type_d_g) then--TYPE block has been transmitted
							cur_st 	<= addr_st;		--Switch to next block transmit
							blk_pos <= 1;			--Prepare block position at start of next block
						else
							cur_st	<= type_st;		--Stay at type state
							blk_pos <= blk_pos + 1;	--Increment position in SOF block
						end if;
						
					when addr_st =>
						--Transmit Address
						dout 		<= addr_blk (addr_d_g * width_g - 1 downto (addr_d_g - 1) * width_g); 	--Transmit Address
						dout_valid_i<= '1';									--Data is valid
						read_addr_en<= '0';									--Address to RAM is not valid
						ram_addr_i	<= (others => '0');						--Zero Address to RAM

						if (addr_d_g > 1) then								--Shift Left the Shift Register
							addr_blk (addr_d_g * width_g - 1 downto 0) <= addr_blk ((addr_d_g - 1) * width_g - 1 downto 0) & zeros_c;
						end if;

						--Check if all Address block has been transmitted. If so - switch to next block
						if (blk_pos = addr_d_g) then--Address block has been transmitted
							cur_st 	<= len_st;		--Switch to next block transmit
							blk_pos <= 1;			--Prepare block position at start of next block
						else
							blk_pos <= blk_pos + 1;	--Increment position in SOF block
							cur_st 	<= addr_st;		--Stay at address state
						end if;
					
					when len_st =>
						--Transmit Data Length
						dout 		<= len_blk (len_d_g * width_g - 1 downto (len_d_g - 1) * width_g);	--Transmit Data Length
						dout_valid_i<= '1';								--Data is valid
						ram_addr_i	<= (others => '0');					--Zero Address to RAM

						if (len_d_g > 1) then							--Shift Left the Shift Register
							len_blk (len_d_g * width_g - 1 downto 0) <= len_blk ((len_d_g - 1) * width_g - 1 downto 0) & zeros_c;
						end if;

						--Check if all length has been transmitted. If so - switch to next block
						if (blk_pos 	= len_d_g) then 	--Length has been transmitted
							cur_st 		<= data_st;			--Switch to next block transmit
							read_addr_en<= '1';				--Address to RAM is valid
							blk_pos 	<= 1;				--Prepare block position at start of next block
						else
							blk_pos 	<= blk_pos + 1;		--Increment position in SOF block
							cur_st 		<= len_st;			--Stay at length state
							read_addr_en<= '0';				--Address to RAM is not valid
						end if;
						
					when data_st =>
						blk_pos 		<= 1;				--Signal is not relevant for this block, prepare for next block
						if (din_valid = '1') then			--Data from RAM is valid
							dout 		<= din;				--Transmit value from RAM
							dout_valid_i<= '1';				--Data is valid

							--Check if all data have been transmitted
							if ((not len_dec1_g) and (ram_addr_i + '1' = len_data)) 
									or (len_dec1_g and (ram_addr_i + '1' > len_data)) then --Data has been fully transmitted
								cur_st 		<= reg_crc_st;		--Switch to next state - register the CRC value from CRC Interface
								read_addr_en<= '0';				--Address to RAM is not valid
								ram_addr_i	<= (others => '0'); --To prevent RAM address exceeding
							else
								ram_addr_i 	<= ram_addr_i + '1';--Increment position in block and RAM Address
								read_addr_en<= '1';				--Address to RAM is valid
								cur_st 		<= data_st;			--Stay at current block
							end if;
						
						else									--Data from RAM is not valid
							dout_valid_i	<= '0';				--Data is not valid for RAM
							cur_st			<= cur_st;			--Stay at current position
							read_addr_en	<= '1';				--Address to RAM is valid
							ram_addr_i		<= ram_addr_i; 		--Keep last address of RAM
						end if;
						
					when reg_crc_st =>
						dout_valid_i<= '0'; 					--Data is not valid
						blk_pos 	<= 1;						--Signal is not relevant for this block, prepare for next block
						read_addr_en<= '0';						--Address to RAM is not valid
						ram_addr_i	<= (others => '0');			--Zero Address to RAM
						if (crc_ack_i = '1') then				--CRC has been acknowledged
							cur_st <= crc_st;					--Switch to next state
						else
							cur_st <= reg_crc_st;				--Stay at current state
						end if;
					
					when crc_st =>
						read_addr_en<= '0';									--Address to RAM is not valid
						ram_addr_i	<= (others => '0');						--Zero Address to RAM
						dout 			<= crc_blk (crc_d_g * width_g - 1 downto (crc_d_g - 1) * width_g);	--Transmit CRC value
						dout_valid_i	<= '1';								--Data is valid

						if (blk_pos = crc_d_g) then				--CRC block has been fully transmitted
							blk_pos <= 1;						--Prepare block position at start of next block
							cur_st 	<= eof_st;					--Switch to next block transmit
						else
							blk_pos <= blk_pos + 1;				--Increment position in block
							cur_st 	<= crc_st;					--Stay at current block
						end if;
					
					when eof_st =>
						read_addr_en<= '0';						--Address to RAM is not valid
						ram_addr_i	<= (others => '0');			--Zero Address to RAM
						--Transmit EOF
						dout 		<= eof_blk (eof_d_g * width_g - 1 downto (eof_d_g - 1) * width_g); 		--Transmit EOF
						dout_valid_i<= '1';								--Data is valid

						if (eof_d_g > 1) then							--Shift Left the Shift Register
							eof_blk (eof_d_g * width_g - 1 downto 0) <= eof_blk (eof_d_g * width_g - 1 downto width_g) & zeros_c;
						end if;

						--Check if all EOF block has been transmitted. If so - switch to next block
						if (blk_pos = eof_d_g) then				--EOF block has been transmitted
							cur_st 	<= idle_st;					--End of transmission
							blk_pos <= 1;						--Prepare block position at start of next block
						else			
							blk_pos <= blk_pos + 1;				--Increment position in block
							cur_st <= eof_st;					--Stay at EOF state
						end if;
						
					when others =>	--This should never happen, since all states are covered
						report "Time: " & time'image(now) & ", Message Pack Encoder - Unimplemented state is being executed in FSM"
						severity error;
					
				end case;
			else
				dout_valid_i<= '0'; 			--Data not is valid
				cur_st 		<= cur_st; 			--Stay at current position
				read_addr_en<= '0';				--Address to RAM is not valid
				ram_addr_i	<= ram_addr_i;		--Keep last address of RAM
				blk_pos		<= blk_pos;			--Keep last value
			end if;
		end if;
	end process fsm_proc;
	
	---------------------------------------------------
	-----------  Process mp_done_proc -----------------
	---------------------------------------------------
	-- The process rises the mp_done flag, which means
	-- that all block has been transmitted
	---------------------------------------------------
	mp_done_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then	-- Reset
			mp_done		<= '0'; 					
		elsif rising_edge (clk) then
			if (cur_st = eof_st) and (blk_pos = eof_d_g) then
				mp_done <= '1';				-- Message pack has been successfully transmitted
			else
				mp_done <= '0';
			end if;
		end if;
	end process mp_done_proc;

	---------------------------------------------------
	-----------  Process req_crc_proc -----------------
	---------------------------------------------------
	-- The process rises the req_crc flag, to request
	-- from the CRC block to supply the current CRC
	---------------------------------------------------
	req_crc_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then	-- Reset
			req_crc		<= '0'; 					
		elsif rising_edge (clk) then
			if (cur_st = data_st) and 
			(((not len_dec1_g) and (ram_addr_i + '1' = len_data)) 
			or (len_dec1_g and (ram_addr_i + '1' > len_data))) then --Data has been fully transmitted
				req_crc <= '1';				-- Request for CRC
			else
				req_crc <= '0';
			end if;
		end if;
	end process req_crc_proc;

	---------------------------------------------------
	-----------  Process crc_register_proc ------------
	---------------------------------------------------
	-- The process register the CRC value from the CRC
	-- block, when the CRC is valid, and rises the
	-- crc_ack_i flag.
	---------------------------------------------------
	crc_register_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then			-- Reset
			crc_ack_i		<= '0'; 				-- CRC has not been acknowledged
			crc_blk			<= (others => '0');
		elsif rising_edge (clk) then
			if (cur_st = reg_crc_st) then			--Register CRC state
				if (crc_in_val = '1') then			--CRC from CRC block is valid
					crc_blk 	<= crc_in;			--Register the CRC
					crc_ack_i	<= '1';				--CRC is valid and has been acknowledged
				else	
					crc_blk		<= crc_blk;			--Keep last value
					crc_ack_i	<= crc_ack_i;  		--Keep last value
				end if;	

			elsif (cur_st = crc_st) then
				if (crc_d_g > 1) then				--Shift Left the Shift Register
					crc_blk (crc_d_g * width_g - 1 downto 0) <= crc_blk (crc_d_g * width_g - 1 downto width_g) & zeros_c;
				end if;
				crc_ack_i		<= '0';				--CRC has not been acknowledged

			else
				crc_blk			<= (others => '0');
				crc_ack_i		<= '0';				--CRC has not been acknowledged
			end if;
		end if;
	end process crc_register_proc;
	
	---------------------------------------------------
	-----------  Process crc_reset_proc ---------------
	---------------------------------------------------
	-- The process resets the CRC value, in case of 
	-- system reset or start of message pack.
	---------------------------------------------------
	crc_reset_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then-- Reset
			reset_crc		<= '1'; 	-- Reset the CRC value
		elsif rising_edge (clk) then
			if (cur_st = idle_st) then
				reset_crc	<= '1'; 	-- Reset the CRC value
			else
				reset_crc	<= '0';
			end if;
		end if;
	end process crc_reset_proc;

	---------------------------------------------------
	-----------  Process crc_data_proc ----------------
	---------------------------------------------------
	-- The process transmits valid data into the CRC
	-- block, and rises the valid data for CRC signal, 
	-- when data is valid.
	---------------------------------------------------
	crc_data_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then 					-- Reset
			data_crc	<= (others => '0');
			data_crc_val<= '0'; 							-- Data is not valid for CRC calculation
		elsif rising_edge (clk) then
			if (fifo_full = '0') and (dout_valid_i = '0') then
				case cur_st is
					when type_st =>
						data_crc	<= type_blk (type_d_g * width_g - 1 downto (type_d_g - 1) * width_g);	-- Transmit data for CRC
						data_crc_val<= '1'; 							-- Data is valid for CRC calculation
					when addr_st =>
						data_crc	<= addr_blk (addr_d_g * width_g - 1 downto (addr_d_g - 1) * width_g);	-- Transmit data for CRC
						data_crc_val<= '1'; 							-- Data is valid for CRC calculation
					when len_st =>
						data_crc	<= len_blk (len_d_g * width_g - 1 downto (len_d_g - 1) * width_g); 	-- Transmit data for CRC				
						data_crc_val<= '1'; 							-- Data is valid for CRC calculation
					when data_st =>
						if (din_valid = '1') then
							data_crc		<= din;			-- Transmit data for CRC
							data_crc_val	<= '1'; 		-- Data is valid for CRC calculation
						else
							data_crc	<= (others => '0');
							data_crc_val<= '0'; 			-- Data is not valid for CRC calculation
						end if;
					when others =>
						data_crc	<= (others => '0');
						data_crc_val<= '0'; 				-- Data is not valid for CRC calculation
				end case;
			else
				data_crc		<= (others => '0');
				data_crc_val	<= '0'; 					-- Data is not valid for CRC calculation
			end if;
		end if;
	end process crc_data_proc;
	
end architecture rtl_mp_enc;		