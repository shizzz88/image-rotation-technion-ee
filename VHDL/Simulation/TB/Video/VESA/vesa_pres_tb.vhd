------------------------------------------------------------------------------------------------
-- Model Name 	:	VESA Test Bench
-- File Name	:	vesa_pres_tb.vhd
-- Generated	:	20.01.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This model implements the VESA Test bench, for the synthesable generator
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		20.01.2011	Beeri Shreiber					Creation			
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;
use ieee.math_real.all;

library std;
use std.textio.all;

entity vesa_pres_tb is
	generic (
			pixel_freq_g			:	positive	:= 40000000;		--40MHz

			file_dir_out_g			:	string		:= "D:\ModelSim\MyDesign\RunLen\VHDL\Simulation\TB\Video\VESA\output_files\";
			file_prefix_out_g		:	string		:= "800X600";		--Image Prefix

			change_frame_clk_g		:	positive	:= 1;				--Change frame position every 'change_frame_clk_g' clocks
			
			reset_polarity_g		:	std_logic 	:= '0';				--Reset Polarity. '0' = Reset
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
							
			hor_pres_pixels_g		:	positive	:= 640;				--640X480 Pixels in frame
			ver_pres_lines_g		:	positive	:= 480;				--640X480 Pixels in frame

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
			ver_sync_time_g			:	integer		:= 4				--Vertical Sync Time (Lines)
	);
end entity vesa_pres_tb;

architecture arc_vesa_pres_tb of vesa_pres_tb is

-----------------------------------    Components	-------------------------------


component vesa_presentation
	generic (
			reset_polarity_g		:	std_logic 	:= '0';				--Reset Polarity. '0' = Reset
			hsync_polarity_g		:	std_logic 	:= '1';				--Positive HSync
			vsync_polarity_g		:	std_logic 	:= '1';				--Positive VSync
			
			change_frame_clk_g		:	positive	:= 1;				--Change frame position each 'change_frame_clk_g' clocks
			
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
end component vesa_presentation;

component vesa_gen_ctrl 
	generic (
			reset_polarity_g		:	std_logic 	:= '0';				--Reset Polarity. '0' = Reset
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
			hor_left_border_g		:	natural		:= 0;				--Horizontal Left Border
			hor_right_border_g		:	natural		:= 0;				--Horizontal Right Border
			hor_back_porch_g		:	integer		:= 88;				--Horizontal Back Porch (Pixels)
			hor_front_porch_g		:	integer		:= 40;				--Horizontal Front Porch (Pixels)
			hor_sync_time_g			:	integer		:= 128;				--Horizontal Sync Time (Pixels)
			ver_top_border_g		:	natural		:= 0;				--Vertical Top Border
			ver_buttom_border_g		:	natural		:= 0;				--Vertical Buttom Border
			ver_back_porch_g		:	integer		:= 23;				--Vertical Back Porch (Lines)
			ver_front_porch_g		:	integer		:= 1;				--Vertical Front Porch (Lines)
			ver_sync_time_g			:	integer		:= 4				--Vertical Sync Time (Lines)
	);
	port(	
			--Clock, Reset
			clk			:		in std_logic;										--Pixel Clock
			reset		:		in std_logic;										--Reset

			--Input RGB
			r_in		:		in std_logic_vector(red_width_g - 1 downto 0);		--Input R Pixel
			g_in		:		in std_logic_vector(green_width_g - 1 downto 0);	--Input G Pixel
			b_in		:		in std_logic_vector(blue_width_g - 1 downto 0);		--Input B Pixel

			--Frame Border (Size of frame)
			left_frame	:		in std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Left frame border
			upper_frame	:		in std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);	--Upper frame border
			right_frame	:		in std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Right frame border
			lower_frame	:		in std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);	--Lower frame border
			
			--Image Enable. Required both enables to be '1' in order to enable image
			vesa_en		:		in std_logic;										--Enable VESA to transmit image
			image_tx_en	:		in std_logic;										--Image transmitter is enabled

			--Handshake
			data_valid	:		in std_logic;										--Data is valid (If not - BLACK will be shown)
			req_data	:		out std_logic;										--Request for data
			pixels_req	:		out std_logic_vector(integer(ceil(log(real(hor_active_pixels_g*req_lines_g)) / log(2.0))) - 1 downto 0); --Request for PIXELS*LINES pixels from FIFO
			req_ln_trig	:		out std_logic;										--Trigger to image transmitter, to load its FIFO with new data

			--Output RGB
			r_out		:		out std_logic_vector(red_width_g - 1 downto 0);		--Output R Pixel
			g_out		:		out std_logic_vector(green_width_g - 1 downto 0);   --Output G Pixel
			b_out		:		out std_logic_vector(blue_width_g - 1 downto 0);  	--Output B Pixel
			
			--Blanking signal
			blank		:		out std_logic;										--Blanking signal
				
			--Sync Signals				
			hsync		:		out std_logic;										--HSync Signal
			vsync		:		out std_logic										--VSync Signal
	);
