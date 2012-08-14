------------------------------------------------------------------------------------------------
-- Model Name 	:	Modular Decompression System TOP
-- File Name	:	mds_top.vhd
-- Generated	:	25.5.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Modular Decompression System TOP
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		25.5.2011	Beeri Schreiber			Creation
--			1.01		24.1.2012	Ran&Uri					crrating generics map in mem_mng_top, disp_ctrl_top
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) Change hidden processes after implementing INTERCON
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mds_top is
	generic (
--				rep_size_g			:	positive	:= 8;				--2^7=128 => Maximum of 128 repetitions for pixel / line
				baudrate_g			:	positive	:= 115200
			);
	port	(
				--Clock and Reset from system
				clk_133				:	in std_logic;
				clk_40				:	in std_logic;
				rst_133				:	in std_logic;
				rst_40				:	in std_logic;
				
				--UART
				uart_serial_in		:	in std_logic;
				uart_serial_out		:	out std_logic;
				
				--SDRAM Signals
				dram_addr			:	out std_logic_vector (11 downto 0);		--Address (12 bit)
				dram_bank			:	out std_logic_vector (1 downto 0);		--Bank
				dram_cas_n			:	out std_logic;							--Column Address is being transmitted
				dram_cke			:	out std_logic;							--Clock Enable
				dram_cs_n			:	out std_logic;							--Chip Select (Here - Mask commands)
				dram_dq				:	inout std_logic_vector (15 downto 0);	--Data in / Data out
				dram_ldqm			:	out std_logic;							--Byte masking
				dram_udqm			:	out std_logic;							--Byte masking
				dram_ras_n			:	out std_logic;							--Row Address is being transmitted
				dram_we_n			:	out std_logic;							--Write Enable
				
				--VESA signals
					--Output RGB
				r_out				:	out std_logic_vector(9 downto 0);		--Output R Pixel
				g_out				:	out std_logic_vector(9 downto 0);   	--Output G Pixel
				b_out				:	out std_logic_vector(9 downto 0);  		--Output B Pixel
				
					--Blanking signal
				blank				:	out std_logic;										--Blanking signal
					
					--Sync Signals			
				hsync				:	out std_logic;										--HSync Signal
				vsync				:	out std_logic										--VSync Signal
			);
end entity mds_top;

architecture rtl_mds_top of mds_top is


--#############################	Constants	##############################################--
constant num_of_wbs_z_c	:	natural := 4;	--4 WBS to INTERCON Z
constant num_of_wbm_z_c :	natural := 2;	--2 WBM to INTERCON Z

--#############################	Components	##############################################--
component intercon
		generic 	
			(
				reset_polarity_g	:	std_logic 	:=	'0';		--Reset polarity: '0' is active low, '1' is active high
				num_of_wbm_g		:	positive	:=	1;			--Number of Wishbone Masters
				num_of_wbs_g		:	positive	:=	3;			--Number of Wishbone Slaves
				adr_width_g			:	positive	:=	10;			--Address width
				blen_width_g		:	positive	:=	10;			--Maximum Burst length
				data_width_g		:	positive	:=	8			--Data Width
			);
		
		port
			(
				--Clock and Reset
				clk_i				:	in std_logic;
				rst					:	in std_logic;
				
				--'ic_' = INTERCON.
				--WBM/WBS ports should be connected to the same port.
				--i.e: wbm_dat_o of the WBM should be connected to ic_wbm_dat_o of the INTERCON
				
				--Signals from INTERCON to WBS
				ic_wbs_adr_i		:	out std_logic_vector (num_of_wbs_g * adr_width_g - 1 downto 0);		--Address in internal RAM
				ic_wbs_tga_i		:	out std_logic_vector (num_of_wbs_g * blen_width_g - 1 downto 0);	--Burst Length
				ic_wbs_dat_i		:	out std_logic_vector (num_of_wbs_g * data_width_g - 1 downto 0);	--Data In (8 bits)
				ic_wbs_cyc_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Cycle command from WBM
				ic_wbs_stb_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Strobe command from WBM
				ic_wbs_we_i			:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Write Enable
				ic_wbs_tgc_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Cycle tag: '0' = Write to components, '1' = Write to registers
				
				--Signals from INTERCON to WBM 
				ic_wbm_dat_i		:	out std_logic_vector (num_of_wbm_g * data_width_g - 1 downto 0);	--Data Out for reading registers (8 bits)
				ic_wbm_stall_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				ic_wbm_ack_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Input data has been successfuly acknowledged
				ic_wbm_err_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				--Signals from WBM to INTERCON
				ic_wbm_adr_o		:	in std_logic_vector (num_of_wbm_g * adr_width_g - 1 downto 0);		--Address in internal RAM
				ic_wbm_tga_o		:	in std_logic_vector (num_of_wbm_g * blen_width_g - 1 downto 0);		--Burst Length
				ic_wbm_dat_o		:	in std_logic_vector (num_of_wbm_g * data_width_g - 1 downto 0);		--Data In (8 bits)
				ic_wbm_cyc_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Cycle command from WBM
				ic_wbm_stb_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Strobe command from WBM
				ic_wbm_we_o			:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Write Enable
				ic_wbm_tgc_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Cycle tag: '0' = Write to components, '1' = Write to registers
				
				--Signals from WBS to INTERCON
				ic_wbs_dat_o		:	in std_logic_vector (num_of_wbs_g * data_width_g - 1 downto 0);		--Data Out for reading registers (8 bits)
				ic_wbs_stall_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0);					--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				ic_wbs_ack_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0);					--Input data has been successfuly acknowledged
				ic_wbs_err_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0)						--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
			);
