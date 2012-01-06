------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Control Write Test Bench
-- File Name	:	rx_path_and_mem_wr_tb_tb.vhd
-- Generated	:	22.4.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: TB for rx_path_and_mem_wr_tb
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		22.4.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

library work ;
use work.ram_generic_pkg.all;

entity rx_path_and_mem_wr_tb is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				burst_len_g			:	positive 					:= 1030;--Burst length to SDRAM
				arbiter_delay_gnt_g	:	positive 					:= 3;	--Number of clocks between arbiter_req to arbiter_gnt
				mode_g				:	natural range 0 to 7 		:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
				message_g			:	natural range 0 to 7 		:= 1;	--Relevant bit in type register, which represent Image chunk ('0') or Summary chunk ('1') mode
				burst_len_dbg_g		:	positive range 1 to 1024	:= 500;	--Burst length in Debug Mode
				wr_addr_dbg_g		:	natural range 0 to 2**22-1	:= 2000;--Write address in Debug Mode
				img_hor_pixels_g	:	positive					:= 640;	--640 activepixels
				img_ver_lines_g		:	positive					:= 480	--480 active lines
			);
end entity rx_path_and_mem_wr_tb;

architecture sim_rx_path_and_mem_wr_tb of rx_path_and_mem_wr_tb is
component mem_mng_top
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				mode_g				:	natural range 0 to 7 		:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
				message_g			:	natural range 0 to 7 		:= 1;	--Relevant bit in type register, which represent Image chunk ('0') or Summary chunk ('1') mode
				img_hor_pixels_g	:	positive					:= 640;	--640 active pixels
				img_ver_lines_g		:	positive					:= 480	--480 active lines
			);
	port	(
				--Clock and Reset
				clk_i				:	in std_logic;							--Wishbone clock
				rst					:	in std_logic;							--Reset

				-- Wishbone Slave (mem_ctrl_wr)
				wr_wbs_adr_i		:	in std_logic_vector (9 downto 0);		--Address in internal RAM
				wr_wbs_tga_i		:	in std_logic_vector (9 downto 0);		--Burst Length
				wr_wbs_dat_i		:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
				wr_wbs_cyc_i		:	in std_logic;							--Cycle command from WBM
				wr_wbs_stb_i		:	in std_logic;							--Strobe command from WBM
				wr_wbs_tgc_i		:	in std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wr_wbs_we_i			:	in std_logic;							--Write Enable
				wr_wbs_dat_o		:	out std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wr_wbs_stall_o		:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wr_wbs_ack_o		:	out std_logic;							--Input data has been successfuly acknowledged
				wr_wbs_err_o		:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

				-- Wishbone Slave (mem_ctrl_rd)
				rd_wbs_adr_i 		:	in std_logic_vector (9 downto 0);		--Address in internal RAM
				rd_wbs_tga_i 		:   in std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				rd_wbs_cyc_i		:   in std_logic;							--Cycle command from WBM
				rd_wbs_tgc_i 		:   in std_logic;							--Cycle tag. '1' indicates start of transaction
				rd_wbs_stb_i		:   in std_logic;							--Strobe command from WBM
				rd_wbs_dat_o 		:  	out std_logic_vector (7 downto 0);		--Data Out (8 bits)
				rd_wbs_stall_o		:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				rd_wbs_ack_o		:   out std_logic;							--Input data has been successfuly acknowledged
				rd_wbs_err_o		:   out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				-- Wishbone Master to SDRAM Controller from Arbiter
				wbm_dat_i			:	in std_logic_vector (15 downto 0);		--Data in (16 bits)
				wbm_stall_i			:	in std_logic;							--Slave is not ready to receive new data
				wbm_err_i			:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
				wbm_ack_i			:	in std_logic;							--When Read Burst: DATA bus must be valid in this cycle
				wbm_adr_o			:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
				wbm_dat_o			:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
				wbm_we_o			:	out std_logic;							--Write Enable
				wbm_tga_o			:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
				wbm_cyc_o			:	out std_logic;							--Cycle Command to interface
				wbm_stb_o			:	out std_logic							--Strobe Command to interface
			);
