------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Control Read
-- File Name	:	mem_ctrl_rd.vhd
-- Generated	:	19.4.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The components transmit data to Wishbone Master, according to its command, as 
--				8 bits data, from 16 bits input from SDRAM.
--
--				Way of operation:
--				Wishbone Slave receives read command. Wishbone cycle on SDRAM start, and data from
--				SDRAM is read to internal RAM. The data from the internal RAM is transmitted to the 
--				Wishbone Master. In case SDRAM's page is over (Column Address is
--				255), the burst will stop, and re-initilize from the next address in the SDRAM.
--
--				Modes of operation:
--				(a)	Normal mode: As described above
--				(b)	Debug mode: One read burst to a specific SDRAM address is being performed.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		19.4.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity mem_ctrl_rd is
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
end entity mem_ctrl_rd;

architecture rtl_mem_ctrl_rd of mem_ctrl_rd is
  
  ---------------------------------  Components		------------------------------
  -- RAM Dual Clock
	component altera_16to8_dc_ram 
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			rdaddress	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
			rdclock		: IN STD_LOGIC ;
			wraddress	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			wrclock		: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END component altera_16to8_dc_ram;
  
component mem_ctrl_rd_wbs 
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0'	--When rst = reset_polarity_g, system is in RESET mode
		);
  port (
		-- Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset

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
		
		-- Signals from registers
		type_reg	:	in std_logic_vector (7 downto 0);		--Type Register
		rd_addr_reg	:	in std_logic_vector (21 downto 0);		--Read from SDRAM Address (Debug mode)

		-- Handhsake with Wishbone Master
		wbm_busy		:	in std_logic;						--'1' when WBM is busy, '0' otherwise
		rd_cnt_zero		:	in std_logic;						--'1' when Read Counter = '0'
		ram_ready		:	in std_logic;						--Active when data can be read from internal RAM 
		type_reg_wbm	:	out std_logic_vector (7 downto 0);	--Type Register
		rd_addr_reg_wbm	:	out std_logic_vector (21 downto 0);	--Read from SDRAM Address (Debug mode)
		init_rd			:	out std_logic;						--'1' - Command WBM to init SDRAM Read command
		restart_rd		:	out std_logic;						--'1' - Command WBM to restart read from the start of the bank
		ram_words_in	:	out std_logic_vector (8 downto 0);	--Number of words (16 bits) which will be stored in RAM at end of SDRAM transaction
		
		-- Hanshake with RAM
		ram_dout	:	in std_logic_vector (7 downto 0);		--Output data from RAM
		ram_addr_out:	out std_logic_vector (9 downto 0)		--Current read address from RAM
		); 
end component mem_ctrl_rd_wbs;

