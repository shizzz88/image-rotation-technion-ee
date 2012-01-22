------------------------------------------------------------------------------------------------
-- Model Name 	:	Display Controller
-- File Name	:	disp_ctrl_top.vhd
-- Generated	:	19.5.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Display Controller TOP.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		10.5.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

library work ;
use work.ram_generic_pkg.all;

entity disp_ctrl_top is
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
end entity disp_ctrl_top;

architecture rtl_disp_ctrl_top of disp_ctrl_top is

--	###########################		Costants		##############################	--
constant reg_width_c			:	positive 	:= 8;	--Width of registers
constant reg_addr_width_c		:	positive 	:= 4;	--Width of registers' address
constant type_reg_addr_c		:	natural		:= 1;	--Type register address
constant left_frame_reg_addr_c	:	natural		:= 5;	--Frame register address
constant right_frame_reg_addr_c	:	natural		:= 6;	--Frame register address
constant upper_frame_reg_addr_c	:	natural		:= 7;	--Frame register address
constant lower_frame_reg_addr_c	:	natural		:= 8;	--Frame register address

--###########################	Signals		###################################--
--40MHz Clock Domain Signals
signal pixels_req		:	std_logic_vector(integer(ceil(log(real(hor_active_pixels_g*req_lines_g)) / log(2.0))) - 1 downto 0); --Request for PIXELS*LINES pixels from FIFO
signal req_ln_trig		:	std_logic;						--Trigger to image transmitter, to load its FIFO with new data
signal vsync_int		:	std_logic;						--Vertical Sync
signal hsync_int		:	std_logic;						--Horizontal Sync
signal dc_fifo_full		:	std_logic;						--DC FIFO is full
signal dc_fifo_wr_en_log:	std_logic;						--DC FIFO Write enable logic
signal vesa_req_data	:	std_logic;						--VESA Generator request for data
signal dc_fifo_empty	:	std_logic;						--DC FIFO is empty
signal dc_fifo_dout		:	std_logic_vector (7 downto 0);	--Output from DC FIFO
signal dc_rd_req		:	std_logic;						--DC FIFO Read Request from VESA when FIFO is not empty
signal vesa_data_valid	:	std_logic;						--Input data is valid for VESA (From DC FIFO)
signal vesa_data_valid_sy:	std_logic;						--Input data is valid for VESA (Sythetic Frame Generator)
signal r_in_sy			:	std_logic_vector (red_width_g - 1 downto 0);	--RED (Synthetic Frame Generator)
signal g_in_sy			:	std_logic_vector (green_width_g - 1 downto 0);	--GREEN (Synthetic Frame Generator)
signal b_in_sy			:	std_logic_vector (blue_width_g - 1 downto 0);	--BLUE (Synthetic Frame Generator)
signal r_in				:	std_logic_vector (red_width_g - 1 downto 0);	--RED   (From DC FIFO)
signal g_in				:	std_logic_vector (green_width_g - 1 downto 0);	--GREEN (From DC FIFO)
signal b_in				:	std_logic_vector (blue_width_g - 1 downto 0);	--BLUE  (From DC FIFO)

--133MHz Clock Domain Signals	
--FIFO
signal wrusedw			:	std_logic_vector (11 downto 0);
signal sc_fifo_full		:	std_logic;						--SC FIFO is full
signal sc_fifo_empty	:	std_logic;						--SC FIFO is empty
signal sc_fifo_dout		:	std_logic_vector (7 downto 0);	--Output FIFO data
signal sc_fifo_dout_val	:	std_logic;						--Output FIFO data is valid
signal sc_fifo_rd_en	:	std_logic;						--Read enable to FIFO
signal sc_fifo_wr_en	:	std_logic;						--Write enable to FIFO
signal dc_fifo_din		:	std_logic_vector (7 downto 0);	--Input FIFO data
signal dc_fifo_wr_en	:	std_logic;						--Write enable to FIFO
signal dc_fifo_aclr		:	std_logic;						--Clear to DC FIFO
signal flush			:	std_logic;						--Flush data in FIFO, and go to rx state in decompressor
signal sc_fifo_rd_req	:	std_logic;						--Read request to sc_fifo from dc_fifo

--Registers
signal left_frame_rg	:	std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Left frame border
signal upper_frame_rg	:	std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);	--Upper frame border
signal right_frame_rg	:	std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Right frame border
signal lower_frame_rg	:	std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);	--Lower frame border

--WBS Signals
signal wbs_reg_din_ack		:	std_logic;					--WBS Register din acknowledged
signal wbs_reg_dout			:   std_logic_vector (reg_width_c - 1 downto 0);		--WBS Register dout
signal wbs_reg_dout_valid	:   std_logic;					--WBS Register dout_valid
signal wbs_reg_cyc			:	std_logic;					--Cycle for Registers

