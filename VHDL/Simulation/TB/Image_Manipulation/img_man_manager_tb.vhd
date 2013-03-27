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
			trig_frac_size			:	positive 	:= 7				-- number of digits after dot = resolution of fracture (binary)
		);
end entity img_man_manager_tb;

architecture sim_img_man_manager_tb of img_man_manager_tb is
----------------------------------components-------------------------------
component img_man_manager is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				img_hor_pixels_g	:	positive					:= 640;	--640 pixel in a coloum
				img_ver_pixels_g	:	positive					:= 480	--480 pixels in a row
			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;				-- clock
				sys_rst				:	in std_logic;				-- Reset
				
				req_trig			:	in std_logic;				-- Trigger for image manipulation to begin,
				--from addr_calc
				addr_calc_oor		:	in std_logic;				--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				addr_calc_valid		:	in std_logic;				--data valid indicator
				
				
				index_valid			:	out std_logic;				--valid signal for index
				row_idx_out			:	out signed (10 downto 0); 	--current row index           --fix to generic
				col_idx_out			:	out signed (10 downto 0); 	--corrent coloumn index		  --fix to generic
				
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
signal row_idx_out_sig			:	 signed (10 downto 0); 	--current row index
signal col_idx_out_sig			:	 signed (10 downto 0); 	--corrent coloumn index
signal idx_valid_sig		:	 std_logic;				--valid signal for row index

	--Signals from image manipulation wbm_wr to intercon Z
signal	img_wr_wbm_adr_o		: std_logic_vector (9 downto 0);		--Address in internal RAM
signal	img_wr_wbm_tga_o		: std_logic_vector (9 downto 0);		--Burst Length
signal	img_wr_wbm_dat_o		: std_logic_vector (7 downto 0);		--Data In (8 bits)
signal	img_wr_wbm_cyc_o		: std_logic;							--Cycle command from WBM
signal	img_wr_wbm_stb_o		: std_logic;							--Strobe command from WBM
signal	img_wr_wbm_we_o			: std_logic;							--Write Enable
signal	img_wr_wbm_tgc_o		: std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
signal	img_wr_wbm_dat_i		:std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
signal	img_wr_wbm_stall_i		:std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal	img_wr_wbm_ack_i		:std_logic;							--Input data has been successfuly acknowledged
signal	img_wr_wbm_err_i		:std_logic;		

	-- --Signals from image manipulation wbm_rd to intercon Y
signal	img_rd_wbm_adr_o 		:	std_logic_vector (9 downto 0);		--Address in internal RAM
signal	img_rd_wbm_tga_o 		:   std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
signal	img_rd_wbm_cyc_o		:   std_logic;							--Cycle command from WBM
signal	img_rd_wbm_tgc_o 		:   std_logic;							--Cycle tag. '1' indicates start of transaction
signal	img_rd_wbm_stb_o		:   std_logic;							--Strobe command from WBM
signal	img_rd_wbm_dat_i		:  std_logic_vector (7 downto 0);		--Data Out (8 bits)
signal	img_rd_wbm_stall_i		:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal	img_rd_wbm_ack_i		:  std_logic;							--Input data has been successfuly acknowledged
signal	img_rd_wbm_err_i		:  std_logic;	

signal	img_rd_wbm_dat_o		:  std_logic_vector (7 downto 0);		--Data Out (8 bits)
signal	img_rd_wbm_we_o			:  std_logic;
--signal	addr_calc_oor_sig			:  std_logic;					
--signal	addr_calc_valid_sig			:  std_logic;	
	
begin
---------------------------		process + inst	-----------------------------------------
clk_100_proc:
system_clk	<=	not system_clk after 5 ns;

rst_10_proc:
system_rst	<=	'0', '1' after 100 ns;

trigger_proc:
trigger <=	'0', '1' after 100 ns, '0' after 120 ns;

img_man_manager_inst: img_man_manager 
		generic map(
				reset_polarity_g 	=>	'0',
				img_hor_pixels_g	 =>640,	--640 active pixels
				img_ver_pixels_g	=> 480	--480 active lines
			)
	port map(
				--Clock and Reset
				sys_clk			=>	system_clk,
				sys_rst			=>	system_rst,
                
				req_trig			=>	trigger,			
				--from addr_calc
				addr_calc_oor		=>	'0',				
				addr_calc_valid		=>	'1',	
				
				
				index_valid			=>	 idx_valid_sig,		
				row_idx_out			=>	row_idx_out_sig, 	
				col_idx_out			=>	col_idx_out_sig	, 	
								
						
					-- Wishbone Mastr (mem_ctrl_wr)
				wr_wbm_adr_o		=>  img_wr_wbm_adr_o,	
				wr_wbm_tga_o		=>  img_wr_wbm_tga_o,	
				wr_wbm_dat_o		=>  img_wr_wbm_dat_o,	
				wr_wbm_cyc_o		=>  img_wr_wbm_cyc_o,	
				wr_wbm_stb_o		=>  img_wr_wbm_stb_o,	
				wr_wbm_we_o			=>  img_wr_wbm_we_o	,	
				wr_wbm_tgc_o		=>  img_wr_wbm_tgc_o,	
				wr_wbm_dat_i		=>  img_wr_wbm_dat_i	,
				wr_wbm_stall_i		=>  img_wr_wbm_stall_i,	
				wr_wbm_ack_i		=>  img_wr_wbm_ack_i,	
				wr_wbm_err_i		=>  img_wr_wbm_err_i,	
                                     
				-- Wishbone Master (em_ctrl_rd)
				rd_wbm_adr_o 		=>  img_rd_wbm_adr_o,
				rd_wbm_tga_o 		=>  img_rd_wbm_tga_o,
				rd_wbm_cyc_o		=>  img_rd_wbm_cyc_o,
				rd_wbm_tgc_o 		=>  img_rd_wbm_tgc_o,
				rd_wbm_stb_o		=>  img_rd_wbm_stb_o,
				rd_wbm_dat_i		=>  img_rd_wbm_dat_i,
				rd_wbm_stall_i		=>  img_rd_wbm_stall_i,
				rd_wbm_ack_i		=>  img_rd_wbm_ack_i,
				rd_wbm_err_i		=>  img_rd_wbm_err_i
				
			);
				
end architecture sim_img_man_manager_tb;