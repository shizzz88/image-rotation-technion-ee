------------------------------------------------------------------------------------------------
-- Model Name 	:	Image Manipulation Manager Test Bench (FSM)
-- File Name	:	img_man_manager_tb.vhd
-- Generated	:	21.08.2012
-- Author		:	Uri Tsipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   TB of Manager for Image manipulation Block
--					
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		21.08.2012	Uri					creation
--					
------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity img_man_manager_tb is
	generic
		(	---DELETE
			x_size_out				:	positive 	:= 600;				-- number of rows  in theoutput image
			y_size_out				:	positive 	:= 800;				-- number of columns  in the output image
			trig_frac_size_g			:	positive 	:= 7				-- number of digits after dot = resolution of fracture (binary)
		);
end entity img_man_manager_tb;

architecture sim_img_man_manager_tb of img_man_manager_tb is
----------------------------------components-------------------------------
component img_man_manager is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				trig_frac_size_g	:	positive := 7;				-- number of digits after dot = resolution of fracture (binary)
				img_hor_pixels_g	:	positive					:= 640;	--640 pixel in a coloum
				img_ver_pixels_g	:	positive					:= 480	--480 pixels in a row
			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;								-- clock
				sys_rst				:	in std_logic;								-- Reset					
				req_trig			:	in std_logic;								-- Trigger for image manipulation to begin,
					
				-- addr_calc					
				
				addr_row_idx_in			:	out signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed)
				addr_col_idx_in			:	out signed (10 downto 0);		--the current column index of the output image
				
				addr_tl_out				:	in std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
				addr_bl_out				:	in std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
				addr_delta_row_out		:	in	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				addr_delta_col_out		:	in	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation

				addr_out_of_range		:	in std_logic;		--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				addr_data_valid_out		:	in std_logic;		--data valid indicator

				addr_unit_finish		:	in std_logic;                              --signal indicating addr_calc is finished
				addr_trigger_unit		:	out std_logic;                               --enable signal for addr_calc
				
			--	-- bilinear
			--	bili_req_trig			:	out std_logic;				-- Trigger for image manipulation to begin,
			--	bili_tl_pixel			:	out	std_logic_vector(trig_frac_size_g downto 0);		--top left pixel
			--	bili_tr_pixel			:	out	std_logic_vector(trig_frac_size_g downto 0);		--top right pixel
			--	bili_bl_pixel           :   out	std_logic_vector(trig_frac_size_g downto 0);		--bottom left pixel
			--	bili_br_pixel           :   out	std_logic_vector(trig_frac_size_g downto 0);		--bottom right pixel
			--	bili_delta_row			:	out	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
			--	bili_delta_col			:	out	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
			--	bili_pixel_valid		:	in std_logic;				--valid signal for index
			--	bili_pixel_res			:	in std_logic_vector (trig_frac_size_g downto 0); 	--current row index           --fix to generic
				
				-- Wishbone Master (mem_ctrl_wr)
				wr_wbm_adr_o		:	out std_logic_vector (9 downto 0);		--Address in internal RAM
				wr_wbm_tga_o		:	out std_logic_vector (9 downto 0);		--Burst Length
				wr_wbm_dat_o		:	out std_logic_vector (7 downto 0);		--Data In (8 bits)
				wr_wbm_cyc_o		:	out std_logic;							--Cycle command from WBM
				wr_wbm_stb_o		:	out std_logic;							--Strobe command from WBM
				wr_wbm_we_o			:	out std_logic;							--Write Enable
				wr_wbm_tgc_o		:	out std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wr_wbm_dat_i		:	in std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wr_wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wr_wbm_ack_i		:	in std_logic;							--Input data has been successfuly acknowledged
				wr_wbm_err_i		:	in std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

				-- Wishbone Master (mem_ctrl_rd)
				rd_wbm_adr_o 		:	out std_logic_vector (9 downto 0);		--Address in internal RAM
				rd_wbm_tga_o 		:   out std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				rd_wbm_cyc_o		:   out std_logic;							--Cycle command from WBM
				rd_wbm_tgc_o 		:   out std_logic;							--Cycle tag. '1' indicates start of transaction
				rd_wbm_stb_o		:   out std_logic;							--Strobe command from WBM
				rd_wbm_dat_i		:  	in std_logic_vector (7 downto 0);		--Data Out (8 bits)
				rd_wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				rd_wbm_ack_i		:   in std_logic;							--Input data has been successfuly acknowledged
				rd_wbm_err_i		:   in std_logic							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
			);