--Signals to registers
signal reg_addr			:	std_logic_vector (reg_addr_width_c - 1 downto 0);	--Address to register. Relevant only when addr_en_g = true
signal reg_din			:	std_logic_vector (reg_width_c - 1 downto 0);		--Input data
signal reg_wr_en		:	std_logic;											--Input data is valid
signal reg_rd_en		:	std_logic;											--Request for data from registers

--Type register signals
signal type_reg_din_ack		:	std_logic;										--Data has been acknowledged
signal type_reg_rd_en		:	std_logic;										--Read Enable
signal type_reg_dout		:	std_logic_vector (reg_width_c - 1 downto 0);	--Output data
signal type_reg_dout_valid	:	std_logic;										--Output data is valid

--Frame's register signals
signal left_frame_reg_din_ack		:	std_logic;								--Data has been acknowledged
signal left_frame_reg_rd_en			:	std_logic;								--Read Enable
signal left_frame_reg_dout_valid	:	std_logic;								--Output data is valid
signal right_frame_reg_din_ack		:	std_logic;								--Data has been acknowledged
signal right_frame_reg_rd_en		:	std_logic;								--Read Enable
signal right_frame_reg_dout_valid	:	std_logic;								--Output data is valid
signal upper_frame_reg_din_ack		:	std_logic;								--Data has been acknowledged
signal upper_frame_reg_rd_en		:	std_logic;								--Read Enable
signal upper_frame_reg_dout_valid	:	std_logic;								--Output data is valid
signal lower_frame_reg_din_ack		:	std_logic;								--Data has been acknowledged
signal lower_frame_reg_rd_en		:	std_logic;								--Read Enable
signal lower_frame_reg_dout_valid	:	std_logic;								--Output data is valid

--Frame
signal left_frame_sy	:	std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Left frame border
signal upper_frame_sy	:	std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);	--Upper frame border
signal right_frame_sy	:	std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Right frame border
signal lower_frame_sy	:	std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);	--Lower frame border

signal left_frame		:	std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Left frame border
signal upper_frame		:	std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);	--Upper frame border
signal right_frame		:	std_logic_vector(integer(ceil(log(real(hor_active_pixels_g)) / log(2.0))) - 1 downto 0);	--Right frame border
signal lower_frame		:	std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);	--Lower frame border

--###########################	Components	###################################--

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
end component vesa_gen_ctrl;

