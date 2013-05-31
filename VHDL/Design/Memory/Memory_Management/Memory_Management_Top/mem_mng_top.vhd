------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Management
-- File Name	:	mem_mng_top.vhd
-- Generated	:	10.5.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Memory Management
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		10.5.2011	Beeri Schreiber			Creation
--			1.10		13.2.2012	Beeri Schreiber			Added another clock domain
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity mem_mng_top is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				mode_g				:	natural range 0 to 7 		:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
				message_g			:	natural range 0 to 7 		:= 1;	--Relevant bit in type register, which represent Image chunk ('0') or Summary chunk ('1') mode
				img_hor_pixels_g	:	positive					:= 256;	--256 active pixels
				img_ver_lines_g		:	positive					:= 192	--192 active lines
			);
	port	(
				-- Clocks and Reset 
				clk_sdram			:	in std_logic;	--Wishbone input clock for SDRAM (133MHz)
				clk_sys				:	in std_logic;	--System clock
				rst_sdram			:	in std_logic;	--Reset for SDRAM Clock domain
				rst_sys				:	in std_logic;	--Reset for System Clock domain
				manipulation_trig	:	out std_logic;	--trigger image manipulation when bank switch

				-- Wishbone Slave (mem_ctrl_wr)
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

				-- Wishbone Slave (mem_ctrl_rd)
				rd_wbs_adr_i 		:	in std_logic_vector (9 downto 0);		--Address in internal RAM
				rd_wbs_tga_i 		:   in std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				rd_wbs_cyc_i		:   in std_logic;							--Cycle command from WBM
				rd_wbs_tgc_i 		:   in std_logic;							--Cycle tag. '1' indicates start of transaction
				rd_wbs_stb_i		:   in std_logic;							--Strobe command from WBM
				rd_wbs_dat_o 		:  	out std_logic_vector (7 downto 0);		--Data Out (8 bits)
				rd_wbs_stall_o		:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				rd_wbs_ack_o		:   out std_logic;							--Input data has been successfuly acknowledged
				rd_wbs_err_o		:   out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				-- Wishbone Master to SDRAM Controller from Arbiter
				wbm_dat_i			:	in std_logic_vector (15 downto 0);		--Data in (16 bits)
				wbm_stall_i			:	in std_logic;							--Slave is not ready to receive new data
				wbm_err_i			:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
				wbm_ack_i			:	in std_logic;							--When Read Burst: DATA bus must be valid in this cycle
				wbm_adr_o			:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
				wbm_dat_o			:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
				wbm_we_o			:	out std_logic;							--Write Enable
				wbm_tga_o			:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
				wbm_cyc_o			:	out std_logic;							--Cycle Command to interface
				wbm_stb_o			:	out std_logic;							--Strobe Command to interface

				--Debug Port
				dbg_type_reg		:	out std_logic_vector (7 downto 0);		--Type Register Value
				dbg_adrr_reg		:	out std_logic_vector (23 downto 0);		--debug Register Value
				dbg_wr_bank_val		:	out std_logic;							--Expected Write SDRAM Bank Value
				dbg_rd_bank_val     :	out std_logic;							--Expected Read SDRAM Bank Value
				dbg_actual_wr_bank	:	out std_logic;							--Actual read bank
				dbg_actual_rd_bank	:	out std_logic							--Actual Written bank
			);
end entity mem_mng_top;

architecture rtl_mem_mng_top of mem_mng_top is

--	###########################		Costants		##############################	--
	constant reg_width_c		:	positive 	:= 8;	--Width of registers
	constant reg_addr_width_c	:	positive 	:= 4;	--Width of registers' address
	constant dbg_reg_depth_c	:	positive	:= 3;	--3*8 = 24 bits
	constant type_reg_addr_c	:	natural		:= 13;	--Type register address (0xD)
	
	--Debug SDRAM register address range: 2-->4 (Total of 24 bits)
	constant dbg_reg_addr_c		:	natural		:= 2;	--Debug SDRAM address (read / write)

