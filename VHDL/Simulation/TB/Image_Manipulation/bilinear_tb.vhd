------------------------------------------------------------------------------------------------
-- Model Name 	:	Bilinear Interpolator Test Bench
-- File Name	:	img_man_manager_tb.vhd
-- Generated	:	21.08.2012
-- Author		:	Uri Tsipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   TB of Bilinear Interpolator Block
--					
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		28.08.2012	Uri					creation
--					
------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity bilinear_tb is
	generic
		(	---DELETE
			pipeline_depth			:	positive 	:= 4;
			trig_frac_size			:	positive 	:= 7				-- number of digits after dot = resolution of fracture (binary)
		);
end entity bilinear_tb;

architecture sim_bilinear_tb of bilinear_tb is
----------------------------------components-------------------------------
component bilinear is
	generic (
				reset_polarity_g		:	std_logic	:= '0';			--Reset active low
				pipeline_depth_g		:	positive := 4;
				trig_frac_size_g		:	positive := 7	-- number of digits after dot = resolution of fracture (binary)

			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;				-- clock
				sys_rst				:	in std_logic;				-- Reset
				req_trig			:	in std_logic;				-- Trigger for image manipulation to begin,
				--from SDRAM
				tl_pixel			:	in	std_logic_vector(trig_frac_size_g downto 0);		--top left pixel
				tr_pixel			:	in	std_logic_vector(trig_frac_size_g downto 0);		--top right pixel
				bl_pixel            :   in	std_logic_vector(trig_frac_size_g downto 0);		--bottom left pixel
				br_pixel            :   in	std_logic_vector(trig_frac_size_g downto 0);		--bottom right pixel
				--from Addr_Calc
				delta_row			:	in	std_logic_vector(trig_frac_size_g-1 downto 0);				
				delta_col			:	in	std_logic_vector(trig_frac_size_g-1 downto 0);				
			

				
				pixel_valid				:	out std_logic;				--valid signal for index
				pixel_res			:	out std_logic_vector (trig_frac_size_g downto 0) 	--current row index           
			
			);
end component bilinear;
----------------------------------constants---------------------------------

----------------------------------signals----------------------------------------
--Clock and Reset
signal system_clk			:	std_logic := '0';
signal system_rst			:	std_logic;

signal trigger				:	std_logic;

signal	valid_sig				:	 std_logic;				--valid signal for index
signal	pixel_res_sig			:	 std_logic_vector (trig_frac_size downto 0); 	--current row index          
			
				
begin
---------------------------		process + inst	-----------------------------------------
clk_133_proc:
system_clk	<=	not system_clk after 3.75 ns;

rst_133_proc:
system_rst	<=	'0', '1' after 97.5 ns;

trigger_proc:
trigger <=	'0', '1' after 101.25 ns, '0' after 108.75 ns;

bilinear_inst : bilinear
	generic map(
				reset_polarity_g		=>'0',
				pipeline_depth_g		=>pipeline_depth,
				trig_frac_size_g		=>trig_frac_size
				)
	port map (  
				--Clock and Reset 
				sys_clk				=>	system_clk,				
				sys_rst				=>	system_rst,			
				req_trig			=>	trigger,				
				--from SDRAM        
				tl_pixel			=>	(others =>'0'),
				tr_pixel			=>	(others =>'0'),
				bl_pixel            =>  (others =>'0'),
				br_pixel            =>  (others =>'0'),
				--from Addr_Calc    
				delta_row			=>	(others =>'0'),
				delta_col			=>	(others =>'0'),
                                    
                --Outputs           
                pixel_valid			=>	valid_sig,				
                pixel_res			=>	pixel_res_sig
            );                      
end architecture sim_bilinear_tb;