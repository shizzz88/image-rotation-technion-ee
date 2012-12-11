------------------------------------------------------------------------------------------------
-- Model Name 	:	RX_PATH
-- File Name	:	rx_path.vhd
-- Generated	:	4.4.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: A comprehensive component that includes all RX's relevant units, in order to work 
--				with Wishbone more easily.
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		4.4.2011	Alon Yavich			Creation
--			1.01		28.5.2011	Beeri Schreiber		Debbuged, Added Type states
------------------------------------------------------------------------------------------------
--	Todo:	
--			(1) Separate Wishbone into different entity
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rx_path is
   generic (
				--------------------- Common generic --------------------------------------------------------
				reset_polarity_g	:	std_logic 	:= '0';				--'0' - Active Low Reset, '1' Active High Reset
				--------------------- mp_dec's generics --------------------------------------------------------
				len_dec1_g			:	boolean  	:= true;			--TRUE - Recieved length is decreased by 1 ,to save 1 bit
																		--FALSE - Recieved length is the actual length			
				sof_d_g				:	positive 	:= 1;				--SOF Depth
				type_d_g			:	positive 	:= 1;				--Type Depth
				addr_d_g			:	positive 	:= 1;				--Address Depth
				len_d_g				:	positive 	:= 2;				--Length Depth
				crc_d_g				:	positive 	:= 1;				--CRC Depth
				eof_d_g				:	positive 	:= 1;				--EOF Depth						
				sof_val_g			:	natural 	:= 100;				--(64h) SOF block value. Upper block is MSB
				eof_val_g			:	natural 	:= 200;				--(C8h) EOF block value. Upper block is MSB				
				width_g				:	positive 	:= 8;				--Data Width (UART = 8 bits)
				--------------------- UART_RX's generics --------------------------------------------------------
				parity_en_g			:	natural range 0 to 1 := 0; 		--1 to Enable parity bit, 0 to disable parity bit
				parity_odd_g		:	boolean 	:= false; 			--TRUE = odd, FALSE = even
				uart_idle_g			:	std_logic 	:= '1';				--Idle line value
				baudrate_g			:	positive	:= 115200;			--UART baudrate
				clkrate_g			:	positive	:= 133333333;		--Sys. clock
				databits_g			:	natural range 5 to 8 := 8;		--Number of databits
				--------------------- RAM's generics --------------------------------------------------------				
				width_in_g			:	positive 				:= 8;	--Width of data
				addr_bits_g			:	positive 				:= 10;	--Depth of data	(2^10 = 1024 addresses)
				--------------------- Checksum's generics --------------------------------------------------------		
				signed_checksum_g	:	boolean		:= false;			--TRUE to signed checksum, FALSE to unsigned checksum
				checksum_init_val_g	:	integer	:= 0;					--Note that the initial value is given as an natural number, and not STD_LOGIC_VECTOR
				checksum_out_width_g:	natural := 8;					--Output CheckSum width
				data_width_g		:	natural := 8					--Input data width
           );
	port	(
				rst					:	in std_logic;							--System Reset
				uart_serial_in		:	in std_logic;							--Serial data in
				--------------------- Wishbone's common ports --------------------------------------------------------		
				clk_i 				:	in std_logic;							-- wishbone Clock
				--------------------- Wishbones Master's ports --------------------------------------------------------
				wbm_ack_i 			:	in std_logic;							-- When Read Burst: DATA bus must be valid in this cycle
				wbm_stall_i 		:	in std_logic;							-- Slave is not ready to receive new data
				wbm_err_i 			:	in std_logic;							-- Error flag: OOR Burst. Burst length is greater that 256-column address
				wbm_dat_i			:	in std_logic_vector(7 downto 0);		-- Input Data
				wbm_adr_o 			:	out std_logic_vector(9 downto 0);		-- Address 0-1023h
				wbm_cyc_o 			:	out std_logic;							-- Cycle Command to interface
				wbm_stb_o 			:	out std_logic;							-- Strobe Command to interface
				wbm_tga_o 			:	out std_logic_vector(9 downto 0);		-- Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
				wbm_tgc_o 			:	out std_logic;							-- Bus cycle tag: '1' write to REG, '0' write to RAM
				wbm_dat_o			:	out std_logic_vector(7 downto 0);		-- Output Data
				wbm_we_o			:	out std_logic							-- Write Enable
			);	