end component mem_mng_top;

component sdram_controller 
  generic
	   (
		reset_polarity_g	:	std_logic	:= '0' --When rst = reset_polarity_g, system is in RESET mode
		);
  port (
		--Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		pll_locked	:	in std_logic;	--PLL Locked indication, for CKE (Clock Enable) signal to SDRAM
		
		--SDRAM Signals
		dram_addr	:	out std_logic_vector (11 downto 0);		--Address (12 bit)
		dram_bank	:	out std_logic_vector (1 downto 0);		--Bank
		dram_cas_n	:	out std_logic;							--Column Address is being transmitted
		dram_cke	:	out std_logic;							--Clock Enable
		dram_cs_n	:	out std_logic;							--Chip Select (Here - Mask commands)
		dram_dq		:	inout std_logic_vector (15 downto 0);	--Data in / Data out
		dram_ldqm	:	out std_logic;							--Byte masking
		dram_udqm	:	out std_logic;							--Byte masking
		dram_ras_n	:	out std_logic;							--Row Address is being transmitted
		dram_we_n	:	out std_logic;							--Write Enable
   
		-- Wishbone Slave signals to Read/Write interface
		wbs_adr_i	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbs_dat_i	:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbs_we_i	:	in std_logic;							--Write Enable
		wbs_tga_i	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbs_cyc_i	:	in std_logic;							--Cycle Command from interface
		wbs_stb_i	:	in std_logic;							--Strobe Command from interface
		wbs_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data
		wbs_err_o	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbs_ack_o	:	out std_logic							--When Read Burst: DATA bus must be valid in this cycle
   );
end component sdram_controller;

component sdram_model
	GENERIC (
		addr_bits : INTEGER := 12;
		data_bits : INTEGER := 16 ;
		col_bits  : INTEGER := 8
		);
	PORT (
		Dq		: inout std_logic_vector (15 downto 0) := (others => 'Z');
		Addr    : in    std_logic_vector (11 downto 0) ;-- := (others => '0');
		Ba      : in    std_logic_vector(1 downto 0);-- := "00";
		Clk     : in    std_logic ;--:= '0';
		Cke     : in    std_logic ;--:= '0';
		Cs      : in    std_logic ;--:= '1';
		Ras     : in    std_logic ;--:= '0';
		Cas     : in    std_logic ;--:= '0';
		We      : in    std_logic ;--:= '0';
		Dqm     : in    std_logic_vector(1 downto 0)-- := (others => 'Z')
		);
	
END component;

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

--Clock and Reset
signal clk_133		:	std_logic := '0'; --133 MHz
signal rst			:	std_logic := '0'; --Reset

--SDRAM Signals
signal dram_addr	:	std_logic_vector (11 downto 0);
signal dram_bank	:	std_logic_vector (1 downto 0);
signal dram_cas_n	:	std_logic;
signal dram_cke		:	std_logic;
signal dram_cs_n	:	std_logic;
signal dram_dq		:	std_logic_vector (15 downto 0);
signal dram_ldqm	:	std_logic;
signal dram_udqm	:	std_logic;
signal dram_ras_n	:	std_logic;
signal dram_we_n	:	std_logic;


-- Wishbone Slave signals (mem_ctrl_wr)
signal wr_wbs_adr_i	:	std_logic_vector (9 downto 0);		--Address in internal RAM
signal wr_wbs_tga_i	:	std_logic_vector (9 downto 0);		--Burst Length
signal wr_wbs_dat_i	:	std_logic_vector (7 downto 0);		--Data In (8 bits)
signal wr_wbs_cyc_i	:	std_logic;							--Cycle command from WBM
signal wr_wbs_tgc_i	:	std_logic;							--Cycle Tag
signal wr_wbs_stb_i	:	std_logic;							--Strobe command from WBM
signal wr_wbs_stall_o:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal wr_wbs_ack_o	:	std_logic;							--Input data has been successfuly acknowledged
signal wr_wbs_err_o	:	std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
signal wr_wbs_we_i	:	std_logic;							--Write Enable
signal wr_wbs_dat_o	:	std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)

