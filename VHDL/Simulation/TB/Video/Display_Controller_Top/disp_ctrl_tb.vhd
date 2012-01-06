------------------------------------------------------------------------------------------------
-- Model Name 	:	Modular Decompression System TOP TB
-- File Name	:	disp_ctrl_tb.vhd
-- Generated	:	29.5.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Modular Decompression System TOP TB
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		29.5.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity disp_ctrl_tb is
	generic
		(
			rep_size_g	:	positive := 8
		);
end entity disp_ctrl_tb;

architecture sim_disp_ctrl_tb of disp_ctrl_tb is

component disp_ctrl_top 
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
			rep_size_g				:	positive	:= 7;				--2^7=128 => Maximum of 128 repetitions for pixel / line
			
			--General FIFO Generics
			fifo_depth_g 			: positive		:= 3840;			-- Maximum elements in FIFO
			fifo_log_depth_g		: natural		:= 10;				-- Logarithm of depth_g (Number of bits to represent depth_g. 2^10=1024)
			
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
component vesa_pic_col 
	generic (
			reset_polarity_g		:	std_logic 	:= '0';				--Reset Polarity. '0' = Reset
			hsync_polarity_g		:	std_logic 	:= '1';				--Positive HSync
			vsync_polarity_g		:	std_logic 	:= '1';				--Positive VSync
			blank_polarity_g		:	std_logic	:= '0';				--When '0' - Blanking signal to the VGA
			
			red_width_g				:	positive 	:= 8;				--Default std_logic_vector size of Red Pixels
			green_width_g			:	positive 	:= 8;				--Default std_logic_vector size of Green Pixels
			blue_width_g			:	positive 	:= 8;				--Default std_logic_vector size of Blue Pixels
							
			hor_active_pixels_g		:	positive	:= 800;				--800 active pixels per line
			ver_active_lines_g		:	positive	:= 600;				--600 active lines
			hor_left_border_g		:	natural		:= 0;				--Horizontal Left Border
			hor_right_border_g		:	natural		:= 0;				--Horizontal Right Border
			hor_back_porch_g		:	integer		:= 88;				--Horizontal Back Porch (Pixels)
			hor_front_porch_g		:	integer		:= 40;				--Horizontal Front Porch (Pixels)
			hor_sync_time_g			:	integer		:= 128;				--Horizontal Sync Time (Pixels)
			ver_top_border_g		:	natural		:= 0;				--Vertical Top Border
			ver_buttom_border_g		:	natural		:= 0;				--Vertical Buttom Border
			ver_back_porch_g		:	integer		:= 23;				--Vertical Back Porch (Lines)
			ver_front_porch_g		:	integer		:= 1;				--Vertical Front Porch (Lines)
			ver_sync_time_g			:	integer		:= 4;				--Vertical Sync Time (Lines)
			
			file_dir_g				:	string		:= "H:\RunLen\VHDL\Simulation\TB\Video\VESA\output_files\";
			file_prefix_g			:	string		:= "out_img"			--Image Prefix
			);
	port	(
			clk						:	in std_logic;					--Clock
			reset					:	in std_logic;
			hsync					:	in std_logic := not hsync_polarity_g;
			vsync					:	in std_logic := not vsync_polarity_g;
			blank					:	in std_logic := not blank_polarity_g;
			r_in					:	in std_logic_vector (red_width_g - 1 downto 0);
			g_in					:	in std_logic_vector (green_width_g - 1 downto 0);
			b_in					:	in std_logic_vector (blue_width_g - 1 downto 0)
			);
end component vesa_pic_col;

-----------------------------	Signals		-----------------------------------
	-- Wishbone Master (RX Block)
signal rx_wbm_adr_o		:	std_logic_vector (9 downto 0) := (others => '0');		--Address in internal RAM
signal rx_wbm_tga_o		:	std_logic_vector (9 downto 0) := (others => '0');		--Burst Length
signal rx_wbm_cyc_o		:	std_logic := '0';							--Cycle command from WBM
signal rx_wbm_stb_o		:	std_logic := '0';							--Strobe command from WBM
signal rx_wbm_we_o		:	std_logic := '0';							--Write Enable
signal rx_wbm_tgc_o		:	std_logic := '0';							--Cycle tag: '0' = Write to components, '1' = Write to registers
signal rx_wbm_dat_o		:	std_logic_vector (7 downto 0) := (others => '0');		--Data Out for reading registers (8 bits)
signal rx_wbm_dat_i		:	std_logic_vector (7 downto 0) := (others => '0');		--Data In (8 bits)
signal rx_wbm_stall_i	:	std_logic := '1';							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal rx_wbm_ack_i		:	std_logic := '0';							--Input data has been successfuly acknowledged
signal rx_wbm_err_i		:	std_logic := '0';							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

	-- Wishbone Slave (mem_ctrl_rd)