--	###########################		Components		##############################	--

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

component mem_ctrl_wr
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0';	--When rst = reset_polarity_g, system is in RESET mode
		mode_g				:	natural range 0 to 7 	:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
		message_g			:	natural range 0 to 7 	:= 1;	--Relevant bit in type register, which represent Image chunk ('0') or Summary chunk ('1') mode
		img_hor_pixels_g	:	positive				:= 256;	--256 activepixels
		img_ver_lines_g		:	positive				:= 192	--192 active lines
		);
  port (
		-- Clocks and Reset 
		clk_sdram	:	in std_logic;	--Wishbone input clock for SDRAM (133MHz)
		clk_sys		:	in std_logic;	--System clock
		rst_sdram	:	in std_logic;	--Reset for SDRAM Clock domain
		rst_sys		:	in std_logic;	--Reset for System Clock domain

		-- Wishbone Slave signals
		wbs_adr_i	:	in std_logic_vector (9 downto 0);		--Address in internal RAM
		wbs_tga_i	:	in std_logic_vector (9 downto 0);		--Burst length
		wbs_dat_i	:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
		wbs_cyc_i	:	in std_logic;							--Cycle command from WBM
		wbs_stb_i	:	in std_logic;							--Strobe command from WBM
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
		wbs_ack_o	:	out std_logic;							--Input data has been successfuly acknowledged
		wbs_err_o	:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
		
		-- Wishbone Master signals to SDRAM
		wbm_adr_o	:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbm_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbm_we_o	:	out std_logic;							--Write Enable
		wbm_tga_o	:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_cyc_o	:	out std_logic;							--Cycle Command to interface
		wbm_stb_o	:	out std_logic;							--Strobe Command to interface
		wbm_stall_i	:	in std_logic;							--Slave is not ready to receive new data
		wbm_err_i	:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbm_ack_i	:	in std_logic;							--When Read Burst: DATA bus must be valid in this cycle
		
		-- Arbiter signals
		arbiter_gnt	:	in std_logic;							--Grant control on SDRAM from Arbiter
		arbiter_req	:	out std_logic;							--Request for control on SDRAM from Arbiter

		-- Wr_Rd_Bank signals
		bank_val	:	in std_logic;							--Wr_Rd_Bank value
		bank_switch	:	out std_logic;							--Signals the Wr_Rd_Bank to switch between banks
		
		-- Signals from registers
		type_reg	:	in std_logic_vector (7 downto 0);		--Type Register
		wr_addr_reg	:	in std_logic_vector (21 downto 0);		--Write to SDRAM Address (Debug mode)
		
		-- Mem_Ctrl_Read signals
		wr_cnt_val	:	out std_logic_vector(integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))) - 1 downto 0);	--wr_cnt value
		wr_cnt_en	:	out std_logic;							--wr_cnt write enable flag (Active for 1 clock)
		
		--Debug Signals
		dbg_wr_bank	:	out std_logic							--Current bank, which is written to.
		); 
end component mem_ctrl_wr;