end component intercon;

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
				wr_wbs_we_i			:	in std_logic;							--Write Enable
				wr_wbs_tgc_i		:	in std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
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


component img_man_top is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
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
				wr_wbs_we_i			:	in std_logic;							--Write Enable
				wr_wbs_tgc_i		:	in std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wr_wbs_dat_o		:	out std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wr_wbs_stall_o		:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wr_wbs_ack_o		:	out std_logic;							--Input data has been successfuly acknowledged
				wr_wbs_err_o		:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

				-- Wishbone Slave (mem_ctrl_rd)
			--	rd_wbs_adr_i 		:	in std_logic_vector (9 downto 0);		--Address in internal RAM
			--	rd_wbs_tga_i 		:   in std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
			--	rd_wbs_cyc_i		:   in std_logic;							--Cycle command from WBM
			--	rd_wbs_tgc_i 		:   in std_logic;							--Cycle tag. '1' indicates start of transaction
			--	rd_wbs_stb_i		:   in std_logic;							--Strobe command from WBM
			--	rd_wbs_dat_o 		:  	out std_logic_vector (7 downto 0);		--Data Out (8 bits)
			--	rd_wbs_stall_o		:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
			--	rd_wbs_ack_o		:   out std_logic;							--Input data has been successfuly acknowledged
			--	rd_wbs_err_o		:   out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
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
end component img_man_top;