end component img_man_manager;
----------------------------------constants---------------------------------

----------------------------------signals----------------------------------------
--Clock and Reset
signal system_clk			:	std_logic := '0';
signal system_rst			:	std_logic;
signal trigger				:	std_logic;
--addr_calc
signal tb_addr_row_idx_in			:	 signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed)
signal tb_addr_col_idx_in			:	 signed (10 downto 0);		--the current column index of the output image
signal tb_addr_tl_out				:	std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
signal tb_addr_bl_out				:	std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
signal tb_addr_delta_row_out		:	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
signal tb_addr_delta_col_out		:	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
signal tb_addr_out_of_range			:	 std_logic;		--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
signal tb_addr_data_valid_out		:	 std_logic;		--data valid indicator
signal tb_addr_unit_finish			:	 std_logic;                              --signal indicating addr_calc is finished
signal tb_addr_trigger_unit			:	 std_logic;                               --enable signal for addr_calc

--coordinate counter

signal tb_row_idx_out			:	 signed (10 downto 0); 	--current row index
signal tb_col_idx_out			:	 signed (10 downto 0); 	--corrent coloumn index
signal tb_idx_valid		:	 std_logic;				--valid signal for row index

	--Signals from image manipulation wbm_wr to intercon Z
signal	tb_wr_wbm_adr_o		: std_logic_vector (9 downto 0);		--Address in internal RAM
signal	tb_wr_wbm_tga_o		: std_logic_vector (9 downto 0);		--Burst Length
signal	tb_wr_wbm_dat_o		: std_logic_vector (7 downto 0);		--Data In (8 bits)
signal	tb_wr_wbm_cyc_o		: std_logic;							--Cycle command from WBM
signal	tb_wr_wbm_stb_o		: std_logic;							--Strobe command from WBM
signal	tb_wr_wbm_we_o		: std_logic;							--Write Enable
signal	tb_wr_wbm_tgc_o		: std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
signal	tb_wr_wbm_dat_i		: std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
signal	tb_wr_wbm_stall_i	: std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal	tb_wr_wbm_ack_i		: std_logic;							--Input data has been successfuly acknowledged
signal	tb_wr_wbm_err_i		: std_logic;		

	-- --Signals from image manipulation wbm_rd to intercon Y
signal	tb_rd_wbm_adr_o 	:	std_logic_vector (9 downto 0);		--Address in internal RAM
signal	tb_rd_wbm_tga_o 	:   std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
signal	tb_rd_wbm_cyc_o		:   std_logic;							--Cycle command from WBM
signal	tb_rd_wbm_tgc_o 	:   std_logic;							--Cycle tag. '1' indicates start of transaction
signal	tb_rd_wbm_stb_o		:   std_logic;							--Strobe command from WBM
signal	tb_rd_wbm_dat_i		:	std_logic_vector (7 downto 0);		--Data Out (8 bits)
signal	tb_rd_wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal	tb_rd_wbm_ack_i		:   std_logic;							--Input data has been successfuly acknowledged
signal	tb_rd_wbm_err_i		:   std_logic;	

signal	tb_rd_wbm_dat_o		:  std_logic_vector (7 downto 0);		--Data Out (8 bits)
signal	tb_rd_wbm_we_o		:  std_logic;
--signal	addr_calc_oor_sig			:  std_logic;					
--signal	addr_calc_valid_sig			:  std_logic;	
	