component synthetic_frame_generator 
	generic (
			reset_polarity_g		:	std_logic 	:= '0';				--Reset Polarity. '0' = Reset
			hsync_polarity_g		:	std_logic 	:= '1';				--Positive HSync
			vsync_polarity_g		:	std_logic 	:= '1';				--Positive VSync
			
			change_frame_clk_g		:	positive	:= 120000000;		--Change frame position each 'change_frame_clk_g' clocks
			
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
end component synthetic_frame_generator;

component general_fifo 
	generic(	 
		reset_polarity_g	: std_logic	:= '0';	-- Reset Polarity
		width_g				: positive	:= 8; 	-- Width of data
		depth_g 			: positive	:= 9;	-- Maximum elements in FIFO
		log_depth_g			: natural	:= 4;	-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
		almost_full_g		: positive	:= 8; 	-- Rise almost full flag at this number of elements in FIFO
		almost_empty_g		: positive	:= 1 	-- Rise almost empty flag at this number of elements in FIFO
		);
	 port(
		 clk 		: in 	std_logic;									-- Clock
		 rst 		: in 	std_logic;                                  -- Reset
		 din 		: in 	std_logic_vector (width_g-1 downto 0);      -- Input Data
		 wr_en 		: in 	std_logic;                                  -- Write Enable
		 rd_en 		: in 	std_logic;                                  -- Read Enable (request for data)
		 flush		: in	std_logic;									-- Flush data
		 dout 		: out 	std_logic_vector (width_g-1 downto 0);	    -- Output Data
		 dout_valid	: out 	std_logic;                                  -- Output data is valid
		 afull  	: out 	std_logic;                                  -- FIFO is almost full
		 full 		: out 	std_logic;	                                -- FIFO is full
		 aempty 	: out 	std_logic;                                  -- FIFO is almost empty
		 empty 		: out 	std_logic;                                  -- FIFO is empty
		 used 		: out 	std_logic_vector (log_depth_g  downto 0) 	-- Current number of elements is FIFO. Note the range. In case depth_g is 2^x, then the extra bit will be used
	     );
end component general_fifo;

component dc_fifo
	port
	(
		aclr		: in std_logic  := '0';
		data		: in std_logic_vector (7 downto 0);
		rdclk		: in std_logic ;
		rdreq		: in std_logic ;
		wrclk		: in std_logic ;
		wrreq		: in std_logic ;
		q			: out std_logic_vector (7 downto 0);
		rdempty		: out std_logic ;
		wrfull		: out std_logic ;
		wrusedw		: out std_logic_vector (12 downto 0)		
	);
end component dc_fifo;

component pixel_mng
   generic (
			reset_polarity_g	:	std_logic	:= '0';		--Reset active low
			vsync_polarity_g	:	std_logic	:= '1';		--VSync Polarity
			screen_hor_pix_g	:	positive	:= 800;		--800X600 = Actual screen resolution
			hor_pixels_g		:	positive	:= 640;		--640X480
			ver_lines_g			:	positive	:= 480;		--640X480
			req_lines_g			:	positive	:= 3;		--Number of lines to request from image transmitter, to hold in its FIFO
			rep_size_g			:	positive	:= 7		--2^7=128 => Maximum of 128 repetitions for pixel / line
           );
   port
   	   (
   	    clk_i			:	in std_logic; 						--Wishbone Clock
   	    rst				:	in std_logic;						--Reset
		
		-- Wishbown Signals
		wbm_ack_i		:	in std_logic;						--Wishbone Acknowledge
		wbm_err_i		:	in std_logic;						--Wishbone Error
		wbm_stall_i		:	in std_logic;						--Wishbone Stall
		wbm_dat_i		:	in std_logic_vector (7 downto 0);	--Wishbone Input Data
		wbm_cyc_o		:	out std_logic;						--Wishbone Cycle
		wbm_stb_o		:	out std_logic;						--Wishbone Strobe
		wbm_adr_o		:	out std_logic_vector (9 downto 0);	--Wishbone Address
		wbm_tga_o		:	out std_logic_vector (9 downto 0);	--Burst Length
		
		--Signals to FIFO
		fifo_wr_en		:	out std_logic;						--Write Enable to FIFO
		fifo_flush		:	out std_logic;						--Flush FIFO
		
		--Signals from VESA Generator (Clock Domain: 40MHz)
		pixels_req		:	in std_logic_vector(integer(ceil(log(real(screen_hor_pix_g*req_lines_g)) / log(2.0))) - 1 downto 0); --Request for PIXELS*LINES pixels from FIFO
		req_ln_trig		:	in std_logic;						--Trigger to image transmitter, to load its FIFO with new data
		vsync			:	in std_logic
		
   	   );
end component pixel_mng;

--component runlen_extractor 
--   generic (
--			reset_polarity_g	:	std_logic	:= '0';		--Reset active low
--			pixels_per_line_g	:	positive	:= 640;		--640X480
--			rep_size_g			:	positive	:= 7;		--2^7=128 => Maximum of 128 repetitions for pixel / line
--			width_g				:	positive	:= 8		--Input / output width
--           );
--  port
--   	   (
--   	     clk		:	in std_logic;       							--Input clock
--   	     rst		:	in std_logic;									--Reset
--		 fifo_full	:	in std_logic;									--Output FIFO is full
--		 fifo_empty	:	in std_logic;									--Input FIFO is empty
--		 flush		:	in std_logic;									--Restart component
--		 din		:	in std_logic_vector (width_g - 1 downto 0);		--Input data
--		 din_val	:	in std_logic;									--Input data is valid
--		 req_data	:	out std_logic;									--Request for data
--		 dout		:	out std_logic_vector (width_g - 1 downto 0);	--Output pixel
--		 dout_val	:	out std_logic									--Output data is valid
 --  	   );
--end component runlen_extractor;

component gen_reg
	generic	(
			reset_polarity_g	:	std_logic	:= '0';					--When reset = reset_polarity_g, system is in RESET mode
			width_g				:	positive	:= 8;					--Width: Number of bits
			addr_en_g			:	boolean		:= true;				--TRUE: Address enabled  - responde by register will occur only when specific address has been specified
			addr_val_g			:	natural		:= 0;					--Default register address
			addr_width_g		:	positive	:= 4;					--2^4 = 16 register address is supported
			read_en_g			:	boolean		:= true;				--Enabling read
			write_en_g			:	boolean		:= true;				--Enabling write
			clear_on_read_g		:	boolean		:= false;				--TRUE: Clear on read (set to default value), FALSE otherwise
			default_value_g		:	natural		:= 0					--Default value of register
			);
	port	(
			--Clock and Reset
			clk				:	in std_logic;									--Clock
			reset			:	in std_logic;									--Reset

			--Address
			addr			:	in std_logic_vector (addr_width_g - 1 downto 0);--Address to register. Relevant only when addr_en_g = true
			
			--Input data handshake
			din				:	in std_logic_vector (width_g - 1 downto 0);		--Input data
			wr_en			:	in std_logic;									--Input data is valid
			clear			:	in std_logic;									--Set register value to its default value.
			din_ack			:	out std_logic;									--Data has been acknowledged
			
			--Output data handshake
			rd_en			:	in std_logic;									--Output data request
			dout			:	out std_logic_vector (width_g - 1 downto 0);	--Output data
			dout_valid		:	out std_logic									--Output data is valid
			);
end component gen_reg;

component wbs_reg
	generic	(
			reset_polarity_g	:	std_logic	:= '0';							--'0' = reset active
			width_g				:	positive	:= 8;							--Width: Registers width
			addr_width_g		:	positive	:= 4							--2^4 = 16 register address is supported
			);
	port	(
			rst			:	in	std_logic;										--Reset
			
			--Wishbone Slave Signals
			clk_i		:	in std_logic;										--Wishbone Clock
			wbs_cyc_i	:	in std_logic;										--Cycle command from WBM
			wbs_stb_i	:	in std_logic;										--Strobe command from WBM
			wbs_adr_i	:	in std_logic_vector (addr_width_g - 1 downto 0);	--Register's address
			wbs_we_i	:	in std_logic;										--Write enable
			wbs_dat_i	:	in std_logic_vector (width_g - 1 downto 0);			--Data In
			wbs_dat_o	:	out std_logic_vector (width_g - 1 downto 0);		--Data Out
			wbs_ack_o	:	out std_logic;										--Input data has been successfuly acknowledged
			wbs_stall_o	:	out std_logic;										--Not ready to receive data
			
			--Signals to Registers
			din_ack		:	in std_logic;										--Write command has been received
			dout		:	in std_logic_vector (width_g - 1 downto 0);			--Output data
			dout_valid	:	in std_logic;										--Output data is valid
			addr		:	out std_logic_vector (addr_width_g - 1 downto 0);	--Address to register.
			din			:	out std_logic_vector (width_g - 1 downto 0);		--Input data
			rd_en		:	out std_logic;										--Request for data
			wr_en		:	out std_logic										--Write data
			);
end component wbs_reg;

begin

--Mux implementation: read request to sc_fifo from dc_fifo
	fifo_mux:	
		sc_fifo_rd_req <= '1' when ((dc_fifo_full='0') and (sc_fifo_empty='0'))
		else '0';
	

	--###########################	Hidden Processes	###########################--
	--DC FIFO aclr
	dc_fifo_aclr_gen1:
	if (reset_polarity_g = '0') generate
		dc_fifo_aclr_proc:
		dc_fifo_aclr	<=	(not rst_133) or flush;
	end generate dc_fifo_aclr_gen1;

	dc_fifo_aclr_gen2:
	if (reset_polarity_g = '1') generate
		dc_fifo_aclr_proc:
		dc_fifo_aclr	<=	rst_133 or flush;
	end generate dc_fifo_aclr_gen2;

	
	--VESA Data valid process
	vesa_data_valid_proc:
	vesa_data_valid	<=	vesa_data_valid_sy when type_reg_dout (synth_bit_g) = '1'
						else (not dc_fifo_empty);

	--VSync process:
	vsync_proc:
	vsync	<=	vsync_int;

	--HSync process:
	hsync_proc:
	hsync	<=	hsync_int;
	
	--DC FIFO Data Request
	dc_rd_req_proc:
	dc_rd_req	<=	vesa_req_data and (not dc_fifo_empty);
	
	--DC FIFO Full
	-- dc_fifo_wr_en_log_proc:
	-- dc_fifo_wr_en_log	<=	dc_fifo_wr_en and (not dc_fifo_full);	
	
	--New picture - Read from start of SDRAM (WBM_TGC_O)
	wbm_tgc_o_proc:
	wbm_tgc_o	<=	flush;	--'1' to start from the first image address

	--RGB Processes:
	r_in_proc:
	r_in	<=	r_in_sy when type_reg_dout (synth_bit_g) = '1'
				else dc_fifo_dout;

	g_in_proc:
	g_in	<=	g_in_sy when type_reg_dout (synth_bit_g) = '1'
				else dc_fifo_dout;

	b_in_proc:
	b_in	<=	b_in_sy when type_reg_dout (synth_bit_g) = '1'
				else dc_fifo_dout;
				
	r_out_proc:
	r_out (1 downto 0)	<= "00";

	g_out_proc:
	g_out (1 downto 0)	<= "00";

	b_out_proc:
	b_out (1 downto 0)	<= "00";
				
	--Frames
	--ZERO all unused bits
	left_frame_zero_proc:
	--left_frame_rg (left_frame_rg'left downto reg_width_c) <=	(others => '0');				--change to large resolution-************************************-
	left_frame_rg <= conv_std_logic_vector (336, left_frame_rg'high+1);

	right_frame_zero_proc:
	--right_frame_rg (right_frame_rg'left downto reg_width_c) <=	(others => '0');				--change to large resolution
	right_frame_rg <= conv_std_logic_vector (336, right_frame_rg'high+1);

	upper_frame_zero_proc:
	upper_frame_rg (upper_frame_rg'left downto reg_width_c) <=	(others => '0');

	lower_frame_zero_proc:
	lower_frame_rg (lower_frame_rg'left downto reg_width_c) <=	(others => '0');

	--Connect frames
	left_frame_proc:
	left_frame	<=	left_frame_sy when type_reg_dout (synth_bit_g) = '1'
					else left_frame_rg;

	right_frame_proc:
	right_frame	<=	right_frame_sy when type_reg_dout (synth_bit_g) = '1'
					else right_frame_rg;

	upper_frame_proc:
	upper_frame	<=	upper_frame_sy when type_reg_dout (synth_bit_g) = '1'
					else upper_frame_rg;

	lower_frame_proc:
	lower_frame	<=	lower_frame_sy when type_reg_dout (synth_bit_g) = '1'
					else lower_frame_rg;
					
	--Cycle is active for registers
	wbs_reg_cyc_proc:
	wbs_reg_cyc	<=	wbs_cyc_i and wbs_tgc_i;
					
	--MUX, to route addressed register data to the WBS
	wbs_reg_dout_proc:
	wbs_reg_dout	<=	type_reg_dout when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c)) 
						else left_frame (reg_width_c - 1 downto 0) 		when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = left_frame_reg_addr_c)) 
						else right_frame (reg_width_c - 1 downto 0) 	when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = right_frame_reg_addr_c)) 
						else upper_frame (reg_width_c - 1 downto 0) 	when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = upper_frame_reg_addr_c))
						else lower_frame (reg_width_c - 1 downto 0) 	when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = lower_frame_reg_addr_c)) 
						else (others => '0');

	--MUX, to route addressed register dout_valid to the WBS
	wbs_reg_dout_valid_proc:
	wbs_reg_dout_valid	<=	type_reg_dout_valid 
							or left_frame_reg_dout_valid 
							or right_frame_reg_dout_valid 
							or upper_frame_reg_dout_valid 
							or lower_frame_reg_dout_valid;

	--MUX, to route addressed register din_ack to the WBS
	wbs_reg_din_ack_proc:
	wbs_reg_din_ack	<=	type_reg_din_ack 
						or left_frame_reg_din_ack
						or right_frame_reg_din_ack
						or upper_frame_reg_din_ack
						or lower_frame_reg_din_ack;
						
	--Read Enables processes:
	type_reg_rd_en_proc:
	type_reg_rd_en	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c) and (reg_rd_en = '1')
						else '0';
					
	left_frame_reg_rd_en_proc:
	left_frame_reg_rd_en	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = left_frame_reg_addr_c) and (reg_rd_en = '1')
								else '0';

	right_frame_reg_rd_en_proc:
	right_frame_reg_rd_en	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = right_frame_reg_addr_c) and (reg_rd_en = '1')
								else '0';

	upper_frame_reg_rd_en_proc:
	upper_frame_reg_rd_en	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = upper_frame_reg_addr_c) and (reg_rd_en = '1')
								else '0';

	lower_frame_reg_rd_en_proc:
	lower_frame_reg_rd_en	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = lower_frame_reg_addr_c) and (reg_rd_en = '1')
								else '0';

								