component disp_ctrl_top is
	generic (
			reset_polarity_g		:	std_logic 	:= '0';				--Reset Polarity. '0' = Reset
			
			--VESA Generics
			hsync_polarity_g		:	std_logic 	:= '1';				--Positive HSync
			vsync_polarity_g		:	std_logic 	:= '1';				--Positive VSync
			blank_polarity_g		:	std_logic	:= '0';				--When '0' - Blanking signal to the VGA
			
			red_default_color_g		:	natural 	:= 0;				--Default Red pixel for Frame
			green_default_color_g	:	natural 	:= 0;				--Default Green pixel for Frame
			blue_default_color_g	:	natural 	:= 0;				--Default Blue pixel for Frame
			
			red_width_g				:	positive 	:= 8;				--Default std_logic_vector size of Red Pixels
			green_width_g			:	positive 	:= 8;				--Default std_logic_vector size of Green Pixels
			blue_width_g			:	positive 	:= 8;				--Default std_logic_vector size of Blue Pixels
			req_delay_g				:	positive	:= 1;				--Number of clocks between the "req_data" request to the "data_valid" answer
			req_lines_g				:	positive	:= 3;				--Number of lines to request from image transmitter, to hold in its FIFO
							
			hor_active_pixels_g		:	positive	:= 800;				--800 active pixels per line
			ver_active_lines_g		:	positive	:= 600;				--600 active lines
			hor_left_border_g		:	natural		:= 0;				--Horizontal Left Border (Pixels)
			hor_right_border_g		:	natural		:= 0;				--Horizontal Right Border (Pixels)
			hor_back_porch_g		:	integer		:= 88;				--Horizontal Back Porch (Pixels)
			hor_front_porch_g		:	integer		:= 40;				--Horizontal Front Porch (Pixels)
			hor_sync_time_g			:	integer		:= 128;				--Horizontal Sync Time (Pixels)
			ver_top_border_g		:	natural		:= 0;				--Vertical Top Border (Lines)
			ver_buttom_border_g		:	natural		:= 0;				--Vertical Bottom Border (Lines)
			ver_back_porch_g		:	integer		:= 23;				--Vertical Back Porch (Lines)
			ver_front_porch_g		:	integer		:= 1;				--Vertical Front Porch (Lines)
			ver_sync_time_g			:	integer		:= 4;				--Vertical Sync Time (Lines)
			
			--Type Register Generics
			synth_bit_g				:	natural range 0 to 7 := 2;		--Relevant bit in type register, which represent Image from SDRAM ('0') or from Synthetic Pattern Generator ('1') 
			
			--Pixel Manager & RunLen-Exctractor generics
--			rep_size_g				:	positive	:= 7;				--2^7=128 => Maximum of 128 repetitions for pixel / line
			
			--General FIFO Generics
			fifo_depth_g 			: positive		:= 4864;			-- Maximum elements in FIFO
			fifo_log_depth_g		: natural		:= 13;				-- Logarithm of depth_g (Number of bits to represent depth_g. 2^10=1024)
			
			--Synthetic Fram Generator
			change_frame_clk_g		:	positive	:= 120000000;		--Change frame position each 'change_frame_clk_g' clocks
			hor_pres_pixels_g		:	positive	:= 640;				--640X480 Pixels in frame
			ver_pres_lines_g		:	positive	:= 480				--640X480 Pixels in frame
			);
	port	(
				--Clock and Reset
				clk_133				:	in std_logic;							--SDRAM clock
				clk_40				:	in std_logic;							--VESA Clock
				rst_133				:	in std_logic;							--Reset (133MHz)
				rst_40				:	in std_logic;							--Reset (40MHz)

				-- Wishbone Slave (For Registers)
				wbs_adr_i			:	in std_logic_vector (9 downto 0);		--Address in internal RAM
				wbs_tga_i			:	in std_logic_vector (9 downto 0);		--Burst Length
				wbs_dat_i			:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
				wbs_cyc_i			:	in std_logic;							--Cycle command from WBM
				wbs_stb_i			:	in std_logic;							--Strobe command from WBM
				wbs_we_i			:	in std_logic;							--Write Enable
				wbs_tgc_i			:	in std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wbs_dat_o			:	out std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wbs_stall_o			:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wbs_ack_o			:	out std_logic;							--Input data has been successfuly acknowledged
				wbs_err_o			:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				-- Wishbone Master to Memory Management block
				wbm_dat_i			:	in std_logic_vector (7 downto 0);		--Data in (8 bits)
				wbm_stall_i			:	in std_logic;							--Slave is not ready to receive new data 
				wbm_ack_i			:	in std_logic;							--Input data has been successfuly acknowledged
				wbm_err_i			:	in std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				wbm_adr_o			:	out std_logic_vector (9 downto 0);		--Address
				wbm_tga_o			:	out std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				wbm_cyc_o			:	out std_logic;							--Cycle command from WBM
				wbm_stb_o			:	out std_logic;							--Strobe command from WBM
				wbm_tgc_o			:	out std_logic;							--Cycle Tag

				--Output RGB
				r_out				:	out std_logic_vector(red_width_g + 1 downto 0);		--Output R Pixel
				g_out				:	out std_logic_vector(green_width_g + 1 downto 0);   --Output G Pixel
				b_out				:	out std_logic_vector(blue_width_g + 1 downto 0);  	--Output B Pixel
				
				--Blanking signal
				blank				:	out std_logic;										--Blanking signal
					
				--Sync Signals			
				hsync				:	out std_logic;										--HSync Signal
				vsync				:	out std_logic										--VSync Signal
			);
