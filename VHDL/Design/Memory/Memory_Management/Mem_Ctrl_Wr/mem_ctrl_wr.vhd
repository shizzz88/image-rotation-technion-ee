------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Control Write
-- File Name	:	mem_ctrl_wr.vhd
-- Generated	:	19.4.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The components receives data from Wishbone Master, as 8 bits data, and stores it
--				into the SDRAM, as 16 bits data.
--
--				Way of operation:
--				Wishbone Slave receives the data, and stores it into internal RAM. in the middle of
--				the Wishbone Cycle, a request for SDRAM BUS grant is being executed.
--				When grant from the arbiter has been received, the data from the internal RAM is 
--				being transmitted to the SDRAM. In case SDRAM's page is over (Column Address is
--				255), the burst will stop, and re-initilize from the next address in the SDRAM.
--
--				Modes of operation:
--				(a)	Normal mode: As described above
--				(b)	Debug mode: One write burst to a specific SDRAM address is being performed.
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

entity mem_ctrl_wr is
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

		-- Wishbone Slave signals (System Clock Domain)
		wbs_adr_i	:	in std_logic_vector (9 downto 0);		--Address in internal RAM
		wbs_tga_i	:	in std_logic_vector (9 downto 0);		--Burst length
		wbs_dat_i	:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
		wbs_cyc_i	:	in std_logic;							--Cycle command from WBM
		wbs_stb_i	:	in std_logic;							--Strobe command from WBM
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
		wbs_ack_o	:	out std_logic;							--Input data has been successfuly acknowledged
		wbs_err_o	:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
		
		-- Wishbone Master signals to SDRAM	(SDRAM Clock Domain)
		wbm_adr_o	:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbm_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbm_we_o	:	out std_logic;							--Write Enable
		wbm_tga_o	:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_cyc_o	:	out std_logic;							--Cycle Command to interface
		wbm_stb_o	:	out std_logic;							--Strobe Command to interface
		wbm_stall_i	:	in std_logic;							--Slave is not ready to receive new data
		wbm_err_i	:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbm_ack_i	:	in std_logic;							--When Read Burst: DATA bus must be valid in this cycle
		
		-- Arbiter signals (SDRAM Clock Domain)
		arbiter_gnt	:	in std_logic;							--Grant control on SDRAM from Arbiter
		arbiter_req	:	out std_logic;							--Request for control on SDRAM from Arbiter

		-- Wr_Rd_Bank signals (SDRAM Clock Domain)
		bank_val	:	in std_logic;							--Wr_Rd_Bank value
		bank_switch	:	out std_logic;							--Signals the Wr_Rd_Bank to switch between banks
		
		-- Signals from registers
		type_reg	:	in std_logic_vector (7 downto 0);		--Type Register
		wr_addr_reg	:	in std_logic_vector (21 downto 0);		--Write to SDRAM Address (Debug mode)
		
		-- Mem_Ctrl_Read signals (SDRAM Clock Domain)
		wr_cnt_val	:	out std_logic_vector(integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))) - 1 downto 0);	--wr_cnt value
		wr_cnt_en	:	out std_logic;							--wr_cnt write enable flag (Active for 1 clock)

		--Debug Signals
		dbg_wr_bank	:	out std_logic							--Current bank, which is written to.
		); 
end entity mem_ctrl_wr;