end entity rx_path;

architecture rtl_rx_path of rx_path is

-----------------------------------  Types   -------------------------------------
type wbm_states is 
				(
				wbm_idle_st,		--Idle state
				wbm_neg_st,			--Wait for STALL negation
				wbm_tx_st,			--transmitting Data
				wbm_wait_burst_st,	--End of burst
				wbm_tx_type_st,		--Trasnmit TYPE register
				wbm_wait_type_st	--Wait for end cycle in type register
				);
----------------------------------------------------------------------------------
--	###########################		Costants		##############################	--
	constant base_type_reg_addr_c	:	natural		:= 13;	--Type register Base address (0xD) 
	constant type_reg_clients_c		:	natural		:= 3;	--Clients: mem_mng, disp_ctrl, tx_path
---------------------------------  Components		------------------------------
component ram_simple
	generic (
				reset_polarity_g:	std_logic 	:= '0';								--'0' - Active Low Reset, '1' Active High Reset
				width_in_g		:	positive 	:= 8;								--Width of data
				addr_bits_g		:	positive 	:= 10								--Depth of data	(2^10 = 1024 addresses)
			);
	port	(
				clk				:	in std_logic;									--System clock
				rst				:	in std_logic;									--System Reset
				addr_in			:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Output address
				aout_valid		:	in std_logic;									--Output address is valid
				data_in			:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid		:	in std_logic; 									--Input data valid
				data_out		:	out std_logic_vector (width_in_g - 1 downto 0);	--Output data
				dout_valid		:	out std_logic 									--Output data valid
			);
end component;	
----------------------------------------------------------------------------------
component uart_rx
generic (
			parity_en_g			:		natural range 0 to 1 := 0; 	--1 to Enable parity bit, 0 to disable parity bit
			parity_odd_g		:		boolean 	:= false; 		--TRUE = odd, FALSE = even
			uart_idle_g			:		std_logic 	:= '1';			--Idle line value
			baudrate_g			:		positive	:= 115200;		--UART baudrate
			clkrate_g			:		positive	:= 133333333;	--Sys. clock
			databits_g			:		natural range 5 to 8 := 8;	--Number of databits
			reset_polarity_g	:		std_logic 	:= '0'	 		--'0' = Active Low, '1' = Active High
		);
port
	(
			din					:	in std_logic;					--Serial data in
			clk					:	in std_logic;					--Sys. clock
			reset				:	in std_logic;					--Reset
			dout				:	out std_logic_vector (databits_g + parity_en_g -1 downto 0);	--Parallel data out
			valid				:	out std_logic;					--Parallel data valid
			parity_err			:	out std_logic;					--Parity error
			stop_bit_err		:	out	std_logic					--Stop bit error
	);
end component;
----------------------------------------------------------------------------------
component mp_dec
generic (
			reset_polarity_g:	std_logic := '0'; 				--'0' = Active Low, '1' = Active High
			len_dec1_g		:	boolean := true;				--TRUE - Recieved length is decreased by 1 ,to save 1 bit
																--FALSE - Recieved length is the actual length
			sof_d_g			:	positive := 1;					--SOF Depth
			type_d_g		:	positive := 1;					--Type Depth
			addr_d_g		:	positive := 1;					--Address Depth
			len_d_g			:	positive := 2;					--Length Depth
			crc_d_g			:	positive := 1;					--CRC Depth
			eof_d_g			:	positive := 1;					--EOF Depth		
			sof_val_g		:	natural := 100;					-- (64h) SOF block value. Upper block is MSB
			eof_val_g		:	natural := 200;					-- (C8h) EOF block value. Upper block is MSB
			width_g			:	positive := 8					--Data Width (UART = 8 bits)
		);
