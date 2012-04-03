------------------------------------------------------------------------------------------------
-- Model Name 	:	Address Converter
-- File Name	:	Addr_Conv.vhd
-- Generated	:	27.03.1012
-- Author		:	Ran Mizrahi
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   converts matrix address [I,J] to SDRAM address (continuous)
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		27.3.2012	Ran&Uri					creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 		update inv zoom factor reset
------------------------------------------------------------------------------------------------

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
				sin_teta			:	in sfixed (0 downto -4);				--sine of rotation angle - calculated by software
				cos_teta			:	in sfixed (0 downto -4);				--cosine of rotation angle - calculated by software
				row_idx_in			:	in std_logic_vector (9 downto 0);		--the current row index of the output image
				col_idx_in			:	in std_logic_vector (9 downto 0);		--the current column index of the output image
				x_start				:	in std_logic_vector (9 downto 0);		--crop start index : the top left pixel for crop		
				y_start				:	in std_logic_vector (9 downto 0);		--crop start index : the top left pixel for crop
				
				tl_out				:	in std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
				tr_out				:	in std_logic_vector (22 downto 0);		--top right pixel address in SDRAM
				bl_out				:	in std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
				br_out				:	in std_logic_vector (22 downto 0);		--bottom right pixel address in SDRAM
				
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
--constant reg_width_c			:	positive 	:= 8;	--Width of registers

--###########################	Signals		###################################--

signal new_frame_x_size 		:	integer range 0 to x_size_out; 		--size of row after crop 
signal new_frame_y_size 		:	integer range 0 to y_size_out; 		--size of column after crop 
signal zoom_factor_int			:	integer range 0 to 8;				-- size of zoom factor
signal inv_zoom_factor			:	ufixed (1 downto -4);				-- inverse of zoom factor
--Output Signals
signal tl_x				:	std_logic_vector (9 downto 0);		--top left row coordinate pixel in input image
signal tl_y				:	std_logic_vector (9 downto 0);		--top left column coordinate pixel in input image
signal tr_x				:	std_logic_vector (9 downto 0);		--top right row coordinate pixel in input image
signal tr_y				:	std_logic_vector (9 downto 0);		--top right column coordinate pixel in input image
signal bl_x				:	std_logic_vector (9 downto 0);		--bottom left row coordinate pixel in input image
signal bl_y				:	std_logic_vector (9 downto 0);		--bottom left column coordinate pixel in input image
signal br_x				:	std_logic_vector (9 downto 0);		--bottom right row coordinate pixel in input image
signal br_y				:	std_logic_vector (9 downto 0);		--bottom right column coordinate pixel in input image

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
		--	inv_zoom_factor				<=	'0'; 
		elsif rising_edge (clk_133) then
			new_frame_x_size			<= x_size_in + 1 - conv_integer(std_logic_vector(x_start));
			new_frame_y_size			<= y_size_in + 1 - conv_integer(std_logic_vector(y_start));
			zoom_factor_int				<=conv_integer(std_logic_vector(zoom_factor));
			inv_zoom_factor				<=to_ufixed(1,1,0) / to_ufixed( zoom_factor_int ,3,0); 								--zoom_factor^-1
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