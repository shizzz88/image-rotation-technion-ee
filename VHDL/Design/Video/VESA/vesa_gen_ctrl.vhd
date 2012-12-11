------------------------------------------------------------------------------------------------
-- Model Name 	:	Vesa Non-Interlaced Generator Controller
-- File Name	:	vesa_gen_ctrl.vhd
-- Generated	:	13.01.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This file implemets VESA Non-Interlaced Controller, which transmit to the VGA 
--				screen the following data and signals:
--					*	(R, G, B) Pixels
--					*	Horizontal and Vertical Sync
--					*	Blanking
--				The (R, G, B) Pixels should be supplied to this entity by an outside component.
--				Back Porch, Front Proch, Left - Right - Upper - Lower borders, Sync Time and 
--				Active pixels / lines should be defined, according to the VESA standard, using
--				the generic parameters.
--				The R, G and B port sizes may be changed individually, using a generic parameter
--
-- Handshake:	*	'req_data' 		- Controller requests for RGB Data.
--				*	'data_valid'	- Input data (RGB) is valid. In case this valid signal will
--									not be supplied within 'req_delay_g' clocks from the request - a 
--									default color pixel will be shown in the screen instead of the 
--									expected pixel !!!
--				*	'req_delay_g'	- Request for data 'req_delay_g' clocks before data is required.
--				*	'req_lines_g'	- Request for (number of active pixels per line)x(req_lines_g) pixels
--									each 'req_lines_g', in order to inform the transmitter, to load to its
--									FIFO some amount of pixels.
--
-- Frame:	A generic-color frame can wrap the transmitted image, using the left, right, lower and upper 
--			input registers.
--
-- Frame example: In case the picture is 800X600, where the ROI is 640X480 and the picture is centered, then:
--		(*) Left and Right frame 	= 80 [ (800-640)/2 ]
--		(*) Upper and Lower frame 	= 60 [ (600-480)/2 ]
--
--						-----------------------------
--						|			Frame			|
--						|   ---------------------	|
--						|   |                   |   |
--						|   |                   |   |
--						|   |                   |   |
--						|   |     	Image       |   |
--						|   |                   |   |
--						|   |                   |   |
--						|   |                   |   |
--						|   ---------------------	|
--						|                           |
--						-----------------------------
--
-- VESA Wave:
--																									|			Blank Time			  |
--				|Sync|	Back Porch	|	Left Border, 	Addr Time (Active Video)	, Right Border	| Front Porch	|Sync| Back Porch |
-- HSync	____------______________________________________________________________________________________________------_____________
--
--				|Sync|	Back Porch	|	Top Border, 	Addr Time (Active Video)	, Buttom Border	| Front Porch	|Sync| Back Porch |
-- VSync	____------______________________________________________________________________________________________------_____________
--
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		13.01.2011	Beeri Schreiber		Creation
--			1.01		29.05.2011	Beeri Schreiber		req_pixels is valid until next change
--			1.02		07.01.2012	Beeri Schreiber		req_pixels bug fixed (right frame was not considered)
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity vesa_gen_ctrl is
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
			hor_left_border_g		:	natural		:= 0;				--Horizontal Left Border (Pixels)
			hor_right_border_g		:	natural		:= 0;				--Horizontal Right Border (Pixels)
			hor_back_porch_g		:	integer		:= 88;				--Horizontal Back Porch (Pixels)
			hor_front_porch_g		:	integer		:= 40;				--Horizontal Front Porch (Pixels)
			hor_sync_time_g			:	integer		:= 128;				--Horizontal Sync Time (Pixels)
			ver_top_border_g		:	natural		:= 0;				--Vertical Top Border (Lines)
			ver_buttom_border_g		:	natural		:= 0;				--Vertical Bottom Border (Lines)
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
end entity vesa_gen_ctrl;

