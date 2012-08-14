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
--					

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
				img_hor_pixels_g	:	positive					:= 640;	--640 active pixels
				img_ver_lines_g		:	positive					:= 480	--480 active lines
			);
	port	(
				--Clock and Reset
				clk_i				:	in std_logic;							--Wishbone clock
				rst					:	in std_logic;							--Reset

				-- Wishbone Slave 
				wr_wbs_adr_i		:	in std_logic_vector (9 downto 0);		--Address in internal RAM
				wr_wbs_tga_i		:	in std_logic_vector (9 downto 0);		--Burst Length
				wr_wbs_dat_i		:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
				wr_wbs_cyc_i		:	in std_logic;							--Cycle command from WBM
				wr_wbs_stb_i		:	in std_logic;							--Strobe command from WBM
				wr_wbs_we_i			:	in std_logic;							--Write Enable
				wr_wbs_tgc_i		:	in std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wr_wbs_dat_o		:	out std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wr_wbs_stall_o		:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wr_wbs_ack_o		:	out std_logic;							--Input data has been successfuly acknowledged
				wr_wbs_err_o		:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				-- Wishbone Master 
				wbm_dat_i			:	in std_logic_vector (15 downto 0);		--Data in (16 bits)
				wbm_stall_i			:	in std_logic;							--Slave is not ready to receive new data
				wbm_err_i			:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
				wbm_ack_i			:	in std_logic;							--When Read Burst: DATA bus must be valid in this cycle
				wbm_adr_o			:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
				wbm_dat_o			:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
				wbm_we_o			:	out std_logic;							--Write Enable
				wbm_tga_o			:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
				wbm_cyc_o			:	out std_logic;							--Cycle Command to interface
				wbm_stb_o			:	out std_logic							--Strobe Command to interface
			);
end entity img_man_top;

architecture rtl_img_man_top of img_man_top is

--	###########################		Costants		##############################	--
	constant reg_width_c		:	positive 	:= 8;	--Width of registers
	constant param_reg_depth_c	:	positive 	:= 2;	--Depth of registers 2*8 = 16 bits
	constant reg_addr_width_c	:	positive 	:= 5;	--Width of registers' address
	constant type_reg_addr_c	:	natural		:= 1;	--Type register address
	constant cos_reg_addr_c		:	natural		:= 20;	--Cosine of Angle register address	
	constant sin_reg_addr_c		:	natural		:= 22;	--Sine of Angle register address
	constant x_start_reg_addr_c	:	natural		:= 14;	--x_start register address
	constant y_start_reg_addr_c	:	natural		:= 16;	--y_start register address
	constant zoom_reg_addr_c	:	natural		:= 18;	--Zoom register address

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





--	###########################		Signals		##############################	--

-- Logic signals, derived from Wishbone Slave (mem_ctrl_wr)
signal wr_wbs_reg_cyc		:	std_logic;						--'1': Cycle to register is active
signal wr_wbs_cmp_cyc		:	std_logic;						--'1': Cycle to component is active
signal wbs_reg_dout			:	std_logic_vector (7 downto 0);	--Output data from Registers
signal wbs_reg_dout_valid	:	std_logic;						--Dout valid for registers
signal wbs_reg_din_ack    	:   std_logic;						--Din has been acknowledeged by registers
signal wbs_cmp_ack_o		:	std_logic;						--WBS_ACK_O from component
signal wbs_reg_ack_o		:	std_logic;						--WBS_ACK_O from registers
signal wbs_cmp_stall_o		:	std_logic;						--WBS_STALL_O from component
signal wbs_reg_stall_o		:	std_logic;						--WBS_STALL_O from registers
signal wr_wbs_cmp_stb		:	std_logic;						--WBS_STB_O to component
signal wr_wbs_reg_stb		:	std_logic;						--WBS_STB_O to registers

-- Wishbone Master signals from Mem_Ctrl_Rd to Arbiter
signal rd_wbm_adr_o	:	std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)	
signal rd_wbm_dat_i	:   std_logic_vector (15 downto 0);		--Data In (16 bits)
signal rd_wbm_we_o	:	std_logic;							--Write Enable
signal rd_wbm_tga_o	:   std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
signal rd_wbm_cyc_o	:   std_logic;							--Cycle Command to interface
signal rd_wbm_stb_o	:   std_logic;							--Strobe Command to interface
signal rd_wbm_stall_i:	std_logic;							--Slave is not ready to receive new data
signal rd_wbm_err_i	:   std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
signal rd_wbm_ack_i	:   std_logic;							--When Read Burst: DATA bus must be valid in this cycle

