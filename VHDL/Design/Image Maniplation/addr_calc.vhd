------------------------------------------------------------------------------------------------
-- Model Name 	:	Address Calculator
-- File Name	:	Addr_Calc.vhd
-- Generated	:	27.03.1012
-- Author		:	Ran Mizrahi&Uri Tzipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   Claculates 4 pixels from input image in order to build the output image
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		27.3.2012	Ran&Uri					creation
--			1.01
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 		check optimal sine and cosine fraction resolution
--			(2)			make vector size more genric, so it will match image sizes - std_logic_vector(integer(ceil(log(real(screen_hor_pix_g*req_lines_g)) / log(2.0))) - 1 downto 0)
--			(3)			change calculation with fixed to use "resize"  
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.fixed_pkg.all;

library work ;
--use work.ram_generic_pkg.all;

entity addr_calc is
	generic (
			reset_polarity_g		:	std_logic	:= '0';			--Reset active low
			x_size_in				:	positive 	:= 96;				-- number of rows  in the input image
			y_size_in				:	positive 	:= 128;				-- number of columns  in the input image
			x_size_out				:	positive 	:= 600;				-- number of rows  in theoutput image
			y_size_out				:	positive 	:= 800				-- number of columns  in the output image
			);
	port	(
				zoom_factor			:	in std_logic_vector (3 downto 0);		--zoom facotr given by user - x2,x4,x8
				sin_teta			:	in sfixed (1 downto -4);				--sine of rotation angle - calculated by software. format- xx.xxxx
				cos_teta			:	in sfixed (1 downto -4);				--cosine of rotation angle - calculated by software. format- xx.xxxx
				
				-- 1 bit [MSB] was added in order to represent the row_idx_in in 2's complement
				row_idx_in			:	in std_logic_vector (10 downto 0);		--the current row index of the output image
				col_idx_in			:	in std_logic_vector (10 downto 0);		--the current column index of the output image
				x_crop_start	    :	in std_logic_vector (10 downto 0);		--crop start index : the top left pixel for crop		
				y_crop_start		:	in std_logic_vector (10 downto 0);		--crop start index : the top left pixel for crop
				
				tl_out				:	out std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
				tr_out				:	out std_logic_vector (22 downto 0);		--top right pixel address in SDRAM
				bl_out				:	out std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
				br_out				:	out std_logic_vector (22 downto 0);		--bottom right pixel address in SDRAM
				
				--delta_row_out		:	out
				--delta_col_out		:	out
				--Clock and Reset
				clk_133				:	in std_logic;							--SDRAM clock
				clk_40				:	in std_logic;							--VESA Clock
				rst_133				:	in std_logic;							--Reset (133MHz)
				rst_40				:	in std_logic;							--Reset (40MHz)

				-- Wishbone Master to Memory Management block
				wbm_dat_i			:	in std_logic_vector (7 downto 0);		--Data in (8 bits)
				wbm_stall_i			:	in std_logic;							--Slave is not ready to receive new data 
				wbm_ack_i			:	in std_logic;							--Input data has been successfuly acknowledged
				wbm_err_i			:	in std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				wbm_adr_o			:	out std_logic_vector (9 downto 0);		--Address
				wbm_tga_o			:	out std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				wbm_cyc_o			:	out std_logic;							--Cycle command from WBM
				wbm_stb_o			:	out std_logic;							--Strobe command from WBM
				wbm_tgc_o			:	out std_logic							--Cycle Tag
			);
end entity addr_calc;

architecture arc_addr_calc of addr_calc is

--	###########################		Costants		##############################	--
constant x_vector_size			:	positive 	:= integer (ceil(log(real(x_size_out)) / log(2.0))) -1 ;	--Width of vector for rows :=9
constant y_vector_size			:	positive 	:= integer (ceil(log(real(y_size_out)) / log(2.0))) -1 ;	--Width of vector for columns :=9

--###########################	Signals		###################################--

signal new_frame_x_size 		:	integer range 0 to x_size_out; 		--size of row after crop 
signal new_frame_y_size 		:	integer range 0 to y_size_out; 		--size of column after crop 
signal zoom_factor_int			:	integer range 0 to 8;				-- size of zoom factor
signal inv_zoom_factor			:	sfixed (2 downto -3);				-- inverse of zoom factor xx.xxxx
signal row_fraction_calc		: 	sfixed (19 downto -10);				-- holds a temp calc of row index in the origin image
signal col_fraction_calc		: 	sfixed (20 downto -10);				-- holds a temp calc of col index in the origin image

--Output Signals
signal tl_x				:	std_logic_vector (9 downto 0);		--top left row coordinate pixel in input image
signal tl_y				:	std_logic_vector (9 downto 0);		--top left column coordinate pixel in input image
signal tr_x				:	std_logic_vector (9 downto 0);		--top right row coordinate pixel in input image
signal tr_y				:	std_logic_vector (9 downto 0);		--top right column coordinate pixel in input image
signal bl_x				:	std_logic_vector (9 downto 0);		--bottom left row coordinate pixel in input image
signal bl_y				:	std_logic_vector (9 downto 0);		--bottom left column coordinate pixel in input image
signal br_x				:	std_logic_vector (9 downto 0);		--bottom right row coordinate pixel in input image
signal br_y				:	std_logic_vector (9 downto 0);		--bottom right column coordinate pixel in input image
signal out_of_range		:	std_logic;							--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop


--###########################	Components	###################################--



