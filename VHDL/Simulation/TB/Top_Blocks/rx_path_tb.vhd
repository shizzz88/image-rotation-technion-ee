------------------------------------------------------------------------------------------------
-- Model Name 	:	RX Path TB
-- File Name	:	rx_path_tb.vhd
-- Generated	:	28.5.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: RX Path Top TB
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		28.5.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rx_path_tb is
end entity rx_path_tb;

architecture sim_rx_path_tb of rx_path_tb is

--#############################	Components	##############################################--

component rx_path
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
end component rx_path;

component uart_tx_gen_model 
   generic (
            --File name explanasion:
			--File name is being named <file_name_g>_<file_idx>.<file_extension_g>
			--i.e: uart_tx_1.txt, uart_tx_2.txt ....
			--file_max_idx_g is the maximum index for files. For example: suppose this
			--parameter is 2, then transmission file order will be:
			-- (1)uart_tx_1.txt (2)uart_tx_2.txt (3) uart_tx_1.txt (4) uart_tx_2.txt ...
			file_name_g			:		string 		:= "uart_tx"; 		--File name to be transmitted
			file_extension_g	:		string		:= "txt";			--File extension
			file_max_idx_g		:		positive	:= 2;				--Maximum file index.
			delay_g				:		positive	:= 10;				--Number of clock cycles delay between two files transmission
			 
			clock_period_g		:		time		:= 8.68 us;			--8.68us = 115,200 Bits/sec
			parity_en_g			:		natural range 0 to 1 := 0; 		--1 to Enable parity bit, 0 to disable parity bit
			parity_odd_g		:		boolean 	:= false; 			--TRUE = odd, FALSE = even
			msb_first_g			:		boolean 	:= false; 			--TRUE = MSB First, FALSE = LSB first
			uart_idle_g			:		std_logic 	:= '1' 				--Idle line value
           );
   port
   	   (
   	     system_clk	:	in std_logic := '0'; 				--System clock, for Valid for one clock
		 uart_out	:	out std_logic := '1';				--Serial data out (UART)
		 value		:	out std_logic_vector (7 downto 0) := (others => '0'); 	--Transmitted value (For user convenience - to see the transmitted value)
		 valid		:	out std_logic := '0'				--Valid value (8 bit) - Active for one clock (For Parallel data simulation)
   	   );
end component uart_tx_gen_model;

component global_nets_top
	generic (
			reset_polarity_g	:	std_logic := '0'		--When '0' - Reset
			);
	port (
			fpga_clk		:	in std_logic ;				--Input clock to the FPGA (50MHz)
			fpga_rst		:	in std_logic ;				--Input reset from FPGA
			sdram_clk		:	out std_logic ;				--Output SDRAM clock (133MHz)
			vesa_clk		:	out std_logic ;				--Output VESA clock (40MHz)
			sync_sdram_rst	:	out std_logic ;				--Output Synchronized reset - 133MHz
			sync_vesa_rst	:	out std_logic				--Output Synchronized reset - 40MHz
		);
end component global_nets_top;
--#############################	Signals ##############################################--

--Clock and Reset
signal clk_133			:	std_logic := '0';
signal rst_133			:	std_logic := '1';
--UART
signal uart_serial_in	:	std_logic;
-- Wishbone Master (RX Block)
signal rx_wbm_adr_o		:	std_logic_vector (9 downto 0);		--Address in internal RAM
signal rx_wbm_tga_o		:	std_logic_vector (9 downto 0);		--Burst Length
signal rx_wbm_dat_i		:	std_logic_vector (7 downto 0);		--Data In (8 bits)
signal rx_wbm_cyc_o		:	std_logic;							--Cycle command from WBM
signal rx_wbm_stb_o		:	std_logic;							--Strobe command from WBM
signal rx_wbm_we_o		:	std_logic;							--Write Enable
signal rx_wbm_tgc_o		:	std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
signal rx_wbm_dat_o		:	std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
signal rx_wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal rx_wbm_ack_i		:	std_logic;							--Input data has been successfuly acknowledged
signal rx_wbm_err_i		:	std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)


--#############################	Instantiaion ##############################################--
begin

clk_proc:
clk_133	<=	not clk_133 after 3.75 ns;

rst_proc:
rst_133	<=	'0', '1' after 10 ns;

uart_gen_inst :  uart_tx_gen_model generic map (
			file_name_g			=> "uart_tx", 		--File name to be transmitted
			file_extension_g	=> "txt",			--File extension
			file_max_idx_g		=> 2,				--Maximum file index.
			msb_first_g			=> false,
			delay_g				=> 10				--Number of clock cycles delay between two files transmission
           )
		port map
		(
			system_clk		=> clk_133,
			uart_out		=> uart_serial_in
		);

-- global_nets_inst : global_nets_top port map (
			-- fpga_clk		=>	clk_50,
			-- fpga_rst		=>	rst_50,
			-- sdram_clk		=>	clk_133,
			-- vesa_clk		=>	clk_40,
			-- sync_sdram_rst	=>	rst_133,
			-- sync_vesa_rst	=>	rst_40
		-- );		

rx_path_inst : rx_path 
	port map (
				rst				=> rst_133, 				
				uart_serial_in	=> uart_serial_in,
				--------------------
				clk_i 			=> clk_133,
				--------------------
				wbm_ack_i 		=>	wbm_ack_i 	,	
				wbm_stall_i 	=>	wbm_stall_i ,	
				wbm_err_i 		=>	wbm_err_i 	,	
				wbm_dat_i		=>	wbm_dat_i	,	
				wbm_adr_o 		=>	wbm_adr_o 	,	
				wbm_cyc_o 		=>	wbm_cyc_o 	,	
				wbm_stb_o 		=>	wbm_stb_o 	,	
				wbm_tga_o 		=>	wbm_tga_o 	,	
				wbm_tgc_o 		=>	wbm_tgc_o 	,	
				wbm_dat_o		=>	wbm_dat_o	,	
				wbm_we_o		=>	wbm_we_o		
			);	
			
wbs_proc: process 
begin
	wbm_ack_i	<=	'0';
	wbm_err_i	<=	'0';
	wbm_dat_i	<=	(others => '0');
	wbm_stall_i	<=	'1';
	wait until (wbm_cyc_o = '1') and (wbm_stb_o = '1');
	wait until rising_edge(clk_133);
	wbm_stall_i	<= '0';
	wait until rising_edge(clk_133);
	while (wbm_stb_o = '1') loop
		wbm_ack_i	<= '1';
		wait until rising_edge(clk_133);
	end loop;
	wbm_ack_i	<= '0';
end process wbs_proc;

end architecture sim_rx_path_tb;