begin
---------------------------		process + inst	-----------------------------------------
clk_100_proc:
system_clk	<=	not system_clk after 5 ns;

rst_10_proc:
system_rst	<=	'0', '1' after 40 ns;

trigger_proc:
trigger <=	'0', '1' after 100 ns, '0' after 110 ns;

tb_wr_wbm_dat_i		<=	"00000000";
tb_wr_wbm_stall_i	<=	'0';
tb_wr_wbm_ack_i		<=	'0';
tb_wr_wbm_err_i		<=	'0';
tb_rd_wbm_dat_i		<=	"00000000";	
tb_rd_wbm_stall_i	<=	'0';	
tb_rd_wbm_ack_i		<=	'0';	
tb_rd_wbm_err_i		<=	'0';	
	
img_man_manager_inst: img_man_manager 
		generic map(
				reset_polarity_g 	=>	'0',
				img_hor_pixels_g	 =>640,	--640 active pixels
				img_ver_pixels_g	=> 480,	--480 active lines
				trig_frac_size_g	=> 7				-- number of digits after dot = resolution of fracture (binary)

			)
	port map(
				--Clock and Reset
				sys_clk			=>	system_clk,
				sys_rst			=>	system_rst,
                
				req_trig			=>	trigger,			
				
				--from addr_calc
				addr_row_idx_in			=>    tb_addr_row_idx_in	,	
				addr_col_idx_in			=>    tb_addr_col_idx_in	,	
				addr_tl_out				=>    tb_addr_tl_out		,	
				addr_bl_out				=>    tb_addr_bl_out		,	
				addr_delta_row_out		=>    tb_addr_delta_row_out	,
				addr_delta_col_out		=>    tb_addr_delta_col_out	,
				addr_out_of_range		=>    tb_addr_out_of_range	,
				addr_data_valid_out		=>    tb_addr_data_valid_out,	
				addr_unit_finish		=>    tb_addr_unit_finish	,
				addr_trigger_unit		=>    tb_addr_trigger_unit	,
					
				-- Wishbone Mastr (mem_ctrl_wr)
				wr_wbm_adr_o		=>  tb_wr_wbm_adr_o,	
				wr_wbm_tga_o		=>  tb_wr_wbm_tga_o,	
				wr_wbm_dat_o		=>  tb_wr_wbm_dat_o,	
				wr_wbm_cyc_o		=>  tb_wr_wbm_cyc_o,	
				wr_wbm_stb_o		=>  tb_wr_wbm_stb_o,	
				wr_wbm_we_o			=>  tb_wr_wbm_we_o	,	
				wr_wbm_tgc_o		=>  tb_wr_wbm_tgc_o,	
				wr_wbm_dat_i		=>  tb_wr_wbm_dat_i	,
				wr_wbm_stall_i		=>  tb_wr_wbm_stall_i,	
				wr_wbm_ack_i		=>  tb_wr_wbm_ack_i,	
				wr_wbm_err_i		=>  tb_wr_wbm_err_i,	
                                     
				-- Wishbone Master (em_ctrl_rd)
				rd_wbm_adr_o 		=>  tb_rd_wbm_adr_o,
				rd_wbm_tga_o 		=>  tb_rd_wbm_tga_o,
				rd_wbm_cyc_o		=>  tb_rd_wbm_cyc_o,
				rd_wbm_tgc_o 		=>  tb_rd_wbm_tgc_o,
				rd_wbm_stb_o		=>  tb_rd_wbm_stb_o,
				rd_wbm_dat_i		=>  tb_rd_wbm_dat_i,
				rd_wbm_stall_i		=>  tb_rd_wbm_stall_i,
				rd_wbm_ack_i		=>  tb_rd_wbm_ack_i,
				rd_wbm_err_i		=>  tb_rd_wbm_err_i
				
			);
				
end architecture sim_img_man_manager_tb;