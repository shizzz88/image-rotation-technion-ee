------------------------------------------------------------------------------------------------
-- Model Name 	:	Top Block - Image Manipulation
-- File Name	:	img_man_top.vhd
-- Generated	:	07.08.2012
-- Author		:	Ran Mizrahi&Uri Tzipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		07.08.2012	Ran&Uri					creation
--			1.1			07.04.2013	uri						added address calculator		
------------------------------------------------------------------------------------------------
-- TO DO:
		--zoom factor,x_crop,y_crop,cos must be reset to 1
		--cos to 010000000
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work ;


entity img_man_top is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				img_hor_pixels_g	:	positive					:= 128;	-- active pixels
				img_ver_pixels_g	:	positive					:= 96;	-- active lines
				trig_frac_size_g	: 	positive					:= 7 ;
				display_hor_pixels_g	:	positive				:= 800;	--800 pixel in a coloum
				display_ver_pixels_g	:	positive				:= 600	--600 pixels in a row
			);
	port	(
				--Clock and Reset
				system_clk				:	in std_logic;							--Clock
				system_rst				:	in std_logic;							--Reset
				req_trig				:	in std_logic;								-- Trigger for image manipulation to begin,
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
end entity img_man_top;

architecture rtl_img_man_top of img_man_top is

--	###########################		Costants		##############################	--
	constant reg_width_c		:	positive 	:= 8;	--Width of registers
	constant param_reg_depth_c	:	positive 	:= 2;	--Depth of registers 2*8 = 16 bits
	constant reg_addr_width_c	:	positive 	:= 5;	--Width of registers' address
	constant type_reg_addr_c	:	natural		:= 16;	--Type register address
	constant x_start_reg_addr_c	:	natural		:= 17;	--x_start register address
	constant y_start_reg_addr_c	:	natural		:= 19;	--y_start register address
	constant zoom_reg_addr_c	:	natural		:= 21;	--Zoom register address
	constant cos_reg_addr_c		:	natural		:= 23;	--Cosine of Angle register address	
	constant sin_reg_addr_c		:	natural		:= 25;	--Sine of Angle register address
--	###########################		Components		##############################	--

component gen_reg
	generic	(
				reset_polarity_g	:	std_logic	:= '0';					--When reset = reset_polarity_g, system is in RESET mode
				width_g				:	positive	:= reg_width_c;					--Width: Number of bits
				addr_en_g			:	boolean		:= true;				--TRUE: Address enabled  - responde by register will occur only when specific address has been specified
				addr_val_g			:	natural		:= 0;					--Default register address
				addr_width_g		:	positive	:= reg_addr_width_c;	--2^5 = 32 register address is supported
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
				width_g				:	positive	:= reg_width_c;							--Width: Registers width
				addr_width_g		:	positive	:= reg_addr_width_c 			--2^reg_addr_width_c =  register address is supported
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


component addr_calc is
	generic (
				reset_polarity_g		:	std_logic	:= '0';					--Reset active low
				x_size_in_g				:	positive 	:= img_ver_pixels_g;	-- number of rows  in the input image
				y_size_in_g				:	positive 	:= img_hor_pixels_g;	-- number of columns  in the input image
				x_size_out_g			:	positive 	:= 600;				-- number of rows  in theoutput image
				y_size_out_g			:	positive 	:= 800;				-- number of columns  in the output image
				trig_frac_size_g		:	positive 	:= 7;				-- number of digits after dot = resolution of fracture (binary)
				pipe_depth_g			:	positive	:= 12;				-- 
				valid_setup_g			:	positive	:= 10
			);
	port	(
				
				zoom_factor			:	in signed (trig_frac_size_g+1 downto 0);	--zoom facotr given by user - x2,x4,x8 (zise fits to sin_teta)
				sin_teta			:	in signed (trig_frac_size_g+1 downto 0);	--sine of rotation angle - calculated by software. 7 bits of sin + 1 bit of signed
				cos_teta			:	in signed (trig_frac_size_g+1 downto 0);	--cosine of rotation angle - calculated by software. 
				
				
				row_idx_in			:	in signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed)
				col_idx_in			:	in signed (10 downto 0);		--the current column index of the output image
				x_crop_start	    :	in signed (10 downto 0);		--crop start index : the top left pixel for crop		
				y_crop_start		:	in signed (10 downto 0);		--crop start index : the top left pixel for crop
				ram_start_add_in	:	in std_logic_vector  (22 downto 0);		--SDram beginning address
				
                tl_out				:	out std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
				tr_out				:	out std_logic_vector (22 downto 0);		--top right pixel address in SDRAM
				bl_out				:	out std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
				br_out				:	out std_logic_vector (22 downto 0);		--bottom right pixel address in SDRAM
				delta_row_out		:	out	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				delta_col_out		:	out	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				
				out_of_range		:	out std_logic;		--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				data_valid_out		:	out std_logic;		--data valid indicator
				
				--CLK, RESET, ENABLE
				enable					:	in std_logic;    	--enable unit port           
				unit_finish			:	out std_logic;                              --signal indicating addr_calc is finished
				trigger_unit			:	in std_logic;                               --enable signal for addr_calc
				system_clk				:	in std_logic;							--SDRAM clock
				system_rst				:	in std_logic							--Reset (133MHz)
			);
end component addr_calc;

component img_man_manager is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				trig_frac_size_g	:	positive := 7;				-- number of digits after dot = resolution of fracture (binary)
				img_hor_pixels_g	:	positive					:= 128;	--128 pixel in a coloum
				img_ver_pixels_g	:	positive					:= 96;	--96 pixels in a row
				display_hor_pixels_g	:	positive				:= 800;	--800 pixel in a coloum
				display_ver_pixels_g	:	positive				:= 600	--600 pixels in a row				
			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;								-- clock
				sys_rst				:	in std_logic;								-- Reset					
				req_trig			:	in std_logic;								-- Trigger for image manipulation to begin,
					
				-- addr_calc					
				
				addr_row_idx_in			:	out signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed)
				addr_col_idx_in			:	out signed (10 downto 0);		--the current column index of the output image
				
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
end component img_man_manager;