-- Wishbone Slave signal (mem_ctrl_rd)
signal rd_wbs_adr_i :	std_logic_vector (9 downto 0);		--Address in internal RAM
signal rd_wbs_tga_i :   std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
signal rd_wbs_cyc_i	:   std_logic;							--Cycle command from WBM
signal rd_wbs_tgc_i :   std_logic;							--Cycle tag. '1' indicates start of transaction
signal rd_wbs_stb_i	:   std_logic;							--Strobe command from WBM
signal rd_wbs_dat_o :  	std_logic_vector (7 downto 0);		--Data Out (8 bits)
signal rd_wbs_stall_o:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal rd_wbs_ack_o	:   std_logic;							--Input data has been successfuly acknowledged
signal rd_wbs_err_o	:   std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

-- Wishbone Master signals to SDRAM from Arbiter
signal wbm_adr_o	:	std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
signal wbm_dat_o	:	std_logic_vector (15 downto 0);		--Data Out (16 bits)
signal wbm_dat_i	:	std_logic_vector (15 downto 0);		--Data in (16 bits)
signal wbm_we_o		:	std_logic;							--Write Enable
signal wbm_tga_o	:	std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
signal wbm_cyc_o	:	std_logic;							--Cycle Command to interface
signal wbm_stb_o	:	std_logic;							--Strobe Command to interface
signal wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data
signal wbm_err_i	:	std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
signal wbm_ack_i	:	std_logic;							--When Read Burst: DATA bus must be valid in this cycle
--UART
signal uart_serial_in	:	std_logic;


