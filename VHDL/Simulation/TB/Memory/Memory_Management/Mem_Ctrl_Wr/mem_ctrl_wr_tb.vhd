------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Control Write Test Bench
-- File Name	:	mem_ctrl_wr_tb.vhd
-- Generated	:	22.4.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: TB for mem_ctrl_wr
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		22.4.2011	Beeri Schreiber			Creation
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

entity mem_ctrl_wr_tb is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				burst_len_g			:	positive 					:= 1030;--Burst length to SDRAM
				arbiter_delay_gnt_g	:	positive 					:= 3;	--Number of clocks between arbiter_req to arbiter_gnt
				mode_g				:	natural range 0 to 7 		:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
				message_g			:	natural range 0 to 7 		:= 1;	--Relevant bit in type register, which represent Image chunk ('0') or Summary chunk ('1') mode
				burst_len_dbg_g		:	positive range 1 to 1024	:= 500;	--Burst length in Debug Mode
				wr_addr_dbg_g		:	natural range 0 to 2**22-1	:= 2000;--Write address in Debug Mode
				img_hor_pixels_g	:	positive					:= 640;	--640 activepixels
				img_ver_lines_g		:	positive					:= 480	--480 active lines
			);
end entity mem_ctrl_wr_tb;

architecture sim_mem_ctrl_wr_tb of mem_ctrl_wr_tb is

component sdram_controller 
  generic
	   (
		reset_polarity_g	:	std_logic	:= '0' --When rst = reset_polarity_g, system is in RESET mode
		);
  port (
		--Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		pll_locked	:	in std_logic;	--PLL Locked indication, for CKE (Clock Enable) signal to SDRAM
		
		--SDRAM Signals
		dram_addr	:	out std_logic_vector (11 downto 0);		--Address (12 bit)
		dram_bank	:	out std_logic_vector (1 downto 0);		--Bank
		dram_cas_n	:	out std_logic;							--Column Address is being transmitted
		dram_cke	:	out std_logic;							--Clock Enable
		dram_cs_n	:	out std_logic;							--Chip Select (Here - Mask commands)
		dram_dq		:	inout std_logic_vector (15 downto 0);	--Data in / Data out
		dram_ldqm	:	out std_logic;							--Byte masking
		dram_udqm	:	out std_logic;							--Byte masking
		dram_ras_n	:	out std_logic;							--Row Address is being transmitted
		dram_we_n	:	out std_logic;							--Write Enable
   
		-- Wishbone Slave signals to Read/Write interface
		wbs_adr_i	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbs_dat_i	:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbs_we_i	:	in std_logic;							--Write Enable
		wbs_tga_i	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbs_cyc_i	:	in std_logic;							--Cycle Command from interface
		wbs_stb_i	:	in std_logic;							--Strobe Command from interface
		wbs_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data
		wbs_err_o	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbs_ack_o	:	out std_logic							--When Read Burst: DATA bus must be valid in this cycle
   );
end component;

component mem_ctrl_wr
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0';	--When rst = reset_polarity_g, system is in RESET mode
		mode_g				:	natural range 0 to 7 	:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
		message_g			:	natural range 0 to 7 	:= 1;	--Relevant bit in type register, which represent Image chunk ('0') or Summary chunk ('1') mode
		img_hor_pixels_g	:	positive				:= 640;	--640 activepixels
		img_ver_lines_g		:	positive				:= 480	--480 active lines
		);
  port (
		-- Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset

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
		wr_cnt_en	:	out std_logic							--wr_cnt write enable flag (Active for 1 clock)
		); 
end component mem_ctrl_wr;

component sdram_model
	GENERIC (
		addr_bits : INTEGER := 12;
		data_bits : INTEGER := 16 ;
		col_bits  : INTEGER := 8
		);
	PORT (
		Dq		: inout std_logic_vector (15 downto 0) := (others => 'Z');
		Addr    : in    std_logic_vector (11 downto 0) ;-- := (others => '0');
		Ba      : in    std_logic_vector(1 downto 0);-- := "00";
		Clk     : in    std_logic ;--:= '0';
		Cke     : in    std_logic ;--:= '0';
		Cs      : in    std_logic ;--:= '1';
		Ras     : in    std_logic ;--:= '0';
		Cas     : in    std_logic ;--:= '0';
		We      : in    std_logic ;--:= '0';
		Dqm     : in    std_logic_vector(1 downto 0)-- := (others => 'Z')
		);
	
END component;

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