component bilinear is
	generic (
				reset_polarity_g		:	std_logic	:= '0';			--Reset active low
				pipeline_depth_g		:	positive := 4;
				trig_frac_size_g		:	positive := 7				-- number of digits after dot = resolution of fracture (binary)

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
				delta_row			:	in	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				delta_col			:	in	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation

				
				pixel_valid			:	out std_logic;				--valid signal for index
				pixel_res			:	out std_logic_vector (trig_frac_size_g downto 0) 	--current row index           --fix to generic
			
			);
end component bilinear;
--	###########################		Signals		##############################	--

-- Logic signals, derived from Wishbone Slave
signal wbs_reg_cyc			:	std_logic;						--'1': Cycle to register is active
signal wbs_cmp_cyc			:	std_logic;						--'1': Cycle to component is active
signal wbs_reg_dout			:	std_logic_vector (7 downto 0);	--Output data from Registers
signal wbs_reg_dout_valid	:	std_logic;						--Dout valid for registers
signal wbs_reg_din_ack    	:   std_logic;						--Din has been acknowledeged by registers
signal wbs_cmp_ack_o		:	std_logic;						--WBS_ACK_O from component
signal wbs_reg_ack_o		:	std_logic;						--WBS_ACK_O from registers
signal wbs_cmp_stall_o		:	std_logic;						--WBS_STALL_O from component
signal wbs_reg_stall_o		:	std_logic;						--WBS_STALL_O from registers
signal wbs_cmp_stb			:	std_logic;						--WBS_STB_O to component
signal wbs_reg_stb			:	std_logic;						--WBS_STB_O to registers

---- Wishbone Master signals from Mem_Ctrl_Rd to Arbiter
--signal rd_wbm_adr_o			:	std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)	
--signal rd_wbm_dat_i			:   std_logic_vector (15 downto 0);		--Data In (16 bits)
--signal rd_wbm_we_o			:	std_logic;							--Write Enable
--signal rd_wbm_tga_o			:   std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
--signal rd_wbm_cyc_o			:   std_logic;							--Cycle Command to interface
--signal rd_wbm_stb_o			:   std_logic;							--Strobe Command to interface
--signal rd_wbm_stall_i			:	std_logic;							--Slave is not ready to receive new data
--signal rd_wbm_err_i			:   std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
--signal rd_wbm_ack_i			:   std_logic;							--When Read Burst: DATA bus must be valid in this cycle

