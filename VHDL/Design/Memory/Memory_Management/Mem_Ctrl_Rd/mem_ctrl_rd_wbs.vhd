------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Control Read Wishbone Slave
-- File Name	:	mem_ctrl_rd_wbs.vhd
-- Generated	:	19.4.2011
-- Author		:	Beeri Schreiber
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

entity mem_ctrl_rd_wbs is
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
end entity mem_ctrl_rd_wbs;

architecture rtl_mem_ctrl_rd_wbs of mem_ctrl_rd_wbs is

  ---------------------------------  Types		----------------------------------
	--Wishbone Slave State Machine
	type wbs_states is (
						wbs_idle_st,			--Idle state
						wbs_init_sdram_rx_st,	--Initilize SDRAM read trasaction, to the RAM
						wbs_wait_ram_rdy_st,	--Wait until RAM is ready (some data has been written to RAM by SDRAM)
						wbs_ram_delay_st,		--Wait one clock - prepare RAM
						wbs_tx_st,				--Transmit data to data requester
						wbs_wait_end_cyc_st,	--End of RAM, but not end of cycle
						wbs_done_st				--Done cycle. Next state: wbs_idle_st
						);
	
  ---------------------------------  Signals	----------------------------------
	--General signals
	signal ack_o_sr			:	std_logic;							--WBS_ACK_O Register
	signal wbs_stall_o_int	:	std_logic;							--WBS_STALL_O Register
	signal restart_i		:	std_logic;							--Internal RESTART_RD
	--Signals for RAM
	signal ram_expect_adr	:	std_logic_vector (9 downto 0);		--Current EXPECTED (and actual) read address from RAM
	
	--State machines
	signal wbs_cur_st		:	wbs_states;
	
  ---------------------------------  Implementation	------------------------------
  begin
	
	------------------------------	Hidden processes	--------------------------
	restart_rd_proc:
	restart_rd	<=	restart_i;
	
	--Output data to Data Requester (WBS_DAT_O)
	wbs_dat_o_proc:
	wbs_dat_o 	<= 	ram_dout;
	
	--Acknowledge to Data Requester (WBS_ACK_O)
	wbs_ack_o_proc:
	wbs_ack_o	<=	ack_o_sr and wbs_cyc_i;

	--STALL to Data Requester (WBS_STALL_O)
	wbs_stall_o_proc:
	wbs_stall_o	<=	wbs_stall_o_int;
	
	--Output address to RAM
	ram_addr_out_proc:
	ram_addr_out	<=	ram_expect_adr;
	
	---------------------------------------------------------------------------------
	----------------------------- Process wbs_fsm_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process is the Wishbone Slave FSM. It receives command to transmit data,
	-- then initilize SDRAM transaction, using Wishbone Master, reads the data from 
	-- the RAM, which was stored there from the SDRAM, and transmits it.
	---------------------------------------------------------------------------------
	wbs_fsm_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbs_cur_st		<= wbs_idle_st;
			
		elsif rising_edge(clk_i) then
			case wbs_cur_st is
				when wbs_idle_st =>
					if (wbs_cyc_i = '1') then 
						if (restart_i = '1') then	--Restart from start of bank
							wbs_cur_st		<= wbs_wait_end_cyc_st;
						elsif ((wbm_busy = '0') and (rd_cnt_zero = '0')) 	--WBS Start of cycle
							or (type_reg (0) = '1') then					--Debug Mode
							wbs_cur_st		<= wbs_init_sdram_rx_st;
						else
							wbs_cur_st		<= wbs_cur_st;			
						end if;
					else
						wbs_cur_st		<= wbs_cur_st;
					end if;
				
				when wbs_init_sdram_rx_st => 
					if (wbs_cyc_i = '0') then
						wbs_cur_st		<=	wbs_idle_st;
					elsif (restart_i = '1') then	--Restart from start of bank
						wbs_cur_st		<= wbs_wait_end_cyc_st;
					else
						wbs_cur_st		<= wbs_wait_ram_rdy_st;
					end if;
					
				when wbs_wait_ram_rdy_st =>
					if (restart_i = '1') then	--Restart from start of bank
						wbs_cur_st		<= wbs_wait_end_cyc_st;
					elsif (ram_ready = '1') then
						wbs_cur_st	<= wbs_ram_delay_st;
					else
						wbs_cur_st	<= wbs_cur_st;
					end if;
				
				when wbs_ram_delay_st =>
					if (restart_i = '1') then	--Restart from start of bank
						wbs_cur_st		<= wbs_wait_end_cyc_st;
					else
						wbs_cur_st		<= wbs_tx_st;
					end if;
				
				when wbs_tx_st =>
					if (restart_i = '1') then	--Restart from start of bank
						wbs_cur_st		<= wbs_wait_end_cyc_st;
					elsif (wbs_cyc_i = '1') and (wbs_stb_i = '1') then
						if (ram_expect_adr = "1111111111") then				--End of RAM addresses
							wbs_cur_st		<= wbs_wait_end_cyc_st;			--Wait for end of cycle
						else
							wbs_cur_st		<= wbs_cur_st;             	    
						end if;
					else													--End of burst
						wbs_cur_st			<= wbs_wait_end_cyc_st;             	    
					end if;
				
				when wbs_wait_end_cyc_st =>
					if (wbs_cyc_i = '1') then
						wbs_cur_st		<= wbs_cur_st;            	    
					else
						wbs_cur_st		<= wbs_done_st;             	    
					end if;
					
				when wbs_done_st =>
					wbs_cur_st		<= wbs_idle_st;
				
				when others =>
					wbs_cur_st		<= wbs_idle_st;
					report "Time: " & time'image(now) & ", mem_ctrl_rd_wbs, wbs_fsm_proc >> Undeclared state has been received!"
					severity error;
			end case;
		end if;
	end process wbs_fsm_proc;
	
	---------------------------------------------------------------------------------
	-------------------------- Process wbs_stall_o_int_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the wbs_stall_o_int signal
	---------------------------------------------------------------------------------
	wbs_stall_o_int_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbs_stall_o_int	<= '1';
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_ram_delay_st) 
			or ((wbs_cur_st = wbs_tx_st) and (wbs_cyc_i = '1') and (wbs_stb_i = '1')) 
			or ((wbs_cur_st = wbs_idle_st) and (restart_i = '1')) then
				wbs_stall_o_int	<= '0';
			else
				wbs_stall_o_int	<= '1';
			end if;
		end if;
	end process wbs_stall_o_int_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process wbs_err_o_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the wbs_err_o signal
	---------------------------------------------------------------------------------
	wbs_err_o_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbs_err_o	<= '0';
		elsif rising_edge (clk_i) then
			if (wbs_cyc_i = '1') then
				if (wbs_stb_i = '1') then
					if (wbs_cur_st = wbs_wait_end_cyc_st)
					or ((wbs_cur_st = wbs_tx_st) and (ram_expect_adr /= wbs_adr_i)) then
						wbs_err_o	<= '1';
					else
						wbs_err_o	<= '0';
					end if;
				else
					wbs_err_o	<= '0';
				end if;
			else
				wbs_err_o		<= '0';
			end if;
		end if;
	end process wbs_err_o_proc;
	
	---------------------------------------------------------------------------------
	-----------------------------	 Process init_rd_proc		---------------------
	---------------------------------------------------------------------------------
	-- The process is '1' to signal WBM to init transaction
	---------------------------------------------------------------------------------
	init_rd_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			init_rd	<= '0';
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_wait_ram_rdy_st) then
				init_rd	<= '1';
			else
				init_rd	<= '0';
			end if;
		end if;
	end process init_rd_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process ram_words_in_proc	---------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_words_in signal
	---------------------------------------------------------------------------------
	ram_words_in_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_words_in		<= (others => '0');
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_init_sdram_rx_st) then
				ram_words_in	<= wbs_tga_i (9 downto 1);			--Latch burst length
			end if;
		end if;
	end process ram_words_in_proc;	
	
	---------------------------------------------------------------------------------
	----------------------------- Process ram_expect_adr_proc	---------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_expect_adr signal
	---------------------------------------------------------------------------------
	ram_expect_adr_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_expect_adr	<= (others => '0');
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_idle_st) then
				ram_expect_adr	<= (others => '0');
			elsif (wbs_cur_st = wbs_tx_st) and (wbs_cyc_i = '1') then
				if (ram_expect_adr = wbs_adr_i) then				--Expected and received address are the same
					ram_expect_adr	<= ram_expect_adr + '1';		--Increment expected address
				else												--ERROR: Expected and received addresses are mismatch
					ram_expect_adr	<= ram_expect_adr;				--Keep last value
					report "Time: " & time'image(now) & ", mem_ctrl_rd_wbs, wbs_fsm_proc >> Expected RAM address does not match to actual input address!"
					severity error;
				end if;
			else
				ram_expect_adr	<= ram_expect_adr;
			end if;
		end if;
	end process ram_expect_adr_proc;

	-- ---------------------------------------------------------------------------------
	-- ----------------------------- Process ram_aout_val_proc	-------------------------
	-- ---------------------------------------------------------------------------------
	-- -- The process controls the ram_aout_val signal
	-- ---------------------------------------------------------------------------------
	-- ram_aout_val_proc: process (clk_i, rst)
	-- begin
		-- if (rst = reset_polarity_g) then
			-- ram_aout_val	<= '0';
		-- elsif rising_edge (clk_i) then
			-- if (wbs_cur_st = wbs_ram_delay_st) or (wbs_cur_st = wbs_tx_st) then
				-- ram_aout_val	<= '1';
			-- else
				-- ram_aout_val	<= '0';
			-- end if;
		-- end if;
	-- end process ram_aout_val_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process ack_o_sr_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process controls the wbs_ack_o_sr shift register, dependent of WBS_STB_I
	---------------------------------------------------------------------------------
	ack_o_sr_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ack_o_sr	<= '0';
		elsif rising_edge (clk_i) then
			if (wbs_cyc_i = '1') and 
				(((ram_expect_adr = wbs_adr_i) and (wbs_stall_o_int = '0'))
				or ((restart_i = '1') and (wbs_cur_st = wbs_wait_end_cyc_st))) then
				ack_o_sr <= wbs_stb_i;
			else
				ack_o_sr <= '0';
			end if;
		end if;
	end process ack_o_sr_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process restart_i_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the 'restart_i' signal. Mirrors the following situation:
	-- '1' when WBM_CYC_I = '1' and WBM_TGC_I = '1' (Restart from start of sdram),
	-- '0' otherwise.
	---------------------------------------------------------------------------------
	restart_i_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			restart_i	<= '1';
		elsif rising_edge (clk_i) then
			if (wbs_cyc_i = '1') and (wbs_tgc_i = '1') then
				restart_i <= '1';
			else
				restart_i <= '0';
			end if;
		end if;
	end process restart_i_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process info_reg_proc		-------------------------
	---------------------------------------------------------------------------------
	-- The process latches the TYPE_REG and ADDR_REG for WBM purposes
	---------------------------------------------------------------------------------
	info_reg_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			rd_addr_reg_wbm	<=	(others => '0');
			type_reg_wbm	<=	(others => '0');
		
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_init_sdram_rx_st) then
				rd_addr_reg_wbm	<=	rd_addr_reg;
				type_reg_wbm	<=	type_reg;
			elsif (wbs_cur_st = wbs_done_st) then -- uri ran
				type_reg_wbm	<=	type_reg;
				rd_addr_reg_wbm	<=	rd_addr_reg;
			end if;
		end if;
	end process info_reg_proc;
	
	--############################################################################--
	--						End of Wishbone Slave								  --
	--############################################################################--
	
end architecture rtl_mem_ctrl_rd_wbs;