port
	(
			--Inputs
			clk				:	in std_logic; 					--Clock
			rst				:	in std_logic;					--Reset
			din				:	in std_logic_vector (width_g - 1 downto 0); --Input data_d_g
			valid			:	in std_logic;					--Data valid
			--Message Pack Status
			mp_done			:	out std_logic;					--Message Pack has been recieved
			eof_err			:	out std_logic;					--EOF has not found
			crc_err			:	out std_logic;					--CRC error
			--Registers
			type_reg		:	out std_logic_vector (width_g * type_d_g - 1 downto 0);
			addr_reg		:	out std_logic_vector (width_g * addr_d_g - 1 downto 0);
			len_reg			:	out std_logic_vector (width_g * len_d_g - 1 downto 0);
			--CRC / CheckSum
			data_crc_val	:	out std_logic; 											--'1' when new data for CRC is valid, '0' otherwise
			data_crc		:	out std_logic_vector (width_g - 1 downto 0);			--Data to be calculated by CRC
			reset_crc		:	out std_logic; 											--'1' to reset CRC value
			req_crc			:	out std_logic; 											--'1' to request for current caluclated CRC
			crc_in			:	in std_logic_vector (width_g * crc_d_g -1 downto 0); 	--CRC value
			crc_in_val		:	in std_logic;  											--'1' when CRC is valid
			
			--Data (Payload)
			write_en		:	out std_logic; 											--'1' = Data is available (width_g length)
			write_addr		:	out std_logic_vector (width_g * len_d_g - 1 downto 0);	--RAM Address
			dout			:	out std_logic_vector (width_g - 1 downto 0) 			--Data to RAM
	);
end component mp_dec;
----------------------------------------------------------------------------------
component checksum_calc 
generic 	(
				reset_polarity_g	:	std_logic := '0'; 	--'0' = active low
				signed_checksum_g	:	boolean	:= false;	--TRUE to signed checksum, FALSE to unsigned checksum
				
				--IMPORTANT:
				--In case of a sign number, remmember that the MSB bit is reserved as the sign bit.
				--It means that the input / output data width represent a number sized (width-1)
				checksum_init_val_g	:	integer	:= 0;		--Note that the initial value is given as an natural number, and not STD_LOGIC_VECTOR
				
				--IMPORTANT:
				--checksum_out_width_g must be greater than or equal to data_width_g
				checksum_out_width_g:	natural := 8;		--Output CheckSum width
				data_width_g		:	natural := 8		--Input data width
			);
	port(           
		clock			: in  std_logic;	--Clock 
		reset			: in  std_logic; 	--Reset
		data			: in  std_logic_vector(data_width_g - 1 downto 0); --Data to calculate
		data_valid		: in  std_logic; 	--Data is Valid
		reset_checksum	: in  std_logic;	--Reset the current checksum to the initial value
		req_checksum	: in  std_logic;	--Request for valid checksum
		checksum_out	: out std_logic_vector(checksum_out_width_g - 1 downto 0); --Checksum value
		checksum_valid	: out std_logic 	--CheckSum valid
	);