--Signals to registers
signal reg_addr				:	std_logic_vector (reg_addr_width_c - 1 downto 0);	--Address to register. Relevant only when addr_en_g = true
signal reg_din				:	std_logic_vector (reg_width_c - 1 downto 0);		--Input data
signal reg_wr_en			:	std_logic;											--Input data is valid
signal reg_rd_en			:	std_logic;											--Request for data from registers

--Type register signals
signal type_reg_din_ack		:	std_logic;											--Data has been acknowledged
signal type_reg_rd_en		:	std_logic;											--Read Enable
signal type_reg_dout		:	std_logic_vector (reg_width_c - 1 downto 0);		--Output data
signal type_reg_dout_valid	:	std_logic;											--Output data is valid


--Cos register signals
signal cos_reg_din_ack		:	std_logic_vector (param_reg_depth_c - 1 downto 0);	--Data has been acknowledged
signal cos_reg_rd_en		:	std_logic_vector (param_reg_depth_c - 1 downto 0);	--Read Enable
signal cos_reg_dout			:	std_logic_vector (param_reg_depth_c * reg_width_c - 1 downto 0);		--Output data
signal cos_reg_dout_valid	:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Output data is valid

--Sin register signals
signal sin_reg_din_ack		:	std_logic_vector (param_reg_depth_c - 1 downto 0);	--Data has been acknowledged
signal sin_reg_rd_en		:	std_logic_vector (param_reg_depth_c - 1 downto 0);	--Read Enable
signal sin_reg_dout			:	std_logic_vector (param_reg_depth_c * reg_width_c - 1 downto 0);		--Output data
signal sin_reg_dout_valid	:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Output data is valid

--x_start register signals
signal x_start_reg_din_ack		:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Data has been acknowledged
signal x_start_reg_rd_en		:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Read Enable
signal x_start_reg_dout			:	std_logic_vector (param_reg_depth_c * reg_width_c - 1 downto 0);	--Output data
signal x_start_reg_dout_valid	:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Output data is valid

--y_start register signals
signal y_start_reg_din_ack		:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Data has been acknowledged
signal y_start_reg_rd_en		:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Read Enable
signal y_start_reg_dout			:	std_logic_vector (param_reg_depth_c * reg_width_c - 1 downto 0);	--Output data
signal y_start_reg_dout_valid	:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Output data is valid

--Zoom register signals
signal zoom_reg_din_ack			:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Data has been acknowledged
signal zoom_reg_rd_en			:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Read Enable
signal zoom_reg_dout			:	std_logic_vector (param_reg_depth_c * reg_width_c - 1 downto 0);	--Output data
signal zoom_reg_dout_valid		:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Output data is valid

--from img_manager
	
	signal	index_valid_sig	            : std_logic;			
	signal	row_idx_out_sig	            : signed (10 downto 0);
	signal	col_idx_out_sig	            : signed (10 downto 0);
	signal	manipulation_trig			: std_logic;	
	-- img_manager to addr_calc
	signal im_addr_row_idx_in			:	 signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed)
	signal im_addr_col_idx_in			:	 signed (10 downto 0);		--the current column index of the output image
	signal im_addr_tl_out				:	std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
	signal im_addr_bl_out				:	std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
	signal im_addr_delta_row_out		:	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
	signal im_addr_delta_col_out		:	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
	signal im_addr_out_of_range		:	std_logic;		--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
	signal im_addr_data_valid_out	:	std_logic;		--data valid indicator 
	signal im_addr_unit_finish		:	 std_logic;                              --signal indicating addr_calc is finished
	signal im_addr_trigger_unit		:	 std_logic;                               --enable signal for addr_calc
	signal im_addr_enable			:	 std_logic;    