---- Wr_Rd_Bank signals
--signal wr_bank_val	:	std_logic; 							--Wr_Bank value
--signal rd_bank_val	:	std_logic;					 		--Rd_Bank value
--signal bank_switch	:	std_logic;							--Signals the Wr_Rd_Bank to switch between banks

---- Mem_Ctrl_Read signals
--signal wr_cnt_val	:	std_logic_vector(integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))) - 1 downto 0);	--wr_cnt value
--signal wr_cnt_en	:	std_logic;							--wr_cnt write enable flag (Active for 1 clock)

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


--	###########################		Implementation		##############################	--
begin	
	
	--Cycle is active for registers
	wr_wbs_reg_cyc_proc:
	wr_wbs_reg_cyc	<=	wr_wbs_cyc_i and wr_wbs_tgc_i;
	
	--Cycle is active for components
	wr_wbs_cmp_cyc_proc:
	wr_wbs_cmp_cyc	<=	wr_wbs_cyc_i and (not wr_wbs_tgc_i);
	
	--Strobe is active for registers
	wr_wbs_reg_stb_proc:
	wr_wbs_reg_stb	<=	wr_wbs_stb_i and wr_wbs_tgc_i;
	
	--Strobe is active for components
	wr_wbs_cmp_stb_proc:
	wr_wbs_cmp_stb	<=	wr_wbs_stb_i and (not wr_wbs_tgc_i);
	
	--WBS_ACK_O
	wr_wbs_ack_o_proc:
	wr_wbs_ack_o	<= 	wbs_reg_ack_o when (wr_wbs_reg_cyc = '1')
						else wbs_cmp_ack_o;
	
	--WBS_STALL_O
	wr_wbs_stall_o_proc:
	wr_wbs_stall_o	<=	wbs_reg_stall_o when (wr_wbs_reg_cyc = '1')
						else wbs_cmp_stall_o;
	
	--MUX, to route addressed register data to the WBS
	wbs_reg_dout_proc:
	wbs_reg_dout	<=	type_reg_dout when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c)) 
						else cos_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = cos_reg_addr_c + 1))      		--top 8 bits
						else cos_reg_dout(reg_width_c - 1 downto 0) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = cos_reg_addr_c))											--buttom 8 bits 
						else sin_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = sin_reg_addr_c + 1))      		--top 8 bits
						else sin_reg_dout(reg_width_c - 1 downto 0) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = sin_reg_addr_c))											--buttom 8 bits 
						else x_start_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = x_start_reg_addr_c + 1))		--top 8 bits
						else x_start_reg_dout(reg_width_c - 1 downto 0) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = x_start_reg_addr_c))                                     --buttom 8 bits 
						else y_start_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = y_start_reg_addr_c + 1))		--top 8 bits
						else y_start_reg_dout(reg_width_c - 1 downto 0) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = y_start_reg_addr_c))                                     --buttom 8 bits 
						else zoom_reg_dout(param_reg_depth_c * reg_width_c - 1 downto reg_width_c) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = zoom_reg_addr_c + 1))		--top 8 bits
						else zoom_reg_dout(reg_width_c - 1 downto 0) when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = zoom_reg_addr_c))                                     --buttom 8 bits 
						else (others => '0');

	--MUX, to route addressed register dout_valid to the WBS
	wbs_reg_dout_valid_proc:
	wbs_reg_dout_valid	<=	sin_reg_dout_valid(0) or sin_reg_dout_valid(1) or cos_reg_dout_valid(0) or cos_reg_dout_valid(1) or x_start_reg_dout_valid(0) or x_start_reg_dout_valid(1) or y_start_reg_dout_valid(0) or y_start_reg_dout_valid(1) or zoom_reg_dout_valid(1) or zoom_reg_dout_valid(0) or type_reg_dout_valid ;
	
	--MUX, to route addressed register din_ack to the WBS
	wbs_reg_din_ack_proc:
	wbs_reg_din_ack	<=sin_reg_din_ack(0) or sin_reg_din_ack(1) or	cos_reg_din_ack(0) or cos_reg_din_ack(1) or x_start_reg_din_ack(0) or x_start_reg_din_ack(1) or y_start_reg_din_ack(0) or y_start_reg_din_ack(1) or zoom_reg_din_ack(0) or zoom_reg_din_ack(1) or type_reg_din_ack;
	
	--Read Enables processes:
	type_reg_rd_en_proc:
	type_reg_rd_en	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	zoom_reg_rd_en_1proc:
	zoom_reg_rd_en(1)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = zoom_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	zoom_reg_rd_en_proc:
	zoom_reg_rd_en(0)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = zoom_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	
	cos_reg_rd_en_1proc:
	cos_reg_rd_en(1)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = cos_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	cos_reg_rd_en_proc:
	cos_reg_rd_en(0)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = cos_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	sin_reg_rd_en_1proc:
	sin_reg_rd_en(1)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = sin_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	sin_reg_rd_en_proc:
	sin_reg_rd_en(0)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = sin_reg_addr_c) and (reg_rd_en = '1')
						else '0';					
	
	x_start_reg_rd_en_1proc:
	x_start_reg_rd_en(1)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = x_start_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	x_start_reg_rd_en_proc:
	x_start_reg_rd_en(0)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = x_start_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	
	y_start_reg_rd_en_1proc:
	y_start_reg_rd_en(1)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = y_start_reg_addr_c +1) and (reg_rd_en = '1')
						else '0';
	y_start_reg_rd_en_proc:
	y_start_reg_rd_en(0)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = y_start_reg_addr_c) and (reg_rd_en = '1')
						else '0';
	

							