end component vesa_gen_ctrl;

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
end component vesa_pic_col;


----------------------------------	Signals	--------------------------------------
--Clock, Reset
signal clk			:		std_logic := '0';								--Pixel Clock
signal reset		:		std_logic;										--Reset
	
--Input RGB	
signal r_in			:		std_logic_vector(red_width_g - 1 downto 0);		--Input R Pixel
signal g_in			:		std_logic_vector(green_width_g - 1 downto 0);	--Input G Pixel
signal b_in			:		std_logic_vector(blue_width_g - 1 downto 0);	--Input B Pixel

--Frame Border (Size of frame)
signal left_frame	:		std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Left frame border
signal upper_frame	:		std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0)	;	--Upper frame border
signal right_frame	:		std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Right frame border
signal lower_frame	:		std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0)	;	--Lower frame border

--Image Enable. Required both enables to be '1' in order to enable image
signal vesa_en		:		std_logic := '1';								--Enable VESA to transmit image
signal image_tx_en	:		std_logic := '1';								--Image transmitter is enabled

--Handshake
signal data_valid	:		std_logic;										--Data is valid (If not - BLACK will be shown)
signal req_data		:		std_logic;										--Request for data
signal pixels_req	:		std_logic_vector(integer(ceil(log(real(hor_active_pixels_g*req_lines_g)) / log(2.0))) - 1 downto 0); --Request for PIXELS*LINES pixels from FIFO
signal req_ln_trig	:		std_logic;										--Trigger to image transmitter, to load its FIFO with new data

--Output RGB
signal r_out		:		std_logic_vector(red_width_g - 1 downto 0);		--Output R Pixel
signal g_out		:		std_logic_vector(green_width_g - 1 downto 0);   --Output G Pixel
signal b_out		:		std_logic_vector(blue_width_g - 1 downto 0);  	--Output B Pixel

--Blanking signal
signal blank		:		std_logic;										--Blanking signal
	
--Sync Signals				
signal hsync		:		std_logic;										--HSync Signal
signal vsync		:		std_logic;										--VSync Signal