component mem_ctrl_rd_wbm
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0';	--When rst = reset_polarity_g, system is in RESET mode
		mode_g				:	natural range 0 to 7 	:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
		img_hor_pixels_g	:	positive				:= 256;	--256 activepixels
		img_ver_lines_g		:	positive				:= 192	--192 active lines
		);
  port (
		-- Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		
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
		
		-- Handhsake with Wishbone Slave
		wbm_busy	:	out std_logic;							--'1' when WBM is busy, '0' otherwise
		rd_cnt_zero	:	out std_logic;							--'1' when Read Counter = '0'
		ram_ready	:	out std_logic;							--Active for 3 clock cycles, when data can be read from internal RAM 
		init_rd		:	in std_logic;							--'1' - Command WBM to init SDRAM Read command
		restart_rd	:	in std_logic;							--'1' - Command WBM to restart read from the start of the bank
		ram_words_in:	in std_logic_vector (8 downto 0);		--Number of words (16 bits) which will be stored in RAM at end of SDRAM transaction

		--Handhsake with RAM
		ram_addr_in		:	out std_logic_vector (8 downto 0);	--Write address to RAM
		ram_data_in		:	out std_logic_vector (15 downto 0);	--Data to RAM
		ram_din_valid	:	out std_logic;						--'1' when data to RAM is valid

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
end component mem_ctrl_rd_wbm;

  ---------------------------------  Signals	----------------------------------
	--Handshake WBM-WBS
	signal wbm_busy		:	std_logic;							--'1' when WBM is busy, '0' otherwise
	signal rd_cnt_zero	:	std_logic;							--'1' when Read Counter = '0'
	signal ram_ready	:	std_logic;							--Active when data can be read from internal RAM 
	signal init_rd		:	std_logic;							--'1' - Command WBM to init SDRAM Read command
	signal restart_rd	:	std_logic;							--'1' - Command WBM to restart read from the start of the bank
	signal ram_words_in	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) which will be stored in RAM at end of SDRAM transaction

	signal wbm_busy_d1		:	std_logic;							--'1' when WBM is busy, '0' otherwise
	signal wbm_busy_d2		:	std_logic;							--'1' when WBM is busy, '0' otherwise
	signal rd_cnt_zero_d1	:	std_logic;							--'1' when Read Counter = '0'
	signal rd_cnt_zero_d2	:	std_logic;							--'1' when Read Counter = '0'
	signal ram_ready_d1		:	std_logic;							--Active when data can be read from internal RAM (Sync stage for CDC)
	signal ram_ready_d2		:	std_logic;							--Active when data can be read from internal RAM (Sync stage for CDC)
	signal ram_ready_d3		:	std_logic;							--Active when data can be read from internal RAM (Sync stage for CDC)
	signal ram_ready_d4		:	std_logic;							--Active when data can be read from internal RAM (Sync stage for CDC)
	signal ram_ready_flt	:	std_logic;							--Active when data can be read from internal RAM (Filter state for CDC)
	signal init_rd_d1		:	std_logic;							--'1' - Command WBM to init SDRAM Read command (Sync stage for CDC)
	signal init_rd_d2		:	std_logic;							--'1' - Command WBM to init SDRAM Read command (Sync stage for CDC)
	signal init_rd_d3		:	std_logic;							--'1' - Command WBM to init SDRAM Read command (Sync stage for CDC)
	signal init_rd_d4		:	std_logic;							--'1' - Command WBM to init SDRAM Read command (Sync stage for CDC)
	signal init_rd_flt		:	std_logic;							--'1' - Command WBM to init SDRAM Read command (Filter state for CDC)
	signal restart_rd_d1	:	std_logic;							--'1' - Command WBM to restart read from the start of the bank (Sync stage for CDC)
	signal restart_rd_d2	:	std_logic;							--'1' - Command WBM to restart read from the start of the bank (Sync stage for CDC) 
	signal restart_rd_d3	:	std_logic;							--'1' - Command WBM to restart read from the start of the bank (Sync stage for CDC) 
	signal restart_rd_d4	:	std_logic;							--'1' - Command WBM to restart read from the start of the bank (Sync stage for CDC) 
	signal restart_rd_flt	:	std_logic;							--'1' - Command WBM to restart read from the start of the bank (Filter state for CDC) 
	signal ram_words_in_d1	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) which will be stored in RAM at end of SDRAM transaction
	signal ram_words_in_d2	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) which will be stored in RAM at end of SDRAM transaction
	signal type_reg_d1		:	std_logic_vector (7 downto 0);		--Type Register
	signal type_reg_d2		:	std_logic_vector (7 downto 0);		--Type Register
	signal rd_addr_reg_d2	:	std_logic_vector (21 downto 0);		--Write to SDRAM Address (Debug mode)
	signal rd_addr_reg_d1	:	std_logic_vector (21 downto 0);		--Write to SDRAM Address (Debug mode)
		
	signal type_reg_wbm		:	std_logic_vector (7 downto 0);		--Type Register
	signal type_reg_wbm_d1	:	std_logic_vector (7 downto 0);		--Type Register
	signal type_reg_wbm_d2	:	std_logic_vector (7 downto 0);		--Type Register
	signal rd_addr_reg_wbm		:	std_logic_vector (21 downto 0);	--Write to SDRAM Address (Debug mode)
	signal rd_addr_reg_wbm_d1	:	std_logic_vector (21 downto 0);	--Write to SDRAM Address (Debug mode)
	signal rd_addr_reg_wbm_d2	:	std_logic_vector (21 downto 0);	--Write to SDRAM Address (Debug mode)
	
	-- Hanshake with RAM
	signal ram_addr_out		:	std_logic_vector (9 downto 0);		--Current read address from RAM
	--signal ram_aout_val		:	std_logic;							--Read address from RAM is valid
	signal ram_addr_in		:	std_logic_vector (8 downto 0);		--Write address to RAM
	signal ram_data_in		:	std_logic_vector (15 downto 0);		--Data to RAM (Before swap)
	signal ram_data_in_swap	:	std_logic_vector (15 downto 0);		--Data to RAM (Swapped)
	signal ram_dout			:	std_logic_vector (7 downto 0);		--Data from RAM
	signal ram_din_valid	:	std_logic;							--'1' when data to RAM is valid
	signal ram_rst			:	std_logic;							--RAM Reset
	
  ---------------------------------  Implementation	------------------------------
  begin
	--Process to RAM Reset
	--RAM Reset
	ram_rst	<=	rst_sys when (reset_polarity_g = '1')
				else not rst_sys;

	--Swap output data so MSB will be written first
	ram_data_out_swap_proc:
	ram_data_in_swap(15 downto 0)	<=	ram_data_in (7 downto 0) & ram_data_in (15 downto 8);

	--Generic RAM: 16 bits input, 8 bits output
	ram1_inst: 	altera_16to8_dc_ram
				port map
					(
					data		=>	ram_data_in_swap,		
--					rd_aclr		=>	ram_rst,
					rdaddress	=>	ram_addr_out,
					rdclock		=>	clk_sys,
					--rden		=>	ram_aout_val,
					wraddress	=>	ram_addr_in,
					wrclock		=>	clk_sdram,
					wren		=>	ram_din_valid,
					q			=>	ram_dout
					);
					
	wbs_inst: mem_ctrl_rd_wbs
				generic map
					(
					reset_polarity_g	=>	reset_polarity_g
					)
				port map
					(
					clk_i			=>	clk_sys,
					rst			    =>	rst_sys,
					                
					wbs_adr_i	    =>	wbs_adr_i	,
					wbs_tga_i	    =>	wbs_tga_i	,
					wbs_cyc_i	    =>	wbs_cyc_i	,
					wbs_tgc_i	    =>	wbs_tgc_i	,
					wbs_stb_i	    =>	wbs_stb_i	,
					wbs_dat_o	    =>	wbs_dat_o	,
					wbs_stall_o	    =>	wbs_stall_o	,
					wbs_ack_o	    =>	wbs_ack_o	,
					wbs_err_o	    =>	wbs_err_o	,
					                
					type_reg		=>	type_reg,
					rd_addr_reg		=>	rd_addr_reg,

					wbm_busy	    =>	wbm_busy_d2	,
					rd_cnt_zero	    =>	rd_cnt_zero_d2	,
					ram_ready	    =>	ram_ready_flt	,
					type_reg_wbm	=>	type_reg_wbm,
					rd_addr_reg_wbm	=>	rd_addr_reg_wbm,
					init_rd		    =>	init_rd		,
					restart_rd	    =>	restart_rd	,
					ram_words_in	=>	ram_words_in,
					 
					ram_dout		=>	ram_dout,
					ram_addr_out    =>	ram_addr_out
					--ram_aout_val    =>	ram_aout_val
				);
					
	wbm_inst: mem_ctrl_rd_wbm
				generic map
					(
					reset_polarity_g	=>	reset_polarity_g,
				    mode_g			    =>	mode_g			,
				    img_hor_pixels_g    =>	img_hor_pixels_g,
				    img_ver_lines_g	    =>	img_ver_lines_g	
					)
				port map
					(
					clk_i			=>	clk_sdram,		
					rst			    =>	rst_sdram,

					wbm_adr_o	    =>	wbm_adr_o	,
					wbm_we_o	    =>	wbm_we_o	,
					wbm_tga_o	    =>	wbm_tga_o	,
					wbm_cyc_o	    =>	wbm_cyc_o	,
					wbm_stb_o	    =>	wbm_stb_o	,
					wbm_dat_i	    =>	wbm_dat_i	,
					wbm_stall_i	    =>	wbm_stall_i	,
					wbm_err_i	    =>	wbm_err_i	,
					wbm_ack_i	    =>	wbm_ack_i	,

					wbm_busy	    =>	wbm_busy	,
					rd_cnt_zero	    =>	rd_cnt_zero	,
					ram_ready	    =>	ram_ready	,
					init_rd		    =>	init_rd_flt	,
					restart_rd	    =>	restart_rd_flt	,
					ram_words_in	=>	ram_words_in_d2,

					ram_addr_in	    =>	ram_addr_in,
					ram_data_in	    =>	ram_data_in	 ,
					ram_din_valid   =>	ram_din_valid,

					arbiter_gnt	    =>	arbiter_gnt	,
					arbiter_req	    =>	arbiter_req	,

					bank_val	    =>	bank_val,

					type_reg	    =>	type_reg_wbm_d2	,
					rd_addr_reg	    =>	rd_addr_reg_wbm_d2,

					wr_cnt_val	    =>	wr_cnt_val	,
					wr_cnt_en	    =>	wr_cnt_en	,
					
					dbg_rd_bank		=>	dbg_rd_bank
					);
		
	---------------------------------------------------------------------------------
	----------------------------- Synchronize Clock Domains	-------------------------
	---------------------------------------------------------------------------------
	-- The process synchronizes the System clock domain signals to the SDRAM clock
	-- domain signals
	---------------------------------------------------------------------------------
	sync_cdc1_proc: process (clk_sdram, rst_sdram)
	begin
		if (rst_sdram = reset_polarity_g) then
			init_rd_d1		<=	'0';
			init_rd_d2		<=	'0';
			init_rd_d3		<=	'0';
			init_rd_d4		<=	'0';
			restart_rd_d1	<=	'1';
			restart_rd_d2	<=	'1';
			restart_rd_d3	<=	'1';
			restart_rd_d4	<=	'1';
			ram_words_in_d1	<=	(others => '0');
			type_reg_d1		<=	(others => '0');
			rd_addr_reg_d1	<=	(others => '0');
			ram_words_in_d2	<=	(others => '0');
			type_reg_d2		<=	(others => '0');
			rd_addr_reg_d2	<=	(others => '0');
			type_reg_wbm_d1	<=	(others => '0');
			type_reg_wbm_d2	<=	(others => '0');
			
		elsif rising_edge (clk_sdram) then
			init_rd_d1		<=	init_rd;
			init_rd_d2		<=	init_rd_d1;
			init_rd_d3		<=	init_rd_d2;
			init_rd_d4		<=	init_rd_d3;
			restart_rd_d1	<=  restart_rd;
			restart_rd_d2	<=  restart_rd_d1;
			restart_rd_d3	<=  restart_rd_d2;
			restart_rd_d4	<=  restart_rd_d3;
			ram_words_in_d1	<=  ram_words_in;
			ram_words_in_d2	<=  ram_words_in_d1;
			type_reg_d1		<=	type_reg;
			type_reg_d2		<=	type_reg_d1;
			rd_addr_reg_d1	<=	rd_addr_reg;
			rd_addr_reg_d2	<=	rd_addr_reg_d1;
			type_reg_wbm_d1	<=	type_reg_wbm;
			type_reg_wbm_d2	<=	type_reg_wbm_d1;		
		end if;
	end process sync_cdc1_proc;

	---------------------------------------------------------------------------------
	----------------------------- init_restart Filter	-------------------------
	---------------------------------------------------------------------------------
	-- The process filters the RAM_READY signal
	---------------------------------------------------------------------------------
	init_restart_flt_proc: process (clk_sdram, rst_sdram)
	begin
		if (rst_sdram = reset_polarity_g) then
			init_rd_flt		<=	'0';
			restart_rd_flt	<=	'0';
		elsif rising_edge (clk_sdram) then
			--Filter 'init_rd'
			if (init_rd_d3 = '1') and (init_rd_d4 = '1') then
				init_rd_flt <= '1';
			else
				init_rd_flt <= '0';
			end if;
			
			--Filter 'restart_rd'
			if (restart_rd_d3 = '1') and (restart_rd_d4 = '1') then
				restart_rd_flt <= '1';
			else
				restart_rd_flt <= '0';
			end if;
		end if;
	end process init_restart_flt_proc;

	
	---------------------------------------------------------------------------------
	----------------------------- Synchronize Clock Domains	-------------------------
	---------------------------------------------------------------------------------
	-- The process synchronizes the SDRAM clock domain signals to the System clock
	-- domain signals
	---------------------------------------------------------------------------------
	sync_cdc2_proc: process (clk_sys, rst_sys)
	begin
		if (rst_sys = reset_polarity_g) then
			wbm_busy_d1		<=	'1';
			wbm_busy_d2		<=	'1';
			rd_cnt_zero_d1	<=	'0';
			rd_cnt_zero_d2	<=	'0';
			ram_ready_d1	<=	'0';	
			ram_ready_d2	<=	'0';	
			ram_ready_d3	<=	'0';	
			ram_ready_d4	<=	'0';	
			rd_addr_reg_wbm_d1	<=	(others => '0');
			rd_addr_reg_wbm_d2	<=	(others => '0');
		elsif rising_edge (clk_sys) then
			wbm_busy_d1		<=	wbm_busy;
			wbm_busy_d2		<=	wbm_busy_d1;
			rd_cnt_zero_d1	<=	rd_cnt_zero;	
			rd_cnt_zero_d2	<=	rd_cnt_zero_d1;
			ram_ready_d1	<=	ram_ready;	
			ram_ready_d2	<=	ram_ready_d1;	
			ram_ready_d3	<=	ram_ready_d2;	
			ram_ready_d4	<=	ram_ready_d3;	
			rd_addr_reg_wbm_d1	<=	rd_addr_reg_wbm;
			rd_addr_reg_wbm_d2	<=	rd_addr_reg_wbm_d1;
		end if;
	end process sync_cdc2_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Ram_Ready Filter	-------------------------
	---------------------------------------------------------------------------------
	-- The process filters the RAM_READY signal
	---------------------------------------------------------------------------------
	ram_ready_flt_proc: process (clk_sys, rst_sdram)
	begin
		if (rst_sdram = reset_polarity_g) then
			ram_ready_flt		<=	'0';
		elsif rising_edge (clk_sys) then
			if (ram_ready_d3 = '1') and (ram_ready_d4 = '1') then
				ram_ready_flt <= '1';
			else
				ram_ready_flt <= '0';
			end if;
		end if;
	end process ram_ready_flt_proc;
	
		
end architecture rtl_mem_ctrl_rd;