signal rd_wbs_adr_i 	:	std_logic_vector (9 downto 0) := (others => '0');		--Address in internal RAM
signal rd_wbs_tga_i 	:   std_logic_vector (9 downto 0) := (others => '0');		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
signal rd_wbs_cyc_i		:   std_logic := '0';							--Cycle command from WBM
signal rd_wbs_tgc_i 	:   std_logic := '0';							--Cycle tag. '1' indicates start of transaction
signal rd_wbs_stb_i		:   std_logic := '0';							--Strobe command from WBM
signal rd_wbs_dat_o 	:  	std_logic_vector (7 downto 0):= (others => '0');		--Data Out (8 bits)
signal rd_wbs_stall_o	:	std_logic := '1';							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal rd_wbs_ack_o		:   std_logic := '0';							--Input data has been successfuly acknowledged
signal rd_wbs_err_o		:   std_logic := '0';							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

--Clock and reset
signal clk_133			:	std_logic := '0';
signal clk_40			:	std_logic := '0';
signal rst_40			:	std_logic := '0';
signal rst_133			:	std_logic := '0';

--VESA
--Output RGB
signal r_out			:	std_logic_vector(9 downto 0);	--Output R Pixel
signal g_out			:	std_logic_vector(9 downto 0);   --Output G Pixel
signal b_out			:	std_logic_vector(9 downto 0);  	--Output B Pixel
	
--Blanking signal	
signal blank			:	std_logic;										--Blanking signal
		
--Sync Signals				
signal hsync			:	std_logic;										--HSync Signal
signal vsync			:	std_logic;										--VSync Signal


begin

clk_133_proc:
clk_133	<=	not clk_133 after 3.75 ns;

clk_40_proc:
clk_40	<=	not clk_40 after 12.5 ns;

rst_133_proc:
rst_133	<=	'0', '1' after 100 ns;

rst_40_proc:
rst_40	<=	'0', '1' after 100 ns;

disp_ctrl_inst :	 disp_ctrl_top	
			generic map
			(rep_size_g=>rep_size_g)
			port map
			(
				clk_133		=>	clk_133	,			
				clk_40		=>	clk_40	,		
				rst_133		=>	rst_133	,		
				rst_40		=>	rst_40	,		
				
				wbs_adr_i	=>	rx_wbm_adr_o		,		
				wbs_tga_i	=>	rx_wbm_tga_o		,		
				wbs_dat_i	=>	rx_wbm_dat_o		,		
				wbs_cyc_i	=>	rx_wbm_cyc_o		,		
				wbs_stb_i	=>	rx_wbm_stb_o		,		
				wbs_we_i	=>	rx_wbm_we_o		,		 	
				wbs_tgc_i	=>	rx_wbm_tgc_o		,	 		
				wbs_dat_o	=>	rx_wbm_dat_i		,				
				wbs_stall_o	=>	rx_wbm_stall_i	,		 	
				wbs_ack_o	=>	rx_wbm_ack_i		,				
				wbs_err_o	=>	rx_wbm_err_i		,	 		
                                                        	
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

			
vesa_pic_col_inst : vesa_pic_col	generic map
			(
				file_dir_g				=> "H:\RunLen\VHDL\Simulation\TB\Video\VESA\output_files\",
				file_prefix_g			=> "out_img"			--Image Prefix
			)
		port map
			(
				clk						=>	clk_40,
				reset					=>	rst_40,
				hsync					=>	hsync,
				vsync					=>	vsync	,
				blank					=>	blank	,
				r_in					=>	r_out (9 downto 2)	,
				g_in					=>	g_out (9 downto 2)	,
				b_in					=>	b_out (9 downto 2)	
			); 
			
-- wbs_proc: process
-- variable data	:	std_logic_vector (7 downto 0) := (others => '0');
-- variable rep_b	:	boolean := false;
-- begin
	-- rd_wbs_ack_o	<=	'0';
	-- rd_wbs_err_o	<=	'0';
	-- rd_wbs_stall_o	<=	'1';
	-- wait until rd_wbs_cyc_i = '1' and rd_wbs_stb_i = '1';
	-- rep_b	:= false;
	-- wait until rising_edge(clk_133);
	-- rd_wbs_stall_o	<=	'0';
	-- wait until rising_edge(clk_133);
	-- while (rd_wbs_stb_i = '1') loop
		-- rd_wbs_ack_o	<=	'1';
		-- if (rep_b) then
			-- rd_wbs_dat_o	<=	x"01";
		-- else
			-- rd_wbs_dat_o	<=	data;
			-- data := data + '1';
		-- end if;
		-- rep_b	:= not rep_b;
	-- wait until rising_edge(clk_133);
	-- end loop;
-- end process wbs_proc;

wmb_proc: process
begin
	rx_wbm_cyc_o	<=	'0';
	rx_wbm_stb_o	<=	'0';
	wait until rising_edge(clk_133);
	rx_wbm_cyc_o	<=	'1';
	rx_wbm_stb_o	<=	'1';
	rx_wbm_tgc_o	<=	'1';
	rx_wbm_adr_o	<=	"00" & x"01";	--Type reg
	rx_wbm_dat_o	<=	x"04";
	wait until rx_wbm_ack_i	= '1';
	rx_wbm_cyc_o	<=	'0';
	rx_wbm_stb_o	<=	'0';
	wait;
	
end process wmb_proc;

			
end architecture sim_disp_ctrl_tb;