--###########################	Instatiation	###################################--


pixel_mng_inst: pixel_mng generic map
						(
							reset_polarity_g	=>	reset_polarity_g,	
							vsync_polarity_g	=>	vsync_polarity_g,
							screen_hor_pix_g	=>	hor_active_pixels_g,
							hor_pixels_g		=>	hor_pres_pixels_g,
							ver_lines_g			=>	ver_pres_lines_g,
							req_lines_g			=>	req_lines_g,
							rep_size_g			=>	rep_size_g
						)
						port map
						(
							clk_i				=>	clk_133,		
							rst			        =>	rst_133,
							wbm_ack_i	        =>	wbm_ack_i,
							wbm_err_i	        =>	wbm_err_i	,
							wbm_stall_i	        =>	wbm_stall_i	,
							wbm_dat_i	        =>	wbm_dat_i	,
							wbm_cyc_o	        =>	wbm_cyc_o	,
							wbm_stb_o	        =>	wbm_stb_o	,
							wbm_adr_o	        =>	wbm_adr_o	,
							wbm_tga_o	        =>	wbm_tga_o	,
							fifo_wr_en	        =>	sc_fifo_wr_en,
							fifo_flush	        =>	flush,
							pixels_req	        =>	pixels_req,
							req_ln_trig	        =>	req_ln_trig,
							vsync		        =>	vsync_int		
						);
						
