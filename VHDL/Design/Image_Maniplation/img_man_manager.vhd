------------------------------------------------------------------------------------------------
-- Model Name 	:	Image Manipulation Manager (FSM)
-- File Name	:	img_man_manager.vhd
-- Generated	:	21.08.2012
-- Author		:	Uri Tsipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   Manager for Image manipulation Block
--					FSM for the image manipulation procces
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		21.08.2012	Uri					creation
--			1.1			28.08.2012	Uri,Moshe			removed init_st, not necessary. fixed false valid on last pixel
------------------------------------------------------------------------------------------------
-- TO DO:
--			fix constants to be derived from generics, don't forget addr_calc.vhd
--			fix	row/col_idx_out	to be generic length		
--			fix top_fsm Read From SDRAM state to support to pixels burst of read.
--			check if index valid is necessary , fix to work according to calc coord proc
--			fix to write back last burst of data or choose image that is built of 1024xN pixels		

------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- use std.textio.all;
-- use work.txt_util.all;
use work.ram_generic_pkg.all;

entity img_man_manager is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				trig_frac_size_g	:	positive := 7;				-- number of digits after dot = resolution of fracture (binary)
				img_hor_pixels_g	:	positive					:= 256;	--256 pixel in a coloum
				img_ver_lines_g	:	positive					:= 192;	--192 pixels in a row
				display_hor_pixels_g	:	positive					:= 800;	--800 pixel in a coloum
				display_ver_pixels_g	:	positive					:= 600	--600 pixels in a row
			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;								-- clock
				sys_rst				:	in std_logic;								-- Reset					
				req_trig			:	in std_logic;								-- Trigger for image manipulation to begin,
				image_tx_en			:	out std_logic;							--enable image transmission

				-- addr_calc					
				
				addr_row_idx_in			:	out signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed) --from coord calc process to address calc
				addr_col_idx_in			:	out signed (10 downto 0);		--the current column index of the output image                                    --from coord calc process to address calc
				
				addr_tl_out				:	in std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
				addr_bl_out				:	in std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
				addr_delta_row_out		:	in	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				addr_delta_col_out		:	in	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation

				addr_out_of_range		:	in std_logic;		--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				addr_data_valid_out		:	in std_logic;		--data valid indicator

				addr_unit_finish		:	in std_logic;                              --signal indicating addr_calc is finished
				addr_trigger_unit		:	out std_logic;                               --enable signal for addr_calc
				addr_enable				:	out std_logic;  
				-- bilinear
				bili_req_trig			:	out std_logic;				-- Trigger for image manipulation to begin,
				bili_tl_pixel			:	out	std_logic_vector(trig_frac_size_g downto 0);		--top left pixel
				bili_tr_pixel			:	out	std_logic_vector(trig_frac_size_g downto 0);		--top right pixel
				bili_bl_pixel           :   out	std_logic_vector(trig_frac_size_g downto 0);		--bottom left pixel
				bili_br_pixel           :   out	std_logic_vector(trig_frac_size_g downto 0);		--bottom right pixel
				bili_delta_row			:	out	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				bili_delta_col			:	out	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				bili_pixel_valid		:	in std_logic;				--valid signal for index
				bili_pixel_res			:	in std_logic_vector (trig_frac_size_g downto 0); 	--current row index           --fix to generic
				
				-- Wishbone Master (mem_ctrl_wr)
				wr_wbm_adr_o		:	out std_logic_vector (9 downto 0);		--Address in internal RAM
				wr_wbm_tga_o		:	out std_logic_vector (9 downto 0);		--Burst Length
				wr_wbm_dat_o		:	out std_logic_vector (7 downto 0);		--Data In (8 bits)
				wr_wbm_cyc_o		:	out std_logic;							--Cycle command from WBM
				wr_wbm_stb_o		:	out std_logic;							--Strobe command from WBM
				wr_wbm_we_o			:	out std_logic;							--Write Enable
				wr_wbm_tgc_o		:	out std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wr_wbm_dat_i		:	in std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wr_wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wr_wbm_ack_i		:	in std_logic;							--Input data has been successfuly acknowledged
				wr_wbm_err_i		:	in std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

				-- Wishbone Master (mem_ctrl_rd)
				rd_wbm_adr_o 		:	out std_logic_vector (9 downto 0);		--Address in internal RAM
				rd_wbm_tga_o 		:   out std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				rd_wbm_cyc_o		:   out std_logic;							--Cycle command from WBM
				rd_wbm_tgc_o 		:   out std_logic;							--Cycle tag. '1' indicates start of transaction
				rd_wbm_stb_o		:   out std_logic;							--Strobe command from WBM
				rd_wbm_dat_i		:  	in std_logic_vector (7 downto 0);		--Data Out (8 bits)
				rd_wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				rd_wbm_ack_i		:   in std_logic;							--Input data has been successfuly acknowledged
				rd_wbm_err_i		:   in std_logic							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
			);
end entity img_man_manager;

architecture rtl_img_man_manager of img_man_manager is
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-------------------------------		Constants		--------------------------------
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	 ----fix to generic
	constant col_bits_c							:	positive 	:= 10;--integer(ceil(log(real(img_hor_pixels_g)) / log(2.0))) ; --Width of registers for coloum index
	constant row_bits_c							:	positive 	:= 10;--integer(ceil(log(real(img_ver_lines_g)) / log(2.0))) ; --Width of registers for row index
			
	constant row_start_int						:	positive:=	(display_ver_pixels_g-img_ver_lines_g)/2+1; --row start index of ouput frame region of Interest
	constant row_end_int						:	positive:=	row_start_int+img_ver_lines_g-1;                --row end index of ouput frame region of Interest
	constant col_start_int						:	positive:=	(display_hor_pixels_g-img_hor_pixels_g)/2+1;--col start index of ouput frame region of Interest
	constant col_end_int						:	positive:=	col_start_int+img_hor_pixels_g-1;                --col end index of ouput frame region of Interest
		
			
	constant row_start	                		:	signed(row_bits_c downto 0):= to_signed( row_start_int,row_bits_c+1);	
	constant row_end	                		:	signed(row_bits_c downto 0):= to_signed( row_end_int,  row_bits_c+1);
    constant col_start	                		:	signed(col_bits_c downto 0):= to_signed( col_start_int,col_bits_c+1);	
    constant col_end	                		:	signed(col_bits_c downto 0):= to_signed( col_end_int,  col_bits_c+1);
			
	--constant image_length_int					:	positive:=img_hor_pixels_g*img_ver_lines_g;	
	--constant image_length 						:	std_logic_vector (15 downto 0)		:= std_logic_vector(to_unsigned(image_length_int, 16));
			
	constant restart_bank_c						:	std_logic_vector (2 downto 0) 	:= "110";--number of cycles for restart enable 
		
	constant mem_mng_type_reg_addr_c			:	std_logic_vector (9 downto 0)		:= "0000001101";	--Type register address
	constant mem_mng_dbg_lsb_reg_addr_c			:	std_logic_vector (9 downto 0)		:= "0000000010";	--dbg register address(ls Byte)
	constant mem_mng_dbg_msb_reg_addr_c			:	std_logic_vector (9 downto 0)		:= "0000000011";	--dbg register address(2nd Byte)
	constant mem_mng_dbg_half_bank_reg_addr_c	:	std_logic_vector (9 downto 0)		:= "0000000100";	--dbg register address(bank Byte)

	-- constant file_name_1_g					:	string  	:= "img_mang_toRAM_test.txt";		--out file name
	-- constant file_name_2_g					:	string  	:= "img_mang_toSDRAM_test.txt";		--out file name

	constant wb_burst_int                   :	positive			:=1024;				--length of burst for write back to SDRAM -1, because counting starts with 0. burst length should be such that for some N : wb_burst_int*N=img_hor_pixels_g*img_ver_lines_g
	constant wb_burst_length_c				:	std_logic_vector 	(9 downto 0):= std_logic_vector(to_unsigned( wb_burst_int-1,10)); 	-- wb_burst_length_c   for wb purposes
	constant wb_address_c					:	std_logic_vector 	(9 downto 0):= std_logic_vector(to_unsigned( wb_burst_int/2,10)); 	-- wb_burst_length_c/2 for wb address counter
	constant wait_for_valid_c				:	std_logic_vector (2 downto 0):="011";
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-------------------------------		Components		--------------------------------
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	
component ram_generic is
	generic (
				reset_polarity_g	:	std_logic 				:= '0';	--'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 				:= 8;	--Width of data
				addr_bits_g			:	positive 				:= 10;	--Depth of data	(2^10 = 1024 addresses)
				power2_out_g		:	natural 				:= 1;	--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide
				power_sign_g		:	integer range -1 to 1 	:= 1 	-- '-1' => output width > input width ; '1' => input width > output width
			);
	port	(
				clk			:	in std_logic;									--System clock
				rst			:	in std_logic;									--System Reset
				addr_in		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out	:	in std_logic_vector ((addr_bits_g - power2_out_g*power_sign_g) - 1 downto 0); 		--Output address
				aout_valid	:	in std_logic;									--Output address is valid
				data_in		:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid	:	in std_logic; 									--Input data valid
				data_out	:	out std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0);	--Output data
				dout_valid	:	out std_logic 									--Output data valid
			);