end component disp_ctrl_top;

component sdram_controller is
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
																--When Write Burst: Data has been read from SDRAM and is valid
   ); 
end component sdram_controller;


--#############################	Signals	##############################################--
	--Future Signals for INTERCON X
signal icx_wbm_dat_i		:	std_logic_vector (8 - 1 downto 0);					
signal icx_wbm_stall_i		:	std_logic;					
signal icx_wbm_ack_i		:	std_logic;					
signal icx_wbm_err_i		:	std_logic;					

signal icx_wbm_adr_o		:	std_logic_vector (10 - 1 downto 0);					--Address in internal RAM
signal icx_wbm_tga_o		:	std_logic_vector (10 - 1 downto 0);					--Burst Length
signal icx_wbm_dat_o		:	std_logic_vector (8 - 1 downto 0);					--Data In (8 bits)
signal icx_wbm_cyc_o		:	std_logic;					--Cycle command from WBM
signal icx_wbm_stb_o		:	std_logic;					--Strobe command from WBM
signal icx_wbm_we_o			:	std_logic;					--Write Enable
signal icx_wbm_tgc_o		:	std_logic;					--Cycle tag: '0' = Write to components, '1' = Write to registers


--INTERCON Z:
	--Signals from INTERCON to WBS
signal ic_wbs_adr_i		:	std_logic_vector (num_of_wbs_z_c * 10 - 1 downto 0);					--Address in internal RAM
signal ic_wbs_tga_i		:	std_logic_vector (num_of_wbs_z_c * 10 - 1 downto 0);					--Burst Length
signal ic_wbs_dat_i		:	std_logic_vector (num_of_wbs_z_c * 8 - 1 downto 0);					--Data In (8 bits)
signal ic_wbs_cyc_i		:	std_logic_vector (num_of_wbs_z_c - 1 downto 0);					--Cycle command from WBM
signal ic_wbs_stb_i		:	std_logic_vector (num_of_wbs_z_c - 1 downto 0);					--Strobe command from WBM
signal ic_wbs_we_i		:	std_logic_vector (num_of_wbs_z_c - 1 downto 0);					--Write Enable
signal ic_wbs_tgc_i		:	std_logic_vector (num_of_wbs_z_c - 1 downto 0);					--Cycle tag: '0' = Write to components, '1' = Write to registers

	--Signals from WBS to INTERCON
signal ic_wbs_dat_o		:	std_logic_vector (num_of_wbs_z_c * 8 - 1 downto 0);					--Data Out for reading registers (8 bits)
signal ic_wbs_stall_o	:	std_logic_vector (num_of_wbs_z_c - 1 downto 0);					--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal ic_wbs_ack_o		:	std_logic_vector (num_of_wbs_z_c - 1 downto 0);					--Input data has been successfuly acknowledged
signal ic_wbs_err_o		:	std_logic_vector (num_of_wbs_z_c - 1 downto 0);					--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)


	-- Wishbone Master (RX Block)
signal rx_wbm_adr_o		:	std_logic_vector (9 downto 0);		--Address in internal RAM
signal rx_wbm_tga_o		:	std_logic_vector (9 downto 0);		--Burst Length
signal rx_wbm_cyc_o		:	std_logic;							--Cycle command from WBM
signal rx_wbm_stb_o		:	std_logic;							--Strobe command from WBM
signal rx_wbm_we_o		:	std_logic;							--Write Enable
signal rx_wbm_tgc_o		:	std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
signal rx_wbm_dat_o		:	std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
signal rx_wbm_dat_i		:	std_logic_vector (7 downto 0);		--Data In (8 bits)
signal rx_wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal rx_wbm_ack_i		:	std_logic;							--Input data has been successfuly acknowledged
signal rx_wbm_err_i		:	std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

