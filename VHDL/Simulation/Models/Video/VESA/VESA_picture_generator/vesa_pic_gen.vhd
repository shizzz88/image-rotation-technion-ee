------------------------------------------------------------------------------------------------
-- Model Name 	:	Vesa Non-Interlaced Image Generator
-- File Name	:	vesa_pic_gen.vhd
-- Generated	:	20.01.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The model loads an image from a file, and transmits it into the VESA generator
-- 				control.
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		20.01.2010	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) Change BMP_io_package to TXT file
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library work;
use work.BMP_io_package.all;

entity vesa_pic_gen is
	generic (
			reset_polarity_g		:	std_logic 	:= '0';				--Reset Polarity. '0' = Reset
			vsync_polarity_g		:	std_logic 	:= '1';				--Positive VSync
			
			hor_active_pixels_g		:	positive	:= 800;				--800 active pixels per line
			ver_active_lines_g		:	positive	:= 600;				--600 active lines

			red_width_g				:	positive 	:= 8;				--Default std_logic_vector size of Red Pixels
			green_width_g			:	positive 	:= 8;				--Default std_logic_vector size of Green Pixels
			blue_width_g			:	positive 	:= 8;				--Default std_logic_vector size of Blue Pixels
			
			req_delay_g				:	positive	:= 1;				--Number of clocks between the "req_data" request to the "data_valid" answer
			max_file_idx_g			:	positive 	:= 1;				--Maximum file index
			file_dir_g				:	string		:= "D:\ModelSim\MyDesign\RunLen\VHDL\Simulation\TB\Video\VESA\input_files\";
			file_prefix_g			:	string		:= "in_img"			--Image Prefix
			);
	port	(
			clk						:	in std_logic;					--Clock
			reset					:	in std_logic;
			vsync					:	in std_logic := not vsync_polarity_g;
			req_data				:	in std_logic;
			r_out					:	out std_logic_vector (red_width_g - 1 downto 0);
			g_out					:	out std_logic_vector (green_width_g - 1 downto 0);
			b_out					:	out std_logic_vector (blue_width_g - 1 downto 0);
			data_valid				: 	out std_logic := '0'
			);
end entity vesa_pic_gen;

architecture sim_vesa_pic_gen of vesa_pic_gen is

------------------------  Signals & Variables ----------------------------------------
signal d_valid_sr		: std_logic_vector (req_delay_g - 1 downto 0) := (others => '0'); 	--Data valid shift register
signal data_valid_i		: std_logic := '0';													--Internal data_valid (not synchronized with data_valid)

begin
	transmit_proc : process
	variable file_index 	: positive range 1 to max_file_idx_g := 1;
	variable pic			: RGB_pic_array;
	variable hsize			: natural;
	variable vsize			: natural;
	begin
		if (reset = reset_polarity_g) then
			wait until (reset = not reset_polarity_g);
		end if;
		
		get_image (file_dir_g & file_prefix_g & "_" & integer'image(file_index) & ".bmp", pic, hsize, vsize);
		--vsize := 600;
		--hsize := 800;
		
		v_loop:
		for idx_v in 1 to vsize loop
			wait until rising_edge(data_valid_i) or (reset = reset_polarity_g);
			wait until (rising_edge(clk)) or (reset = reset_polarity_g);
			if (reset = reset_polarity_g) or (vsync = vsync_polarity_g) then
				exit v_loop;
			end if;
			h_loop:
			for idx_h in 1 to hsize loop
				r_out <= conv_std_logic_vector(pic(R)(idx_v, idx_h),red_width_g);
				g_out <= conv_std_logic_vector(pic(G)(idx_v, idx_h),green_width_g);
				b_out <= conv_std_logic_vector(pic(B)(idx_v, idx_h),blue_width_g);
				--r_out <= conv_std_logic_vector(idx_v mod 2**red_width_g ,red_width_g);
				--g_out <= conv_std_logic_vector(idx_v mod 2**green_width_g ,green_width_g);
				--b_out <= conv_std_logic_vector(idx_v mod 2**blue_width_g ,blue_width_g);
				wait until (rising_edge(clk)) or (reset = reset_polarity_g);
				if (reset = reset_polarity_g) or (vsync = vsync_polarity_g) then
					exit v_loop;
				end if;
			end loop h_loop;
		end loop v_loop;

		if (vsync /= vsync_polarity_g) and (reset /= reset_polarity_g) then
			wait until (vsync = vsync_polarity_g) or (reset = reset_polarity_g);
		end if;
		
		--Skip to next file to transmit
		if (file_index = max_file_idx_g) then
			file_index := 1;
		else
			file_index := file_index + 1;
		end if;
		
	end process transmit_proc;
	
	------
	data_valid_proc: process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			data_valid <= '0';
		elsif rising_edge(clk) then
			data_valid <= data_valid_i;
		end if;
	end process data_valid_proc;
	
	------
	data_valid_i_proc:
	data_valid_i <= d_valid_sr (req_delay_g - 1);
	
	------
	data_valid_sr_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			d_valid_sr <= (others => '0');
		elsif falling_edge(clk) then
			if (req_delay_g = 1) then
				d_valid_sr (0) <= req_data;
			else
				d_valid_sr (req_delay_g - 1 downto 0) <= d_valid_sr (req_delay_g - 2 downto 0) & req_data;
			end if;
		end if;
	end process data_valid_sr_proc;
	
end architecture sim_vesa_pic_gen;