architecture rtl_mem_ctrl_wr of mem_ctrl_wr is

  ---------------------------------  Components		------------------------------
  -- RAM Dual Clock
	component altera_8to16_dc_ram 
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdaddress	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			rdclock		: IN STD_LOGIC ;
			wraddress	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
			wrclock		: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END component altera_8to16_dc_ram;
	
  component mem_ctrl_wr_wbs 
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
		wbs_tga_i	:	in std_logic_vector (9 downto 0);		--Burst length
		wbs_dat_i	:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
		wbs_cyc_i	:	in std_logic;							--Cycle command from WBM
		wbs_stb_i	:	in std_logic;							--Strobe command from WBM
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
		wbs_ack_o	:	out std_logic;							--Input data has been successfuly acknowledged
		wbs_err_o	:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
		
		-- RAM signals
		ram_addr_in		:	out std_logic_vector (9 downto 0);	--Input address to RAM
		ram_data_in		:	out std_logic_vector (7 downto 0);	--Input data to RAM
		ram_din_valid	:	out std_logic;						--Input data & address to RAM are valid		
		
		-- Signals from registers
		type_reg	:	in std_logic_vector (7 downto 0);		--Type Register
		wr_addr_reg	:	in std_logic_vector (21 downto 0);		--Write to SDRAM Address (Debug mode)

		-- Signals to mem_ctrl_wr_WBM
		wbm_busy		:	in std_logic;						--'1' when WBM is busy, '0' otherwise
		type_reg_wbm	:	out std_logic_vector (7 downto 0);	--Type Register
		wr_addr_reg_wbm	:	out std_logic_vector (21 downto 0);	--Write to SDRAM Address (Debug mode)
		ram_ready		:	out std_logic;						--Active for 1 clock cycle, when 3/4 data has been stored to internal RAM and ready to be stored in SDRAM
		ram_num_words	:	out std_logic_vector (8 downto 0)	--Number of words (16 bits) stored in RAM (Valid when ram_ready = '1')
		); 
  end component mem_ctrl_wr_wbs;
  
  component mem_ctrl_wr_wbm
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
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		
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
		
		-- RAM Signals
		ram_addr_out	:	out std_logic_vector (8 downto 0); 	--Output address
		ram_data_out	:	in std_logic_vector (15 downto 0);	--Output data
		
		-- Signals from mem_ctrl_wr_WBS
		wbm_busy		:	out std_logic;						--'1' when WBM is busy, '0' otherwise
		ram_ready		:	in std_logic;						--Active when 3/4 data has been stored to internal RAM and ready to be stored in SDRAM
		ram_num_words	:	in std_logic_vector (8 downto 0);	--Number of words (16 bits) stored in RAM (Valid when ram_ready = '1')

		-- Mem_Ctrl_Read signals
		wr_cnt_val	:	out std_logic_vector(integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))) - 1 downto 0);	--wr_cnt value
		wr_cnt_en	:	out std_logic;							--wr_cnt write enable flag (Active for 1 clock)
		
		--Debug Signals
		dbg_wr_bank	:	out std_logic							--Current bank, which is written to.
		); 
  end component mem_ctrl_wr_wbm;

  ---------------------------------  Signals	----------------------------------
	-- RAM signals
	signal ram_addr_in		:	std_logic_vector (9 downto 0);	--Input address to RAM
	signal ram_data_in		:	std_logic_vector (7 downto 0);	--Input data to RAM
	signal ram_din_valid	:	std_logic;						--Input data & address to RAM are valid		
	signal ram_addr_out		:	std_logic_vector (8 downto 0); 	--Output address
	--signal ram_aout_valid	:	std_logic;						--Output address is valid
	signal ram_data_out		:	std_logic_vector (15 downto 0);	--Output data
	signal ram_data_out_swap:	std_logic_vector (15 downto 0);	--Output data from RAM (Swapped)
	signal ram_rst			:	std_logic;						--RAM Reset
		
	-- Signals to mem_ctrl_wr_WBM	 (Clock domain sync)
	signal wbm_busy			:	std_logic;						--WBM is busy
	signal wbm_busy_d1		:	std_logic;						--WBM is busy
	signal wbm_busy_d2		:	std_logic;						--WBM is busy
	signal ram_ready		:	std_logic;						--Active for 1 clock cycle, when 3/4 data has been stored to internal RAM and ready to be stored in SDRAM
	signal ram_ready_d1		:	std_logic;						--1st sync stage
	signal ram_ready_d2		:	std_logic;						--2nd sync stage
	signal ram_ready_d3		:	std_logic;						--3rd sync stage
	signal ram_ready_d4		:	std_logic;						--4th sync stage
	signal ram_ready_flt	:	std_logic;						--Filter stage (3th=4th = '1')
	signal ram_num_words	:	std_logic_vector (8 downto 0);	--Number of words (16 bits) stored in RAM (Valid when ram_ready = '1')
	signal ram_num_words_d1	:	std_logic_vector (8 downto 0);	--1st sync stage
	signal ram_num_words_d2	:	std_logic_vector (8 downto 0);	--2nd sync stage
	signal type_reg_wbm		:	std_logic_vector (7 downto 0);	--Type Register
	signal type_reg_wbm_d1	:	std_logic_vector (7 downto 0);	--Type Register
	signal type_reg_wbm_d2	:	std_logic_vector (7 downto 0);	--Type Register
	signal wr_addr_reg_wbm		:	std_logic_vector (21 downto 0);	--Write to SDRAM Address (Debug mode)
	signal wr_addr_reg_wbm_d1	:	std_logic_vector (21 downto 0);	--Write to SDRAM Address (Debug mode)
	signal wr_addr_reg_wbm_d2	:	std_logic_vector (21 downto 0);	--Write to SDRAM Address (Debug mode)
	
  ---------------------------------  Implementation	------------------------------
  begin

	--RAM Reset
	ram_rst	<=	rst_sdram when (reset_polarity_g = '1')
				else not rst_sdram;
	
	--Swap output data so MSB will be read first
	ram_data_out_swap_proc:
	ram_data_out(15 downto 0)	<=	ram_data_out_swap (7 downto 0) & ram_data_out_swap (15 downto 8);
	
	-- RAM: 8 bits input, 16 bits output
	ram1_inst: 	altera_8to16_dc_ram
				port map
					(
					data		=>	ram_data_in,
					--rd_aclr		=>	ram_rst,
					rdaddress	=>	ram_addr_out,
					rdclock		=>	clk_sdram,
					--rden		=>	ram_aout_valid,
					wraddress	=>	ram_addr_in,
					wrclock		=>	clk_sys,
					wren		=>	ram_din_valid,
					q			=>	ram_data_out_swap
					);
	
	--Memory Control Write - WBS
	wbs_inst:	mem_ctrl_wr_wbs
				generic map
					(
						reset_polarity_g	=>	reset_polarity_g
					)
				port map
					(	
					clk_i			=>	clk_sys,		
					rst				=>	rst_sys,
						            
					wbs_adr_i		=>	wbs_adr_i	,
					wbs_tga_i		=>	wbs_tga_i	,
					wbs_dat_i		=>	wbs_dat_i	,
					wbs_cyc_i		=>	wbs_cyc_i	,
					wbs_stb_i		=>	wbs_stb_i	,
					wbs_stall_o		=>	wbs_stall_o	,
					wbs_ack_o		=>	wbs_ack_o	,
					wbs_err_o		=>	wbs_err_o	,
						            
					ram_addr_in		=>	ram_addr_in (9 downto 0)	,
					ram_data_in		=>	ram_data_in	,
					ram_din_valid	=>	ram_din_valid,
					
					type_reg		=>	type_reg,
					wr_addr_reg		=>	wr_addr_reg,
					
					wbm_busy		=>	wbm_busy_d2,
					type_reg_wbm	=>	type_reg_wbm,
					wr_addr_reg_wbm	=>	wr_addr_reg_wbm,
					ram_ready	    =>	ram_ready,
					ram_num_words   =>	ram_num_words	
					);
					
	--Memory Control Write - WBM
	wbm_inst:	mem_ctrl_wr_wbm
				generic map
					(
					reset_polarity_g	=> reset_polarity_g	,	
					mode_g				=> mode_g				,
					message_g			=> message_g			,
					img_hor_pixels_g	=> img_hor_pixels_g	,
					img_ver_lines_g		=> img_ver_lines_g	
					)
				port map
					(
					clk_i			=>	clk_sdram,			
					rst				=>	rst_sdram,
                                    
					wbm_adr_o		=>	wbm_adr_o	,
					wbm_dat_o		=>	wbm_dat_o	,
					wbm_we_o		=>	wbm_we_o	,
					wbm_tga_o		=>	wbm_tga_o	,
					wbm_cyc_o		=>	wbm_cyc_o	,
					wbm_stb_o		=>	wbm_stb_o	,
					wbm_stall_i		=>	wbm_stall_i	,
					wbm_err_i		=>	wbm_err_i	,
					wbm_ack_i		=>	wbm_ack_i	,
					                
					arbiter_gnt		=>	arbiter_gnt,
					arbiter_req		=>	arbiter_req,
                                    
					bank_val		=>	bank_val	,
					bank_switch		=>	bank_switch	,
                                    
					type_reg		=>	type_reg_wbm_d2	,
					wr_addr_reg		=>	wr_addr_reg_wbm_d2,
					                
					ram_addr_out	=>	ram_addr_out (8 downto 0)	,
					--ram_aout_valid	=>	ram_aout_valid	,
					ram_data_out	=>	ram_data_out	,
					                
					wbm_busy		=>	wbm_busy,
					ram_ready		=>	ram_ready_flt	,
					ram_num_words	=>	ram_num_words_d2,
					                
					wr_cnt_val		=>	wr_cnt_val	,
					wr_cnt_en		=>	wr_cnt_en	,
					dbg_wr_bank		=>	dbg_wr_bank
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
			ram_ready_d1		<=	'0';
			ram_ready_d2		<=	'0';
			ram_ready_d3		<=	'0';
			ram_ready_d4		<=	'0';
			ram_num_words_d1	<=	(others => '0');
			ram_num_words_d2	<=	(others => '0');
			type_reg_wbm_d1		<=	(others => '0');
			type_reg_wbm_d2		<=	(others => '0');
			wr_addr_reg_wbm_d1	<=	(others => '0');
			wr_addr_reg_wbm_d2	<=	(others => '0');
		elsif rising_edge (clk_sdram) then
			ram_ready_d1		<=	ram_ready;
			ram_ready_d2		<=	ram_ready_d1;
			ram_ready_d3		<=	ram_ready_d2;
			ram_ready_d4		<=	ram_ready_d3;
			ram_num_words_d1	<=	ram_num_words;
			ram_num_words_d2	<=	ram_num_words_d1;
			type_reg_wbm_d1		<=	type_reg_wbm;
			type_reg_wbm_d2		<=	type_reg_wbm_d1;
			wr_addr_reg_wbm_d1	<=	wr_addr_reg_wbm;
			wr_addr_reg_wbm_d2	<=	wr_addr_reg_wbm_d1;
		end if;
	end process sync_cdc1_proc;

	---------------------------------------------------------------------------------
	----------------------------- Ram_Ready Filter	-------------------------
	---------------------------------------------------------------------------------
	-- The process filters the RAM_READY signal
	---------------------------------------------------------------------------------
	ram_ready_flt_proc: process (clk_sdram, rst_sdram)
	begin
		if (rst_sdram = reset_polarity_g) then
			ram_ready_flt		<=	'0';
		elsif rising_edge (clk_sdram) then
			if (ram_ready_d3 = '1') and (ram_ready_d4 = '1') then
				ram_ready_flt <= '1';
			else
				ram_ready_flt <= '0';
			end if;
		end if;
	end process ram_ready_flt_proc;

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
		elsif rising_edge (clk_sys) then
			wbm_busy_d1		<=	wbm_busy;
			wbm_busy_d2		<=	wbm_busy_d1;
		end if;
	end process sync_cdc2_proc;
	
end architecture rtl_mem_ctrl_wr;