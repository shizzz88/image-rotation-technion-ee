------------------------------------------------------------------------------------------------
-- Model Name 	:	Vesa Non-Interlaced Image Generator
-- File Name	:	vesa_presentation.vhd
-- Generated	:	09.03.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The generator generates a color pattern to the screen.
--				This generator is synthesable. Its purpose is to check the VESA generator
--				on the FPGA.
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		09.03.2010	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

entity vesa_presentation is
	generic (
			reset_polarity_g		:	std_logic 	:= '0';				--Reset Polarity. '0' = Reset
			hsync_polarity_g		:	std_logic 	:= '1';				--Positive HSync
			vsync_polarity_g		:	std_logic 	:= '1';				--Positive VSync
			
			change_frame_clk_g		:	positive	:= 266000000;		--Change frame position each 'change_frame_clk_g' clocks
			
			hor_pres_pixels_g		:	positive	:= 640;				--640X480 Pixels in frame
			ver_pres_lines_g		:	positive	:= 480;				--640X480 Pixels in frame

			hor_active_pixels_g		:	positive	:= 800;				--800 active pixels per line
			ver_active_lines_g		:	positive	:= 600;				--600 active lines

			red_width_g				:	positive 	:= 8;				--Default std_logic_vector size of Red Pixels
			green_width_g			:	positive 	:= 8;				--Default std_logic_vector size of Green Pixels
			blue_width_g			:	positive 	:= 8				--Default std_logic_vector size of Blue Pixels
			);
	port	(
			clk						:	in std_logic;					--Clock
			reset					:	in std_logic;
			vsync					:	in std_logic;
			hsync					:	in std_logic;
			req_data				:	in std_logic;
			r_out					:	out std_logic_vector (red_width_g - 1 downto 0);
			g_out					:	out std_logic_vector (green_width_g - 1 downto 0);
			b_out					:	out std_logic_vector (blue_width_g - 1 downto 0);
			left_frame				:	out std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Left frame border
			upper_frame				:	out std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);		--Upper frame border
			right_frame				:	out std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Right frame border
			lower_frame				:	out std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);		--Lower frame border
			data_valid				: 	out std_logic
			);
end entity vesa_presentation;

architecture rtl_vesa_presentation of vesa_presentation is

------------------------  Constants -------------------------------------------------
constant rf_c			: integer := 2**(red_width_g - 8); 		--Red factor
constant gf_c			: integer := 2**(green_width_g - 8); 	--Blue factor
constant bf_c			: integer := 2**(blue_width_g - 8); 	--Blue factor

------------------------  Signals & Variables ----------------------------------------
signal hcnt				: integer range 0 to hor_pres_pixels_g;	--Horizontal Counter
signal vcnt				: integer range 0 to ver_pres_lines_g;	--Vertical Counter

signal frame_cnt		: integer range 0 to change_frame_clk_g;--Frame Counter
signal frame_flag		: std_logic;							--Change frame flag
signal frame_state		: natural range 1 to 5;					--Frame state (FSM)