component mem_ctrl_rd
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0';	--When rst = reset_polarity_g, system is in RESET mode
		mode_g				:	natural range 0 to 7 	:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
		img_hor_pixels_g	:	positive				:= 256;	--256 activepixels
		img_ver_lines_g		:	positive				:= 192	--192 active lines
		);
  port (
		-- Clocks and Reset 
		clk_sdram	:	in std_logic;	--Wishbone input clock for SDRAM (133MHz)
		clk_sys		:	in std_logic;	--System clock
		rst_sdram	:	in std_logic;	--Reset for SDRAM Clock domain
		rst_sys		:	in std_logic;	--Reset for System Clock domain

		-- Wishbone Slave signals
		wbs_adr_i	:	in std_logic_vector (9 downto 0);		--Address in internal RAM
		wbs_tga_i	:	in std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
		wbs_cyc_i	:	in std_logic;							--Cycle command from WBM
		wbs_tgc_i	:	in std_logic;							--Cycle tag. '1' indicates start of transaction
		wbs_stb_i	:	in std_logic;							--Strobe command from WBM
		wbs_dat_o	:	out std_logic_vector (7 downto 0);		--Data Out (8 bits)
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
		wbs_ack_o	:	out std_logic;							--Input data has been successfuly acknowledged
		wbs_err_o	:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
		
		-- Wishbone Master signals to SDRAM
		wbm_adr_o	:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbm_we_o	:	out std_logic;							--Write Enable
		wbm_tga_o	:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_cyc_o	:	out std_logic;							--Cycle Command to interface
		wbm_stb_o	:	out std_logic;							--Strobe Command to interface
		wbm_dat_i	:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbm_stall_i	:	in std_logic;							--Slave is not ready to receive new data
		wbm_err_i	:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbm_ack_i	:	in std_logic;							--When Read Burst: DATA bus must be valid in this cycle
		
		-- Arbiter signals
		arbiter_gnt	:	in std_logic;							--Grant control on SDRAM from Arbiter
		arbiter_req	:	out std_logic;							--Request for control on SDRAM from Arbiter

		-- Wr_Rd_Bank signals
		bank_val	:	in std_logic;							--Wr_Rd_Bank value
	
		-- Signals from registers
		type_reg	:	in std_logic_vector (7 downto 0);		--Type Register
		rd_addr_reg	:	in std_logic_vector (21 downto 0);		--Read from SDRAM Address (Debug mode)
		
		-- mem_ctrl_write signals
		wr_cnt_val	:	in std_logic_vector(integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))) - 1 downto 0);	--wr_cnt value
		wr_cnt_en	:	in std_logic;							--wr_cnt write enable flag (Active for 1 clock)

		--Debug Signals
		dbg_rd_bank	:	out std_logic							--Current bank, which is Read from.
		); 
end component mem_ctrl_rd;

component mem_mng_arbiter
	generic	(
			reset_polarity_g	:	std_logic	:= '0'					--When reset = reset_polarity_g, system is in RESET mode
			);
	port	(
			--Clock and Reset
			clk				:	in std_logic;							--Clock
			reset			:	in std_logic;							--Reset
									
			--Requests and grants						
			wr_req			:	in std_logic;							--Write request
			rd_req			:	in std_logic;							--Read Request
			wr_gnt			:	out std_logic;							--Write grant
			rd_gnt			:	out std_logic;							--Read grant
			
			-- Write: Wishbone Master signals to SDRAM
			wr_wbm_adr_o	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
			wr_wbm_dat_o	:	in std_logic_vector (15 downto 0);		--Data Out (16 bits)
			wr_wbm_we_o		:	in std_logic;							--Write Enable
			wr_wbm_tga_o	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
			wr_wbm_cyc_o	:	in std_logic;							--Cycle Command to interface
			wr_wbm_stb_o	:	in std_logic;							--Strobe Command to interface
			wr_wbm_stall_i	:	out std_logic;							--Slave is not ready to receive new data
			wr_wbm_err_i	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
			wr_wbm_ack_i	:	out std_logic;							--When Read Burst: DATA bus must be valid in this cycle
			
			-- Read: Wishbone Master signals to SDRAM
			rd_wbm_adr_o	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
			rd_wbm_we_o		:	in std_logic;							--Write Enable
			rd_wbm_tga_o	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
			rd_wbm_cyc_o	:	in std_logic;							--Cycle Command to interface
			rd_wbm_stb_o	:	in std_logic;							--Strobe Command to interface
			rd_wbm_dat_i	:	out std_logic_vector (15 downto 0);		--Data In (16 bits)
			rd_wbm_stall_i	:	out std_logic;							--Slave is not ready to receive new data
			rd_wbm_err_i	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
			rd_wbm_ack_i	:	out std_logic;							--When Read Burst: DATA bus must be valid in this cycle

			-- Wishbone Master signals to SDRAM, after arbitration
			wbm_adr_o		:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
			wbm_we_o		:	out std_logic;							--Write Enable
			wbm_tga_o		:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
			wbm_cyc_o		:	out std_logic;							--Cycle Command to interface
			wbm_stb_o		:	out std_logic;							--Strobe Command to interface
			wbm_dat_o		:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
			wbm_dat_i		:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
			wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data
			wbm_err_i		:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
			wbm_ack_i		:	in std_logic							--When Read Burst: DATA bus must be valid in this cycle
			);