--Clock and Reset
signal clk_133		:	std_logic := '0'; --133 MHz
signal rst			:	std_logic := '0'; --Reset

--SDRAM Signals
signal dram_addr	:	std_logic_vector (11 downto 0);
signal dram_bank	:	std_logic_vector (1 downto 0);
signal dram_cas_n	:	std_logic;
signal dram_cke		:	std_logic;
signal dram_cs_n	:	std_logic;
signal dram_dq		:	std_logic_vector (15 downto 0);
signal dram_ldqm	:	std_logic;
signal dram_udqm	:	std_logic;
signal dram_ras_n	:	std_logic;
signal dram_we_n	:	std_logic;

-- Wishbone Slave signals
signal wbs_adr_i	:	std_logic_vector (9 downto 0);		--Address in internal RAM
signal wbs_tga_i	:	std_logic_vector (9 downto 0);		--Burst Length
signal wbs_dat_i	:	std_logic_vector (7 downto 0);		--Data In (8 bits)
signal wbs_cyc_i	:	std_logic;							--Cycle command from WBM
signal wbs_stb_i	:	std_logic;							--Strobe command from WBM
signal wbs_stall_o	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal wbs_ack_o	:	std_logic;							--Input data has been successfuly acknowledged
signal wbs_err_o	:	std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

-- Wishbone Master signals from Mem_Ctrl_Wr to Arbiter
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
signal rd_wbm_adr_o	:	std_logic_vector (21 downto 0) := (others => '0');		--Address (Bank, Row, Col)	
signal rd_wbm_dat_i	:   std_logic_vector (15 downto 0);		--Data In (16 bits)
signal rd_wbm_we_o	:	std_logic := '0';							--Write Enable
signal rd_wbm_tga_o	:   std_logic_vector (7 downto 0) := (others => '0');		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
signal rd_wbm_cyc_o	:   std_logic := '0';							--Cycle Command to interface
signal rd_wbm_stb_o	:   std_logic := '0';							--Strobe Command to interface
signal rd_wbm_stall_i:	std_logic;							--Slave is not ready to receive new data
signal rd_wbm_err_i	:   std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
signal rd_wbm_ack_i	:   std_logic;							--When Read Burst: DATA bus must be valid in this cycle

-- Wishbone Master signals to SDRAM from Arbiter
signal wbm_adr_o	:	std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
signal wbm_dat_o	:	std_logic_vector (15 downto 0);		--Data Out (16 bits)
signal wbm_dat_i	:	std_logic_vector (15 downto 0);		--Data in (16 bits)
signal wbm_we_o		:	std_logic;							--Write Enable
signal wbm_tga_o	:	std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
signal wbm_cyc_o	:	std_logic;							--Cycle Command to interface
signal wbm_stb_o	:	std_logic;							--Strobe Command to interface
signal wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data
signal wbm_err_i	:	std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
signal wbm_ack_i	:	std_logic;							--When Read Burst: DATA bus must be valid in this cycle

-- Arbiter signals
signal arb_wr_gnt	:	std_logic;							--Write: Grant control on SDRAM from Arbiter
signal arb_wr_req	:	std_logic;							--Write: Request for control on SDRAM from Arbiter
signal arb_rd_gnt	:	std_logic;							--Read: Grant control on SDRAM from Arbiter
signal arb_rd_req	:	std_logic;							--Read: Request for control on SDRAM from Arbiter

-- Wr_Rd_Bank signals
signal bank_val		:	std_logic; 							--Wr_Rd_Bank value
signal bank_switch	:	std_logic;							--Signals the Wr_Rd_Bank to switch between banks

-- Mem_Ctrl_Read signals
signal wr_cnt_val	:	std_logic_vector(integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))) - 1 downto 0);	--wr_cnt value
signal wr_cnt_en	:	std_logic;							--wr_cnt write enable flag (Active for 1 clock)

--General signals
signal end_of_wbs	:	boolean := false;					--End of WBS (Write to mem_ctrl_wr) process
signal all_ack_satisfied	:	boolean := false;			--WBS recevied all expected ACK_I / ERR_I

-- Signals of registers
signal type_reg		:	std_logic_vector (7 downto 0) := (others => '0');	--Type Register
signal wr_addr_reg	:	std_logic_vector (21 downto 0):= (others => '0');	--Write to SDRAM Address (Debug mode)

shared variable blen 		:	natural;