--runlen_extractor_inst :	runlen_extractor generic map
--						(
--							reset_polarity_g	=>	reset_polarity_g,	
--							pixels_per_line_g	=>	hor_pres_pixels_g,
--							rep_size_g			=>	rep_size_g,
--							width_g				=>	8
--						)
--					port map
--						(
--							 clk				=>	clk_133,
--							 rst				=>	rst_133,
--							 fifo_full			=>	dc_fifo_full,
--							 fifo_empty			=>	sc_fifo_empty,
--							 flush				=>	flush,
--							 din				=>	sc_fifo_dout,
--							 din_val			=>	sc_fifo_dout_val,
--							 req_data			=>	sc_fifo_rd_en,
--							 dout				=>	dc_fifo_din,
--							 dout_val			=>	dc_fifo_wr_en
--						);

-- dc_fifo_inst	:	dc_fifo port map --Imgrotate
						-- (
							-- aclr				=>	dc_fifo_aclr,
							-- data				=>	wbm_dat_i,
							-- rdclk				=>	clk_40,
							-- rdreq				=>	dc_rd_req,
							-- wrclk				=>	clk_133,
							-- wrreq				=>	wbm_ack_i,--sc_fifo_wr_en,--is coreect?
							-- q					=>	dc_fifo_dout,
							-- rdempty				=>	dc_fifo_empty,
							--wrfull				=>	dc_fifo_full,
							-- wrusedw(12)			=>	dc_fifo_full,
							-- wrusedw(11 downto 0)=>	wrusedw (11 downto 0)
						-- );