begin
	-------------------------------------------------------------------
	------------------	Process frame_cnt_proc	-----------------------
	-------------------------------------------------------------------
	-- The process counts number of clocks. Each 'change_frame_clk_g',
	-- it rises a flag, to change frame position.
	-------------------------------------------------------------------
	frame_cnt_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			frame_cnt	<= 0;
			frame_flag 	<= '0';
		
		elsif rising_edge(clk) then
			if (frame_cnt = change_frame_clk_g) then
				frame_cnt 	<= 0;
				frame_flag 	<= '1';
			else
				frame_cnt 	<= frame_cnt + 1;
				frame_flag 	<= '0';
			end if;
		end if;
	end process frame_cnt_proc;
	
	-------------------------------------------------------------------
	------------------	Process frame_proc	---------------------------
	-------------------------------------------------------------------
	-- The process changes the frame position, when the 'frame_flag'
	-- rises.
	-------------------------------------------------------------------
	frame_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			left_frame	<= conv_std_logic_vector((hor_active_pixels_g - hor_pres_pixels_g),  integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));	--TOP Right
			upper_frame	<= conv_std_logic_vector(0, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
			right_frame	<= conv_std_logic_vector(0, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
			lower_frame	<= conv_std_logic_vector((ver_active_lines_g - ver_pres_lines_g), integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
			frame_state <= 1;

		elsif rising_edge(clk) then
			if (frame_flag = '1') then --Change frame position
				case frame_state is
					when 1 =>	--Centered
						left_frame	<= conv_std_logic_vector((hor_active_pixels_g - hor_pres_pixels_g)/2,  integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
                        upper_frame	<= conv_std_logic_vector((ver_active_lines_g - ver_pres_lines_g)/2, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
					    right_frame	<= conv_std_logic_vector((hor_active_pixels_g - hor_pres_pixels_g)/2, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
	                    lower_frame	<= conv_std_logic_vector((ver_active_lines_g - ver_pres_lines_g)/2, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
						frame_state <= 2;

					when 2 =>	--Top left 
						left_frame	<= conv_std_logic_vector(0,  integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
                        upper_frame	<= conv_std_logic_vector(0, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
					    right_frame	<= conv_std_logic_vector((hor_active_pixels_g - hor_pres_pixels_g), integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
	                    lower_frame	<= conv_std_logic_vector((ver_active_lines_g - ver_pres_lines_g), integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
						frame_state <= 3;
	
					when 3 =>	--Top right 
						left_frame	<= conv_std_logic_vector((hor_active_pixels_g - hor_pres_pixels_g),  integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
                        upper_frame	<= conv_std_logic_vector(0, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
					    right_frame	<= conv_std_logic_vector(0, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
	                    lower_frame	<= conv_std_logic_vector((ver_active_lines_g - ver_pres_lines_g), integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
						frame_state <= 4;

					when 4 =>	--Buttom left 
						left_frame	<= conv_std_logic_vector(0,  integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
                        upper_frame	<= conv_std_logic_vector((ver_active_lines_g - ver_pres_lines_g), integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
					    right_frame	<= conv_std_logic_vector((hor_active_pixels_g - hor_pres_pixels_g), integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
	                    lower_frame	<= conv_std_logic_vector(0, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
						frame_state <= 5;
						
					when 5 =>	--Buttom right
						left_frame	<= conv_std_logic_vector((hor_active_pixels_g - hor_pres_pixels_g),  integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
                        upper_frame	<= conv_std_logic_vector((ver_active_lines_g - ver_pres_lines_g), integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
					    right_frame	<= conv_std_logic_vector(0, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
	                    lower_frame	<= conv_std_logic_vector(0, integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))));
						frame_state <= 1;
				end case;
			
			else
				frame_state <= frame_state;
			end if;
		end if;
	end process frame_proc;

	-------------------------------------------------------------------
	------------------	Process cnt_proc	---------------------------
	-------------------------------------------------------------------
	-- The process counts the horizontal and vertical lines
	-------------------------------------------------------------------
	cnt_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			hcnt <= 0;
			vcnt <= 0;

		elsif rising_edge(clk) then
			if (vsync = vsync_polarity_g) then
				hcnt <= 0;
				vcnt <= 0;
			else
				if (hsync = hsync_polarity_g) then
					if (hcnt /= 0) then
						hcnt <= 0;
						if (vcnt < ver_pres_lines_g) then
							vcnt <= vcnt + 1;
						else
							vcnt <= 0;
						end if;
					else
						hcnt <= hcnt;
						vcnt <= vcnt;
					end if;
				
				elsif (hcnt < hor_pres_pixels_g) and (req_data = '1') then
					hcnt <= hcnt + 1;
					
				else
					hcnt <= hcnt;
					vcnt <= vcnt;
				end if;
			end if;
		end if;
	end process cnt_proc;
	
	-------------------------------------------------------------------
	------------------	Process transmit_proc	-----------------------
	-------------------------------------------------------------------
	-- The process transmits the R, G and B pixel to the screen
	-------------------------------------------------------------------
	transmit_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			r_out 		<= (others => '0');
			g_out 		<= (others => '0');
			b_out 		<= (others => '0');
			data_valid 	<= '0';
		
		elsif rising_edge(clk) then
			if (req_data = '1') then	--Request for data_valid
				data_valid <= '1';		--Data is valid
				if (hcnt <= hor_pres_pixels_g / 4) then
					r_out <= conv_std_logic_vector((hcnt + vcnt mod 256)*rf_c, red_width_g);
					g_out <= (others => '0');
					b_out <= (others => '0');
				elsif (hcnt <= hor_pres_pixels_g / 2) then
					r_out <= (others => '0');
					g_out <= conv_std_logic_vector((hcnt + vcnt mod 256)*gf_c, green_width_g);
					b_out <= (others => '0');
				elsif (hcnt <= 3 * hor_pres_pixels_g / 4) then
					r_out <= (others => '0');
					g_out <= (others => '0');
					b_out <= conv_std_logic_vector((hcnt + vcnt mod 256)*bf_c, blue_width_g);
				else
					r_out <= conv_std_logic_vector((hcnt + vcnt mod 256)*rf_c, red_width_g);
					g_out <= conv_std_logic_vector((hcnt + vcnt mod 256)*gf_c, green_width_g);
					b_out <= conv_std_logic_vector((hcnt + vcnt mod 256)*bf_c, blue_width_g);
				end if;
			
			else
				data_valid <= '0';
				r_out 		<= (others => '0');
				g_out 		<= (others => '0');
				b_out 		<= (others => '0');
			end if;
		end if;
	end process transmit_proc;
	
end architecture rtl_vesa_presentation;