architecture rtl_vesa_gen_ctrl of vesa_gen_ctrl is

	-----------------------------  Constants  ----------------------------
	constant hor_sync_start_c	: natural	:= hor_active_pixels_g + hor_left_border_g + hor_right_border_g + hor_front_porch_g;
	constant hor_sync_end_c		: natural	:= hor_sync_start_c + hor_sync_time_g;
	constant hor_total_c		: natural	:= hor_sync_end_c + hor_back_porch_g;
	constant hor_blank_start_c	: natural	:= hor_left_border_g + hor_active_pixels_g + hor_right_border_g;
	constant hor_blank_time_c	: natural	:= hor_front_porch_g + hor_sync_time_g + hor_back_porch_g;

	constant ver_sync_start_c	: natural	:= ver_active_lines_g + ver_top_border_g + ver_buttom_border_g + ver_front_porch_g;
	constant ver_sync_end_c		: natural	:= ver_sync_start_c + ver_sync_time_g;
	constant ver_total_c		: natural	:= ver_sync_end_c + ver_back_porch_g;
	constant ver_blank_start_c	: natural	:= ver_top_border_g + ver_active_lines_g + ver_buttom_border_g;
	constant ver_blank_time_c	: natural	:= ver_front_porch_g + ver_sync_time_g + ver_back_porch_g;

	-----------------------------  Signals  ----------------------------
	--Counters
	signal hcnt					:	natural range 0 to hor_total_c;			--Horizontal Counter
	signal vcnt 				: 	natural range 0 to ver_total_c;			--Vertical Counter
	signal req_lines_cnt		:	positive range 1 to ver_active_lines_g;	--Require pixel counter
	
	--Image Enable	
	signal vesa_en_i			:	std_logic;								--Internal VESA enable
	signal image_tx_en_i		:	std_logic;								--Internal image tx enable
	
	--Frame Border	
	signal left_frame_i			:	natural range 0 to hor_left_border_g + hor_active_pixels_g - 1;							--Left Frame Internal value
	signal right_frame_i		:	natural range 0 to hor_left_border_g + hor_active_pixels_g + hor_right_border_g - 1;	--Right Frame Internal value
	signal upper_frame_i		:	natural range 0 to ver_top_border_g + ver_active_lines_g - 1;							--Upper Frame Internal value
	signal lower_frame_i		:	natural range 0 to ver_top_border_g + ver_active_lines_g + ver_buttom_border_g - 1;		--Lower Frame Internal value
	
	--Internal Conditions
	signal pic_enable_i			:	boolean;								--Vesa Enable and Image Enable

	signal req_data_hor_cond1	:	boolean;								--Drawable area condition #1
	signal req_data_hor_cond2	:	boolean;								--Drawable area condition #2
	signal req_data_ver_cond1	:	boolean;								--Vertical area condition #1
	
	signal blanking_hor_cond	:	boolean;                                --Blanking horizontal condition
	signal blanking_ver_cond	:	boolean;                                --Blanking vertical condition
	
	--VSync
	signal vsync_i				:	std_logic;								--Internal vsync
	
	-----------------------------  Implementation  ----------------------------