dc_fifo_inst	:	dc_fifo port map
						(
							aclr				=>	dc_fifo_aclr,
							data				=>	sc_fifo_dout,--Imgrotate
							rdclk				=>	clk_40,
							rdreq				=>	dc_rd_req,
							wrclk				=>	clk_133,
							wrreq				=>	sc_fifo_dout_val,--Imgrotate write to dc fifo-
							q					=>	dc_fifo_dout,
							rdempty				=>	dc_fifo_empty,
							--wrfull				=>	dc_fifo_full,
							wrusedw(12)			=>	dc_fifo_full,
							wrusedw(11 downto 0)=>	wrusedw (11 downto 0)
						);
sc_fifo_inst 	:	general_fifo generic map (	 
							reset_polarity_g	=>	reset_polarity_g,
							width_g				=>	8,
							depth_g 			=>	fifo_depth_g,
							log_depth_g			=>	fifo_log_depth_g
						)
						port map
						(
						 clk				=>	clk_133, 		
							 rst 		        =>	rst_133,
							 din 		        =>	wbm_dat_i,
							 wr_en 		        =>	sc_fifo_wr_en,
							 rd_en 		        =>	sc_fifo_rd_req,--Imgrotate
							 flush		        =>	flush,
							 dout 		        =>	sc_fifo_dout,
							 dout_valid	        =>	sc_fifo_dout_val,
							 --afull  	        =>	,
							 full 		        =>	sc_fifo_full,--Imgrotate deleted psik
							 --aempty 	        =>	,
							 empty 		        =>	sc_fifo_empty--Imgrotate
						 );

