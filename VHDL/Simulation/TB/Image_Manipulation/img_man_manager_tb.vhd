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
				img_ver_pixels_g		:	positive					:= 480	--480 pixels in a row
			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;				-- clock
				sys_rst				:	in std_logic;				-- Reset
				
				req_trig			:	in std_logic;				-- Trigger for image manipulation to begin,
				
				row_idx_out			:	out signed (10 downto 0); 	--current row index
				col_idx_out			:	out signed (10 downto 0) 	--corrent coloumn index
				
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

begin
---------------------------		process + inst	-----------------------------------------
clk_133_proc:
system_clk	<=	not system_clk after 3.75 ns;

rst_133_proc:
system_rst	<=	'0', '1' after 100 ns;

trigger_proc:
trigger <=	'1', '0' after 100 ns, '1' after 107.5 ns;

manager_inst : img_man_manager
	generic map(
				reset_polarity_g 	=> '0', 
				img_hor_pixels_g	=> 640,	--640 pixel in a coloum
				img_ver_pixels_g	=> 480	--480 pixels in a row
				)                   
	port map (                      
				sys_clk				=>	system_clk,				-- clock
				sys_rst				=>	system_rst,				-- Reset            
				req_trig			=>	trigger,				--trigger for image manipulation to begin,       
				row_idx_out			=>	row_idx_out_sig, 	--current row index
				col_idx_out			=>	col_idx_out_sig 	--corrent coloumn index
				
				);
				
end architecture sim_img_man_manager_tb;