begin
	--Clock process
	clk_proc:
	clk_133 <= not clk_133 after 3.75 ns;
	
	--Reset process
	rst_proc:
	rst 	<= reset_polarity_g, not reset_polarity_g after 400 ns;
	
	--Arbiter grant process
	arbiter_gnt_proc: process
	begin
		arb_rd_req	<= '0';
		wait for 248 us;
		wait until rising_edge(clk_133);
		arb_rd_req	<= '1';
		wait for 10 us;
		wait until rising_edge(clk_133);
		arb_rd_req	<= '0';
		wait;
	end process arbiter_gnt_proc;
	
	--Bank value process
	bank_val_proc: process
	begin
		bank_val <= '0';
		while true loop
			wait until bank_switch = '1';
			wait until rising_edge(clk_133);
			bank_val <= not bank_val;
		end loop;
	end process bank_val_proc;
	
	--Wishbone slave process
	wbs_proc: process
	
	--Execute Data Burst
	procedure wbm_burst (constant burst_param : in natural) is
	variable min_val	:	natural;
	variable counter	:	std_logic_vector (7 downto 0);
	begin
		wbs_cyc_i	<= '0';
		wbs_stb_i	<= '0';
		blen		:= burst_param;
		counter		:= (others => '0');
		wbs_dat_i	<= 	counter;
		while blen > 0 loop
			if (blen > 1023) then
				min_val := 1023;
			else
				min_val := blen - 1;
			end if;
			wbs_adr_i	<= (others => '0');
			wbs_tga_i	<= conv_std_logic_vector (min_val, 10);
			wait until rising_edge(clk_133);
			wbs_cyc_i	<= '1';
			wbs_stb_i	<= '1';
			blen_loop:
			for idx in 0 to min_val loop	--Burst length
				wbs_dat_i	<= 	counter;
				counter			:=	counter + '1';
				if (wbs_stall_o = '1') then
					counter			:= (others => '0');
					wbs_dat_i		<= 	counter;
					counter			:=	counter + '1';
					wait until wbs_stall_o = '0';
					wait until rising_edge(clk_133);
					wbs_dat_i		<= 	counter;
					counter			:=	counter + '1';
				end if;
				wbs_adr_i	<= wbs_adr_i + '1';
				blen := blen - 1;

				if (idx = min_val) or (blen = 1) then
					wbs_stb_i	<= '0';
				end if;
				wait until rising_edge(clk_133);
				if (blen <= 1) then
					if (blen = 1) then
						wbs_stb_i	<= '0';
						blen := blen -1;
					end if;
					exit blen_loop;
				end if;
			end loop blen_loop;
			wait until all_ack_satisfied;
			wbs_cyc_i	<= '0';
		end loop;
		end_of_wbs	<= true, false after 7 ns;
	end procedure wbm_burst;

	--Execute Summary Chunk data
	procedure wbm_sum (constant burst_param : in natural) is
	variable sum_chunk_v	: natural;
	variable sum_counter	: natural;
	begin
		sum_counter	:= 0;
		sum_chunk_v := burst_param;
		while (sum_chunk_v > 0) loop
			sum_chunk_v := sum_chunk_v / 256;
			sum_counter	:= sum_counter + 1;
		end loop;
		sum_chunk_v := burst_param;
		type_reg(1) <= '1';	--Summary chunk
		wbs_cyc_i	<= '0';
		wbs_stb_i	<= '0';
		wbs_adr_i	<= (others => '0');
		wbs_tga_i	<= conv_std_logic_vector(integer(ceil(real(sum_counter))) - 1, 10);
		wait until rising_edge(clk_133);
		wbs_cyc_i	<= '1';
		wbs_stb_i	<= '1';
		chunk_loop:
		while (sum_chunk_v > 0) loop
			wbs_dat_i	<= conv_std_logic_vector(sum_chunk_v mod 256, 8);
			if (wbs_stall_o = '1') then
				wait until wbs_stall_o = '0';
				wait until rising_edge(clk_133);
			end if;
			sum_chunk_v := sum_chunk_v / 256;
			wbs_dat_i	<= conv_std_logic_vector(sum_chunk_v mod 256, 8);
			wbs_adr_i	<= wbs_adr_i + '1';

			if (sum_chunk_v = 0) then
				wbs_stb_i	<= '0';
			end if;
			wait until rising_edge(clk_133);
		end loop chunk_loop;
		wait until all_ack_satisfied;
		wbs_cyc_i	<= '0';
		end_of_wbs	<= true, false after 7 ns;
		type_reg(1) <= '0';	--Data chunk
	end procedure wbm_sum;
	
	begin
		end_of_wbs	<= false;
		type_reg	<= (others => '0');
		wbs_cyc_i	<= '0';
		wbs_stb_i	<= '0';
		wait for 230 us;	--After RESET process of SDRAM

		----########## 	BURST #1	##########
		--wbm_burst (burst_len_g);
		--
		----Summary chunk
		--wbm_sum (burst_len_g);
		--
		----########## 	DEBUG #1	##########
		----Change type register: Debug mode
		--type_reg(0)	<= '1';
		--wr_addr_reg	<= conv_std_logic_vector(wr_addr_dbg_g, 22);
		--wbm_burst (burst_len_dbg_g);
		
		--########## 	BURST #2	##########
		--Change type register: Normal mode
		type_reg(0)	<= '0';
		wbm_burst (burst_len_g);
		--########## 	BURST #3	##########
		wbm_burst (burst_len_g);

		--Summary chunk
		wbm_sum (burst_len_g*2);
		wait;
	end process wbs_proc;
	
	--Count number of WBS_ACK_I
	ack_i_cnt_proc: process
	begin
		all_ack_satisfied	<= false;
		wait until wbs_cyc_i = '1';
		wait until rising_edge(clk_133);
		wait until wbs_ack_o = '0';
		all_ack_satisfied	<= true;
		wait until rising_edge(clk_133);
	end process ack_i_cnt_proc;
	
	--Componenets:
	sdr_ctrl : sdram_controller 	generic map (
										reset_polarity_g  	=> reset_polarity_g
										)
									port map(
										clk_i		=> clk_133,
	                                    rst			=> rst,
	                                    pll_locked	=> '1',
	                                    
	                                    dram_addr	=> dram_addr,	
	                                    dram_bank	=> dram_bank,	
	                                    dram_cas_n	=> dram_cas_n,	
	                                    dram_cke	=> dram_cke,	
	                                    dram_cs_n	=> dram_cs_n,	
	                                    dram_dq		=> dram_dq,		
	                                    dram_ldqm	=> dram_ldqm,	
	                                    dram_udqm	=> dram_udqm,	
	                                    dram_ras_n	=> dram_ras_n,	
	                                    dram_we_n	=> dram_we_n,	
	                                    
	                                    wbs_adr_i	=> wbm_adr_o,	
	                                    wbs_dat_i	=> wbm_dat_o,	
										wbs_we_i	=> wbm_we_o	,
										wbs_tga_i	=> wbm_tga_o,	
										wbs_cyc_i	=> wbm_cyc_o,	
										wbs_stb_i	=> wbm_stb_o,	
										wbs_dat_o	=> wbm_dat_i,	
										wbs_stall_o	=> wbm_stall_i,	
										wbs_err_o	=> wbm_err_i,	
										wbs_ack_o	=> wbm_ack_i
									);
									
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
										clk_i	=> clk_133,		
										rst		=> rst,

										-- Wishbone Slave signals
										wbs_adr_i	=> wbs_adr_i,
										wbs_tga_i	=> wbs_tga_i,
										wbs_dat_i	=> wbs_dat_i,	
										wbs_cyc_i	=> wbs_cyc_i,	
										wbs_stb_i	=> wbs_stb_i,	
										wbs_stall_o	=> wbs_stall_o,	
										wbs_ack_o	=> wbs_ack_o,	
										wbs_err_o	=> wbs_err_o,	
										
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
										bank_val	=> bank_val,	
										bank_switch	=> bank_switch,	
										
										-- Signals from registers
										type_reg	=> type_reg,	
										wr_addr_reg	=> wr_addr_reg,
										
										-- Mem_Ctrl_Read signals
										wr_cnt_val	=> wr_cnt_val,	
										wr_cnt_en	=> wr_cnt_en	
										); 
	
	sdram_model_inst : sdram_model port map (
										Dq		=> dram_dq,	
	                                    Addr    => dram_addr,
	                                    Ba      => dram_bank,
	                                    Clk     => clk_133,
	                                    Cke     => dram_cke,
	                                    Cs      => dram_cs_n,
	                                    Ras     => dram_ras_n,
	                                    Cas     => dram_cas_n,
	                                    We      => dram_we_n,
	                                    Dqm(0)  => dram_ldqm,
	                                    Dqm(1)  => dram_udqm
									);
									
	arbiter_inst : mem_mng_arbiter generic map 
										(reset_polarity_g => reset_polarity_g)
									port map
										(
										clk				=>	clk_133,			
										reset			=>	rst,
														
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
									
end architecture sim_mem_ctrl_wr_tb;