begin

	vsync_i_proc:
	vsync	<=	vsync_i;
	
	---------------------------------------------------------------------
	--------------------------	counter_proc Process	-----------------
	---------------------------------------------------------------------
	-- The process points at the current pixel, increments / zeros it
	-- as required
	---------------------------------------------------------------------
	counter_proc: process(clk, reset)
	begin
		if (reset = reset_polarity_g) then
			hcnt <= hor_sync_start_c - 2;
			vcnt <= ver_sync_start_c - 2;
		elsif rising_edge(clk) then
			if (vesa_en_i = '1') then					--VESA is enabled
				if (hcnt = hor_total_c - 1) then		--End of line
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
			else										--VESA is disabled
				hcnt <= hor_sync_start_c - 2;
				vcnt <= ver_sync_start_c - 2;
			end if;
		end if;
	end process counter_proc;

	---------------------------------------------------------------------
	--------------------------	hsync_proc Process	---------------------
	---------------------------------------------------------------------
	-- The process' output is the HSync signal, according to the 
	-- horizontal and vertical counters
	---------------------------------------------------------------------
	hsync_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			hsync	 <= not hsync_polarity_g;
		elsif rising_edge(clk) then
			if (hcnt >= hor_sync_start_c - 1) and (hcnt < hor_sync_end_c - 1) then
				hsync 		<= hsync_polarity_g;
			else
				hsync 		<= not hsync_polarity_g;
			end if;
		end if;
	end process hsync_proc;

	---------------------------------------------------------------------
	--------------------------	vsync_proc Process	---------------------
	---------------------------------------------------------------------
	-- The process' output is the VSync signal, according to the 
	-- horizontal and vertical counters
	---------------------------------------------------------------------
	vsync_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			vsync_i 		<= not vsync_polarity_g;
			vesa_en_i		<= '0';
			image_tx_en_i	<= '0';
			left_frame_i	<= hor_left_border_g;
			right_frame_i	<= hor_left_border_g + hor_active_pixels_g - 1;
			upper_frame_i	<= ver_top_border_g;
			lower_frame_i	<= ver_top_border_g + ver_active_lines_g - 1;
		elsif rising_edge(clk) then
			if (vesa_en_i = '1') then								--VESA is enabled for current image
				if (vcnt >= ver_sync_start_c) and (vcnt < ver_sync_end_c) then
					vsync_i 		<= vsync_polarity_g;
					
					--Register Image Enable and Frame
					image_tx_en_i	<= image_tx_en;
					vesa_en_i		<= vesa_en;
					left_frame_i	<= hor_left_border_g + conv_integer(left_frame);
					right_frame_i	<= hor_left_border_g + hor_active_pixels_g - conv_integer(right_frame) - 1;
					upper_frame_i	<= ver_top_border_g + conv_integer(upper_frame);
					lower_frame_i	<= ver_top_border_g + ver_active_lines_g - conv_integer(lower_frame) - 1;
				else
					vsync_i 		<= not vsync_polarity_g;
					
					--Keep last value
					image_tx_en_i	<= image_tx_en_i;
					vesa_en_i		<= vesa_en_i;
					left_frame_i	<= left_frame_i;
					right_frame_i	<= right_frame_i;
					upper_frame_i	<= upper_frame_i;
					lower_frame_i	<= lower_frame_i;
				end if;
			else												--VESA is disabled. Wait until it is enabled
				vsync_i 			<= not vsync_polarity_g;	
				vesa_en_i			<= vesa_en;					--Register VESA enable
				image_tx_en_i		<= image_tx_en;				--Register Image TX enable
				left_frame_i		<= hor_left_border_g;
				right_frame_i		<= hor_left_border_g + hor_active_pixels_g - 1;
				upper_frame_i		<= ver_top_border_g;
				lower_frame_i		<= ver_top_border_g + ver_active_lines_g - 1;
			end if;
		end if;
	end process vsync_proc;
	
	---------------------------------------------------------------------
	---------------	req_lines_trigger_proc Process	---------------------
	---------------------------------------------------------------------
	-- The process' outputs are the trigger, to the image transmitter, to
	-- enter to its FIFO new data, as required in the pixels_req bus, 
	-- and the number of required pixels.
	---------------------------------------------------------------------
	req_lines_trigger_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			req_lines_cnt	<= 1;
			req_ln_trig		<= '0';
			pixels_req		<= (others => '0');
		elsif rising_edge(clk) then
			if pic_enable_i												--Image is enabled
			and (hcnt = hor_left_border_g + hor_active_pixels_g) then 	--Start of blanking
				if (vsync_i = vsync_polarity_g) then
					req_lines_cnt 	<= 1;
					req_ln_trig		<= '0';
				elsif (req_lines_cnt = 1) then
					req_lines_cnt 	<= req_lines_g;
					req_ln_trig		<= '1';
					pixels_req		<= conv_std_logic_vector((hor_active_pixels_g - conv_integer(left_frame) - conv_integer(right_frame) ) * req_lines_g, integer(ceil(log(real(hor_active_pixels_g * req_lines_g)) / log(2.0))));
				elsif ((vcnt < lower_frame_i) and (vcnt >= upper_frame_i)) then
					req_lines_cnt	<= req_lines_cnt - 1;
					req_ln_trig 	<= '0';
				else
					req_lines_cnt	<= req_lines_cnt;
					req_ln_trig 	<= '0';
				end if;
			else
				req_lines_cnt	<= req_lines_cnt;
				req_ln_trig 	<= '0';
			end if;
		end if;
	end process req_lines_trigger_proc;
	
	---------------------------------------------------------------------
	--------------------------	rgb_proc Process	---------------------
	---------------------------------------------------------------------
	-- The process' output is the entered picture (RGB Pixels) by the
	-- transmitter component, or black pixels, in case of blanking, or
	-- frame transmitting.
	---------------------------------------------------------------------
	rgb_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			r_out <= conv_std_logic_vector (red_default_color_g, red_width_g);
			g_out <= conv_std_logic_vector (green_default_color_g, green_width_g);
			b_out <= conv_std_logic_vector (blue_default_color_g, blue_width_g);
		elsif rising_edge(clk) then
			if (vesa_en_i = '1')
			and ((hcnt < hor_left_border_g + hor_active_pixels_g) and (hcnt >= hor_left_border_g))
			and ((vcnt < ver_top_border_g + ver_active_lines_g) and (vcnt >= ver_top_border_g)) then --Not at blanking range
				if (left_frame_i > hcnt + hor_left_border_g) or (hor_left_border_g + right_frame_i < hcnt)		--Draw Frame
					or (upper_frame_i > vcnt + ver_top_border_g) or ( ver_top_border_g + lower_frame_i < vcnt) then
					r_out <= conv_std_logic_vector (red_default_color_g, red_width_g);
					g_out <= conv_std_logic_vector (green_default_color_g, green_width_g);
					b_out <= conv_std_logic_vector (blue_default_color_g, blue_width_g);
				elsif (data_valid = '1') and (image_tx_en_i = '1') then	--Data valid and image tx is enabled
					r_out <= r_in;
					g_out <= g_in;
					b_out <= b_in;
				else													--Data is not valid. Use default color instead
					r_out <= conv_std_logic_vector (red_default_color_g, red_width_g);
					g_out <= conv_std_logic_vector (green_default_color_g, green_width_g);
					b_out <= conv_std_logic_vector (blue_default_color_g, blue_width_g);
				end if;
			else														--Blanking
				r_out <= (others => '0');
				g_out <= (others => '0');
				b_out <= (others => '0');
			end if;
		end if;
	end process rgb_proc;
	
	---------------------------------------------------------------------
	--------------------------	req_data_proc Process	-----------------
	---------------------------------------------------------------------
	-- The process request for data from the data provider, one pixel 
	-- before it should be transmitted. In case the 'data_valid' will not
	-- be '1' one clock after the request, black pixel will replace the
	-- requested pixel.
	---------------------------------------------------------------------
	req_data_proc : process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			req_data	<= '0';
		elsif rising_edge(clk) then
			if pic_enable_i
			and req_data_ver_cond1 and (req_data_hor_cond1 or req_data_hor_cond2) then
				req_data <= '1';	--Request for data when video is active AND black-frame is not in range
			else
				req_data <= '0';
			end if;
		end if;
	end process req_data_proc;
	
	---------------------------------------------------------------------
	------------------	pic_enable_proc Process	-------------------------
	---------------------------------------------------------------------
	-- The process execute the picture enable condition, that should be 
	-- checked in some processses, in order to work in higher clock 
	-- frequency
	---------------------------------------------------------------------
	pic_enable_proc:
	pic_enable_i <= ((vesa_en_i = '1') and (image_tx_en_i = '1'));
	
	---------------------------------------------------------------------
	------------------	req_data_cond_proc Process	---------------------
	---------------------------------------------------------------------
	-- The process execute some condition, that should be checked in the
	-- 'req_data_proc', in order to work in higher clock frequency
	---------------------------------------------------------------------
	req_data_cond_proc: process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			req_data_hor_cond1 <= false;
			req_data_hor_cond2 <= false;
			req_data_ver_cond1 <= false;
		elsif rising_edge (clk) then
			req_data_hor_cond1 <= ((hcnt + 1 + req_delay_g < right_frame_i) and (hcnt + 1 + req_delay_g + 1 >= left_frame_i));              --Drawable area condition #1
			req_data_hor_cond2 <= (hor_total_c + left_frame_i <= req_delay_g + hcnt + 2);                                                   --Drawable area condition #2
			req_data_ver_cond1 <= ((upper_frame_i <= vcnt) and (lower_frame_i >= vcnt));                                                    --Vertical area condition #1
		end if;
	end process req_data_cond_proc; 
	
	---------------------------------------------------------------------
	------------------      blanking_signal_proc Process    -----------------
	---------------------------------------------------------------------
	-- A logic zero on this signal drives the analog outputs: R, G, B, to
	-- the blanking level. While BLANK is a logical triggered, the 
	-- R, G, B pixel inputs are ignored
	---------------------------------------------------------------------
	blanking_signal_proc: process(clk, reset)
	begin
			if (reset = reset_polarity_g) then
					blank <= blank_polarity_g;                      --Blanking signal to the VGA
			elsif rising_edge(clk) then
					if (vesa_en_i = '0') 
					or blanking_hor_cond
					or blanking_ver_cond then
							blank <= blank_polarity_g;              --Blanking signal to the VGA
					else
							blank <= not blank_polarity_g;  		--Active Video / Left, Right, Top, Buttom Border
					end if;
			end if;
	end process blanking_signal_proc;       
	
	---------------------------------------------------------------------
	------------------      blanking_cond_proc Process      ---------------------
	---------------------------------------------------------------------
	-- The process is the conditionals of the 'blanking_signal_proc'
	---------------------------------------------------------------------
	blanking_cond_proc: process (clk, reset)
	begin
			if (reset = reset_polarity_g) then
					blanking_hor_cond <= false;
					blanking_ver_cond <= false;
			elsif rising_edge(clk) then
					blanking_hor_cond <= ((hcnt >= hor_blank_start_c - 2) and (hcnt < hor_blank_start_c + hor_blank_time_c - 2));
					blanking_ver_cond <= ((vcnt >= ver_blank_start_c) and (vcnt < ver_blank_start_c + ver_blank_time_c));
			end if;
	end process blanking_cond_proc;

end architecture rtl_vesa_gen_ctrl;