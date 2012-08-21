------------------------------------------------------------------------------------------------
-- Model Name 	:	Image Manipulation Manager (FSM)
-- File Name	:	img_man_manager.vhd
-- Generated	:	21.08.2012
-- Author		:	Uri Tzipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   Manager for Image manipulation Block
--					FSM for the image manipulation procces
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		21.08.2012	Uri					creation
--					

------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work ;

entity img_man_manager is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				img_hor_pixels_g	:	positive					:= 640;	--640 pixel in a coloum
				img_ver_lines_g		:	positive					:= 480	--480 pixels in a row
			);
	port	(
				--Clock and Reset
				clk_i				:	in std_logic;							--Wishbone clock
				rst					:	in std_logic;							--Reset

				
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
				wbs_err_o			:	out std_logic							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
			
			);
end entity img_man_manager;

architecture rtl_img_man_manager of img_man_manager is

--	###########################		Costants		##############################	--
	constant num_pixels_c		:	positive 	:= img_hor_pixels_g * img_ver_lines_g;	--Number of pixels
	constant col_reg_width_c	:	positive 	:= integer(ceil(log(real(img_hor_pixels_g)) / log(2.0))) ; --Width of registers for coloum index
	constant row_reg_width_c	:	positive 	:= integer(ceil(log(real(img_ver_pixels_g)) / log(2.0))) ; --Width of registers for row index
	constant param_reg_depth_c	:	positive 	:= 1;	--Depth of registers 1*width
	constant reg_addr_width_c	:	positive 	:= 5;	--Width of registers' address
	constant row_reg_addr_c		:	natural		:= 24;	--Zoom register address
	constant col_reg_addr_c		:	natural		:= 26;	--Zoom register address

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

--	###########################		Signals		##############################	--

--Zoom register signals
signal zoom_reg_din_ack			:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Data has been acknowledged
signal zoom_reg_rd_en			:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Read Enable
signal zoom_reg_dout			:	std_logic_vector (param_reg_depth_c * reg_width_c - 1 downto 0);	--Output data
signal zoom_reg_dout_valid		:	std_logic_vector (param_reg_depth_c - 1 downto 0);					--Output data is valid

----------------------------------FSM-------------------------------------
------------------------------	Types	------------------------------------
	type fsm_states is (
							fsm_idle_st,			-- Idle - wait to start 
							fsm_create_crd_st, 		-- initialize coordinate registers to (0,0) or (1,1)??
							fsm_advance_crd_st,		-- advance cordinate by 1, if line is over move to next line
							fsm_address_calc_st,	-- send coordinates to Address Calc, if out of range WB BLACK_PIXEL(0) else continue
							fsm_READ_from_SDRAM_st, -- read 4 pixels from SDRAM according to result of addr_calc
							fsm_bilinear_st,		-- do a bilinear interpolation between the 4 pixels
							fsm_WB_to_SDRAM_st,		-- Write Back result to SDRAM
						);

--	###########################		Implementation		##############################	--
begin	
	
	
							
--	---------------------------------------------------------------------------------------
--	----------------------------	Bank value process	-----------------------------------
--	---------------------------------------------------------------------------------------
--	-- The process switches between the two double banks when fine image has been received.
--	---------------------------------------------------------------------------------------
--	bank_val_proc: process (clk_i, rst)
--	begin
--		if (rst = reset_polarity_g) then
--			bank_val <= '0';
--			rd_bank_val <= '1';
--		elsif rising_edge (clk_i) then
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
	
	row_reg_generate:
	for idx in (param_reg_depth_c - 1) downto 0 generate
		gen_reg_dbg_inst	:	gen_reg generic map (
										reset_polarity_g	=>	reset_polarity_g,	
										width_g				=>	reg_width_c,
										addr_en_g			=>	true,
										addr_val_g			=>	(row_reg_addr_c + idx),
										addr_width_g		=>	reg_addr_width_c,
										read_en_g			=>	true,
										write_en_g			=>	true,
										clear_on_read_g		=>	false,
										default_value_g		=>	0
									)
									port map (
										clk					=>	clk_i,
									    reset		        =>	rst,
									    addr		        =>	reg_addr,
									    din			        =>	reg_din,
									    wr_en		        =>	reg_wr_en,
									    clear		        =>	'0',
                                        din_ack		        =>	row_reg_din_ack (idx),
                                        rd_en				=>	row_reg_rd_en (idx),
                                        dout		        =>	row_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
                                        dout_valid	        =>	row_reg_dout_valid (idx)
									);
	end generate row_reg_generate;	
	
	col_reg_generate:
	for idx in (param_reg_depth_c - 1) downto 0 generate
		gen_reg_dbg_inst	:	gen_reg generic map (
										reset_polarity_g	=>	reset_polarity_g,	
										width_g				=>	reg_width_c,
										addr_en_g			=>	true,
										addr_val_g			=>	(col_reg_addr_c + idx),
										addr_width_g		=>	reg_addr_width_c,
										read_en_g			=>	true,
										write_en_g			=>	true,
										clear_on_read_g		=>	false,
										default_value_g		=>	0
									)
									port map (
										clk					=>	clk_i,
									    reset		        =>	rst,
									    addr		        =>	reg_addr,
									    din			        =>	reg_din,
									    wr_en		        =>	reg_wr_en,
									    clear		        =>	'0',
                                        din_ack		        =>	col_reg_din_ack (idx),
                                        rd_en				=>	col_reg_rd_en (idx),
                                        dout		        =>	col_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
                                        dout_valid	        =>	col_reg_dout_valid (idx)
									);
	end generate col_reg_generate;

end architecture rtl_img_man_manager;