begin
	--Clock process
	clk_proc:
	clk_133 <= not clk_133 after 3.75 ns;
	
	--Reset process
	rst_proc:
	rst 	<= reset_polarity_g, not reset_polarity_g after 400 ns;
	
	sdr_ctrl : sdram_controller 	generic map (
										reset_polarity_g  	=> reset_polarity_g
										)
									port map(
										clk_i		=> clk_133,
	                                    rst			=> rst,
	                                    pll_locked	=> '1',
	                                    
	                                    dram_addr	=> dram_addr,	
	                                    dram_bank	=> dram_bank,	
	                                    dram_cas_n	=> dram_cas_n,	
	                                    dram_cke	=> dram_cke,	
	                                    dram_cs_n	=> dram_cs_n,	
	                                    dram_dq		=> dram_dq,		
	                                    dram_ldqm	=> dram_ldqm,	
	                                    dram_udqm	=> dram_udqm,	
	                                    dram_ras_n	=> dram_ras_n,	
	                                    dram_we_n	=> dram_we_n,	
	                                    
	                                    wbs_adr_i	=> wbm_adr_o,	
	                                    wbs_dat_i	=> wbm_dat_o,	
										wbs_we_i	=> wbm_we_o	,
										wbs_tga_i	=> wbm_tga_o,	
										wbs_cyc_i	=> wbm_cyc_o,	
										wbs_stb_i	=> wbm_stb_o,	
										wbs_dat_o	=> wbm_dat_i,	
										wbs_stall_o	=> wbm_stall_i,	
										wbs_err_o	=> wbm_err_i,	
										wbs_ack_o	=> wbm_ack_i
									);
									
	
	sdram_model_inst : sdram_model port map (
										Dq		=> dram_dq,	
	                                    Addr    => dram_addr,
	                                    Ba      => dram_bank,
	                                    Clk     => clk_133,
	                                    Cke     => dram_cke,
	                                    Cs      => dram_cs_n,
	                                    Ras     => dram_ras_n,
	                                    Cas     => dram_cas_n,
	                                    We      => dram_we_n,
	                                    Dqm(0)  => dram_ldqm,
	                                    Dqm(1)  => dram_udqm
									);
									
	mem_mng_top_inst: mem_mng_top generic map
									(
										reset_polarity_g	=>	reset_polarity_g,
									    mode_g			    =>	mode_g,			
									    message_g		    =>	message_g,		
									    img_hor_pixels_g    =>	img_hor_pixels_g,
									    img_ver_lines_g	    =>	img_ver_lines_g	
									)
								port map
									(
										clk_i			=>	clk_133,			
										rst				=>	rst,

										wr_wbs_adr_i	=>	wr_wbs_adr_i	,		
										wr_wbs_tga_i	=>	wr_wbs_tga_i	,
										wr_wbs_dat_i	=>	wr_wbs_dat_i	,
										wr_wbs_cyc_i	=>	wr_wbs_cyc_i	,
										wr_wbs_stb_i	=>	wr_wbs_stb_i	,
										wr_wbs_we_i		=>	wr_wbs_we_i		,
										wr_wbs_tgc_i	=>	wr_wbs_tgc_i	,
										wr_wbs_dat_o	=>	wr_wbs_dat_o	,
										wr_wbs_stall_o	=>	wr_wbs_stall_o	,
										wr_wbs_ack_o	=>	wr_wbs_ack_o	,
										wr_wbs_err_o	=>	wr_wbs_err_o	,
                                                        
										rd_wbs_adr_i 	=>	rd_wbs_adr_i 	,	
										rd_wbs_tga_i 	=>	rd_wbs_tga_i 	,
										rd_wbs_cyc_i	=>	rd_wbs_cyc_i	,
										rd_wbs_tgc_i 	=>	rd_wbs_tgc_i 	,
										rd_wbs_stb_i	=>	rd_wbs_stb_i	,
										rd_wbs_dat_o 	=>	rd_wbs_dat_o 	,
										rd_wbs_stall_o	=>	rd_wbs_stall_o	,
										rd_wbs_ack_o	=>	rd_wbs_ack_o	,
										rd_wbs_err_o	=>	rd_wbs_err_o	,
										                
										wbm_dat_i		=>	wbm_dat_i	    ,
										wbm_stall_i		=>	wbm_stall_i	    ,
										wbm_err_i		=>	wbm_err_i	    ,
										wbm_ack_i		=>	wbm_ack_i	    ,
										wbm_adr_o		=>	wbm_adr_o	    ,
										wbm_dat_o		=>	wbm_dat_o	    ,
										wbm_we_o		=>	wbm_we_o	    ,
										wbm_tga_o		=>	wbm_tga_o	    ,
										wbm_cyc_o		=>	wbm_cyc_o	    ,
										wbm_stb_o		=>	wbm_stb_o	
									);
									

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

rx_path_inst : rx_path 
	port map (
				rst				=> rst, 				
				uart_serial_in	=> uart_serial_in,
				--------------------
				clk_i 			=> clk_133,
				--------------------                        
				wbm_ack_i 		=>	wr_wbs_ack_o 	,	        
				wbm_stall_i 	=>	wr_wbs_stall_o ,	        
				wbm_err_i 		=>	wr_wbs_err_o 	,	        
				wbm_dat_i		=>	wr_wbs_dat_o	,	        
				wbm_adr_o 		=>	wr_wbs_adr_i 	,	        
				wbm_cyc_o 		=>	wr_wbs_cyc_i 	,	        
				wbm_stb_o 		=>	wr_wbs_stb_i 	,	        
				wbm_tga_o 		=>	wr_wbs_tga_i 	,	        
				wbm_tgc_o 		=>	wr_wbs_tgc_i 	,	        
				wbm_dat_o		=>	wr_wbs_dat_i	,	
				wbm_we_o		=>	wr_wbs_we_i		
			);	
										
end architecture sim_rx_path_and_mem_wr_tb;