end component; 
----------------------------------------------------------------------------------
--------------------------------  Signals ----------------------------------------
--General signals
	signal data_rx2dec		:	std_logic_vector (width_g - 1 downto 0); --Input data_d_g
	signal valid			:	std_logic; 							--Data valid
	--signal parity_err		:	std_logic; 							--Parity bit error
	signal sbit_err			:	std_logic; 							--Stop bit error
	signal sbit_err_status	:	std_logic; 							--Stop bit error
	signal ram_ready		:	std_logic;							--Active for 1 clock cycle, when all data has been stored to internal RAM
	signal ack_i_cnt		:	natural range 0 to 1024;			--Number of expected WBM_ACK_I
	signal err_i_status		:	std_logic;							--WBM_ERR_I has been received
	signal dat_1st_bool		:	boolean;							--TRUE: First read data on ram at each transaction, FALSE otherwise
	signal neg_cyc_bool		:	boolean;							--TRUE: Negate NOW (At this clock) WBM_CYC_O, FALSE otherwise
	signal wbm_cyc_internal	:	std_logic;							--Internal WBM_CYC_O
	signal wbm_stb_internal	:	std_logic;							--Internal WBM_STB_O
	signal wbm_adr_internal	:	std_logic_vector (9 downto 0);		--Internal WBM_ADR_O
	
	--Signals for RAM
	signal ram_addr_out		:	std_logic_vector (9 downto 0);		--Read address from RAM
	signal ram_aout_val		:	std_logic;							--Read address from RAM is valid
	signal ram_dout_valid	:	std_logic;							--Output data from RAM is valid
	signal ram_dout			:	std_logic_vector (width_g - 1 downto 0);
	--signal ram_dout			:	std_logic_vector (15 downto 0);		--Output data from RAM
	signal ram_full_addr	:	std_logic_vector (width_g * len_d_g - 1 downto 0);	--RAM address from MP Decoder
	alias  ram_expect_adr	:	std_logic_vector (9 downto 0) is ram_full_addr (9 downto 0);		--Current EXPECTED (and actual) write address to RAM
	signal ram_1st_data		:	std_logic_vector (7 downto 0);		--Holds first data of RAM at each transaction

	--Signals derived from RAM transactions
	signal ram_bytes_left	:	std_logic_vector (9 downto 0);		--Number of bytes (8 bits) stored in RAM, that has not been transfered YET 
	
	--Message Pack Status
	signal eof_err_status	:	std_logic; 							--EOF has not found
	signal crc_err_status	:	std_logic; 							--EOF has not found
	signal eof_err			:	std_logic; 							--EOF has not found
	signal crc_err			:	std_logic; 							--CRC error
	signal mp_done			:	std_logic;
	
	--Registers	
	signal type_reg			:	std_logic_vector (width_g * type_d_g - 1 downto 0);
	signal addr_reg			:	std_logic_vector (width_g * addr_d_g - 1 downto 0); 
	signal len_reg			:	std_logic_vector (width_g * len_d_g - 1 downto 0); 
	signal type_reg_offset	:	natural range 0 to type_reg_clients_c;	--Offset of type register. Used to point to specific component (mem_mng, disp_ctrl, tx_path)
	alias  datalen			:	std_logic_vector (9 downto 0) is len_reg (9 downto 0);
		
	--Data (Payload)	
	signal write_en			:	std_logic; 													--'1' = Data is available (width_g length)
	signal dec2ram			:	std_logic_vector (width_g - 1 downto 0) := (others => '0'); --Data to RAM
	
	--Decoder:
	signal dec2crc_valid	: std_logic; 													--'1' when new data for CRC is valid, '0' otherwise
	signal dec2crc_data	    : std_logic_vector (width_g - 1 downto 0); 						--Data to be calculated by CRC
	signal dec2crc_rst   	: std_logic; 													--'1' to reset CRC value
	signal dec2crc_req	    : std_logic; 													--'1' to request for current caluclated CRC
	signal crc2dec_data	    : std_logic_vector (width_g * crc_d_g -1 downto 0); 			--CRC value
	signal crc2dec_valid   	: std_logic;  													--'1' when CRC is valid
	
	--State machines
	signal wbm_cur_st		:	wbm_states;