vesa_gen_ctrl_inst 	:	vesa_gen_ctrl generic map(
							reset_polarity_g		=>	reset_polarity_g	,
							hsync_polarity_g		=>	hsync_polarity_g	,
							vsync_polarity_g		=>	vsync_polarity_g	,
							blank_polarity_g		=>	blank_polarity_g	,
							red_default_color_g		=>	red_default_color_g	,
							green_default_color_g	=>	green_default_color_g,
							blue_default_color_g	=>	blue_default_color_g,
							red_width_g				=>	red_width_g	  	,
							green_width_g			=>	green_width_g 	,
							blue_width_g			=>	blue_width_g  	,
							req_delay_g				=>	req_delay_g			,
							req_lines_g				=>	req_lines_g			, 
							hor_active_pixels_g		=>	hor_active_pixels_g	,
							ver_active_lines_g		=>	ver_active_lines_g	,
							hor_left_border_g		=>	hor_left_border_g	,
							hor_right_border_g		=>	hor_right_border_g	,
							hor_back_porch_g		=>	hor_back_porch_g	,
							hor_front_porch_g		=>	hor_front_porch_g	,
							hor_sync_time_g			=>	hor_sync_time_g		,
							ver_top_border_g		=>	ver_top_border_g	,
							ver_buttom_border_g		=>	ver_buttom_border_g	,
							ver_back_porch_g		=>	ver_back_porch_g	,
							ver_front_porch_g		=>	ver_front_porch_g	,
							ver_sync_time_g			=>	ver_sync_time_g		
						)
					port map
						(	
							clk			=>	clk_40,
							reset		=>	rst_40,
							r_in		=>	r_in,
							g_in		=>	g_in,
							b_in		=>	b_in,
							left_frame	=>	left_frame,
							upper_frame	=>	upper_frame,
							right_frame	=>	right_frame,
							lower_frame	=>	lower_frame,
							vesa_en		=>	'1',
							image_tx_en	=>	'1',
							data_valid	=>	vesa_data_valid,
							req_data	=>	vesa_req_data,
							pixels_req	=>	pixels_req,
							req_ln_trig	=>	req_ln_trig,
							r_out		=>	r_out (red_width_g + 1 downto 2),
							g_out		=>	g_out (green_width_g + 1 downto 2),
							b_out		=>	b_out (blue_width_g + 1 downto 2),
							blank		=>	blank,
							hsync		=>	hsync_int,
							vsync		=>	vsync_int
	);

synth_pic_gen_inst 	:	synthetic_frame_generator generic map 
						(
							reset_polarity_g		=>	reset_polarity_g,
							hsync_polarity_g		=>	hsync_polarity_g,
							vsync_polarity_g		=>	vsync_polarity_g,
							change_frame_clk_g		=>	change_frame_clk_g,
							hor_pres_pixels_g		=>	hor_pres_pixels_g,
							ver_pres_lines_g		=>	ver_pres_lines_g,
							hor_active_pixels_g		=>	hor_active_pixels_g,
							ver_active_lines_g		=>	ver_active_lines_g,
							red_width_g				=>	red_width_g,
							green_width_g			=>	green_width_g,
							blue_width_g			=>	blue_width_g
						)
						port map(
							clk						=>	clk_40,
							reset					=>	rst_40,
							vsync					=>	vsync_int,
							hsync					=>	hsync_int,
							req_data				=>	vesa_req_data,
							r_out					=>	r_in_sy,
							g_out					=>	g_in_sy,
							b_out					=>	b_in_sy,
							left_frame				=>	left_frame_sy,
							upper_frame				=>	upper_frame_sy,
							right_frame				=>	right_frame_sy,
							lower_frame				=>	lower_frame_sy,
							data_valid				=>	vesa_data_valid_sy
			);

gen_reg_type_inst	:	gen_reg generic map (
							reset_polarity_g	=>	reset_polarity_g,	
							width_g				=>	reg_width_c,
							addr_en_g			=>	true,
							addr_val_g			=>	type_reg_addr_c,
							addr_width_g		=>	reg_addr_width_c,
							read_en_g			=>	true,
							write_en_g			=>	true,
							clear_on_read_g		=>	false,
							default_value_g		=>	0
						)
						port map (
							clk					=>	clk_133,
							reset		        =>	rst_133,
							addr		        =>	reg_addr,
							din			        =>	reg_din,
							wr_en		        =>	reg_wr_en,
							clear		        =>	'0',
							din_ack		        =>	type_reg_din_ack,
							rd_en				=>	type_reg_rd_en,
							dout		        =>	type_reg_dout,
							dout_valid	        =>	type_reg_dout_valid
						);
			
-- gen_reg_left_frame_inst	:	gen_reg generic map (
							-- reset_polarity_g	=>	reset_polarity_g,	
							-- width_g				=>	reg_width_c,
							-- addr_en_g			=>	true,
							-- addr_val_g			=>	left_frame_reg_addr_c,
							-- addr_width_g		=>	reg_addr_width_c,
							-- read_en_g			=>	true,
							-- write_en_g			=>	true,
							-- clear_on_read_g		=>	false,
							-- default_value_g		=>	(hor_active_pixels_g - hor_pres_pixels_g)/2
						-- )
						-- port map (
							-- clk					=>	clk_133,
							-- reset		        =>	rst_133,
							-- addr		        =>	reg_addr,
							-- din			        =>	reg_din,
							-- wr_en		        =>	reg_wr_en,
							-- clear		        =>	'0',
							-- din_ack		        =>	left_frame_reg_din_ack,
							-- rd_en				=>	left_frame_reg_rd_en,
							-- dout		        =>	left_frame_rg (reg_width_c - 1 downto 0),
							-- dout_valid	        =>	left_frame_reg_dout_valid
						-- );
						