end component mem_mng_arbiter;

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

-- Wishbone Master signals from mem_ctrl_wr to Arbiter
signal wr_wbm_adr_o	:	std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
signal wr_wbm_dat_o	:	std_logic_vector (15 downto 0);		--Data Out (16 bits)
signal wr_wbm_we_o	:	std_logic;							--Write Enable
signal wr_wbm_tga_o	:	std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
signal wr_wbm_cyc_o	:	std_logic;							--Cycle Command to interface
signal wr_wbm_stb_o	:	std_logic;							--Strobe Command to interface
signal wr_wbm_stall_i:	std_logic;							--Slave is not ready to receive new data
signal wr_wbm_err_i	:	std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
signal wr_wbm_ack_i	:	std_logic;							--When Read Burst: DATA bus must be valid in this cycle

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

-- Arbiter signals
signal arb_wr_gnt	:	std_logic;							--Write: Grant control on SDRAM from Arbiter
signal arb_wr_req	:	std_logic;							--Write: Request for control on SDRAM from Arbiter
signal arb_rd_gnt	:	std_logic;							--Read: Grant control on SDRAM from Arbiter
signal arb_rd_req	:	std_logic;							--Read: Request for control on SDRAM from Arbiter

-- Wr_Rd_Bank signals
signal wr_bank_val	:	std_logic; 							--Wr_Bank value
signal rd_bank_val	:	std_logic;					 		--Rd_Bank value
signal bank_switch	:	std_logic;							--Signals the Wr_Rd_Bank to switch between banks

-- Mem_Ctrl_Read signals
signal wr_cnt_val	:	std_logic_vector(integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))) - 1 downto 0);	--wr_cnt value
signal wr_cnt_en	:	std_logic;							--wr_cnt write enable flag (Active for 1 clock)

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

--Debug SDRAM register signals
signal dbg_reg_din_ack		:	std_logic_vector (dbg_reg_depth_c - 1 downto 0);	--Data has been acknowledged
signal dbg_reg_rd_en		:	std_logic_vector (dbg_reg_depth_c - 1 downto 0);	--Read Enable
signal dbg_reg_dout			:	std_logic_vector (dbg_reg_depth_c * reg_width_c - 1 downto 0);		--Output data
signal dbg_reg_dout_valid	:	std_logic_vector (dbg_reg_depth_c - 1 downto 0);					--Output data is valid

