------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Control Write Wisbone Slave
-- File Name	:	mem_ctrl_wr_wbs.vhd
-- Generated	:	6.02.2012
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The components receives data from Wishbone Master, as 8 bits data, and stores it
--				into the RAM.
--
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		6.02.2012	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mem_ctrl_wr_wbs is
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
		ram_ready		:	out std_logic;						--Active for 4 clock cycles, when 3/4 data has been stored to internal RAM and ready to be stored in SDRAM
		ram_num_words	:	out std_logic_vector (8 downto 0)	--Number of words (16 bits) stored in RAM (Valid when ram_ready = '1')
		); 
end entity mem_ctrl_wr_wbs;

architecture rtl_mem_ctrl_wr_wbs of mem_ctrl_wr_wbs is

  ---------------------------------  Types		----------------------------------
	--Wishbone Slave State Machine
	type wbs_states is (
						wbs_idle_st,		--Idle state
						wbs_neg_stall_st,	--Negate STALL_O
						wbs_rx_st,			--Receiving data from data provider
						wbs_wait_end_cyc_st,--End of RAM, but not end of cycle
						wbs_done_st			--Done cycle. Next state: wbs_idle_st
						);

  ---------------------------------  Signals	----------------------------------
	--General Signals
	signal ram_ready_i		:	std_logic;							--Internal RAM Ready
	signal ram_ready_sr		:	std_logic_vector (3 downto 0);		--Shift Register of RAM_Ready_i
	signal done_cnt			:	std_logic_vector (2 downto 0);		--Counter for WBM_BUSY
	
	--Signals for RAM
	signal ram_expect_adr	:	std_logic_vector (9 downto 0);		--Current EXPECTED (and actual) write address to RAM
	
	--Signals derived from RAM transactions
	signal ram_words_i	:	std_logic_vector (8 downto 0);			--Number of words (16 bits) stored in RAM
	
	--State machine
	signal wbs_cur_st		:	wbs_states;
	
  ---------------------------------  Implementation	------------------------------
  begin
	
	------------------------------	Hidden processes	--------------------------
	
	--Number of words (16 bits) which will finally be stored in the RAM
	ram_num_words_proc:
	ram_num_words	<=	ram_words_i;
	
	--Input Address to RAM
	ram_addr_in_proc:
	ram_addr_in		<=	ram_expect_adr;
	
	--Input Data to RAM
	ram_data_in_proc:
	ram_data_in		<=	wbs_dat_i;
	
	---------------------------------------------------------------------------------
	----------------------------- Process wbs_fsm_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process is the FSM of the Wishbone Slave, which receives data, and stores
	-- it in the internal RAM.
	-- Handled output signals in this process:
	-- * wbs_stall_o	-	WBS Stall
	-- * wbs_ack_o		-	WBS Acknowledged
	-- * wbs_err_o		-	WBS Error
	---------------------------------------------------------------------------------
	wbs_fsm_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbs_cur_st		<= wbs_idle_st;
			wbs_stall_o		<= '1';
			wbs_ack_o		<= '0';
			wbs_err_o		<= '0';
			ram_din_valid	<= '0';
			ram_expect_adr	<= (others => '0');
			
		elsif rising_edge(clk_i) then
			case wbs_cur_st is
				when wbs_idle_st =>
					wbs_err_o		<= '0';
					ram_expect_adr	<= ram_expect_adr;
					wbs_stall_o		<= '1';								--Not ready for next transaction
					wbs_ack_o 		<= '0';								--Data not acknowledged
					
					if (wbs_cyc_i = '1') and (wbm_busy = '0') then	--SDRAM write cycle is NOT in progress, and input transaction has just opened
						wbs_cur_st		<= wbs_neg_stall_st;
					else
						wbs_cur_st		<= wbs_idle_st;
					end if;
				
				when wbs_neg_stall_st =>
					wbs_err_o		<= '0';
					ram_expect_adr	<= (others => '0');
					wbs_stall_o		<= '0';								--Ready for next transaction
					wbs_ack_o 		<= '0';								--Data not acknowledged
					ram_din_valid	<= '1';	--'1' when WBS_RX_ST
					wbs_cur_st		<= wbs_rx_st;
				
				when wbs_rx_st =>
					if (wbs_cyc_i = '1') and (wbs_stb_i = '1') then
						wbs_stall_o			<= '0';							--Ready for next transaction
						if (ram_expect_adr = wbs_adr_i) then				--Expected and received address are the same
							wbs_ack_o 		<= '1';							--Data acknowledged
							wbs_err_o		<= '0';
							ram_expect_adr	<= ram_expect_adr + '1';		--Increment expected address
						else
							wbs_ack_o 		<= '0';
							wbs_err_o		<= '1';							--Error report
							ram_expect_adr	<= ram_expect_adr;				--Keep last value
							report "Time: " & time'image(now) & ", Mem_Ctrl_Wr, wbs_fsm_proc >> Expected RAM address does not match to actual input address!"
							severity error;
						end if;
						if (ram_expect_adr = "1111111111") then				--End of RAM addresses
							wbs_cur_st		<= wbs_wait_end_cyc_st;			--Wait for end of cycle
							ram_din_valid	<= '0';	--'1' when WBS_RX_ST
						else
							wbs_cur_st		<= wbs_rx_st;             	    
							ram_din_valid	<= '1';	--'1' when WBS_RX_ST
						end if;

					else													--End of burst
						wbs_cur_st			<= wbs_wait_end_cyc_st;             	    
						wbs_stall_o			<= '1';                     	    
						wbs_ack_o			<= '0';                     	    
						wbs_err_o			<= '0';                     	    
						ram_expect_adr		<= ram_expect_adr;
					end if;
				
				when wbs_wait_end_cyc_st =>
					wbs_ack_o 			<= '0';							--Data acknowledged
					ram_expect_adr		<= ram_expect_adr;				--Keep last value
					wbs_stall_o			<= '1';							--Not ready for next transaction

					if (wbs_cyc_i = '1') then
						if (wbs_stb_i = '1') then
							wbs_err_o		<= '1';						--Error - end of RAM
						else
							wbs_err_o		<= '0';
						end if;
						wbs_cur_st			<= wbs_wait_end_cyc_st;            	    
					else
						wbs_err_o			<= '0';                         
						wbs_cur_st			<= wbs_done_st;             	    
					end if;
					
				when wbs_done_st =>
					if done_cnt (2) = '1' then	--Switch to IDLE_ST after 4 clocks (to avoid getting WBM_BUSY in delay, which might start new WBS cycle before end of WBM)
						wbs_cur_st		<= wbs_idle_st;
					else
						wbs_cur_st		<= wbs_cur_st;
					end if;
					wbs_stall_o		<= '1';
					wbs_ack_o		<= '0';
					wbs_err_o		<= '0';
					ram_expect_adr	<= ram_expect_adr;
				
				when others =>
					wbs_cur_st		<= wbs_idle_st;
					report "Time: " & time'image(now) & ", Mem_Ctrl_Wr, wbs_fsm_proc >> Undeclared state has been received!"
					severity error;
			end case;
		end if;
	end process wbs_fsm_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process burst_len_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process latches burst length, from the WBS_TGA_I
	---------------------------------------------------------------------------------
	burst_len_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_words_i		<= (others => '0');					
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_neg_stall_st) then
				ram_words_i	<= wbs_tga_i (9 downto 1);		--Latch burst length / 2 (8 bits --> 16 bits)
			else
				ram_words_i	<= ram_words_i;
			end if;
		end if;
	end process burst_len_proc;	

	---------------------------------------------------------------------------------
	----------------------------- Process ram_ready_i_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_ready signal, to signal the WBM to start writing
	-- to the SDRAM
	---------------------------------------------------------------------------------
	ram_ready_i_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_ready_i	<= '0';
		elsif rising_edge (clk_i) then
			if ((wbs_cur_st = wbs_rx_st) 
			and (conv_integer(ram_expect_adr(9 downto 1)) = conv_integer(ram_words_i(8 downto 1)) + conv_integer(ram_words_i(8 downto 2)))) then	--3/4 of the data has been stored to RAM
				ram_ready_i	<= '1';
			else
				ram_ready_i	<= '0';
			end if;
		end if;
	end process ram_ready_i_proc;	

	---------------------------------------------------------------------------------
	----------------------------- Process ram_ready_sr_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process is the ShiftRegister of RAM_READY_I
	---------------------------------------------------------------------------------
	ram_ready_sr_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_ready_sr		<= (others => '0');
		elsif rising_edge (clk_i) then
			ram_ready_sr (2 downto 0)	<= ram_ready_sr (3 downto 1);
			ram_ready_sr (3)			<= ram_ready_i;
		end if;
	end process ram_ready_sr_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process ram_ready_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process is the RAM_READY process, to be active for 4 clocks (CDC Purposes)
	---------------------------------------------------------------------------------
	ram_ready_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_ready		<= '0';
		elsif rising_edge (clk_i) then
			if (ram_ready_sr (0) = '1') 
			or (ram_ready_sr (1) = '1') 
			or (ram_ready_sr (2) = '1') 
			or (ram_ready_sr (3) = '1')  then
				ram_ready 	<= '1';
			else
				ram_ready	<= '0';
			end if;
		end if;
	end process ram_ready_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process done_cnt_proc		-------------------------
	---------------------------------------------------------------------------------
	-- The process manages the WBS_DONE_ST transit to WBS_IDLE_ST after 4 clocks,
	-- to avoid entering new WBS cycle before end of WBM cycle (might happen due
	-- to CDC delay of WBM_BUSY)
	---------------------------------------------------------------------------------
	done_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			done_cnt	<=	"011";
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_done_st) then
				done_cnt	<=	done_cnt - '1';
			elsif (wbs_cur_st = wbs_idle_st) then
				done_cnt	<=	"011";
			else
				done_cnt	<=	done_cnt;
			end if;
		end if;
	end process done_cnt_proc; 
	
	---------------------------------------------------------------------------------
	----------------------------- Process info_reg_proc		-------------------------
	---------------------------------------------------------------------------------
	-- The process latches the TYPE_REG and ADDR_REG for WBM purposes
	---------------------------------------------------------------------------------
	info_reg_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wr_addr_reg_wbm	<=	(others => '0');
			type_reg_wbm	<=	(others => '0');
		
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_neg_stall_st) then
				wr_addr_reg_wbm	<=	wr_addr_reg;
				type_reg_wbm	<=	type_reg;
			end if;
		end if;
	end process info_reg_proc;

	--############################################################################--
	--						End of Wishbone Slave								  --
	--############################################################################--

end architecture rtl_mem_ctrl_wr_wbs;