-- gen_reg_right_frame_inst	:	gen_reg generic map (
							-- reset_polarity_g	=>	reset_polarity_g,	
							-- width_g				=>	reg_width_c,
							-- addr_en_g			=>	true,
							-- addr_val_g			=>	right_frame_reg_addr_c,
							-- addr_width_g		=>	reg_addr_width_c,
							-- read_en_g			=>	true,
							-- write_en_g			=>	true,                                
							-- clear_on_read_g		=>	false,                               	
							-- default_value_g		=>	(hor_active_pixels_g - hor_pres_pixels_g)/2
						-- )
						-- port map (
							-- clk					=>	clk_133,
							-- reset		        =>	rst_133,
							-- addr		        =>	reg_addr,
							-- din			        =>	reg_din,
							-- wr_en		        =>	reg_wr_en,
							-- clear		        =>	'0',
							-- din_ack		        =>	right_frame_reg_din_ack,
							-- rd_en				=>	right_frame_reg_rd_en,
							-- dout		        =>	right_frame_rg (reg_width_c - 1 downto 0),
							-- dout_valid	        =>	right_frame_reg_dout_valid
						-- );
						
gen_reg_upper_frame_inst	:	gen_reg generic map (
							reset_polarity_g	=>	reset_polarity_g,	
							width_g				=>	reg_width_c,
							addr_en_g			=>	true,
							addr_val_g			=>	upper_frame_reg_addr_c,
							addr_width_g		=>	reg_addr_width_c,
							read_en_g			=>	true,
							write_en_g			=>	true,
							clear_on_read_g		=>	false,
							default_value_g		=>	(ver_active_lines_g - ver_pres_lines_g)/2
						)
						port map (
							clk					=>	clk_133,
							reset		        =>	rst_133,
							addr		        =>	reg_addr,
							din			        =>	reg_din,
							wr_en		        =>	reg_wr_en,
							clear		        =>	'0',
							din_ack		        =>	upper_frame_reg_din_ack,
							rd_en				=>	upper_frame_reg_rd_en,
							dout		        =>	upper_frame_rg (reg_width_c - 1 downto 0),
							dout_valid	        =>	upper_frame_reg_dout_valid
						);
						
gen_reg_lower_frame_inst	:	gen_reg generic map (
							reset_polarity_g	=>	reset_polarity_g,	
							width_g				=>	reg_width_c,
							addr_en_g			=>	true,
							addr_val_g			=>	lower_frame_reg_addr_c,
							addr_width_g		=>	reg_addr_width_c,
							read_en_g			=>	true,
							write_en_g			=>	true,
							clear_on_read_g		=>	false,
							default_value_g		=>	(ver_active_lines_g - ver_pres_lines_g)/2
						)
						port map (
							clk					=>	clk_133,
							reset		        =>	rst_133,
							addr		        =>	reg_addr,
							din			        =>	reg_din,
							wr_en		        =>	reg_wr_en,
							clear		        =>	'0',
							din_ack		        =>	lower_frame_reg_din_ack,
							rd_en				=>	lower_frame_reg_rd_en,
							dout		        =>	lower_frame_rg (reg_width_c - 1 downto 0),
							dout_valid	        =>	lower_frame_reg_dout_valid
						);
						
wbs_reg_inst	:	wbs_reg generic map (
							reset_polarity_g=>	reset_polarity_g,
							width_g			=>	reg_width_c,
							addr_width_g	=>	reg_addr_width_c
						)
						port map (
							rst				=>	rst_133,
							clk_i			=> 	clk_133,
							wbs_cyc_i	    =>	wbs_reg_cyc,	
							wbs_stb_i	    => 	wbs_stb_i,	
							wbs_adr_i	    =>	wbs_adr_i (reg_addr_width_c - 1 downto 0),	
							wbs_we_i	    => 	wbs_we_i,	
							wbs_dat_i	    => 	wbs_dat_i,	
							wbs_dat_o	    => 	wbs_dat_o,	
							wbs_ack_o	    => 	wbs_ack_o,	
							wbs_stall_o		=>	wbs_stall_o,
							
							din_ack			=>	wbs_reg_din_ack,
							dout		    =>	wbs_reg_dout,
							dout_valid	    =>	wbs_reg_dout_valid,
							addr		    =>	reg_addr,
							din			    =>	reg_din,
							rd_en		    =>	reg_rd_en,
							wr_en		    =>	reg_wr_en
						);
							
--WBS_ERR_O
wbs_err_o_proc:
wbs_err_o	<=	'0';							
end architecture rtl_disp_ctrl_top;