--	###########################		Implementation		##############################	--
begin	
	
	--Cycle is active for registers
	wr_wbs_reg_cyc_proc:
	wr_wbs_reg_cyc	<=	wr_wbs_cyc_i and wr_wbs_tgc_i when
						(conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c) or
						(conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c + 2) or
						(conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c + 1) or
						(conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c)
						else '0';
	
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
						else dbg_reg_dout (3 * reg_width_c - 1 downto 2 * reg_width_c) 	when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c + 2)) 
						else dbg_reg_dout (2 * reg_width_c - 1 downto reg_width_c) 		when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c + 1)) 
						else dbg_reg_dout (reg_width_c - 1 downto 0)  					when ((wr_wbs_reg_cyc = '1') and (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c))
						else (others => '0');

	--MUX, to route addressed register dout_valid to the WBS
	wbs_reg_dout_valid_proc:
	wbs_reg_dout_valid	<=	type_reg_dout_valid or dbg_reg_dout_valid (2) or dbg_reg_dout_valid (1)	or dbg_reg_dout_valid (0);
	
	--MUX, to route addressed register din_ack to the WBS
	wbs_reg_din_ack_proc:
	wbs_reg_din_ack	<=	type_reg_din_ack or dbg_reg_din_ack (2) or dbg_reg_din_ack (1) or dbg_reg_din_ack (0);
	
	--Read Enables processes:
	type_reg_rd_en_proc:
	type_reg_rd_en	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c) and (reg_rd_en = '1')
						else '0';

	dbg_reg_rd_en_2proc:
	dbg_reg_rd_en(2)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c + 2) and (reg_rd_en = '1')
							else '0';

	dbg_reg_rd_en_1proc:
	dbg_reg_rd_en(1)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c + 1) and (reg_rd_en = '1')
							else '0';

	dbg_reg_rd_en_0proc:
	dbg_reg_rd_en(0)	<=	'1' when (conv_integer(wr_wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_reg_addr_c) and (reg_rd_en = '1')
							else '0';
							

	---------------------------------------------------------------------------------------
	----------------------------	Bank value process	-----------------------------------
	---------------------------------------------------------------------------------------
	-- The process switches between the two double banks when fine image has been received.
	---------------------------------------------------------------------------------------
	bank_val_proc: process (clk_sdram, rst_sdram)
	begin
		if (rst_sdram = reset_polarity_g) then
			wr_bank_val <= '0';
			rd_bank_val <= '1';
		elsif rising_edge (clk_sdram) then

				if (bank_switch = '1') then
					wr_bank_val <= not wr_bank_val;
					rd_bank_val <= not rd_bank_val;
				else
					wr_bank_val <= wr_bank_val;
					rd_bank_val <= rd_bank_val;
				end if;
		end if;
	end process bank_val_proc;
	
--	###########################		Instances		##############################	--
	mem_ctrl_wr_inst : mem_ctrl_wr generic map
									   (
										reset_polarity_g 	=> reset_polarity_g,
										mode_g				=> mode_g,
										message_g			=> message_g,
										img_hor_pixels_g	=> img_hor_pixels_g,
										img_ver_lines_g		=> img_ver_lines_g
										)
									port map
										(
										-- Clocks and Reset 
										clk_sdram	=> clk_sdram,
                                        clk_sys		=> clk_sys,		
										rst_sdram	=> rst_sdram,			
										rst_sys		=> rst_sys,		

										-- Wishbone Slave signals
										wbs_adr_i	=> wr_wbs_adr_i,
										wbs_tga_i	=> wr_wbs_tga_i,
										wbs_dat_i	=> wr_wbs_dat_i,	
										wbs_cyc_i	=> wr_wbs_cmp_cyc,	
										wbs_stb_i	=> wr_wbs_cmp_stb,	
										wbs_stall_o	=> wbs_cmp_stall_o,	
										wbs_ack_o	=> wbs_cmp_ack_o,	
										wbs_err_o	=> wr_wbs_err_o,	
										
										-- Wishbone Master signals to SDRAM
										wbm_adr_o	=> wr_wbm_adr_o,
										wbm_dat_o	=> wr_wbm_dat_o,
										wbm_we_o	=> wr_wbm_we_o,
										wbm_tga_o	=> wr_wbm_tga_o,
										wbm_cyc_o	=> wr_wbm_cyc_o,
										wbm_stb_o	=> wr_wbm_stb_o,
										wbm_stall_i	=> wr_wbm_stall_i,	
										wbm_err_i	=> wr_wbm_err_i,
										wbm_ack_i	=> wr_wbm_ack_i,
										
										-- Arbiter signals
										arbiter_gnt	=> arb_wr_gnt,
										arbiter_req	=> arb_wr_req,

										-- Wr_Rd_Bank signals
										bank_val	=> wr_bank_val,	
										bank_switch	=> bank_switch,	
										
										-- Signals from registers
										type_reg	=> type_reg_dout,	
										wr_addr_reg	=> dbg_reg_dout (21 downto 0),
										
										-- Mem_Ctrl_Read signals
										wr_cnt_val	=> wr_cnt_val,	
										wr_cnt_en	=> wr_cnt_en,

										--Debug Signals
										dbg_wr_bank	=> dbg_actual_wr_bank	
										); 
									
	arbiter_inst : mem_mng_arbiter generic map 
										(reset_polarity_g => reset_polarity_g)
									port map
										(
										clk				=>	clk_sdram,			
										reset			=>	rst_sdram,
														
										wr_req			=>	arb_wr_req,
										rd_req			=>	arb_rd_req,
										wr_gnt			=>	arb_wr_gnt,
										rd_gnt			=>	arb_rd_gnt,
										                
										wr_wbm_adr_o	=>	wr_wbm_adr_o,
										wr_wbm_dat_o	=>  wr_wbm_dat_o,
										wr_wbm_we_o		=>  wr_wbm_we_o,
										wr_wbm_tga_o	=>  wr_wbm_tga_o,
										wr_wbm_cyc_o	=>  wr_wbm_cyc_o,
										wr_wbm_stb_o	=>  wr_wbm_stb_o,
										wr_wbm_stall_i	=>  wr_wbm_stall_i,
										wr_wbm_err_i	=>  wr_wbm_err_i,
										wr_wbm_ack_i	=>  wr_wbm_ack_i,
										               
										rd_wbm_adr_o	=>	rd_wbm_adr_o,	
										rd_wbm_we_o		=>	rd_wbm_we_o,		
										rd_wbm_tga_o	=>	rd_wbm_tga_o,	
										rd_wbm_cyc_o	=>	rd_wbm_cyc_o,	
										rd_wbm_stb_o	=>	rd_wbm_stb_o,	
										rd_wbm_dat_i	=>	rd_wbm_dat_i,	
										rd_wbm_stall_i	=>	rd_wbm_stall_i,	
										rd_wbm_err_i	=>	rd_wbm_err_i,	
										rd_wbm_ack_i	=>	rd_wbm_ack_i,	
										                
										wbm_adr_o		=>	wbm_adr_o,
										wbm_we_o		=>  wbm_we_o,
										wbm_tga_o		=>  wbm_tga_o,
										wbm_cyc_o		=>  wbm_cyc_o,
										wbm_stb_o		=>  wbm_stb_o,
										wbm_dat_o		=>  wbm_dat_o,
										wbm_dat_i		=>  wbm_dat_i,
										wbm_stall_i		=>  wbm_stall_i,
										wbm_err_i		=>  wbm_err_i,
										wbm_ack_i		=>  wbm_ack_i	
										);
										
	mem_ctrl_rd_inst : mem_ctrl_rd generic map (
										reset_polarity_g	=>	reset_polarity_g,
					                    mode_g				=>	mode_g,			
	                                    img_hor_pixels_g	=>	img_hor_pixels_g,
	                                    img_ver_lines_g		=>	img_ver_lines_g
										)
									port map
									(
										-- Clocks and Reset 
										clk_sdram		=>	clk_sdram	,
										clk_sys			=>	clk_sys		,
										rst_sdram		=>	rst_sdram	,
										rst_sys			=>	rst_sys		,

										-- Wishbone Slave signals
										wbs_adr_i		=>	rd_wbs_adr_i,
										wbs_tga_i	    =>  rd_wbs_tga_i,
										wbs_cyc_i	    =>  rd_wbs_cyc_i,	
										wbs_tgc_i	    =>  rd_wbs_tgc_i,
										wbs_stb_i	    =>  rd_wbs_stb_i,	
										wbs_dat_o	    =>  rd_wbs_dat_o,
										wbs_stall_o	    =>  rd_wbs_stall_o,	
										wbs_ack_o	    =>  rd_wbs_ack_o,	
										wbs_err_o	    =>  rd_wbs_err_o,	
										
										-- Wishbone Master signals to SDRAM
										wbm_adr_o		=>	rd_wbm_adr_o,	
										wbm_we_o	    =>  rd_wbm_we_o,	
										wbm_tga_o	    =>  rd_wbm_tga_o,	
										wbm_cyc_o	    =>  rd_wbm_cyc_o,	
										wbm_stb_o	    =>  rd_wbm_stb_o,	
										wbm_dat_i	    =>  rd_wbm_dat_i,	
										wbm_stall_i	    =>  rd_wbm_stall_i,	
										wbm_err_i	    =>  rd_wbm_err_i,	
										wbm_ack_i	    =>  rd_wbm_ack_i,	
										
										-- Arbiter signals
										arbiter_gnt		=>	arb_rd_gnt,
										arbiter_req	    =>	arb_rd_req,

										-- Wr_Rd_Bank signals
										bank_val		=>	rd_bank_val,
									
										-- Signals from registers
										type_reg		=>	type_reg_dout,	
										rd_addr_reg	    =>	dbg_reg_dout (21 downto 0),
										
										-- mem_ctrl_write signals
										wr_cnt_val		=>	wr_cnt_val,	
										wr_cnt_en	    =>  wr_cnt_en,
										
										--Debug Signals
										dbg_rd_bank		=> dbg_actual_rd_bank	
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
										clk					=>	clk_sys,
									    reset		        =>	rst_sys,
									    addr		        =>	reg_addr,
									    din			        =>	reg_din,
									    wr_en		        =>	reg_wr_en,
									    clear		        =>	'0',
                                        din_ack		        =>	type_reg_din_ack,
                                        rd_en				=>	type_reg_rd_en,
										dout		        =>	type_reg_dout,
                                        dout_valid	        =>	type_reg_dout_valid
									);
	
	dbg_reg_generate:
	for idx in (dbg_reg_depth_c - 1) downto 0 generate
		gen_reg_dbg_inst	:	gen_reg generic map (
										reset_polarity_g	=>	reset_polarity_g,	
										width_g				=>	reg_width_c,
										addr_en_g			=>	true,
										addr_val_g			=>	(dbg_reg_addr_c + idx),
										addr_width_g		=>	reg_addr_width_c,
										read_en_g			=>	true,
										write_en_g			=>	true,
										clear_on_read_g		=>	false,
										default_value_g		=>	0
									)
									port map (
										clk					=>	clk_sys,
									    reset		        =>	rst_sys,
									    addr		        =>	reg_addr,
									    din			        =>	reg_din,
									    wr_en		        =>	reg_wr_en,
									    clear		        =>	'0',
                                        din_ack		        =>	dbg_reg_din_ack (idx),
                                        rd_en				=>	dbg_reg_rd_en (idx),
                                        dout		        =>	dbg_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
                                        dout_valid	        =>	dbg_reg_dout_valid (idx)
									);
	end generate dbg_reg_generate;
	
	wbs_reg_inst	:	wbs_reg generic map (
										reset_polarity_g=>	reset_polarity_g,
										width_g			=>	reg_width_c,
										addr_width_g	=>	reg_addr_width_c
									)
									port map (
										rst				=>	rst_sys,
										clk_i			=> 	clk_sys,
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
trigger_proc:
manipulation_trig<=bank_switch;	
-------------------------------	Debug Process--------------------------
dbg_type_reg_proc:
dbg_type_reg	<=	type_reg_dout;

dbg_wr_bank_val_proc:
dbg_wr_bank_val	<=	wr_bank_val;

dbg_rd_bank_val_proc:
dbg_rd_bank_val <=	rd_bank_val;  

dbg_addr_reg_proc:
dbg_adrr_reg	<=	dbg_reg_dout;
end architecture rtl_mem_mng_top;