--Internal Display and Memory WBS
signal mem_rx_wbm_dat_i		:	std_logic_vector (7 downto 0);		--Data In (8 bits)
signal mem_rx_wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal mem_rx_wbm_ack_i		:	std_logic;							--Input data has been successfuly acknowledged
signal mem_rx_wbm_err_i		:	std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
signal disp_rx_wbm_dat_i	:	std_logic_vector (7 downto 0);		--Data In (8 bits)
signal disp_rx_wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal disp_rx_wbm_ack_i	:	std_logic;							--Input data has been successfuly acknowledged
signal disp_rx_wbm_err_i	:	std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

	-- Wishbone Slave (mem_ctrl_rd)
signal rd_wbs_adr_i 	:	std_logic_vector (9 downto 0);		--Address in internal RAM
signal rd_wbs_tga_i 	:   std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
signal rd_wbs_cyc_i		:   std_logic;							--Cycle command from WBM
signal rd_wbs_tgc_i 	:   std_logic;							--Cycle tag. '1' indicates start of transaction
signal rd_wbs_stb_i		:   std_logic;							--Strobe command from WBM
signal rd_wbs_dat_o 	:  	std_logic_vector (7 downto 0);		--Data Out (8 bits)
signal rd_wbs_stall_o	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal rd_wbs_ack_o		:   std_logic;							--Input data has been successfuly acknowledged
signal rd_wbs_err_o		:   std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

	-- Wishbone Master to SDRAM Controller
signal wbm_dat_i		:	std_logic_vector (15 downto 0);		--Data in (16 bits)
signal wbm_stall_i		:	std_logic;							--Slave is not ready to receive new data
signal wbm_err_i		:	std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
signal wbm_ack_i		:	std_logic;							--When Read Burst: DATA bus must be valid in this cycle
signal wbm_adr_o		:	std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
signal wbm_dat_o		:	std_logic_vector (15 downto 0);		--Data Out (16 bits)
signal wbm_we_o			:	std_logic;							--Write Enable
signal wbm_tga_o		:	std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
signal wbm_cyc_o		:	std_logic;							--Cycle Command to interface
signal wbm_stb_o		:	std_logic;							--Strobe Command to interface

begin

--Hidden Processes
--Connects WBS DATA to INTERCON. First "00" is MUX INTERCON (Intercon X). TODO: Second "00" is TX_PATH, which is not implemented yet
ic_wbs_dat_o_proc:
ic_wbs_dat_o	<=	x"0000" & disp_rx_wbm_dat_i & mem_rx_wbm_dat_i ;

--Connects WBS ACK to INTERCON. First '0' is MUX INTERCON (Intercon X). TODO: Second '0' is TX_PATH, which is not implemented yet
ic_wbs_ack_o_proc:
ic_wbs_ack_o	<=	"00" & disp_rx_wbm_ack_i & mem_rx_wbm_ack_i ;

--Connects WBS ERR to INTERCON. First '0' is MUX INTERCON (Intercon X). TODO: Second '0' is TX_PATH, which is not implemented yet
ic_wbs_err_o_proc:
ic_wbs_err_o	<=	"00" & disp_rx_wbm_err_i & mem_rx_wbm_err_i;

--Connects WBS STALL to INTERCON. First '1' is MUX INTERCON (Intercon X). TODO: Second '1' is TX_PATH, which is not implemented yet
ic_wbs_stall_o_proc:
ic_wbs_stall_o	<=	"11" & disp_rx_wbm_stall_i & mem_rx_wbm_stall_i;