end component ram_generic;
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-------------------------------		Types		--------------------------------
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||	
	type fsm_states is (
							fsm_idle_st,			-- Idle - wait to start 
							fsm_increment_coord_st,	-- increment coordinate by 1, if line is over move to next line
							fsm_address_calc_st,	-- send coordinates to Address Calc, if out of range WB BLACK_PIXEL(0) else continue
							fsm_READ_from_SDRAM_st, -- read 4 pixels from SDRAM according to result of addr_calc
							fsm_bilinear_st,		-- do a bilinear interpolation between the 4 pixels
							result_to_RAM_st,		--write result to ram (0 when out of range , bilinear output when in range)
							fsm_WB_to_SDRAM_st,		-- Write Back result to SDRAM
							summery_chunk_st
						);
	type read_states is (	
							read_idle_st,
							write_type_reg_0x80_1_st,
							write_dbg_reg_lsb_1_st,write_dbg_reg_msb_1_st,write_dbg_reg_start_bank_1_st,
							write_type_reg_0x81_1_st, 
							wait_ack_1_st,
							prepare_for_second_pair_st,
							write_type_reg_0x80_2_st,
							write_dbg_reg_lsb_2_st,write_dbg_reg_msb_2_st,write_dbg_reg_start_bank_2_st,
							write_type_reg_0x81_2_st,
							wait_ack_2_st,
							restart_sdram_after_read,
							write_type_reg_0x00_1_st,
							write_type_reg_0x00_2_st
					);
	type write_states is (	
							write_idle_st,
							write_wb_addr_lsb_st,		--write lsb Byte of address
							write_wb_addr_msb_st,		--write msb Byte of address
							write_wb_addr_half_bank_st,	--write to top of address register in order to devide the bank to 2
							write_type_reg_0x01_st,		--write 01 to type reg, debug mode
							--write_wait_st,
							--prep_ram_to_burst_st,
							write_burst_st,				--start burst
							prep_st,					--prep state before idle
							write_type_reg_0x00_st		----write 00 to type reg, normal mode
							--prepare_RAM_st,
							--write_type_reg_0x00_1_st -- disable debug mode, so the banks will changed back							
					);
	-- type summery_states is (
							-- summery_idle_st,
							-- summery_write_type_reg_st,
							-- summery_write_length_st,
							-- summery_done_st
					-- );	
					
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-------------------------------		Signals		--------------------------------
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	
	
	
		
	-------------------------FSM-------------------------------------------------------
	signal cur_st					: fsm_states;			-- Current State
	signal manipulation_complete	: std_logic;		-- flag, indicating when image manipulation is complete (including summery chunk)	
	signal bank_val					:std_logic;
	-------------------------Coordinate Counter Procces
	signal final_pixel 				: std_logic;					-- flag indicating when image is at final pixel, flags up but should enable WB of last chunk
	signal row_index_signed		 	: signed (row_bits_c downto 0);	  
	signal col_index_signed       	: signed (col_bits_c downto 0);  	  
	signal index_valid				: std_logic; 		--  signal for coordinate incerement process

	------------------------Address Calculator
	signal en_addr_calc_proc		: std_logic_vector (1 downto 0);	
	signal addr_calc_oor			: std_logic;		--address calculator result is out of range (oor)
	signal addr_calc_valid			: std_logic;		--address calculator result is valid
	signal addr_calc_tl				: std_logic_vector (22 downto 0);
	signal addr_calc_bl				: std_logic_vector (22 downto 0);
	signal addr_calc_d_row			: std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
	signal addr_calc_d_col			: std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
	
	--------------------------Read From SDRAM
	signal finish_read_pxl			: std_logic_vector (1 downto 0);		--finish Read From SDRAM state
	signal en_read_proc				: std_logic;		--start Read From SDRAM state
    signal read_SDRAM_state 		: read_states;
	signal read_first				: std_logic;
	signal rd_adr_o_counter			: std_logic_vector (9 downto 0);	
	signal restart_bank				: std_logic_vector (2 downto 0);
	signal	r_wr_wbm_adr_o			: std_logic_vector (9 downto 0);		--Address in internal RAM
	signal	r_wr_wbm_tga_o			: std_logic_vector (9 downto 0);		--Burst Length
	signal	r_wr_wbm_dat_o			: std_logic_vector (7 downto 0);		--Data In (8 bits)
	signal	r_wr_wbm_cyc_o			: std_logic;							--Cycle command from WBM
	signal	r_wr_wbm_stb_o			: std_logic;							--Strobe command from WBM
	signal	r_wr_wbm_we_o			: std_logic;							--Write Enable
	signal	r_wr_wbm_tgc_o			: std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
	
	--------------------------bilinear interpolation
	signal en_bili_trig				:	std_logic;		-- bilinear
	signal tl_pixel					:	std_logic_vector (7 downto 0);		--top left pixel, first pair
	signal tr_pixel					:	std_logic_vector (7 downto 0);		--top right pixel, first pair
	signal bl_pixel					:	std_logic_vector (7 downto 0);		--bottom left pixel, second pair
	signal br_pixel					:	std_logic_vector (7 downto 0);		--bottom right pixel, second pair
	signal pixel_res				:   std_logic_vector (trig_frac_size_g downto 0); 
	
	--------------------------WB to SDRAM
	signal RAM_is_full				: std_logic;	
	signal wb_address				: std_logic_vector(22 downto 0);
	signal ram_addr_in_counter		: std_logic_vector(wb_burst_length_c'left downto 0);
	-- file   out_file_1					: TEXT open write_mode is file_name_1_g;
	-- file   out_file_2					: TEXT open write_mode is file_name_2_g;

	signal write_SDRAM_state 		: write_states;
	signal wr_wbm_adr_o_counter		: std_logic_vector(wb_burst_length_c'left downto 0);--wbm_adr_o  counter
	signal ram_adr_o_counter		: std_logic_vector(wb_burst_length_c'left downto 0);-- ram addres out counter
	signal en_write_proc        	: std_logic;	
	signal finish_write_proc		: std_logic;
	
	signal ram_addr_in 				: std_logic_vector(wb_burst_length_c'left downto 0);	
	-- signal ram_addr_out 			: std_logic_vector(wb_burst_length_c'left downto 0);
	signal ram_addr_out_valid		: std_logic;
	signal ram_din			    	: std_logic_vector(7 downto 0);
	signal ram_din_valid			: std_logic;
	signal ram_dout	            	: std_logic_vector(7 downto 0);
	-- signal ram_dout_wait_cyc1        : std_logic_vector(7 downto 0);
	-- signal ram_dout_wait_cyc2        : std_logic_vector(7 downto 0);
	-- signal ram_dout_wait_cyc3        : std_logic_vector(7 downto 0);
	-- signal ram_dout_wait_cyc4       : std_logic_vector(7 downto 0);
	
	signal ram_dout_valid 			: std_logic;
	signal wait_for_valid			: std_logic_vector (2 downto 0);
	signal	w_wr_wbm_adr_o			: std_logic_vector (9 downto 0);		--Address in internal RAM
	signal	w_wr_wbm_tga_o			: std_logic_vector (9 downto 0);		--Burst Length
	signal	w_wr_wbm_dat_o			: std_logic_vector (7 downto 0);		--Data In (8 bits)
	signal	w_wr_wbm_cyc_o			: std_logic;							--Cycle command from WBM
	signal	w_wr_wbm_stb_o			: std_logic;							--Strobe command from WBM
	signal	w_wr_wbm_we_o			: std_logic;							--Write Enable
	signal	w_wr_wbm_tgc_o			: std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
	---------------------------- Summery state
	-- signal  summery_done         	:	 std_logic;
	-- signal  en_summery           	:	 std_logic;
	-- signal  summery_st           	:summery_states;
	-- signal 	summery_ack_counter		:	 std_logic_vector (1 downto 0);		--counts acks
	-- signal	s_wr_wbm_adr_o			:	 std_logic_vector (9 downto 0);		--Address in internal RAM
	-- signal	s_wr_wbm_tga_o			:	 std_logic_vector (9 downto 0);		--Burst Length
	-- signal	s_wr_wbm_dat_o			:	 std_logic_vector (7 downto 0);		--Data In (8 bits)
	-- signal	s_wr_wbm_cyc_o			:	 std_logic;							--Cycle command from WBM
	-- signal	s_wr_wbm_stb_o			:	 std_logic;							--Strobe command from WBM
	-- signal	s_wr_wbm_we_o			:	 std_logic;							--Write Enable
	-- signal	s_wr_wbm_tgc_o			:	 std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
------------------------------		Implementation		------------------------------
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
begin	
wire_proc:
rd_wbm_adr_o<= rd_adr_o_counter;

mux_wr_wbm_adr_o_port:
wr_wbm_adr_o	<=  wr_wbm_adr_o_counter when (en_write_proc='1' and (write_SDRAM_state=write_burst_st or write_SDRAM_state=prep_st))
					else w_wr_wbm_adr_o	 when (en_write_proc='1')
					--else s_wr_wbm_adr_o  when (en_summery='1')	
					else    r_wr_wbm_adr_o	;
--with summery
-- mux_wbm_ports:
-- wr_wbm_tga_o	<=  w_wr_wbm_tga_o	 when en_write_proc='1' else 	s_wr_wbm_tga_o			when en_summery='1'   	else r_wr_wbm_tga_o	;
-- wr_wbm_dat_o	<=  w_wr_wbm_dat_o	 when en_write_proc='1' else 	s_wr_wbm_dat_o			when en_summery='1'   	else r_wr_wbm_dat_o	;
-- wr_wbm_cyc_o	<=  w_wr_wbm_cyc_o	 when en_write_proc='1' else 	s_wr_wbm_cyc_o			when en_summery='1'   	else r_wr_wbm_cyc_o	;
-- wr_wbm_stb_o	<=  w_wr_wbm_stb_o	 when en_write_proc='1' else 	s_wr_wbm_stb_o			when en_summery='1'   	else r_wr_wbm_stb_o	;
-- wr_wbm_we_o		<=  w_wr_wbm_we_o	 when en_write_proc='1' else 	s_wr_wbm_we_o			when en_summery='1'   	else r_wr_wbm_we_o	;
-- wr_wbm_tgc_o	<=  w_wr_wbm_tgc_o	 when en_write_proc='1' else 	s_wr_wbm_tgc_o			when en_summery='1'   	else r_wr_wbm_tgc_o	;

--without summery
mux_wbm_ports:
wr_wbm_tga_o	<=  w_wr_wbm_tga_o	 when en_write_proc='1'    	else r_wr_wbm_tga_o	;
wr_wbm_dat_o	<= 	ram_dout  		when (en_write_proc='1' and write_SDRAM_state=write_burst_st) else
					w_wr_wbm_dat_o	 when en_write_proc='1'   else --
					r_wr_wbm_dat_o	;
wr_wbm_cyc_o	<=  w_wr_wbm_cyc_o	 when en_write_proc='1'    	else r_wr_wbm_cyc_o	;
wr_wbm_stb_o	<=  w_wr_wbm_stb_o	 when en_write_proc='1'    	else r_wr_wbm_stb_o	;
wr_wbm_we_o		<=  w_wr_wbm_we_o	 when en_write_proc='1'    	else r_wr_wbm_we_o	;
wr_wbm_tgc_o	<=  w_wr_wbm_tgc_o	 when en_write_proc='1'    	else r_wr_wbm_tgc_o	;

image_tx_port:
image_tx_en	<=	manipulation_complete;
----------------------------------------------------------------------------------------
----------------------------		fsm_proc Process			------------------------
----------------------------------------------------------------------------------------
----------------------------    This is the main FSM Process    ------------------------
----------------------------------------------------------------------------------------
	fsm_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			cur_st					<=	fsm_idle_st;
			en_read_proc 			<=	'0';
			en_addr_calc_proc		<="00";
			en_bili_trig			<='0';
			pixel_res				<=(others => '0');
			--en_summery				<='0';
			manipulation_complete	<='0';
			ram_addr_in            <=(others => '0');
			ram_din                <=(others => '0');
			ram_din_valid          <='0';
			en_write_proc<='0';
			bank_val<='1';				--reset bank value to 1, after first trigger bank val is 0

		elsif rising_edge (sys_clk) then
			case cur_st is
			------------------------------Idle State--------------------------------- --
				when fsm_idle_st =>
					--for debug - disable block
--					if (req_trig='1')  then
--						report "Image Manipulation disabled - start display of original image from original bank  Time: " & time'image(now) severity note;
--						cur_st	<= 	fsm_idle_st;
--						manipulation_complete	<='1';
--					elsif (manipulation_complete='1') then
--						manipulation_complete	<='1';
--						cur_st	<= 	fsm_idle_st;
--					else
--						manipulation_complete	<='0';
--						cur_st	<= 	fsm_idle_st;	
					--end if;
					
					 if (req_trig='1')  then
						 report "Start of Image Manipulation  Time: " & time'image(now) severity note;
						 cur_st	<= 	fsm_increment_coord_st;
						 manipulation_complete	<='0';
						bank_val<=not(bank_val);
                        
					 else
						 cur_st 	<= 	fsm_idle_st;
					 end if;				
			-----------------------------Increment coordinate state----------------------	
				when fsm_increment_coord_st	=>				
								ram_din_valid          <='0';

					if (final_pixel = '1') then  			-- image is complete, back to idle
						report "End of Image Manipulation  Time: " & time'image(now) severity note;
						--cur_st	<=	summery_chunk_st;
						cur_st	<=	fsm_idle_st;
						manipulation_complete<='1';
					else
						cur_st 	<= 	fsm_address_calc_st;	-- finish calculate index 
						en_addr_calc_proc		<="01";		-- trigger addr_calc
					end if;
			-----------------------------Increment coordinate state----------------------	
				-- when summery_chunk_st	=>
					-- if (summery_done='1') then	
						-- manipulation_complete<='1';
						-- en_summery<='0';
						-- cur_st 	<= 	fsm_idle_st;
					-- else
						-- en_summery<='1';
						-- cur_st 	<= 	summery_chunk_st;
					-- end if;	
			-----------------------------Address calculate state----------------------						
				when fsm_address_calc_st =>
					en_addr_calc_proc		<="10";							--diable  addr_calc trigger
					if ((addr_calc_oor and addr_calc_valid) = '1') then		--current index is out of range, WB black
						en_addr_calc_proc	<="00";
						cur_st			<=	result_to_RAM_st;
					elsif ((not(addr_calc_oor) and addr_calc_valid) ='1') then		--addr_calc is finish, continue to Read from SDRAM
						cur_st 			<= 	fsm_READ_from_SDRAM_st;
						--cur_st			<=fsm_increment_coord_st;
						en_addr_calc_proc	<="00";
					else
						cur_st 			<= 	fsm_address_calc_st;					
					end if;	
			
			-----------------------------Read From SDRAM state----------------------					
				when fsm_READ_from_SDRAM_st =>
					en_read_proc	<= '1'; 					--start read process			
					if (finish_read_pxl="11")	then			--finish read 2  adressess
						en_read_proc	<= '0';					--end read process	
						cur_st 	<= 	fsm_bilinear_st;
						en_bili_trig <='1';					--trigger bilinear
						--cur_st	<= 	fsm_increment_coord_st;		--debug
					elsif (finish_read_pxl="01")	then			-- finish read 1st adresss
						cur_st	<=	fsm_READ_from_SDRAM_st;
					elsif (finish_read_pxl="00")	then			-- not finish read 1st adresss.
						cur_st	<=	fsm_READ_from_SDRAM_st;	
					end if;	
			-----------------------------bilinear state----------------------
				when fsm_bilinear_st =>	
					en_bili_trig <='0';	--diable bilinear triggfr
					pixel_res <=bili_pixel_res;
					if (bili_pixel_valid='0') then
						cur_st 	<= 	fsm_bilinear_st;
					elsif (bili_pixel_valid='1') then
							cur_st 	<= 	result_to_RAM_st;		
					end if;
			-----------------------------write result to RAM state----------------------	
				when result_to_RAM_st	=>
					if (addr_calc_oor='0') then
						ram_din	<= pixel_res;
					else 
						ram_din	<= "00000100";--(others => '0');--write black pixel in case out of range
					end if;
					
					ram_addr_in<=ram_addr_in_counter;
					ram_din_valid<='1';	
					
					if (RAM_is_full='1') then --ram is full
						cur_st 	<= 	fsm_WB_to_SDRAM_st;	
					else
						cur_st 	<= 	fsm_increment_coord_st;	
					end if;

			-----------------------------Write Back to SDRAM state----------------------
				when fsm_WB_to_SDRAM_st =>
					ram_din_valid<='0';	
					if (finish_write_proc ='1') then
						 cur_st 	<= 	fsm_increment_coord_st;
						en_write_proc<='0';
					else 	
						 cur_st 	<= fsm_WB_to_SDRAM_st;
						 en_write_proc<='1';
			        end if;
			-----------------------------Debugg state, catch Unimplemented state
				when others =>
					cur_st	<=	fsm_idle_st;
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected" severity error;
				end case;
		end if;
	end process fsm_proc;
------------------------------------------------------------------------------------------
----------------------------		Summery  Processe			-------------------------
-----------------------------------------------------------------------------------------
----------------------------    the process writes summery data     ------------------------
------------------------------------------------------------------------------------------
	
	-- sum_proc: process (sys_clk, sys_rst)
	-- begin
		-- if (sys_rst = reset_polarity_g) then
            -- summery_st	<=summery_idle_st;
			-- summery_done<='0';
			-- s_wr_wbm_adr_o	<=	(others => '0');
			-- s_wr_wbm_tga_o	<=	(others => '0');
			-- s_wr_wbm_dat_o	<=	"00000000";
			-- s_wr_wbm_cyc_o	<=	'0';
			-- s_wr_wbm_stb_o	<=	'0';
			-- s_wr_wbm_we_o		<=	'0';
			-- s_wr_wbm_tgc_o	<=	'0';
			-- summery_ack_counter	<=	(others => '0');

		-- elsif rising_edge (sys_clk) then
			-- case summery_st	is		
				-- ----------------------------------------------------------------------------
				-- when summery_idle_st =>
					-- summery_ack_counter	<=	(others => '0');

					-- if (en_summery='1') then
						-- summery_st<=summery_write_type_reg_st;
					-- else
						-- summery_st<=summery_idle_st;
					-- end if;
				-- ----------------------------------------------------------------------------	
				-- when summery_write_type_reg_st =>
					-- --write 0x2 to type register(0x2) - meaning summery chunk
					 -- if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						-- summery_st <= summery_write_type_reg_st;
						-- s_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						-- s_wr_wbm_dat_o	<=	"00000010";	--summery chunk
						-- s_wr_wbm_tga_o	<=	(others => '0');
						-- s_wr_wbm_cyc_o	<=	'1';
						-- s_wr_wbm_stb_o	<=	'1';
						-- s_wr_wbm_we_o		<=	'1';
						-- s_wr_wbm_tgc_o	<=	'1';
					-- elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						-- summery_st <= summery_write_length_st;
						-- s_wr_wbm_adr_o	<=	(others => '0');
						-- s_wr_wbm_tga_o	<=	(others => '0');
						-- s_wr_wbm_dat_o	<=	"00000000";
						-- s_wr_wbm_cyc_o	<=	'0';
						-- s_wr_wbm_stb_o	<=	'0';
						-- s_wr_wbm_we_o		<=	'0';
						-- s_wr_wbm_tgc_o	<=	'0';							
					-- end if;
					-- summery_ack_counter	<=	(others => '0');
				-- --------------------------------------------------------------------------	
				-- when summery_write_length_st =>
					-- --write 0x2 to type register(0x2) - meaning summery chunk
					 
					 -- summery_ack_counter<=summery_ack_counter+wr_wbm_ack_i;
					 -- if (summery_ack_counter="10") then
						-- summery_done<='1';
						-- summery_st <= summery_done_st;
						-- s_wr_wbm_adr_o	<=	"0000000010";
						-- s_wr_wbm_tga_o	<=	(others => '0');
						-- s_wr_wbm_dat_o	<=	"00000000";
						-- s_wr_wbm_cyc_o	<=	'0';
						-- s_wr_wbm_stb_o	<=	'0';
						-- s_wr_wbm_we_o		<=	'0';
						-- s_wr_wbm_tgc_o	<=	'0';
						
					 -- elsif	(wr_wbm_stall_i='1' )then				--first part of summery
						-- summery_st <= summery_write_length_st;
						-- s_wr_wbm_adr_o	<=	(others => '0');
						-- s_wr_wbm_dat_o	<=	image_length(15 downto 8);	
						-- s_wr_wbm_tga_o	<=	"0000000000";
						-- s_wr_wbm_cyc_o	<=	'1';
						-- s_wr_wbm_stb_o	<=	'1';
						-- s_wr_wbm_we_o	<=	'1';
						-- s_wr_wbm_tgc_o	<=	'0';
					-- elsif	(wr_wbm_stall_i='0'   )then               --second part of summery
						-- summery_st <= summery_write_length_st;
						-- s_wr_wbm_adr_o	<=	"0000000001";
						-- s_wr_wbm_dat_o	<=	image_length(7 downto 0);	
						-- s_wr_wbm_tga_o	<=	"0000000001";
						-- s_wr_wbm_cyc_o	<=	'1';
						-- s_wr_wbm_stb_o	<=	'1';
						-- s_wr_wbm_we_o	<=	'1';
						-- s_wr_wbm_tgc_o	<=	'0';							
					-- else
						-- s_wr_wbm_adr_o	<=	"0000000010";
					-- end if;
					
				-- --------------------------------------------------------------------------	
				-- when summery_done_st =>	
						-- summery_done<='1';
						-- summery_st <= summery_idle_st;	
				-- --------------------------------------------------------------------------	
				-- when others =>
					-- report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected in summery process" severity error;
				-- end case;
		-- end if;					
	-- end process sum_proc;
	----------------------------------------------------------------------------------------
----------------------------		Write Back  Processes			------------------------
----------------------------------------------------------------------------------------
----------------------------    the process writes ram contents to SDRAM     ------------------------
----------------------------------------------------------------------------------------
	
	write_back_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			wr_wbm_adr_o_counter			<=(others => '0');
			write_SDRAM_state	<=write_idle_st;
			finish_write_proc	<='0';	
			w_wr_wbm_adr_o		<=	(others => '0');
			w_wr_wbm_tga_o		<=	(others => '0');
			w_wr_wbm_dat_o		<=	(others => '0');
			w_wr_wbm_cyc_o		<=	'0';
			w_wr_wbm_stb_o		<=	'0';
			w_wr_wbm_we_o		<=	'0';
			w_wr_wbm_tgc_o		<=	'0';
			wb_address	<=	(others => '0');
			-- ram_dout_wait_cyc1 <=	(others => '0');
			-- ram_dout_wait_cyc2 <=	(others => '0');
			-- ram_dout_wait_cyc3 <=	(others => '0');
			-- ram_dout_wait_cyc4 <=	(others => '0');
			ram_adr_o_counter				<=(others => '0');
			wait_for_valid	<=(others => '0');
			ram_addr_out_valid<='0';
		elsif rising_edge (sys_clk) then	
				
				
				case write_SDRAM_state is		
			--------------------------------------------------------------------------	
				when write_idle_st =>
					if (manipulation_complete='1') then
					wb_address<=(others => '0');
					end if;
					if ((en_write_proc='1') and (finish_write_proc ='0') )  then
						write_SDRAM_state	<= 	write_wb_addr_lsb_st;
					else
						finish_write_proc	<='0';
						write_SDRAM_state	<= 	write_idle_st;
						w_wr_wbm_adr_o		<=	(others => '0');
						w_wr_wbm_tga_o		<=	(others => '0');
						w_wr_wbm_dat_o		<=	(others => '0');
						w_wr_wbm_cyc_o		<=	'0';
						w_wr_wbm_stb_o		<=	'0';
						w_wr_wbm_we_o		<=	'0';
						w_wr_wbm_tgc_o		<=	'0';
					    wr_wbm_adr_o_counter			<=(others => '0');
						-- ram_dout_wait_cyc1 <=	(others => '0');
						-- ram_dout_wait_cyc2 <=	(others => '0');
						-- ram_dout_wait_cyc3 <=	(others => '0');
						-- ram_dout_wait_cyc4 <=	(others => '0');
                       	ram_addr_out_valid<='0';
                        wait_for_valid	<=(others => '0');
					end if;
			--------------------------------------------------------------------------				
				when write_wb_addr_lsb_st =>
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						write_SDRAM_state <= write_wb_addr_lsb_st;
						w_wr_wbm_adr_o	<=	mem_mng_dbg_lsb_reg_addr_c;
						w_wr_wbm_dat_o	<=	wb_address(7 downto 0);
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_cyc_o	<=	'1';
						w_wr_wbm_stb_o	<=	'1';
						w_wr_wbm_we_o	<=	'1';
						w_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						write_SDRAM_state <= write_wb_addr_msb_st;
						w_wr_wbm_adr_o	<=	(others => '0');
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_dat_o	<=	"00000000";
						w_wr_wbm_cyc_o	<=	'0';
						w_wr_wbm_stb_o	<=	'0';
						w_wr_wbm_we_o	<=	'0';
						w_wr_wbm_tgc_o	<=	'0';
					end if;
			--------------------------------------------------------------------------				
				when write_wb_addr_msb_st =>
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						write_SDRAM_state <= write_wb_addr_msb_st;
						w_wr_wbm_adr_o	<=	mem_mng_dbg_msb_reg_addr_c;
						w_wr_wbm_dat_o	<=	wb_address(15 downto 8);
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_cyc_o	<=	'1';
						w_wr_wbm_stb_o	<=	'1';
						w_wr_wbm_we_o	<=	'1';
						w_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						write_SDRAM_state <= write_wb_addr_half_bank_st;
						w_wr_wbm_adr_o	<=	(others => '0');
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_dat_o	<=	"00000000";
						w_wr_wbm_cyc_o	<=	'0';
						w_wr_wbm_stb_o	<=	'0';
						w_wr_wbm_we_o	<=	'0';
						w_wr_wbm_tgc_o	<=	'0';
					end if;
			--------------------------------------------------------------------------				
				when write_wb_addr_half_bank_st =>
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						write_SDRAM_state <= write_wb_addr_half_bank_st;
						w_wr_wbm_adr_o	<=	mem_mng_dbg_half_bank_reg_addr_c;
						--original image [bank 0,msb 1], manipulated image [bank 0,msb 0] 0000
						--original image [bank 0,msb 0], manipulated image [bank 0,msb 1] 0001
						w_wr_wbm_dat_o	<=	"00" & bank_val & "1" & wb_address(19 downto 16);--"0001" & wb_address(19 downto 16);
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_cyc_o	<=	'1';
						w_wr_wbm_stb_o	<=	'1';
						w_wr_wbm_we_o	<=	'1';
						w_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						write_SDRAM_state <= write_type_reg_0x01_st;
						w_wr_wbm_adr_o	<=	(others => '0');
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_dat_o	<=	"00000000";
						w_wr_wbm_cyc_o	<=	'0';
						w_wr_wbm_stb_o	<=	'0';
						w_wr_wbm_we_o	<=	'0';
						w_wr_wbm_tgc_o	<=	'0';
					end if;					
			--------------------------------------------------------------------------				
				when write_type_reg_0x01_st =>
					--write 0x01 to Type register in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						write_SDRAM_state <= write_type_reg_0x01_st;
						w_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						w_wr_wbm_dat_o	<=	"00000001";--in order to change to debug mode write 00000000 
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_cyc_o	<=	'1';
						w_wr_wbm_stb_o	<=	'1';
						w_wr_wbm_we_o	<=	'1';
						w_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						write_SDRAM_state <= write_burst_st;
						w_wr_wbm_adr_o	<=	(others => '0');
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_dat_o	<=	"00000000";
						w_wr_wbm_cyc_o	<=	'0';
						w_wr_wbm_stb_o	<=	'0';
						w_wr_wbm_we_o	<=	'0';
						w_wr_wbm_tgc_o	<=	'0';
					end if;
                        wr_wbm_adr_o_counter			<=(others => '0');
						ram_adr_o_counter				<=(others => '0');
		--------------------------------------------------------------------------									
				when write_burst_st =>
					--write ram contents to SDRAM 
					--ram_addr_out_valid<='1';
					if ((wait_for_valid=wait_for_valid_c) and (ram_adr_o_counter/=wb_burst_length_c))  then
						ram_addr_out_valid<='1';
						ram_adr_o_counter<=ram_adr_o_counter+1;
					elsif  ((wait_for_valid=wait_for_valid_c) and (ram_adr_o_counter=wb_burst_length_c)) then
						ram_addr_out_valid<='0';
					else
						ram_addr_out_valid<='1';
						wait_for_valid<=wait_for_valid+1;
					end if;	
					
					if 	(wr_wbm_stall_i='0' and  wr_wbm_ack_i='0')then
						wr_wbm_adr_o_counter			<=	"0000000001";
						--ram_adr_o_counter	<= "0000000001";

					
					elsif ( wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						--if (final_pixel='1')  then --burst of special length TODO!!!!!!!!!!!!!!!
							
						
						--else	--regular burst
							if 	(wr_wbm_adr_o_counter=wb_burst_length_c) then
								write_SDRAM_state 		<= prep_st;			-- burst is over, prepare for idle
								wr_wbm_adr_o_counter	<=wr_wbm_adr_o_counter+'1';
								--ram_adr_o_counter		<= ram_adr_o_counter+1;

							else
								wr_wbm_adr_o_counter	<=wr_wbm_adr_o_counter+'1';		--burst isn't over, continue count
								--ram_adr_o_counter		<= ram_adr_o_counter+1;
								write_SDRAM_state 		<= write_burst_st;
							end if;
					end if;
					
					
					--ram_dout_wait_cyc1	<=	ram_dout;
					--ram_dout_wait_cyc2	<= ram_dout_wait_cyc1;
					--ram_dout_wait_cyc3	<= ram_dout_wait_cyc2;
					--ram_dout_wait_cyc4	<= ram_dout_wait_cyc3;
	
					w_wr_wbm_dat_o	<=	ram_dout ;
					w_wr_wbm_tga_o	<=	wb_burst_length_c;
					w_wr_wbm_cyc_o	<=	'1';
					w_wr_wbm_stb_o	<=	'1';
					w_wr_wbm_we_o	<=	'1';
					w_wr_wbm_tgc_o	<=	'0';
					
					--ram_addr_out		<=wr_wbm_adr_o_counter;
				--------------------------------------------------------------------------
				when prep_st => 

					if (wr_wbm_stall_i='1') then
							wb_address			<=	wb_address+wb_address_c; --add half of burst length, because SDRAM has 16 bit word
							write_SDRAM_state 	<= write_type_reg_0x00_st;
							--finish_write_proc	<='1';
						--else
							--finish_write_proc	<='0';
						end if;
						
						w_wr_wbm_adr_o	<=	(others => '0');
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_dat_o	<=	"00000000";
						w_wr_wbm_cyc_o	<=	'0';
						w_wr_wbm_stb_o	<=	'0';
						w_wr_wbm_we_o	<=	'0';
						w_wr_wbm_tgc_o	<=	'0';							
					--------------------------------------------------------------------------				
				when write_type_reg_0x00_st =>
					--write 0x00 to Type register in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						write_SDRAM_state <= write_type_reg_0x00_st;
						w_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						w_wr_wbm_dat_o	<=	"00000000";--in order to change to debug mode write 00000000 
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_cyc_o	<=	'1';
						w_wr_wbm_stb_o	<=	'1';
						w_wr_wbm_we_o	<=	'1';
						w_wr_wbm_tgc_o	<=	'1';
						finish_write_proc	<='0';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						finish_write_proc	<='1';
						write_SDRAM_state <= write_idle_st;
						w_wr_wbm_adr_o	<=	(others => '0');
						w_wr_wbm_tga_o	<=	(others => '0');
						w_wr_wbm_dat_o	<=	"00000000";
						w_wr_wbm_cyc_o	<=	'0';
						w_wr_wbm_stb_o	<=	'0';
						w_wr_wbm_we_o	<=	'0';
						w_wr_wbm_tgc_o	<=	'0';
					end if;
				--------------------------------------------------------------------------
				when others =>
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected in write sdram process" severity error;
				end case;				
		end if;
	end process write_back_proc;	
---------------------------------------------------------------------------------------
----------------------------	writeProcess process	-----------------------------------
---------------------------------------------------------------------------------------
-- THE process will write output image to txt file
---------------------------------------------------------------------------------------
	-- writeTxtProcess : PROCESS(sys_clk)

  -- BEGIN

    -- if rising_edge(sys_clk) then

		-- IF (write_SDRAM_state=write_burst_st and wr_wbm_stall_i='0') THEN
			-- --print(out_file, "0x"&hstr(tl_out_sig)& " 0x"&hstr(tr_out_sig)& " 0x"&hstr(bl_out_sig)& " 0x"&hstr(br_out_sig)& " "&str(delta_row_out_sig)& " "&str(delta_col_out_sig)& "   " &str(out_of_range_sig));
			-- --print tl,tr,bl,br,delta_row,delta_col (decimal) , out_of_range //str((row_index_signed))& " "&str((col_index_signed))& 
				-- print(out_file_2, str (ram_dout));			
		-- END IF;
             -- IF (cur_st=result_to_RAM_st) THEN
                        -- --print(out_file, "0x"&hstr(tl_out_sig)& " 0x"&hstr(tr_out_sig)& " 0x"&hstr(bl_out_sig)& " 0x"&hstr(br_out_sig)& " "&str(delta_row_out_sig)& " "&str(delta_col_out_sig)& "   " &str(out_of_range_sig));
                        -- --print tl,tr,bl,br,delta_row,delta_col (decimal) , out_of_range //str((row_index_signed))& " "&str((col_index_signed))& 
                        -- if (addr_calc_oor='0') then
                                -- print(out_file_1, str (pixel_res));
                        -- else
                                -- print(out_file_1, "0");
                        -- end if;
                -- END IF;
	-- end if;

  -- END PROCESS writeTxtProcess;	
---------------------------------------------------------------------------------------
----------------------------	addr_calc process	-----------------------------------
---------------------------------------------------------------------------------------
-- THE process will activate the address calculator
-- input coordinate from coord_proc
-- output 4 pixel addreses (need only two)+ 2 delta fractions 
---------------------------------------------------------------------------------------	
addr_calc_proc : process (sys_clk,sys_rst)			
	begin
		if (sys_rst =reset_polarity_g) then	
			addr_trigger_unit		<=	'0';
			addr_row_idx_in			<=(others => '0');
			addr_col_idx_in			<=(others => '0');
			
			addr_calc_tl		<=  (others => '0');
			addr_calc_bl		<=  (others => '0');
			addr_calc_d_row		<=  (others => '0');	                
			addr_calc_d_col		<=  (others => '0'); 
			
			addr_calc_oor		<=  '0';
			addr_calc_valid		<=  '0' ;
			addr_enable			<= '0';
			
		elsif rising_edge(sys_clk) then
			--trigger addres calculator
			if (  en_addr_calc_proc ="01")  then --begin address calculation , send trigger to addr_calc
				addr_trigger_unit	<='1';
				addr_enable			<='1';
			elsif ( en_addr_calc_proc ="10") then -- calculation in progress ,disable trigger
				addr_trigger_unit	<=	'0';
				addr_enable			<='1';
			elsif ( en_addr_calc_proc ="00") then -- calculation is finished or not begun
				addr_enable			<='0';
			end if;	
			addr_row_idx_in		<=  row_index_signed;	--from coord calc process to address calc
			addr_col_idx_in		<=  col_index_signed;	--from coord calc process to address calc
			--debbug
			

			
			if (addr_tl_out(8 downto 1)= "11111111") then
				addr_calc_tl		<=  '0' & addr_tl_out(22 downto 2)& '0';
			else
				addr_calc_tl		<=  '0' & addr_tl_out(22 downto 1);
			end if;

			if (addr_bl_out(8 downto 1)= "11111111") then
				addr_calc_bl		<=  '0' & addr_bl_out(22 downto 2)& '0';
			else
				addr_calc_bl		<=  '0' & addr_bl_out(22 downto 1);
			end if;


			addr_calc_d_row		<=  addr_delta_row_out;	                
			addr_calc_d_col		<=  addr_delta_col_out; 
			addr_calc_oor		<=  addr_out_of_range;
			addr_calc_valid		<=  addr_data_valid_out ;
			
			
		end if;	
		
end process addr_calc_proc;	



---------------------------------------------------------------------------------------
----------------------------	read_from_SDRAM process	-----------------------------------
---------------------------------------------------------------------------------------
-- the process will manage the read transaction from the sdram
-- the read will be executed in 4 phase, 2 phases for each address
-- 
-- 
---------------------------------------------------------------------------------------	
read_from_SDRAM : process (sys_clk,sys_rst)			
	begin
		if (sys_rst =reset_polarity_g) then	
			finish_read_pxl		<=	(others => '0');			
			read_SDRAM_state	<=	read_idle_st;
			rd_wbm_tga_o 		<=	(others => '0');	
			rd_wbm_cyc_o		<=	'0';	
			rd_wbm_stb_o		<=	'0';
			--rd_wbm_adr_o		<=	(others => '0');	
			rd_wbm_tga_o		<=	(others => '0');	
			rd_wbm_cyc_o		<=	'0';
			rd_wbm_tgc_o		<=	'0';
			finish_read_pxl		<=	(others => '0');							
			tl_pixel			<=	(others => '0');
			tr_pixel			<=	(others => '0'); 
			bl_pixel			<=	(others => '0');
			br_pixel			<=	(others => '0');
			rd_adr_o_counter	<=	(others => '0');
			restart_bank	<=	(others => '0');
			r_wr_wbm_adr_o	<=	(others => '0');
			r_wr_wbm_tga_o	<=	(others => '0');
			r_wr_wbm_dat_o	<=	"00000000";
			r_wr_wbm_cyc_o	<=	'0';
			r_wr_wbm_stb_o	<=	'0';
			r_wr_wbm_we_o		<=	'0';
			r_wr_wbm_tgc_o	<=	'0';
			read_first<='0';

		elsif rising_edge(sys_clk)  then	
			case read_SDRAM_state is		
			--------------------------------------------------------------------------	
				when read_idle_st =>
					finish_read_pxl<="00";   			--reset read pixel counter 
					if ((en_read_proc='1') and (finish_read_pxl /="11") )  then
						read_SDRAM_state	<= 	write_type_reg_0x80_1_st;
					else
						read_SDRAM_state	<= 	read_idle_st;
						rd_wbm_tga_o 	<=	"0000000000";	
						rd_wbm_cyc_o	<=	'0';	
						rd_wbm_stb_o	<=	'0';
						read_first<='0';
						rd_adr_o_counter<=	(others => '0');
						restart_bank	<=	(others => '0');
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';
					end if;
			--------------------------------------------------------------------------					
				when write_type_reg_0x80_1_st =>
						--write 0x80 to Type register in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_type_reg_0x80_1_st;
						r_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"10000000";
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= write_dbg_reg_lsb_1_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';						
					end if;
			--------------------------------------------------------------------------	
				when write_dbg_reg_lsb_1_st =>
					--write address to DBG_address_register(0x2) - bottom bits of address in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_dbg_reg_lsb_1_st;
						r_wr_wbm_adr_o	<=	mem_mng_dbg_lsb_reg_addr_c;
						r_wr_wbm_dat_o	<=	addr_calc_tl(7 downto 0);	--address from addr_calc
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= write_dbg_reg_msb_1_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';							
					end if;							
			--------------------------------------------------------------------------		
				when write_dbg_reg_msb_1_st =>
					--write address to DBG_address_register(0x3) - top bits of address in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_dbg_reg_msb_1_st;
						r_wr_wbm_adr_o	<=	mem_mng_dbg_msb_reg_addr_c;
						r_wr_wbm_dat_o	<=	addr_calc_tl(15 downto 8); --address from addr_calc
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= write_dbg_reg_start_bank_1_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';							

					end if;
			--------------------------------------------------------------------------		
				when write_dbg_reg_start_bank_1_st =>
					--write address to DBG_address_register(0x3) - top bits of address in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_dbg_reg_start_bank_1_st;
						r_wr_wbm_adr_o	<=	mem_mng_dbg_half_bank_reg_addr_c;
						--original image [bank 0,msb 1], manipulated image [bank 0,msb 0] 00010000
						--original image [bank 0,msb 0], manipulated image [bank 0,msb 1] 00000000
						r_wr_wbm_dat_o	<=	"00"& bank_val& "0" & addr_calc_tl(19 downto 16);--"0000" & addr_calc_tl(19 downto 16);--(others => '0'); --address from addr_calc
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= write_type_reg_0x81_1_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';							
					end if;						
			--------------------------------------------------------------------------					
				when write_type_reg_0x81_1_st =>
					--write 0x81 to Type register in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_type_reg_0x81_1_st;
						r_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						r_wr_wbm_dat_o	<=	"10000001";
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= wait_ack_1_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';							
						read_first<='0';
					end if;	
			--------------------------------------------------------------------------			
				when wait_ack_1_st =>
					rd_wbm_tga_o 	<=	"0000000010";	
					rd_wbm_cyc_o	<=	'1';	
					rd_wbm_stb_o	<=	'1';
					rd_wbm_tgc_o	<=	'0';
					if (rd_wbm_stall_i ='0' and rd_wbm_ack_i='0') then 
						rd_adr_o_counter <= "0000000001";
					end if;
					

					if (rd_wbm_ack_i='1') then		--recieve ack on read						
						rd_adr_o_counter <= rd_adr_o_counter +'1';
						-- sample two pixel read from SDRAM
						if (read_first='0')		then				--ack on top left
							--rd_wbm_adr_o	<="0000000001"; 		--advance read address
							tl_pixel	<= rd_wbm_dat_i;	
							read_first	<='1';
							read_SDRAM_state  <=wait_ack_1_st;
						elsif (read_first='1' )	then				--ack on top right
							--rd_wbm_adr_o	<="0000000010";			--advance read address						
							tr_pixel	<= rd_wbm_dat_i;	
							read_first	<='0';
							read_SDRAM_state	<=	write_type_reg_0x00_1_st;
							finish_read_pxl	<= "01";	-- finish first pixels pair
							--write 0x00 to Type register in mem_mng	
							r_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
							r_wr_wbm_tga_o	<=	(others => '0');
							r_wr_wbm_dat_o	<=	"00000000";
							r_wr_wbm_cyc_o	<=	'1';
							r_wr_wbm_stb_o	<=	'1';
							r_wr_wbm_we_o		<=	'1';
							r_wr_wbm_tgc_o	<=	'1';
							rd_wbm_tgc_o	<=	'1';--for restart from start of bank
							restart_bank	<=	(others => '0');
						end if;
					else
						finish_read_pxl	<=	"00";
						read_SDRAM_state<=	wait_ack_1_st;
					end if;
					
			--------------------------------------------------------------------------		
				when write_type_reg_0x00_1_st	=>
					if (rd_wbm_ack_i='1') then
						rd_adr_o_counter <= rd_adr_o_counter +'1';
					end if;
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						--write 0x00 to Type register in mem_mng	
						r_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= prepare_for_second_pair_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';
					end if;					
			--------------------------------------------------------------------------		
				when prepare_for_second_pair_st =>
					rd_wbm_tgc_o	<=	'1';--for restart from start of bank
					rd_wbm_tga_o 	<=	"0000000000";	                                  
					rd_wbm_cyc_o	<=	'1';	                                          
					rd_wbm_stb_o	<=	'0';                                              
                                
					r_wr_wbm_adr_o	<=	(others => '0');                                  
					r_wr_wbm_tga_o	<=	(others => '0');                                  	
					r_wr_wbm_dat_o	<=	(others => '0');                                  
					r_wr_wbm_cyc_o	<=	'0';                                              
					r_wr_wbm_stb_o	<=	'0';                                              
					r_wr_wbm_we_o		<=	'0';                                              
					r_wr_wbm_tgc_o	<=	'0';                                              
					if (	restart_bank=restart_bank_c) then
						read_SDRAM_state <= write_type_reg_0x80_2_st;
					else
						read_SDRAM_state <= prepare_for_second_pair_st;
						restart_bank	<=	restart_bank+'1';
					end if;
			--------------------------------------------------------------------------			
				when write_type_reg_0x80_2_st => 
					rd_wbm_tgc_o	<=	'0';
					rd_wbm_tga_o 	<=	"0000000000";	                                  
					rd_wbm_cyc_o	<=	'0';	                                          
					rd_wbm_stb_o	<=	'0';                                              
					rd_adr_o_counter<=	(others => '0');
					--write 0x80 to Type register in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_type_reg_0x80_2_st;
						r_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"10000000";
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= write_dbg_reg_lsb_2_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';						
					end if;
			--------------------------------------------------------------------------
				when write_dbg_reg_lsb_2_st =>
					--write address to DBG_address_register(0x2) - bottom bits of address in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_dbg_reg_lsb_2_st;
						r_wr_wbm_adr_o	<=	mem_mng_dbg_lsb_reg_addr_c;
						r_wr_wbm_dat_o	<=	addr_calc_bl(7 downto 0);	--address from addr_calc
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= write_dbg_reg_msb_2_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';							
					end if;	
			--------------------------------------------------------------------------		
				when write_dbg_reg_msb_2_st =>
					--write address to DBG_address_register(0x3) - top bits of address in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_dbg_reg_msb_2_st;
						r_wr_wbm_adr_o	<=	mem_mng_dbg_msb_reg_addr_c;
						r_wr_wbm_dat_o	<=	addr_calc_bl(15 downto 8); --address from addr_calc
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= write_dbg_reg_start_bank_2_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';							

					end if;
								--------------------------------------------------------------------------		
				when write_dbg_reg_start_bank_2_st =>
					--write address to DBG_address_register(0x3) - top bits of address in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_dbg_reg_start_bank_2_st;
						r_wr_wbm_adr_o	<=	mem_mng_dbg_half_bank_reg_addr_c;
						--original image [bank 0,msb 1], manipulated image [bank 0,msb 0] 00010000
						--original image [bank 0,msb 0], manipulated image [bank 0,msb 1] 00000000
						r_wr_wbm_dat_o	<=	"00" & bank_val & "0" & addr_calc_bl(19 downto 16);--"0000"& addr_calc_bl(19 downto 16);--"00000000"
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= write_type_reg_0x81_2_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';							
					end if;	
			--------------------------------------------------------------------------	
				when write_type_reg_0x81_2_st =>
					--write 0x81 to Type register in mem_mng
					if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
						read_SDRAM_state <= write_type_reg_0x81_2_st;
						r_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						r_wr_wbm_dat_o	<=	"10000001";
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_cyc_o	<=	'1';
						r_wr_wbm_stb_o	<=	'1';
						r_wr_wbm_we_o		<=	'1';
						r_wr_wbm_tgc_o	<=	'1';
					elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
						read_SDRAM_state <= wait_ack_2_st;
						r_wr_wbm_adr_o	<=	(others => '0');
						r_wr_wbm_tga_o	<=	(others => '0');
						r_wr_wbm_dat_o	<=	"00000000";
						r_wr_wbm_cyc_o	<=	'0';
						r_wr_wbm_stb_o	<=	'0';
						r_wr_wbm_we_o		<=	'0';
						r_wr_wbm_tgc_o	<=	'0';							
						read_first<='0';
					end if;
			--------------------------------------------------------------------------	
				when wait_ack_2_st =>
					rd_wbm_tga_o 	<=	"0000000010";	
					rd_wbm_cyc_o	<=	'1';	
					rd_wbm_stb_o	<=	'1';
					restart_bank	<="000";
					if (rd_wbm_stall_i ='0' and rd_wbm_ack_i='0') then 
						rd_adr_o_counter <= "0000000001";
					end if;

					if (rd_wbm_ack_i='1') then			-- recieve ack on read						
						rd_adr_o_counter <= rd_adr_o_counter +'1';
						-- sample two pixel read from SDRAM
						if (read_first='0')		then					--ack on bottom left
							finish_read_pxl	<=	"01";
							read_SDRAM_state		<=	wait_ack_2_st;							
							bl_pixel	<= rd_wbm_dat_i;	
							read_first	<='1';
						elsif (read_first='1')	then					-- ack on bottom right
							br_pixel	<= rd_wbm_dat_i;	
							read_first	<='0';
							read_SDRAM_state	<=	write_type_reg_0x00_2_st;
						end if;
					else
						finish_read_pxl	<=	"01";
						read_SDRAM_state		<=	wait_ack_2_st;
					end if;
			--------------------------------------------------------------------------		
				when write_type_reg_0x00_2_st	=>
						if (rd_wbm_ack_i='1') then			-- recieve ack on read
							rd_adr_o_counter <= rd_adr_o_counter +'1';
						end if;
						if	(wr_wbm_stall_i='1' or wr_wbm_ack_i='0')then
							--write 0x00 to Type register in mem_mng	
							r_wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
							r_wr_wbm_tga_o	<=	(others => '0');
							r_wr_wbm_dat_o	<=	"00000000";
							r_wr_wbm_cyc_o	<=	'1';
							r_wr_wbm_stb_o	<=	'1';
							r_wr_wbm_we_o		<=	'1';
							r_wr_wbm_tgc_o	<=	'1';
						elsif (wr_wbm_stall_i='0' and wr_wbm_ack_i='1') then
							read_SDRAM_state <= restart_sdram_after_read;
							r_wr_wbm_adr_o	<=	(others => '0');
							r_wr_wbm_tga_o	<=	(others => '0');
							r_wr_wbm_dat_o	<=	"00000000";
							r_wr_wbm_cyc_o	<=	'0';
							r_wr_wbm_stb_o	<=	'0';
							r_wr_wbm_we_o		<=	'0';
							r_wr_wbm_tgc_o	<=	'0';
						end if;				
			--------------------------------------------------------------------------	
				when restart_sdram_after_read	=>
					r_wr_wbm_adr_o	<=	(others => '0');
					r_wr_wbm_tga_o	<=	(others => '0');
					r_wr_wbm_dat_o	<=	"00000000";
					r_wr_wbm_cyc_o	<=	'0';
					r_wr_wbm_stb_o	<=	'0';
					r_wr_wbm_we_o		<=	'0';
					r_wr_wbm_tgc_o	<=	'0';				
					rd_wbm_stb_o	<=	'0';						

					if (restart_bank=restart_bank_c) then
						rd_wbm_tgc_o	<=	'0';--end restart from start of bank
						rd_wbm_cyc_o	<=	'0';
						finish_read_pxl	<= "11";					-- finish second pixels pair
						read_SDRAM_state <= read_idle_st;
						rd_adr_o_counter <= (others=>'0');
					else
						rd_adr_o_counter <= rd_adr_o_counter +'1';
						rd_wbm_tgc_o	<=	'1';--for restart from start of bank
						rd_wbm_cyc_o	<=	'1';	
						rd_wbm_stb_o	<=	'0';						
						read_SDRAM_state <= restart_sdram_after_read;
						restart_bank	<=	restart_bank+'1';
					end if;			
			--------------------------------------------------------------------------		
				when others =>
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected in read sdram process" severity error;
				end case;	
			--------------------------------------------------------------------------	
		end if;	
	end process read_from_SDRAM;
	-------------------------------------------------------------------------------------
----------------------------	bilinear process	-----------------------------------
---------------------------------------------------------------------------------------
-- THE process will cotrol the  bilinear interpolation execution using the bilinear.vhd block
-- reminder: input 4 pixels, output 1 pixel

---------------------------------------------------------------------------------------	


bili_proc : process (sys_clk,sys_rst)			
	begin
		if (sys_rst =reset_polarity_g) then	
			bili_req_trig<='0';
			bili_tl_pixel	<=  (others => '0');
			bili_tr_pixel	<=  (others => '0');
			bili_bl_pixel   <=  (others => '0');
			bili_br_pixel   <=  (others => '0');
			bili_delta_row	<=  (others => '0');
			bili_delta_col	<=  (others => '0');

			
		elsif rising_edge(sys_clk) then
			if (addr_tl_out(0)='0') then 
				bili_tl_pixel	<=  tl_pixel;
				bili_tr_pixel	<=  tr_pixel;
			else
				bili_tl_pixel	<=  tr_pixel;	--temp fix for odd adresses
				bili_tr_pixel	<=  tr_pixel;
			end if;	
			if (addr_bl_out(0)='0') then 
				bili_bl_pixel   <=  bl_pixel;
				bili_br_pixel   <=  br_pixel;
			else                             --temp fix for odd adresses
				bili_bl_pixel   <=  br_pixel;
				bili_br_pixel   <=  br_pixel;
			end if;
			bili_delta_row	<=  addr_calc_d_row;
			bili_delta_col	<=  addr_calc_d_col;
			
			--trigger addres calculator
			if (  en_bili_trig ='1')  then --begin address calculation , send trigger to addr_calc
				bili_req_trig	<='1';
			elsif ( en_bili_trig ='0') then -- calculation in progress ,disable trigger
				bili_req_trig	<=	'0';
			end if;		
			
			
		end if;	
	end process bili_proc;
----------------------------------------------------------------------------------------
----------------------------		write_burst_counter  Processes			------------------------
----------------------------------------------------------------------------------------
----------------------------    the process counts from 0 upto  wb_burst_length_c-1   ------------------------
----------------------------    when the process reaches wb_burst_length_c-1, it sends a trigger and restarts		  ---------------------
----------------------------------------------------------------------------------------
		write_burst_counter_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			ram_addr_in_counter <= (others => '0');
			RAM_is_full	<=  '0';
		elsif rising_edge (sys_clk) then	
			
			if (cur_st=fsm_idle_st) then 						
				ram_addr_in_counter	<= (others => '0');
				RAM_is_full	<=  '0';
			
			elsif (cur_st=result_to_RAM_st)  then	
				
				if (ram_addr_in_counter=wb_burst_length_c-1) then
					ram_addr_in_counter			<=ram_addr_in_counter	+ '1';
					RAM_is_full	<=  '1';	
				else
					ram_addr_in_counter			<=ram_addr_in_counter	+ '1';
					RAM_is_full	<=  '0';
				end if;
			elsif (cur_st=fsm_WB_to_SDRAM_st)  then
				if (ram_addr_in_counter=wb_burst_length_c-1) then
					ram_addr_in_counter			<=	(others => '0');
					RAM_is_full	<=  '0';
				end if;
			end if;		
		end if;
	end process write_burst_counter_proc;
		


	----------------------------------------------------------------------------------------
----------------------------		index valid  Processes			------------------------
----------------------------------------------------------------------------------------
----------------------------    the process controls when index output is valid    ------------------------
----------------------------------------------------------------------------------------
	index_valid_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			index_valid <= '0';
		elsif rising_edge (sys_clk) then	

			if (cur_st=fsm_increment_coord_st and final_pixel='0') then
				index_valid		<= '1';
			else
				index_valid		<= '0';
			end if;	
		end if;
	end process index_valid_proc;	
---------------------------------------------------------------------------------------
----------------------------	coordinate process	-----------------------------------
---------------------------------------------------------------------------------------
-- THE process will advance the row/col indexes until end of image
-- when image is over a flag will rise - final_pixel
-- reset will set the coordinates at (0,0)
-- init will set the coordinates at (row_start,col_start)
---------------------------------------------------------------------------------------	
coord_proc : process (sys_clk,sys_rst)			
	begin                                                                                                                     
		if (sys_rst =reset_polarity_g) then	                                                                                  
			final_pixel <='0';                                                                                               
			row_index_signed <=(others => '0');                                                                                    
			col_index_signed <=(others => '0');
		elsif rising_edge(sys_clk) then
			if (cur_st=fsm_idle_st) then 						--initialize row and col counter
				row_index_signed<=row_start;
				col_index_signed<= col_start-1;				--col starts with col_start -1 since fsm_increment_st is prior to calculation!!!!!!!!!!!!!!!!!!!!!!!!!!
				
				final_pixel <='0';
			
			elsif (cur_st=fsm_increment_coord_st)  then			
				if (col_index_signed<col_end) then				--increment col if possible else move to new row
						col_index_signed<=col_index_signed+1;
						final_pixel <='0';
				else
					if (row_index_signed< row_end) then 			--increment row if possible else picture is over
                        col_index_signed<= col_start	;
						row_index_signed<=row_index_signed+1;
					end if;	
				end if;
			elsif (cur_st=fsm_address_calc_st) and (col_index_signed=col_end) and (row_index_signed=row_end) then
				final_pixel <='1';
			end if;
		end if;	
end process coord_proc;

--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-------------------------------		Instances		--------------------------------
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--ram_addr_out_valid<=(not wr_wbm_stall_i) when (write_SDRAM_state=write_burst_st) else '0';		--start reading ram when stall is 0
wb_ram_inst: ram_generic
	generic map(
				reset_polarity_g	=>'0',
				width_in_g			=> 8,	--Width of data
				addr_bits_g			=>wb_burst_length_c'left+1,	--Depth of data	(2^10 = 1024 addresses)
				power2_out_g		=>0,	--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide
				power_sign_g		=>1 	-- '-1' => output width > input width ; '1' => input width > output width
			)
	port map(
				clk			=>	sys_clk,										--System clock
				rst			=>	sys_rst,										--System Reset
				addr_in		=>	ram_addr_in, 								--Input address from write_burst_counter_proc
				addr_out	=>	ram_adr_o_counter, 		--Output address
				aout_valid	=>	ram_addr_out_valid,									--Output address is valid
				data_in		=>	ram_din,										--Input data from bilinear stage
				din_valid	=>	ram_din_valid,									--Input data valid
				data_out	=>	ram_dout,	--Output data
				dout_valid	=>	ram_dout_valid 									--Output data valid
			);
	
end architecture rtl_img_man_manager;