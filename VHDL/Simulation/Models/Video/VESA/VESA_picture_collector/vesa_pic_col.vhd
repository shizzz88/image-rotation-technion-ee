------------------------------------------------------------------------------------------------
-- Model Name 	:	Vesa Non-Interlaced Image Generator
-- File Name	:	vesa_pic_col.vhd
-- Generated	:	05.02.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description:  The model receives transmitted image from the VESA Picture Generator, and
--				stores it into a file.
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		05.02.2010	Beeri Schreiber		Creation
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

entity vesa_pic_col is
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
			
			file_dir_g				:	string		:= "D:\ModelSim\MyDesign\RunLen\VHDL\Simulation\TB\Video\VESA\output_files\";
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
end entity vesa_pic_col;

architecture sim_vesa_pic_col of vesa_pic_col is

	-----------------------------  Constants  ----------------------------
	constant hor_sync_start_c	: natural	:= hor_active_pixels_g + hor_left_border_g + hor_right_border_g + hor_front_porch_g;
	constant hor_sync_end_c		: natural	:= hor_sync_start_c + hor_sync_time_g;
	constant hor_total_c		: natural	:= hor_sync_end_c + hor_back_porch_g;

	constant ver_sync_start_c	: natural	:= ver_active_lines_g + ver_top_border_g + ver_buttom_border_g + ver_front_porch_g;
	constant ver_sync_end_c		: natural	:= ver_sync_start_c + ver_sync_time_g;
	constant ver_total_c		: natural	:= ver_sync_end_c + ver_back_porch_g;

	-----------------------------  Signals  ----------------------------
	shared variable pic				: 	RGB_pic_array;							--Picture
	shared variable collect_active	:	boolean := false;						--Collecting picture
	
	--Counters
	signal hcnt						:	natural range 0 to hor_total_c;			--Horizontal Counter
	signal vcnt 					: 	natural range 0 to ver_total_c;			--Vertical Counter
	
	begin
	---------------------------------------------------------------------
	--------------------------	counter_proc Process	-----------------
	---------------------------------------------------------------------
	-- The process points at the current pixel, increments / zeros it
	-- as required
	---------------------------------------------------------------------
	counter_proc: process(clk, reset)
	begin
		if (reset = reset_polarity_g) then
			hcnt <= hor_sync_start_c - 1;
			vcnt <= ver_sync_start_c - 1;
		elsif rising_edge(clk) then
			if (vsync = vsync_polarity_g) then
				vcnt <= ver_sync_end_c - 1;
			end if;
			if (hsync = hsync_polarity_g) then
				hcnt <= hor_sync_end_c - 1;
			elsif (hcnt = hor_total_c - 1) then		--End of line
				hcnt <= 0;
			else
				if (hcnt = hor_sync_start_c - 2) then
					if (vcnt = ver_total_c - 1) then	--End of frame
						vcnt <= 0;
					else
						vcnt <= vcnt + 1;
					end if;
				end if;

				hcnt <= hcnt + 1;
			end if;
		end if;
	end process counter_proc;
	
	---------------------------------------------------------------------
	----------------------	collect_pic_proc Process	-----------------
	---------------------------------------------------------------------
	-- The process collects the image
	---------------------------------------------------------------------
	collect_pic_proc: process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			collect_active := true;
		elsif rising_edge(clk) then
			if ((hcnt < hor_left_border_g + hor_active_pixels_g) and (hcnt >= hor_left_border_g))
			and ((vcnt < ver_top_border_g + ver_active_lines_g) and (vcnt >= ver_top_border_g)) then --Not at blanking range
				pic(R)(vcnt - ver_top_border_g + 1, hcnt - hor_left_border_g + 1) := conv_integer(r_in) mod 256;
				pic(G)(vcnt - ver_top_border_g + 1, hcnt - hor_left_border_g + 1) := conv_integer(g_in) mod 256;
				pic(B)(vcnt - ver_top_border_g + 1, hcnt - hor_left_border_g + 1) := conv_integer(b_in) mod 256;
				collect_active := true;
			else
				collect_active := false;
			end if;
		end if;
	end process collect_pic_proc;
	
	---------------------------------------------------------------------
	----------------------	save_pic_proc Process	---------------------
	---------------------------------------------------------------------
	-- The process stores the image to hard drive
	---------------------------------------------------------------------
	save_pic_proc: process
	variable file_index 	: positive := 1;
	begin
		wait until (vsync'event) and (vsync = vsync_polarity_g); --First sync
		while true loop
			wait until (vsync'event) and (vsync = vsync_polarity_g);
			put_image (file_dir_g & file_prefix_g & "_" & integer'image(file_index) & ".bmp", pic, hor_active_pixels_g, ver_active_lines_g);
			file_index := file_index + 1;
		end loop;
	end process save_pic_proc;
	
end architecture sim_vesa_pic_col;