--Instatiations
intercon_z_inst		:	intercon generic map
			(
				reset_polarity_g	=>	'0',	
				num_of_wbm_g		=>	num_of_wbm_z_c,
				num_of_wbs_g		=>	num_of_wbs_z_c,
				adr_width_g			=>	10,
				blen_width_g		=>	10,
				data_width_g		=>	8
			)
		
		port map
			(
				clk_i				=> clk_133,
				rst					=> rst_133,
				
				--Signals from INTERCON to WBS
				ic_wbs_adr_i		=>	ic_wbs_adr_i,	
				ic_wbs_tga_i		=>	ic_wbs_tga_i,	
				ic_wbs_dat_i		=>	ic_wbs_dat_i,	
				ic_wbs_cyc_i		=>	ic_wbs_cyc_i,	
				ic_wbs_stb_i		=>	ic_wbs_stb_i,	
				ic_wbs_we_i			=>	ic_wbs_we_i	,	
				ic_wbs_tgc_i		=>	ic_wbs_tgc_i,	
				
				--Signals from INTERCON to WBM 
				ic_wbm_dat_i (7 downto 0)	=>	rx_wbm_dat_i (7 downto 0),
				ic_wbm_dat_i (15 downto 8)	=>	icx_wbm_dat_i (7 downto 0),
				ic_wbm_stall_i(0)			=>	rx_wbm_stall_i,
				ic_wbm_stall_i(1)			=>	icx_wbm_stall_i,
				ic_wbm_ack_i(0)				=>	rx_wbm_ack_i,
				ic_wbm_ack_i(1)				=>	icx_wbm_ack_i,
				ic_wbm_err_i(0)				=>	rx_wbm_err_i,
				ic_wbm_err_i(1)				=>	icx_wbm_err_i,
				
				--Signals from WBM to INTERCON
				ic_wbm_adr_o (9 downto 0)	=>	rx_wbm_adr_o,		
				ic_wbm_adr_o (19 downto 10)	=>	icx_wbm_adr_o (9 downto 0),		
				ic_wbm_tga_o (9 downto 0)	=>	rx_wbm_tga_o,		
				ic_wbm_tga_o (19 downto 10)	=>	icx_wbm_tga_o (9 downto 0),		
				ic_wbm_dat_o (7 downto 0)	=>	rx_wbm_dat_o,		
				ic_wbm_dat_o (15 downto 8)	=>	icx_wbm_dat_o (7 downto 0),		
				ic_wbm_cyc_o(0)				=>	rx_wbm_cyc_o,		
				ic_wbm_cyc_o(1)				=>	icx_wbm_cyc_o,		
				ic_wbm_stb_o(0)				=>	rx_wbm_stb_o,		
				ic_wbm_stb_o(1)				=>	icx_wbm_stb_o,		
				ic_wbm_we_o(0)				=>	rx_wbm_we_o,		
				ic_wbm_we_o(1)				=>	icx_wbm_we_o,		
				ic_wbm_tgc_o(0)				=>	rx_wbm_tgc_o,		
				ic_wbm_tgc_o(1)				=>	icx_wbm_tgc_o,		
				
				--Signals from WBS to INTERCON
				ic_wbs_dat_o		=>	ic_wbs_dat_o,	
				ic_wbs_stall_o		=>	ic_wbs_stall_o,	
				ic_wbs_ack_o		=>	ic_wbs_ack_o,	
				ic_wbs_err_o		=>	ic_wbs_err_o	
			);