-------------------------------	Implementation	---------------------------
begin

	vesa_pres_inst: vesa_presentation generic map
					(                          
						reset_polarity_g	   => reset_polarity_g,
						hsync_polarity_g	   => hsync_polarity_g,
						vsync_polarity_g	   => vsync_polarity_g,
						                       
						hor_pres_pixels_g	   => hor_pres_pixels_g,
						ver_pres_lines_g	   => ver_pres_lines_g,
						
						hor_active_pixels_g	   => hor_active_pixels_g,
						ver_active_lines_g	   => ver_active_lines_g,
						
						change_frame_clk_g	   => change_frame_clk_g,
						
						red_width_g			   => red_width_g,
						green_width_g		   => green_width_g,
						blue_width_g		   => blue_width_g
					)
					port map
					(
						clk			           =>	clk,			
					    reset		           =>	reset,
					    vsync		           =>	vsync,		
						hsync				   =>	hsync,
					    req_data	           =>	req_data,
					    r_out		           =>	r_in,	
					    g_out		           =>	g_in,		
					    b_out		           =>	b_in,
						left_frame	           =>	left_frame,	
						upper_frame	           =>	upper_frame,	
						right_frame	           =>	right_frame,	
						lower_frame	           =>	lower_frame,	
					    data_valid	           =>	data_valid	
					);
					
	vesa_gen_ctrl_inst: vesa_gen_ctrl generic map
					(
						reset_polarity_g		=>	reset_polarity_g		,
					    hsync_polarity_g		=>  hsync_polarity_g		,
					    vsync_polarity_g		=>  vsync_polarity_g		,
					    blank_polarity_g		=>  blank_polarity_g		,
					                                                      
					    red_default_color_g		=>  red_default_color_g		,
					    green_default_color_g	=>  green_default_color_g	,
					    blue_default_color_g	=>  blue_default_color_g	,
					                            
					    red_width_g				=>  red_width_g				,
					    green_width_g			=>  green_width_g			,
					    blue_width_g			=>  blue_width_g			,
					    req_delay_g				=>  req_delay_g				,
					    req_lines_g				=>  req_lines_g				,
					    				        
					    hor_active_pixels_g		=>  hor_active_pixels_g		,
					    ver_active_lines_g		=>  ver_active_lines_g		,
					    hor_left_border_g		=>  hor_left_border_g		,
					    hor_right_border_g		=>  hor_right_border_g		,
					    hor_back_porch_g		=>  hor_back_porch_g		,
					    hor_front_porch_g		=>  hor_front_porch_g		,
					    hor_sync_time_g			=>  hor_sync_time_g			,
					    ver_top_border_g		=>  ver_top_border_g		,
					    ver_buttom_border_g		=>  ver_buttom_border_g		,
					    ver_back_porch_g		=>  ver_back_porch_g		,
						ver_front_porch_g	    =>  ver_front_porch_g		,
						ver_sync_time_g		    =>  ver_sync_time_g			
					)
					port map
					(
						clk			           =>	clk			            ,
						reset		           =>	reset		            ,
						                       
						r_in		           =>	r_in		            ,
						g_in		           =>	g_in		            ,
						b_in		           =>	b_in		            ,
						                       
					    left_frame	           =>	left_frame	            ,
					    upper_frame	           =>	upper_frame	            ,
					    right_frame	           =>	right_frame	            ,
					    lower_frame	           =>	lower_frame	            ,
					                           
					    vesa_en		           =>	vesa_en		            ,
					    image_tx_en	           =>	image_tx_en	            ,
					                           
					    data_valid	           =>	data_valid	            ,
					    req_data	           =>	req_data	            ,
					    pixels_req	           =>	pixels_req	            ,
					    req_ln_trig	           =>	req_ln_trig	            ,
					                           
					    r_out		           =>	r_out		            ,
					    g_out		           =>	g_out		            ,
					    b_out		           =>	b_out		            ,
					                           
					    blank		           =>	blank					,
					    	                        	
					    hsync		           =>   hsync					,
					    vsync		           =>   vsync		
					);
					
	vesa_pic_col_inst : vesa_pic_col generic map 
					(
						reset_polarity_g		=> reset_polarity_g	       ,
	                    hsync_polarity_g	    => hsync_polarity_g	       ,
	                    vsync_polarity_g	    => vsync_polarity_g	       ,
	                    blank_polarity_g	    => blank_polarity_g	       ,
	                                                                       
	                    red_width_g			    => red_width_g			   ,
	                    green_width_g		    => green_width_g		   ,
	                    blue_width_g		    => blue_width_g		       ,
	                    				         				           
	                    hor_active_pixels_g	    => hor_active_pixels_g	   ,
	                    ver_active_lines_g	    => ver_active_lines_g	   ,
	                    hor_left_border_g	    => hor_left_border_g	   ,
	                    hor_right_border_g	    => hor_right_border_g	   ,
	                    hor_back_porch_g	    => hor_back_porch_g	       ,
	                    hor_front_porch_g	    => hor_front_porch_g	   ,
	                    hor_sync_time_g		    => hor_sync_time_g		   ,
	                    ver_top_border_g	    => ver_top_border_g	       ,
	                    ver_buttom_border_g	    => ver_buttom_border_g	   ,
	                    ver_back_porch_g	    => ver_back_porch_g	       ,
	                    ver_front_porch_g	    => ver_front_porch_g	   ,
	                    ver_sync_time_g		    => ver_sync_time_g		   ,

						file_dir_g				=> file_dir_out_g		   ,
						file_prefix_g			=> "pres_" & file_prefix_out_g
					)
					port map 
					(
						clk		                => clk		,
	                    reset	                => reset	,
	                    hsync	                => hsync	,
	                    vsync	                => vsync	,
	                    blank	                => blank	,
	                    r_in	                => r_out	,
	                    g_in	                => g_out	,
	                    b_in	                => b_out	
					);
					
	--Clock Process
	clock_proc:
	clk	<= not clk after (1 sec /real(pixel_freq_g*2));	--40MHz
	
	--Reset at startup
	rst_proc:
	reset <= reset_polarity_g, (not reset_polarity_g) after 400 ns;

end architecture arc_vesa_pres_tb;