--bilinear
	signal	bilinear_req_trig			:	std_logic;				-- Trigger for image manipulation to begin,
	signal	bilinear_tl_pixel			:	std_logic_vector(trig_frac_size_g downto 0);		--top left pixel
	signal	bilinear_tr_pixel			:	std_logic_vector(trig_frac_size_g downto 0);		--top right pixel
	signal	bilinear_bl_pixel           :	std_logic_vector(trig_frac_size_g downto 0);		--bottom left pixel
	signal	bilinear_br_pixel           :	std_logic_vector(trig_frac_size_g downto 0);		--bottom right pixel
	signal	bilinear_delta_row			:	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
	signal	bilinear_delta_col			:	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
	signal	bilinear_pixel_valid		:	std_logic;				--valid signal for index
	signal	bilinear_pixel_res			:	std_logic_vector (trig_frac_size_g downto 0); 	--current row index           --fix to generic
	--- garbage signals - to be deleted
signal  addr_tr_out_garbage				:	 std_logic_vector (22 downto 0);
signal  addr_br_out_garbage				:	 std_logic_vector (22 downto 0);
--	###########################		Implementation		##############################	--
begin	
	
	--Cycle is active for registers
	wbs_reg_cyc_proc:
	wbs_reg_cyc	<=	wbs_cyc_i and wbs_tgc_i;
	
	--Cycle is active for components
	wbs_cmp_cyc_proc:
	wbs_cmp_cyc	<=	wbs_cyc_i and (not wbs_tgc_i);
	
	--Strobe is active for registers
	wbs_reg_stb_proc:
	wbs_reg_stb	<=	wbs_stb_i and wbs_tgc_i;
	
	--Strobe is active for components
	wbs_cmp_stb_proc:
	wbs_cmp_stb	<=	wbs_stb_i and (not wbs_tgc_i);
	
	--WBS_ACK_O
	wbs_ack_o_proc:
	wbs_ack_o	<= 	wbs_reg_ack_o when (wbs_reg_cyc = '1')
						else wbs_cmp_ack_o;
	
	--WBS_STALL_O
	wbs_stall_o_proc:
	wbs_stall_o	<=	wbs_reg_stall_o when (wbs_reg_cyc = '1')
						else wbs_cmp_stall_o;
	
	--MUX, to route addressed register data to the WBS
	wbs_reg_dout_proc:
	wbs_reg_dout	<=	type_reg_dout when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c)) 
						else cos_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = cos_reg_addr_c + 1))      		--top 8 bits
						else cos_reg_dout(reg_width_c - 1 downto 0) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = cos_reg_addr_c))											--buttom 8 bits 
						else sin_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = sin_reg_addr_c + 1))      		--top 8 bits
						else sin_reg_dout(reg_width_c - 1 downto 0) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = sin_reg_addr_c))											--buttom 8 bits 
						else x_start_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = x_start_reg_addr_c + 1))		--top 8 bits
						else x_start_reg_dout(reg_width_c - 1 downto 0) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = x_start_reg_addr_c))                                     --buttom 8 bits 
						else y_start_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = y_start_reg_addr_c + 1))		--top 8 bits
						else y_start_reg_dout(reg_width_c - 1 downto 0) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = y_start_reg_addr_c))                                     --buttom 8 bits 
						else zoom_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = zoom_reg_addr_c + 1))		--top 8 bits
						else zoom_reg_dout(reg_width_c - 1 downto 0) when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = zoom_reg_addr_c))                                     --buttom 8 bits 
						else (others => '0');

	--MUX, to route addressed register dout_valid to the WBS
	wbs_reg_dout_valid_proc:
	wbs_reg_dout_valid	<=	sin_reg_dout_valid(0) or sin_reg_dout_valid(1) or cos_reg_dout_valid(0) or cos_reg_dout_valid(1) or x_start_reg_dout_valid(0) or x_start_reg_dout_valid(1) or y_start_reg_dout_valid(0) or y_start_reg_dout_valid(1) or zoom_reg_dout_valid(1) or zoom_reg_dout_valid(0) or type_reg_dout_valid ;
	
	--MUX, to route addressed register din_ack to the WBS
	wbs_reg_din_ack_proc:
	wbs_reg_din_ack	<=sin_reg_din_ack(0) or sin_reg_din_ack(1) or	cos_reg_din_ack(0) or cos_reg_din_ack(1) or x_start_reg_din_ack(0) or x_start_reg_din_ack(1) or y_start_reg_din_ack(0) or y_start_reg_din_ack(1) or zoom_reg_din_ack(0) or zoom_reg_din_ack(1) or type_reg_din_ack;
	
	--Read Enables processes:
	type_reg_rd_en_proc:
	type_reg_rd_en	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	zoom_reg_rd_en_1proc:
	zoom_reg_rd_en(1)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = zoom_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	zoom_reg_rd_en_proc:
	zoom_reg_rd_en(0)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = zoom_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	
	cos_reg_rd_en_1proc:
	cos_reg_rd_en(1)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = cos_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	cos_reg_rd_en_proc:
	cos_reg_rd_en(0)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = cos_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	sin_reg_rd_en_1proc:
	sin_reg_rd_en(1)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = sin_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	sin_reg_rd_en_proc:
	sin_reg_rd_en(0)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = sin_reg_addr_c) and (reg_rd_en = '1')
						else '0';					
	
	x_start_reg_rd_en_1proc:
	x_start_reg_rd_en(1)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = x_start_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	x_start_reg_rd_en_proc:
	x_start_reg_rd_en(0)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = x_start_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	
	y_start_reg_rd_en_1proc:
	y_start_reg_rd_en(1)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = y_start_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	y_start_reg_rd_en_proc:
	y_start_reg_rd_en(0)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = y_start_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	
	reset_proc: process ( system_rst)
	begin
		if (system_rst = reset_polarity_g) then
			wbs_dat_o			<=(others => '0');
			wbs_stall_o			<='0';						
			wbs_ack_o			<='0';						
			wbs_err_o			<='0';		
		end if	;
	end process reset_proc;	
							