mem_mng_inst 	:	 mem_mng_top generic map
				(
					img_hor_pixels_g	 => 128,                                         --************************************-
				    img_ver_lines_g	     => 96                                        --************************************-
					--img_hor_pixels_g	 => 640,
				    --img_ver_lines_g	     => 480
				)
				port map
				(
				clk_i			=>	clk_133,				
				rst				=>	rst_133,	
				wr_wbs_adr_i	=>	ic_wbs_adr_i (9 downto 0)		,	
				wr_wbs_tga_i	=>	ic_wbs_tga_i (9 downto 0)		,	
				wr_wbs_dat_i	=>	ic_wbs_dat_i (7 downto 0)		,	
				wr_wbs_cyc_i	=>	ic_wbs_cyc_i (0)		,	
				wr_wbs_stb_i	=>	ic_wbs_stb_i (0)		,	
				wr_wbs_we_i		=>	ic_wbs_we_i  (0)		,	
				wr_wbs_tgc_i	=>	ic_wbs_tgc_i (0)		,	
				wr_wbs_dat_o	=>	mem_rx_wbm_dat_i		,	
				wr_wbs_stall_o	=>	mem_rx_wbm_stall_i	,	
				wr_wbs_ack_o	=>	mem_rx_wbm_ack_i		,	
				wr_wbs_err_o	=>	mem_rx_wbm_err_i		,	
				
				rd_wbs_adr_i 	=>	rd_wbs_adr_i 	,	
				rd_wbs_tga_i 	=>	rd_wbs_tga_i 	,	
				rd_wbs_cyc_i	=>	rd_wbs_cyc_i	,	
				rd_wbs_tgc_i 	=>	rd_wbs_tgc_i 	,	
				rd_wbs_stb_i	=>	rd_wbs_stb_i	,	
				rd_wbs_dat_o 	=>	rd_wbs_dat_o 	,	
				rd_wbs_stall_o	=>	rd_wbs_stall_o	,	
				rd_wbs_ack_o	=>	rd_wbs_ack_o	,	
				rd_wbs_err_o	=>	rd_wbs_err_o	,	
				
				wbm_dat_i		=>	wbm_dat_i		,	
				wbm_stall_i		=>	wbm_stall_i		,	
				wbm_err_i		=>	wbm_err_i		,	
				wbm_ack_i		=>	wbm_ack_i		,	
				wbm_adr_o		=>	wbm_adr_o		,	
				wbm_dat_o		=>	wbm_dat_o		,	
				wbm_we_o		=>	wbm_we_o		,	
				wbm_tga_o		=>	wbm_tga_o		,	
				wbm_cyc_o		=>	wbm_cyc_o		,	
				wbm_stb_o		=>	wbm_stb_o			
			);

---------------------------- Image Manipulation---------------------------
img_man_inst 	:	 img_man_top generic map
				(	
					reset_polarity_g	 => '0',
					img_hor_pixels_g	 => 128,                                         --************************************-
				    img_ver_lines_g	     => 96                                        --************************************-
					--img_hor_pixels_g	 => 640,
				    --img_ver_lines_g	     => 480
				)
				port map
				(
				clk_i			=>	clk_133,				
				rst				=>	rst_133,	
				wr_wbs_adr_i	=>	ic_wbs_adr_i (9 downto 0)		,	
				wr_wbs_tga_i	=>	ic_wbs_tga_i (9 downto 0)		,	
				wr_wbs_dat_i	=>	ic_wbs_dat_i (7 downto 0)		,	
				wr_wbs_cyc_i	=>	ic_wbs_cyc_i (0)		,	
				wr_wbs_stb_i	=>	ic_wbs_stb_i (0)		,	
				wr_wbs_we_i		=>	ic_wbs_we_i  (0)		,	
				wr_wbs_tgc_i	=>	ic_wbs_tgc_i (0)		,	
				wr_wbs_dat_o	=>	mem_rx_wbm_dat_i		,	
				wr_wbs_stall_o	=>	mem_rx_wbm_stall_i	,	
				wr_wbs_ack_o	=>	mem_rx_wbm_ack_i		,	
				wr_wbs_err_o	=>	mem_rx_wbm_err_i		,	
				
				
				wbm_dat_i		=>	wbm_dat_i		,	
				wbm_stall_i		=>	wbm_stall_i		,	
				wbm_err_i		=>	wbm_err_i		,	
				wbm_ack_i		=>	wbm_ack_i		,	
				wbm_adr_o		=>	wbm_adr_o		,	
				wbm_dat_o		=>	wbm_dat_o		,	
				wbm_we_o		=>	wbm_we_o		,	
				wbm_tga_o		=>	wbm_tga_o		,	
				wbm_cyc_o		=>	wbm_cyc_o		,	
				wbm_stb_o		=>	wbm_stb_o			
			);