--	---------------------------------------------------------------------------------------
--	----------------------------	Bank value process	-----------------------------------
--	---------------------------------------------------------------------------------------
--	-- The process switches between the two double banks when fine image has been received.
--	---------------------------------------------------------------------------------------
--	bank_val_proc: process (clk_i, rst)
--	begin
--		if (rst = reset_polarity_g) then
--			wr_bank_val <= '0';
--			rd_bank_val <= '1';
--		elsif rising_edge (clk_i) then
--			if (bank_switch = '1') then
--				wr_bank_val <= not wr_bank_val;
--				rd_bank_val <= not rd_bank_val;
--			else
--				wr_bank_val <= wr_bank_val;
--				rd_bank_val <= rd_bank_val;
--			end if;
--		end if;
--	end process bank_val_proc;
	
--	###########################		Instances		##############################	--
			
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
										clk					=>	clk_i,
									    reset		        =>	rst,
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
		gen_reg_dbg_inst	:	gen_reg generic map (
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
									port map (
										clk					=>	clk_i,
									    reset		        =>	rst,
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
		gen_reg_dbg_inst	:	gen_reg generic map (
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
										clk					=>	clk_i,
									    reset		        =>	rst,
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
		gen_reg_dbg_inst	:	gen_reg generic map (
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
										clk					=>	clk_i,
									    reset		        =>	rst,
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
		gen_reg_dbg_inst	:	gen_reg generic map (
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
										clk					=>	clk_i,
									    reset		        =>	rst,
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
		gen_reg_dbg_inst	:	gen_reg generic map (
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
										clk					=>	clk_i,
									    reset		        =>	rst,
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


	
	wbs_reg_inst	:	wbs_reg generic map (
										reset_polarity_g=>	reset_polarity_g,
										width_g			=>	reg_width_c,
										addr_width_g	=>	reg_addr_width_c
									)
									port map (
										rst				=>	rst,
										clk_i			=> 	clk_i,
									    wbs_cyc_i	    =>	wr_wbs_reg_cyc,
									    wbs_stb_i	    => 	wr_wbs_reg_stb,
									    wbs_adr_i	    =>	wr_wbs_adr_i (reg_addr_width_c - 1 downto 0), 
									    wbs_we_i	    => 	wr_wbs_we_i,
									    wbs_dat_i	    => 	wr_wbs_dat_i,
									    wbs_dat_o	    => 	wr_wbs_dat_o,
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