----------------------------------------------------------------------------------	
begin
-------------------------  Components Implementation	--------------------------
	uart_rx_c : uart_rx generic map ( 
										parity_en_g		=> parity_en_g,		
										parity_odd_g	=> parity_odd_g,	
										uart_idle_g	    => uart_idle_g,	    
										baudrate_g		=> baudrate_g,		
										clkrate_g		=> clkrate_g,		
										databits_g		=> databits_g,		
										reset_polarity_g=> reset_polarity_g
								)
						port map (
										din		     => uart_serial_in,
										clk		     => clk_i,
										reset		 => rst,
										dout		 => data_rx2dec,
										valid		 => valid,
										--parity_err	 => parity_err,
										stop_bit_err => sbit_err
							);
										
	mp_dec1 : mp_dec	generic map (
										reset_polarity_g => reset_polarity_g,
										len_dec1_g		 => len_dec1_g,					
										sof_d_g			 => sof_d_g,			
										type_d_g		 => type_d_g,		
										addr_d_g		 => addr_d_g,		
										len_d_g			 => len_d_g,			
										crc_d_g			 => crc_d_g,			
										eof_d_g			 => eof_d_g,			
										sof_val_g		 => sof_val_g,		
										eof_val_g		 => eof_val_g,		
										width_g			 => width_g			
									)        
						port map (   		
										clk			 => clk_i,			
										rst			 => rst,
										din			 => data_rx2dec,
										valid		 => valid,										
										mp_done		 => mp_done,		
										eof_err		 => eof_err,		
										crc_err		 => crc_err,		
																
										type_reg	 => type_reg,	
										addr_reg	 => addr_reg,	
										len_reg		 => len_reg,		
													
										data_crc_val => dec2crc_valid,	
										data_crc	 => dec2crc_data,
										reset_crc	 => dec2crc_rst,
										req_crc		 => dec2crc_req,	
										crc_in		 => crc2dec_data,	
										crc_in_val	 => crc2dec_valid,
														
										write_en	 => write_en,	
										write_addr 	 => ram_full_addr,
										dout		 => dec2ram
										);

									
	ram_inst1 : ram_simple generic map (
										reset_polarity_g => reset_polarity_g,
										width_in_g		 => width_in_g,		
										addr_bits_g		 => addr_bits_g																							
									)
							port map (	
										clk			=>	clk_i,
										rst			=>	rst,
										addr_in		=>	ram_expect_adr, 
										addr_out	=>	ram_addr_out,
										aout_valid	=>	ram_aout_val,
										data_in		=>	dec2ram,
										din_valid	=>	write_en,
										data_out	=>	ram_dout,
										dout_valid	=>	ram_dout_valid
									);
									
	checksum_inst_dec : checksum_calc 	generic map (
										reset_polarity_g	 => reset_polarity_g,	
										signed_checksum_g	 =>	signed_checksum_g,					
										checksum_init_val_g	 => checksum_init_val_g,	
										checksum_out_width_g => checksum_out_width_g,
										data_width_g		 => data_width_g		                                                         										
												)
										port map (
										clock			=>	clk_i,	
										reset			=>	rst,
										data			=>	dec2crc_data,	
										data_valid		=>	dec2crc_valid,
										reset_checksum	=>	dec2crc_rst,
										req_checksum	=>	dec2crc_req,		            
										checksum_out	=>	crc2dec_data,	
										checksum_valid	=>	crc2dec_valid
										);
	
	------------------------------	Hidden processes	--------------------------

	--Cycle to Mem Man. (WBM_CYC_O)
	wbm_cyc_o_proc:
	wbm_cyc_o <= 	wbm_cyc_internal when (not neg_cyc_bool)
					else '0';
	
	--Strobe to Mem Man. (WBM_STB_O)
	wbm_stb_o_proc:
	wbm_stb_o	<= 	wbm_stb_internal;
						
	--Write enable to Mem Man. (WBM_WE_O) is always '1' for this component
	wbm_we_o_proc:
	wbm_we_o <= '1';
	
	--Output Address (WBM_ADR_O)
	wbm_adr_o_proc:
	wbm_adr_o	<=	wbm_adr_internal;
	
	--Data out (WBM_DAT_O)
	wbm_dat_o_proc:
	wbm_dat_o  <= 	type_reg when ((wbm_cur_st = wbm_tx_type_st) or (wbm_cur_st = wbm_wait_type_st))
					else ram_1st_data when dat_1st_bool
					else ram_dout;
	
	--Type check
	wbm_tgc_o  <= 	'1' when ((wbm_cur_st = wbm_tx_type_st) or (wbm_cur_st = wbm_wait_type_st))	--TYPE register tx
					else type_reg(7);

	---------------------------------------------------------------------------------
	----------------------------- Process ram_ready_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_ready signal, to signal the WBM to start writing
	-- to the SDRAM
	-----------wbm_tgc_o----------------------------------------------------------------------
	ram_ready_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_ready	<= '0';
		elsif rising_edge (clk_i) then
			if (mp_done = '1') 	--Message has beeen received, and not errors detected
			and (eof_err_status = '0') and (crc_err_status = '0') 
			and (sbit_err_status = '0') then --Parity is disabled ==> the follwoing phrase is not being executed (parity_err = '0')
				ram_ready	<= '1';
			else
				ram_ready	<= '0';
			end if;
		end if;
	end process ram_ready_proc;	
	
	-------------------------------------------------------------------------------------------
	----------------------------- Process wbm_fsm_proc	---------------------------------------
	-------------------------------------------------------------------------------------------
	-- The process is the FSM of the Wishbone Master, which transmit data to Memory Management
	-------------------------------------------------------------------------------------------
	wbm_fsm_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbm_cur_st		<= wbm_idle_st;
			wbm_tga_o		<= (others => '0');
			ram_addr_out	<= (others => '0');
			ram_bytes_left	<= (others => '0');
			wbm_adr_internal<= (others => '0');
			wbm_cyc_internal<= '0';
			wbm_stb_internal<= '0';
			ram_aout_val	<= '0';
			type_reg_offset	<= 0;
			
		elsif rising_edge (clk_i) then
			case wbm_cur_st is
				when wbm_idle_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out	<= (others => '0');
					wbm_adr_internal<= (others => '0');
					type_reg_offset	<= 0;

					ram_bytes_left	<= datalen;			--Latch number of words in RAM
					
					--Check whether data could be transmitted
					if (ram_ready = '1') then				--RAM is ready
						wbm_cur_st	<= wbm_tx_type_st;
						ram_aout_val<= '1';
					else
						wbm_cur_st 	<= wbm_idle_st;
						ram_aout_val<= '0';
					end if;
				
				when wbm_neg_st =>	--first RAM
					wbm_cyc_internal<= '1';
					wbm_stb_internal<= '1';
					ram_aout_val	<= '1';
					ram_addr_out	<= ram_addr_out + '1';
					ram_bytes_left	<= ram_bytes_left;
					wbm_cur_st		<= wbm_tx_st;
					wbm_tga_o		<= datalen;
					wbm_adr_internal<= "00" & addr_reg (7 downto 0);
	
				when wbm_tx_st =>
					wbm_cyc_internal<= '1';
					if (ram_bytes_left /= "000000000") then
						wbm_stb_internal<= wbm_stb_internal;
						if (wbm_stall_i = '0')then	--Slave ready	
							ram_addr_out	<= ram_addr_out + '1';
							wbm_adr_internal<= wbm_adr_internal + '1';
							ram_bytes_left	<= ram_bytes_left - '1';
						else										--STALL
							ram_addr_out	<= ram_addr_out;
							wbm_adr_internal<= wbm_adr_internal;
							ram_bytes_left	<= ram_bytes_left;
						end if;

						ram_aout_val	<= '1';
						wbm_cur_st		<= wbm_tx_st;

					elsif (wbm_stall_i = '0') then	--Slave ready, End of cycle	
							ram_addr_out	<= ram_addr_out;
							wbm_stb_internal<= '0';
							ram_aout_val	<= '0';
							wbm_cur_st		<= wbm_wait_burst_st;

					else						--Slave is not ready, Keep current position
						ram_addr_out	<= ram_addr_out;
						wbm_stb_internal<= wbm_stb_internal;
						ram_aout_val	<= '1';
						wbm_cur_st		<= wbm_cur_st;							
					end if;
					
				when wbm_wait_burst_st =>
					wbm_adr_internal<=wbm_adr_internal;
					ram_addr_out	<= ram_addr_out;
					ram_bytes_left	<= ram_bytes_left;

					--Burst length to Mem					
					if (wbm_stall_i = '1') then						--Not ready for next data	
						wbm_stb_internal	<= wbm_stb_internal;
					else
						wbm_stb_internal	<= '0';
					end if;

					if (err_i_status = '1') then					--An error has occured
						wbm_cyc_internal<= '0';
						wbm_cur_st		<= wbm_idle_st;
					elsif (ack_i_cnt = 0) then						--All data has been transmitted to SDRAM
						wbm_cyc_internal	<= '0';
						wbm_cur_st			<= wbm_idle_st;
					else											--Cycle is in progress
						wbm_cyc_internal<= '1';
						wbm_cur_st		<= wbm_wait_burst_st;
					end if;
					
				when wbm_tx_type_st =>
					wbm_cyc_internal<= '1';
					wbm_adr_internal<= conv_std_logic_vector (base_type_reg_addr_c + type_reg_offset, 10);
					wbm_stb_internal<= wbm_stb_internal;
					if (wbm_stall_i = '0')then	--Slave ready	
						wbm_stb_internal<= '0';
						type_reg_offset	<= type_reg_offset + 1;	--Prepre next client
						wbm_cur_st		<= wbm_wait_type_st;
					else										--STALL
						wbm_stb_internal<= '1';
						type_reg_offset	<= type_reg_offset;
						wbm_cur_st		<= wbm_cur_st;
					end if;
				
				when wbm_wait_type_st =>
					wbm_stb_internal	<= '0';

					if (err_i_status = '1') then						--An error has occured
						wbm_cyc_internal<= '0';
						wbm_adr_internal<= wbm_adr_internal;
						wbm_cur_st		<= wbm_idle_st;
					elsif (ack_i_cnt = 0) then							--All data has been transmitted to SDRAM
						wbm_cyc_internal	<= '0';
						wbm_adr_internal	<= (others => '0');
						if (type_reg_offset = type_reg_clients_c) then	--All clients had received Type Register Value
							wbm_cur_st		<= wbm_neg_st;
						else											--Transmit next client's type register
							wbm_cur_st		<= wbm_tx_type_st;
						end if;
							
					else												--Cycle is in progress
						wbm_cyc_internal<= '1';
						wbm_adr_internal<= wbm_adr_internal;
						wbm_cur_st		<= wbm_cur_st;
					end if;
					
				when others =>
					wbm_cur_st		<= wbm_idle_st;
					report "Time: " & time'image(now) & ", Mem_Ctrl_Wr, wbm_fsm_proc >> Undeclared state has been received!"
					severity error;
			end case;
		end if;
	end process wbm_fsm_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process first_data_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_1st_data signal, for first data transfer, and
	-- the dat_1st_bool signal, which indicates whether to use or not use the
	-- ram_1st_data signal.
	---------------------------------------------------------------------------------
	first_data_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_1st_data	<= (others => '0');
			dat_1st_bool	<= true;
		
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_neg_st) then
				dat_1st_bool	<= true;				--Use ram_1st_data as input to SDRAM
				ram_1st_data	<= ram_dout;			--Output value of RAM
			elsif (wbm_cur_st = wbm_tx_st) then
				ram_1st_data		<= ram_1st_data;	--Keep last value
				if (wbm_stall_i = '0') then
					dat_1st_bool<= false;
				else
					dat_1st_bool	<= dat_1st_bool;	--Keep last value
				end if;
				
			else
				ram_1st_data		<= ram_1st_data;	--Keep last value
				dat_1st_bool		<= dat_1st_bool;	--Keep last value
			end if;
		end if;
	end process first_data_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process ack_i_cnt_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process counts the number of WBM_ACK_I that has been received, which
	-- suppose to be equal to the number of WBM_STB_O that has been transmitted.
	---------------------------------------------------------------------------------
	ack_i_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ack_i_cnt	<= 0;
			neg_cyc_bool<= false;
			
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_neg_st) then
				ack_i_cnt <= conv_integer(datalen) + 1;
			elsif (wbm_cur_st = wbm_tx_type_st) then
				ack_i_cnt <= 1;	--Type Register TX
			elsif (wbm_ack_i = '1') and (ack_i_cnt > 0) then				--WBM_ACK_I has been received
				if (ack_i_cnt = 1) then
					neg_cyc_bool	<= true;
				else
					neg_cyc_bool	<= false;
				end if;
				ack_i_cnt	<= ack_i_cnt - 1;
			else
				ack_i_cnt	<= ack_i_cnt;
				neg_cyc_bool<= false;
			end if;
		end if;
	end process ack_i_cnt_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process err_i_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process sniffs for WBM_ERR_I from SDRAM.
	---------------------------------------------------------------------------------
	err_i_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			err_i_status	<= '0';
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_idle_st) then
				err_i_status	<= '0';
			else
				err_i_status	<= (err_i_status or wbm_err_i); --Sniff for WBM_ERR_I
			end if;
		end if;
	end process err_i_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process eof_err_proc	-----------------------------
	---------------------------------------------------------------------------------
	eof_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			eof_err_status	<= '0';
		elsif rising_edge (clk_i) then
			if (mp_done = '1') then
				eof_err_status	<= '0';
			else
				eof_err_status	<= (eof_err or eof_err_status); --Sniff for WBM_ERR_I
			end if;
		end if;
	end process eof_proc;
	---------------------------------------------------------------------------------
	----------------------------- Process crc_err_proc	-----------------------------
	---------------------------------------------------------------------------------
	crc_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			crc_err_status	<= '0';
		elsif rising_edge (clk_i) then
			if (mp_done = '1') then
				crc_err_status	<= '0';
			else
				crc_err_status	<= (crc_err or crc_err_status); --Sniff for WBM_ERR_I
			end if;
		end if;
	end process crc_proc;
	---------------------------------------------------------------------------------
	----------------------------- Process sbit_err_proc	-----------------------------
	---------------------------------------------------------------------------------
	sbit_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			sbit_err_status	<= '0';
		elsif rising_edge (clk_i) then
			if (mp_done = '1') then
				sbit_err_status	<= '0';
			else
				sbit_err_status	<= (sbit_err or sbit_err_status); --Sniff for WBM_ERR_I
			end if;
		end if;
	end process sbit_proc;
	
	--Parity is disabled in this project
	-- ---------------------------------------------------------------------------------
	-- ----------------------------- Process parity_err_proc	-------------------------
	-- ---------------------------------------------------------------------------------
	-- parity_proc: process (clk_i, rst)
	-- begin
		-- if (rst = reset_polarity_g) then
			-- parity_err_status	<= '0';
		-- elsif rising_edge (clk_i) then
			-- if (mp_done = '1') then
				-- parity_err_status	<= '0';
			-- else
				-- parity_err_status	<= (parity_err or parity_err_status); --Sniff for WBM_ERR_I
			-- end if;
		-- end if;
	-- end process parity_proc;
end architecture rtl_rx_path;        	            