---------------------------- END Image Manipulation---------------------------
disp_ctrl_inst :	 disp_ctrl_top	
			generic map
			(
--				rep_size_g			=>	rep_size_g,
				hor_pres_pixels_g	=>	128,										--************************************-
				ver_pres_lines_g	=>	96											--************************************-
				--hor_pres_pixels_g	=>	640,	
				--ver_pres_lines_g	=>	480					
			)
			port map
			(
				clk_133		=>	clk_133	,			
				clk_40		=>	clk_40	,		
				rst_133		=>	rst_133	,		
				rst_40		=>	rst_40	,		
				
				wbs_adr_i	=>	ic_wbs_adr_i (19 downto 10)		,		
				wbs_tga_i	=>	ic_wbs_tga_i (19 downto 10)		,		
				wbs_dat_i	=>	ic_wbs_dat_i (15 downto 8)		,		
				wbs_cyc_i	=>	ic_wbs_cyc_i (1)		,		
				wbs_stb_i	=>	ic_wbs_stb_i (1)		,		
				wbs_we_i	=>	ic_wbs_we_i  (1)	,		 	
				wbs_tgc_i	=>	ic_wbs_tgc_i (1)		,	 		
				wbs_dat_o	=>	disp_rx_wbm_dat_i		,				
				wbs_stall_o	=>	disp_rx_wbm_stall_i	,		 	
				wbs_ack_o	=>	disp_rx_wbm_ack_i		,				
				wbs_err_o	=>	disp_rx_wbm_err_i		,	 		
                                                        	
				wbm_dat_i	=>	rd_wbs_dat_o,		                		
				wbm_stall_i	=>	rd_wbs_stall_o,		                		
				wbm_ack_i	=>	rd_wbs_ack_o,		
				wbm_err_i	=>	rd_wbs_err_o,		
				wbm_adr_o	=>	rd_wbs_adr_i,		
				wbm_tga_o	=>	rd_wbs_tga_i,		
				wbm_cyc_o	=>	rd_wbs_cyc_i,		
				wbm_stb_o	=>	rd_wbs_stb_i,		
				wbm_tgc_o	=>	rd_wbs_tgc_i,
				r_out		=>	r_out,		
				g_out		=>	g_out,		
				b_out		=>	b_out,		
				blank		=>	blank,		
				hsync		=>	hsync,		
				vsync		=>	vsync		
			);

sdr_ctrl :	sdram_controller  port map
		(
		clk_i		=>	clk_133,
		rst			=>  rst_133,
		pll_locked	=>  '1',
		dram_addr	=>  dram_addr	,
		dram_bank	=>  dram_bank	,
		dram_cas_n	=>  dram_cas_n	,
		dram_cke	=>  dram_cke	,
		dram_cs_n	=>  dram_cs_n	,
		dram_dq		=>  dram_dq		,
		dram_ldqm	=>  dram_ldqm	,
		dram_udqm	=>  dram_udqm	,
		dram_ras_n	=>  dram_ras_n	,
		dram_we_n	=>  dram_we_n	,                     	
		wbs_adr_i	=>  wbm_adr_o,                                 	
		wbs_dat_i	=>  wbm_dat_o,          
		wbs_we_i	=>  wbm_we_o,           
		wbs_tga_i	=>  wbm_tga_o,          
		wbs_cyc_i	=>  wbm_cyc_o,          
		wbs_stb_i	=>  wbm_stb_o,          
		wbs_dat_o	=>  wbm_dat_i,          
		wbs_stall_o	=>  wbm_stall_i,        
		wbs_err_o	=>  wbm_err_i,          
		wbs_ack_o	=> 	wbm_ack_i
   );               

rx_path_inst : rx_path	
			generic map
			(
				baudrate_g			=>	baudrate_g
			)
			port map (
				rst					=>	rst_133,	
				clk_i 				=>	clk_133,
				uart_serial_in		=>	uart_serial_in,
				wbm_ack_i 			=>	rx_wbm_ack_i,                       		
				wbm_stall_i 		=>	rx_wbm_stall_i,                       		
				wbm_err_i 			=>	rx_wbm_err_i,                       		
				wbm_dat_i			=>	rx_wbm_dat_i,                       		
				wbm_adr_o 			=>	rx_wbm_adr_o,                       		
				wbm_cyc_o 			=>	rx_wbm_cyc_o,                       		
				wbm_stb_o 			=>	rx_wbm_stb_o,                       		
				wbm_tga_o 			=>	rx_wbm_tga_o,                       		
				wbm_tgc_o 			=>	rx_wbm_tgc_o,                       	
				wbm_dat_o			=>	rx_wbm_dat_o,                       		
				wbm_we_o			=>	rx_wbm_we_o                        		
			);	

end architecture rtl_mds_top;