-- component synthetic_frame_generator 
	-- generic (
			-- green_width_g			:	positive 	:= 8;				--Default std_logic_vector size of Green Pixels
			-- blue_width_g			:	positive 	:= 8				--Default std_logic_vector size of Blue Pixels
			-- );
	-- port	(
			-- lower_frame				:	out std_logic_vector(integer(ceil(log(real(ver_active_lines_g)) / log(2.0))) - 1 downto 0);		--Lower frame border
			-- data_valid				: 	out std_logic
			-- );
-- end component synthetic_frame_generator;



begin
----------------------------------------------------------------------------------------
	----------------------------		calc_out_img_size_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- The process calculates output image size after crop
	----------------------------------------------------------------------------------------
	calc_out_img_size_proc: process (clk_133, rst_133)
	begin
		if (rst_133 = reset_polarity_g) then
			new_frame_x_size			<=	0;
			new_frame_y_size			<=	0;
			zoom_factor_int				<=	0;
			inv_zoom_factor				<=	 ( others => '0') ;
			row_fraction_calc			<=	 ( others => '0') ;
			tl_x   						<=	 ( others => '0') ;
		elsif rising_edge (clk_133) then
			new_frame_x_size			<= 	x_size_in + 1 - conv_integer(std_logic_vector(x_crop_start));
			new_frame_y_size			<= 	y_size_in + 1 - conv_integer(std_logic_vector(y_crop_start));
			zoom_factor_int				<=	conv_integer(std_logic_vector(zoom_factor));
			inv_zoom_factor				<=  to_sfixed(1,1,0) / to_sfixed( zoom_factor_int ,3,0); 								--zoom_factor^-1
			row_fraction_calc			<=	  (inv_zoom_factor*( to_sfixed(row_idx_in,10,0)- to_sfixed(x_size_out,10,0)/to_sfixed(2,3,0))*cos_teta) --temp row indx calc, before rounding
											+ (inv_zoom_factor*( to_sfixed(col_idx_in,10,0)- to_sfixed(y_size_out,10,0)/to_sfixed(2,3,0))*sin_teta)    
											+ (to_sfixed(new_frame_x_size,10,0)/to_sfixed(2,3,0));
			col_fraction_calc			<= 	- (inv_zoom_factor*( to_sfixed(row_idx_in,10,0)- to_sfixed(x_size_out,10,0)/to_sfixed(2,3,0))*sin_teta) --temp col indx calc, before rounding
											+ (inv_zoom_factor*( to_sfixed(col_idx_in,10,0)- to_sfixed(y_size_out,10,0)/to_sfixed(2,3,0))*cos_teta)    
											+ (to_sfixed(new_frame_y_size,10,0)/to_sfixed(2,3,0));
			
	--		if    ((row_fraction_calc'left =0) and  (col_fraction_calc'left =0) and 									-- test if indexes are in range
	--			  (row_fraction_calc < to_sfixed(new_frame_x_size,row_fraction_calc)-to_sfixed(1,row_fraction_calc)) and
	--			  (col_fraction_calc < to_sfixed(new_frame_y_size,col_fraction_calc)-to_sfixed(1,col_fraction_calc)) ) then
	--			  
	--			  row_fraction_calc		<= row_fraction_calc+to_sfixed(new_frame_x_size,row_fraction_calc);		--move [i,j] to ROI by [Xstart,Ystat].
	--			  col_fraction_calc		<= col_fraction_calc+to_sfixed(new_frame_y_size,col_fraction_calc);
	--			  
	--			  -- round up and down
	--			-- tl_x   <=  		conv_std_logic_vector(row_fraction_calc (x_vector_size downto 0) , x_vector_size)	;
	--			tl_x  <=  to_slv (row_fraction_calc) (x_vector_size downto 0)	;
	--			-- tl_x   <=  		row_fraction_calc (x_vector_size downto 0)	;
	--			-- tl_y   <=		
	--			-- tr_x   <=		
	--			-- tr_y   <=		
	--			-- bl_x   <=		
	--			-- bl_y   <=		
	--			-- br_x   <=		
	--			-- br_y   <=		
	--		else
	--			out_of_range <= '1';
	--		end if	 ; 
		
		end if;
	end process calc_out_img_size_proc;
								
-- --###########################	Instatiation	###################################--


-- pixel_mng_inst: pixel_mng generic map
						-- (
							-- reset_polarity_g	=>	reset_polarity_g,	
							-- vsync_polarity_g	=>	vsync_polarity_g,
							-- screen_hor_pix_g	=>	hor_active_pixels_g,
							-- hor_pixels_g		=>	hor_pres_pixels_g,
							-- ver_lines_g			=>	ver_pres_lines_g,
							-- req_lines_g			=>	req_lines_g
-- --							rep_size_g			=>	rep_size_g
						-- )
						-- port map
						-- (
							-- clk_i				=>	clk_133,		
							-- rst			        =>	rst_133,
							-- wbm_ack_i	        =>	wbm_ack_i,
							-- wbm_err_i	        =>	wbm_err_i	,
							-- wbm_stall_i	        =>	wbm_stall_i	,
							-- wbm_dat_i	        =>	wbm_dat_i	,
							-- wbm_cyc_o	        =>	wbm_cyc_o	,
							-- wbm_stb_o	        =>	wbm_stb_o	,
							-- wbm_adr_o	        =>	wbm_adr_o	,
							-- wbm_tga_o	        =>	wbm_tga_o	,
							-- fifo_wr_en	        =>	sc_fifo_wr_en,
							-- fifo_flush	        =>	flush,
							-- pixels_req	        =>	pixels_req,
							-- req_ln_trig	        =>	req_ln_trig,
							-- vsync		        =>	vsync_int		
						-- );


	
end architecture arc_addr_calc;