--	---------------------------------------------------------------------------------------
--	----------------------------	Bank value process	-----------------------------------
--	---------------------------------------------------------------------------------------
--	-- The process switches between the two double banks when fine image has been received.
--	---------------------------------------------------------------------------------------
--	bank_val_proc: process (system_clk, system_rst)
--	begin
--		if (system_rst = reset_polarity_g) then
--			bank_val <= '0';
--			rd_bank_val <= '1';
--		elsif rising_edge (system_clk) then
--			if (bank_switch = '1') then
--				bank_val <= not bank_val;
--				rd_bank_val <= not rd_bank_val;
--			else
--				bank_val <= bank_val;
--				rd_bank_val <= rd_bank_val;
--			end if;
--		end if;
--	end process bank_val_proc;
	
--	###########################		Instances		##############################	--
	
	img_man_manager_inst : img_man_manager 
	generic map 
				(reset_polarity_g => reset_polarity_g,
				display_hor_pixels_g=>display_ver_pixels_g,--works for old counter process
				display_ver_pixels_g=>display_hor_pixels_g
				--	display_hor_pixels_g=>display_hor_pixels_g,
				--    display_ver_pixels_g=>display_ver_pixels_g
				)
	port map(
			sys_clk				=>	system_clk,				-- clock
			sys_rst				=>	system_rst,				-- Reset
			req_trig			=>	req_trig,		-- Trigger for image manipulation to begin,
            
			--from addr_calc
			
			
			addr_row_idx_in			=>  im_addr_row_idx_in,		--to address calculator
			addr_col_idx_in			=>  im_addr_col_idx_in	,	--to address calculator                        
			addr_tl_out				=>  im_addr_tl_out,			--from address calculator
			addr_bl_out				=>  im_addr_bl_out,			--from address calculator
			addr_delta_row_out		=>  im_addr_delta_row_out,	--from address calculator
			addr_delta_col_out		=>  im_addr_delta_col_out,	--from address calculator											
			addr_out_of_range		=>  im_addr_out_of_range,	--from address calculator
			addr_data_valid_out		=>  im_addr_data_valid_out,	--from address calculator 											
			addr_unit_finish		=>  im_addr_unit_finish,	--from address calculator
			addr_trigger_unit		=>  im_addr_trigger_unit,	
			addr_enable				=>	im_addr_enable,
			-- bilinear
			bili_req_trig			=>	 bilinear_req_trig	 ,
			bili_tl_pixel			=>	 bilinear_tl_pixel	 ,
			bili_tr_pixel			=>	 bilinear_tr_pixel	 ,
			bili_bl_pixel           =>	 bilinear_bl_pixel   ,
			bili_br_pixel           =>	 bilinear_br_pixel   ,
			bili_delta_row			=>	 bilinear_delta_row	 ,
			bili_delta_col			=>	 bilinear_delta_col	 ,
			bili_pixel_valid		=>	 bilinear_pixel_valid,
			bili_pixel_res			=>	 bilinear_pixel_res	 ,
			
			-- Wishbone Master (mem_ctrl_wr)
			wr_wbm_adr_o		=>	    wr_wbm_adr_o	,
			wr_wbm_tga_o		=>	    wr_wbm_tga_o	,
			wr_wbm_dat_o		=>	    wr_wbm_dat_o	,
			wr_wbm_cyc_o		=>	    wr_wbm_cyc_o	,
			wr_wbm_stb_o		=>	    wr_wbm_stb_o	,
			wr_wbm_we_o			=>	    wr_wbm_we_o		,
			wr_wbm_tgc_o		=>	    wr_wbm_tgc_o	,
			wr_wbm_dat_i		=>	    wr_wbm_dat_i	,
			wr_wbm_stall_i		=>	    wr_wbm_stall_i	,
			wr_wbm_ack_i		=>	    wr_wbm_ack_i	,
			wr_wbm_err_i		=>	    wr_wbm_err_i	,
			                                            
			-- Wishbone Master (mem_ctrl-- Wishbone Mast'rd)
			rd_wbm_adr_o 		=>	    rd_wbm_adr_o 	,
			rd_wbm_tga_o 		=>      rd_wbm_tga_o 	,
			rd_wbm_cyc_o		=>      rd_wbm_cyc_o	,
			rd_wbm_tgc_o 		=>      rd_wbm_tgc_o 	,
			rd_wbm_stb_o		=>      rd_wbm_stb_o	,
			rd_wbm_dat_i		=>      rd_wbm_dat_i	,
			rd_wbm_stall_i		=>	    rd_wbm_stall_i	,
			rd_wbm_ack_i		=>      rd_wbm_ack_i	,
			rd_wbm_err_i		=>      rd_wbm_err_i	
	);
	
	addr_calc_inst	:	addr_calc	
	generic map (
				reset_polarity_g		=> '0',				--Reset active low
				x_size_in_g				=> img_ver_pixels_g,	-- number of rows  in the input image
				y_size_in_g				=> img_hor_pixels_g,	-- number of columns  in the input image
				x_size_out_g			=> 600,				-- number of rows  in theoutput image
				y_size_out_g			=> 800,				-- number of columns  in the output image
				trig_frac_size_g		=> 7,				-- number of digits after dot = resolution of fracture (binary)
				pipe_depth_g			=> 12,				-- 
				valid_setup_g			=> 10
	)
	port map(
			
			-- zoom_factor			=>	signed(zoom_reg_dout(trig_frac_size_g+1 downto 0)),	--from register --std_logic_vector int signed
			-- sin_teta			=>  signed(sin_reg_dout(trig_frac_size_g+1 downto 0)),	--from register --std_logic_vector int signed
			-- cos_teta			=>  signed(cos_reg_dout(trig_frac_size_g+1 downto 0)) , --from register --std_logic_vector int signed             
			-- x_crop_start	 	=>	signed(x_start_reg_dout(10 downto 0)),
			-- y_crop_start		=>  signed(y_start_reg_dout(10 downto 0)),
			row_idx_in			=>	im_addr_row_idx_in,	--from manager
			col_idx_in			=>	im_addr_col_idx_in,	--from manager
			
			zoom_factor			=>	"010000000",
			-- sin_teta			=>	"000000000",--0 degrees
			-- cos_teta			=>	"010000000",
			sin_teta			=>	"001101110",--60 degreed
			cos_teta			=>	"001000000", 			
			x_crop_start	 	=>	"00000000001",
			y_crop_start		=>	"00000000001",
			--row_idx_in			=>	"00100101101",
			--col_idx_in			=>	"00100101101",
			
			ram_start_add_in	=> (others => '0'),
			                     
            tl_out				=> im_addr_tl_out,
			tr_out				=> addr_tr_out_garbage	,			
			bl_out				=> im_addr_bl_out,
			br_out				=> addr_br_out_garbage,
			delta_row_out		=> im_addr_delta_row_out,
			delta_col_out		=> im_addr_delta_col_out,
			                    
			out_of_range		=> im_addr_out_of_range,
			data_valid_out		=> im_addr_data_valid_out,
			                    
			--CLK, RESET, ENABLE
			enable				=> im_addr_enable,    	--enable unit port           
			unit_finish			=> im_addr_unit_finish, 
			trigger_unit		=> im_addr_trigger_unit,
			system_clk			=> system_clk,
			system_rst			=> system_rst
	); 

	bilinear_inst: bilinear 
	generic map(
			reset_polarity_g		=>'0',			--Reset active low
			pipeline_depth_g		=>4,
			trig_frac_size_g		=>7				-- number of digits after dot = resolution of fracture (binary)

	)
	port map(
			--Clock and Reset 
			sys_clk				=>	system_clk,				-- clock
			sys_rst				=>	system_rst,				-- Reset
			req_trig			=>	bilinear_req_trig,			-- Trigger for image manipulation to begin,
			--from img_manger
			tl_pixel			=>        bilinear_tl_pixel,	
			tr_pixel			=>        bilinear_tr_pixel,	
			bl_pixel            =>        bilinear_bl_pixel,	
			br_pixel            =>        bilinear_br_pixel,   
			--from img_manger                
			delta_row			=>        bilinear_delta_row,	
			delta_col			=>        bilinear_delta_col,	
             --result                     
			pixel_valid			=>        bilinear_pixel_valid,
			pixel_res			=>        bilinear_pixel_res	
			
	);

	
	gen_reg_type_inst	:	gen_reg 
	generic map (
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
	port map(
			clk					=>	system_clk,
			reset		        =>	system_rst,
			addr		        =>	reg_addr,
			din			        =>	reg_din,
			wr_en		        =>	reg_wr_en,
			clear		        =>	'0',
			din_ack		        =>	type_reg_din_ack,
			rd_en				=>	type_reg_rd_en,
			dout		        =>	type_reg_dout,
			dout_valid	        =>	type_reg_dout_valid
	);
									

	cos_reg_generate:
	for idx in (param_reg_depth_c - 1) downto 0 generate
		gen_reg_dbg_inst	:	gen_reg 
		generic map (
					reset_polarity_g	=>	reset_polarity_g,	
					width_g				=>	reg_width_c,
					addr_en_g			=>	true,
					addr_val_g			=>	(cos_reg_addr_c + idx),
					addr_width_g		=>	reg_addr_width_c,
					read_en_g			=>	true,
					write_en_g			=>	true,
					clear_on_read_g		=>	false,
					default_value_g		=>	0
		)
		port map(
				clk					=>	system_clk,
				reset		        =>	system_rst,
				addr		        =>	reg_addr,
				din			        =>	reg_din,
				wr_en		        =>	reg_wr_en,
				clear		        =>	'0',
                din_ack		        =>	cos_reg_din_ack (idx),
                rd_en				=>	cos_reg_rd_en (idx),
                dout		        =>	cos_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
                dout_valid	        =>	cos_reg_dout_valid (idx)
		);
	end generate cos_reg_generate;
	
	sin_reg_generate:
	for idx in (param_reg_depth_c - 1) downto 0 generate
		gen_reg_dbg_inst	:	gen_reg 
		generic map (
					reset_polarity_g	=>	reset_polarity_g,	
					width_g				=>	reg_width_c,
					addr_en_g			=>	true,
					addr_val_g			=>	(sin_reg_addr_c + idx),
					addr_width_g		=>	reg_addr_width_c,
					read_en_g			=>	true,
					write_en_g			=>	true,
					clear_on_read_g		=>	false,
					default_value_g		=>	0
		)
		port map (
		clk					=>	system_clk,
		reset		        =>	system_rst,
		addr		        =>	reg_addr,
		din			        =>	reg_din,
		wr_en		        =>	reg_wr_en,
		clear		        =>	'0',
        din_ack		        =>	sin_reg_din_ack (idx),
        rd_en				=>	sin_reg_rd_en (idx),
        dout		        =>	sin_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
        dout_valid	        =>	sin_reg_dout_valid (idx)
		);
	end generate sin_reg_generate;
	
	x_start_reg_generate:
	for idx in (param_reg_depth_c - 1) downto 0 generate
		gen_reg_dbg_inst	:	gen_reg 
		generic map (
					reset_polarity_g	=>	reset_polarity_g,	
					width_g				=>	reg_width_c,
					addr_en_g			=>	true,
					addr_val_g			=>	(x_start_reg_addr_c + idx),
					addr_width_g		=>	reg_addr_width_c,
					read_en_g			=>	true,
					write_en_g			=>	true,
					clear_on_read_g		=>	false,
					default_value_g		=>	0
		)
		port map (
				clk					=>	system_clk,
				reset		        =>	system_rst,
				addr		        =>	reg_addr,
				din			        =>	reg_din,
				wr_en		        =>	reg_wr_en,
				clear		        =>	'0',
                din_ack		        =>	x_start_reg_din_ack (idx),
                rd_en				=>	x_start_reg_rd_en (idx),
                dout		        =>	x_start_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
                dout_valid	        =>	x_start_reg_dout_valid (idx)
		);
	end generate x_start_reg_generate;
	
	y_start_reg_generate:
	for idx in (param_reg_depth_c - 1) downto 0 generate
		gen_reg_dbg_inst	:	gen_reg 
		generic map (
					reset_polarity_g	=>	reset_polarity_g,	
					width_g				=>	reg_width_c,
					addr_en_g			=>	true,
					addr_val_g			=>	(y_start_reg_addr_c + idx),
					addr_width_g		=>	reg_addr_width_c,
					read_en_g			=>	true,
					write_en_g			=>	true,
					clear_on_read_g		=>	false,
					default_value_g		=>	0
		)
		port map (
				clk					=>	system_clk,
				reset		        =>	system_rst,
				addr		        =>	reg_addr,
				din			        =>	reg_din,
				wr_en		        =>	reg_wr_en,
				clear		        =>	'0',
                din_ack		        =>	y_start_reg_din_ack (idx),
                rd_en				=>	y_start_reg_rd_en (idx),
                dout		        =>	y_start_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
                dout_valid	        =>	y_start_reg_dout_valid (idx)
		);
	end generate y_start_reg_generate;

	zoom_reg_generate:
	for idx in (param_reg_depth_c - 1) downto 0 generate
		gen_reg_dbg_inst	:	gen_reg 
		generic map (
					reset_polarity_g	=>	reset_polarity_g,	
					width_g				=>	reg_width_c,
					addr_en_g			=>	true,
					addr_val_g			=>	(zoom_reg_addr_c + idx),
					addr_width_g		=>	reg_addr_width_c,
					read_en_g			=>	true,
					write_en_g			=>	true,
					clear_on_read_g		=>	false,
					default_value_g		=>	0
		)
		port map (
				clk					=>	system_clk,
				reset		        =>	system_rst,
				addr		        =>	reg_addr,
				din			        =>	reg_din,
				wr_en		        =>	reg_wr_en,
				clear		        =>	'0',
                din_ack		        =>	zoom_reg_din_ack (idx),
                rd_en				=>	zoom_reg_rd_en (idx),
                dout		        =>	zoom_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
                dout_valid	        =>	zoom_reg_dout_valid (idx)
		);
	end generate zoom_reg_generate;	


	
	wbs_reg_inst	:	wbs_reg 
	generic map (
				reset_polarity_g=>	reset_polarity_g,
				width_g			=>	reg_width_c,
				addr_width_g	=>	reg_addr_width_c
	)
	port map (
			rst				=>	system_rst,
			clk_i			=> 	system_clk,
			wbs_cyc_i	    =>	wbs_reg_cyc,
			wbs_stb_i	    => 	wbs_reg_stb,
			wbs_adr_i	    =>	wbs_adr_i (reg_addr_width_c - 1 downto 0), 
			wbs_we_i	    => 	wbs_we_i,
			wbs_dat_i	    => 	wbs_dat_i,
			wbs_dat_o	    => 	wbs_dat_o,
			wbs_ack_o	    => 	wbs_reg_ack_o,
			wbs_stall_o		=>	wbs_reg_stall_o,
			
			din_ack			=>	wbs_reg_din_ack,
			dout		    =>	wbs_reg_dout,
			dout_valid	    =>	wbs_reg_dout_valid,
			addr		    =>	reg_addr,
			din			    =>	reg_din,
			rd_en		    =>	reg_rd_en,
			wr_en		    =>	reg_wr_en
	);
	
end architecture rtl_img_man_top;