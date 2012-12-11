------------------------------------------------------------------------------------------------
-- Model Name 	:	Wishbone Controller of TX Path
-- File Name	:	tx_path_wbm.vhd
-- Generated	:	1.2.2012
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		2.1.2012	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;


entity tx_path_wbm is
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0';	--When rst = reset_polarity_g, system is in RESET mode
		data_width_g		:	natural 				:= 8;	--Data width
		addr_width_g		:	natural					:= 10	--Address length
		);
  port (
		-- Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		
		--Control signals
		start_rx	:	in std_logic;										--'1' to start the RX from WBS
		burst_len	:	in std_logic_vector (addr_width_g - 1 downto 0);	--Required burst length
		init_addr	:	in std_logic_vector (addr_width_g - 1 downto 0);	--Initial address for burst length
		reg_cmp_en	:	in std_logic;										--'0': Read from registers, '1': Read from component (SDRAM)
		
		-- Wishbone Master signals to INTERCON
		wbm_cyc_o	:	out std_logic;										--Cycle Command to interface
		wbm_tgc_o	:	out std_logic;										--Tag Cycle Command to interface ('1': Read from registers, '0': Read from component)
		wbm_stb_o	:	out std_logic;										--Strobe Command to interface
		wbm_we_o	:	out std_logic;										--Write Enable
		wbm_adr_o	:	out std_logic_vector (addr_width_g - 1 downto 0);	--Address
		wbm_tga_o	:	out std_logic_vector (addr_width_g - 1 downto 0);	--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_dat_i	:	in std_logic_vector (data_width_g - 1 downto 0);	--Data In
		wbm_stall_i	:	in std_logic;										--Slave is not ready to receive new data
		wbm_err_i	:	in std_logic;										--Error flag
		wbm_ack_i	:	in std_logic;										--When Read Burst: DATA bus must be valid in this cycle
		
		-- End of read transaction signals
		end_wbm_rx	:	out std_logic;										--'1' for one clock when end of read transaction
		
		-- RAM signals to TX_PATH
		ram_addr_in	:	out std_logic_vector (addr_width_g - 1 downto 0); 	--Input address to RAM
		ram_data_in	:	out std_logic_vector (data_width_g - 1 downto 0);	--Input data to RAM
		ram_din_val	:	out std_logic 										--Input data valid to RAM
		); 
end entity tx_path_wbm;

architecture rtl_tx_path_wbm of tx_path_wbm is

  ---------------------------------  Types		----------------------------------
	--Wishbone Master State Machine
	type wbm_states is (
						wbm_idle_st,		--Idle state
						wbm_rx_st,			--Receiving data from INTERCON
						wbm_wait_burst_st	--Wait for end of burst
						);
  
  ---------------------------------  Signals	----------------------------------
	--General signals
	signal ack_i_cnt		:	natural range 0 to conv_integer(2**addr_width_g);				--Number of expected WBM_ACK_I
	signal err_i_status		:	std_logic;							--WBM_ERR_I has been received
	signal neg_cyc_bool		:	boolean;							--TRUE: Negate NOW (At this clock) WBM_CYC_O, FALSE otherwise
	signal ack_cnt_zero_b	:	boolean;							--TRUE: ack_i_cnt = 0.
	signal wbm_cyc_internal	:	std_logic;							--Internal WBS_CYC_O
	signal wbm_stb_internal	:	std_logic;							--Internal WBS_STB_O
	signal cur_rd_addr		:	std_logic_vector(addr_width_g - 1 downto 0);		--Current read address
	
	--Signals derived from RAM transactions
	signal ram_words_left	:	std_logic_vector (addr_width_g downto 0);		--Number of words waiting to be stored in RAM (1 extra bit for counter)
	signal ram_in_addr_i	:	std_logic_vector (addr_width_g - 1 downto 0);	--Current write address to RAM + 1
	signal ram_in_addr_i_d1	:	std_logic_vector (addr_width_g - 1 downto 0);	--Current write address to RAM + 1 ; One clock delay
	
	--State machine
	signal wbm_cur_st		:	wbm_states;
	
  ---------------------------------  Implementation	------------------------------
  begin
	
	------------------------------	Hidden processes	--------------------------
	
	--RAM input data
	ram_data_in_proc:
	ram_data_in	<= wbm_dat_i;
	
	--RAM data valid
	ram_data_val_proc:
	ram_din_val	<=	wbm_ack_i;
	
	--Cycle to SDRAM (WBM_CYC_O)
	wbm_cyc_o_proc:
	wbm_cyc_o 	<= 	wbm_cyc_internal when (not neg_cyc_bool)
					else '0';

	--Strobe (WBM_STB_O)
	wbm_stb_o_proc:
	wbm_stb_o	<= 	wbm_stb_internal;
						
	--Write enable is always '0' for this component
	wbm_we_o_proc:
	wbm_we_o 	<= '0';
	
	--Address out to SDRAM (WBM_ADR_O)
	wbm_adr_o_proc:
	wbm_adr_o	<= 	cur_rd_addr;
	
	--############################################################################--
	--						Start of Wishbone Master							  --
	--############################################################################--
	---------------------------------------------------------------------------------
	----------------------------- Process wbm_fsm_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process is the FSM of the Wishbone Master, which receives data from the 
	-- SDRAM and stores it to the SDRAM.
	---------------------------------------------------------------------------------
	wbm_fsm_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbm_cur_st		<= wbm_idle_st;
            wbm_tga_o		<= (others => '0');
			wbm_tgc_o		<= '0';	
			cur_rd_addr		<= (others => '0');
			ram_in_addr_i	<= (others => '0');
			ram_words_left	<= (others => '0');
            wbm_cyc_internal<= '0';
			wbm_stb_internal<= '0';
			end_wbm_rx		<= '0';

		elsif rising_edge (clk_i) then
			case wbm_cur_st is
				when wbm_idle_st =>
					ram_in_addr_i	<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_words_left	<= '0' & burst_len;			--Latch number of required words
					end_wbm_rx		<= '0';

					--Wait for init flag
					if (start_rx = '1') then
						wbm_cur_st			<= wbm_rx_st;
						wbm_tga_o			<= burst_len;
						assert (conv_integer(init_addr) + conv_integer(burst_len) < 2**addr_width_g)
						report "Time: " & time'image(now) & ", tx_path_wbm, wbm_fsm_proc >> Burst Length + Init addr > maximum burst length"
						severity error;
						
						if (reg_cmp_en = '1') then			--Read from component (SDRAM)
							wbm_tgc_o	<= '0';	
							cur_rd_addr	<= (others => '0');
						else								--Read from registers
							wbm_tgc_o	<= '1';	
							cur_rd_addr	<= init_addr;
						end if;
					else
						cur_rd_addr	<= cur_rd_addr;
						wbm_cur_st 	<= wbm_idle_st;
						wbm_tga_o	<= (others => '0');
					end if;
				
				when wbm_rx_st =>
					wbm_cyc_internal<= '1';
					end_wbm_rx		<= '0';
					
					if (ram_words_left (addr_width_g) = '1') then						--End of cycle
						wbm_stb_internal<= '0';
						cur_rd_addr		<= cur_rd_addr;
						ram_in_addr_i	<= ram_in_addr_i;
						wbm_cur_st		<= wbm_wait_burst_st;
					else											--Cycle in progress
						wbm_stb_internal<= '1';
						wbm_cur_st		<= wbm_rx_st;

						--Check STALL_I status
						if (wbm_stall_i = '0') then					--Ready for next data	
							cur_rd_addr		<= cur_rd_addr + '1';
							ram_in_addr_i	<= ram_in_addr_i + '1';
							ram_words_left	<= ram_words_left - '1';
						else										--Repeat last transaction
							cur_rd_addr		<= cur_rd_addr;
							ram_in_addr_i	<= ram_in_addr_i;
							ram_words_left	<= ram_words_left;
						end if;
					end if;
					
				when wbm_wait_burst_st =>

					cur_rd_addr		<= cur_rd_addr;
					ram_in_addr_i	<= ram_in_addr_i;
					ram_words_left	<= ram_words_left;
					
					if (err_i_status = '1') then					--An error has occured
						wbm_cyc_internal<= '0';
						wbm_cur_st		<= wbm_idle_st;
						end_wbm_rx		<= '1';
						
					elsif (ack_i_cnt = 0) then						--All data has been transmitted 
						wbm_cyc_internal	<= '0';
						wbm_cur_st			<= wbm_idle_st;
						end_wbm_rx			<= '1';
					else											--Cycle is in progress
						wbm_cyc_internal<= '1';
						wbm_cur_st		<= wbm_wait_burst_st;
						end_wbm_rx		<= '0';
					end if;
					
				when others =>
					wbm_cur_st		<= wbm_idle_st;
					report "Time: " & time'image(now) & ", tx_path_wbm, wbm_fsm_proc >> Undeclared state has been received!"
					severity error;
			end case;
		end if;
	end process wbm_fsm_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process ack_i_cnt_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process counts the number of WBM_ACK_I that has been received, which
	-- suppose to be equal to the number of WBM_STB_O that has been transmitted.
	---------------------------------------------------------------------------------
	ack_i_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ack_i_cnt		<= 0;
			neg_cyc_bool	<= false;
			ack_cnt_zero_b	<= true;
			
		elsif rising_edge (clk_i) then
			if ((wbm_cur_st = wbm_idle_st) and (start_rx = '1')) then	--Setting Burst Length = number of expected ABM_ACK_I
				ack_i_cnt		<= conv_integer(burst_len) + 1;
				neg_cyc_bool	<= false;
				ack_cnt_zero_b	<= false;

			elsif ack_cnt_zero_b then				--ack_i_cnt = 0
				ack_i_cnt		<= ack_i_cnt;
				neg_cyc_bool	<= false;
				ack_cnt_zero_b	<= ack_cnt_zero_b;
			
			elsif (wbm_ack_i = '1') then 			--WBM_ACK_I has been received
				if (ack_i_cnt = 1) then
					neg_cyc_bool	<= true;
					ack_cnt_zero_b	<= true;
				else
					neg_cyc_bool	<= false;
					ack_cnt_zero_b	<= false;
				end if;
				ack_i_cnt	<= ack_i_cnt - 1;
			else
				ack_i_cnt		<= ack_i_cnt;
				neg_cyc_bool	<= false;
				ack_cnt_zero_b	<= ack_cnt_zero_b;
			end if;
		end if;
	end process ack_i_cnt_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process err_i_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process sniffs for WBM_ERR_I from SDRAM.
	---------------------------------------------------------------------------------
	err_i_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			err_i_status	<= '0';
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_idle_st) then
				err_i_status	<= '0';
			else
				err_i_status	<= (err_i_status or wbm_err_i); --Sniff for WBM_ERR_I
			end if;
		end if;
	end process err_i_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process ram_adr_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process creates one clock delay for the clock, for SDRAM addr at DBG mode
	---------------------------------------------------------------------------------
	ram_in_addr_i_d1_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_in_addr_i_d1	<= (others => '0');
		elsif rising_edge (clk_i) then
			ram_in_addr_i_d1	<= ram_in_addr_i;	
		end if;
	end process ram_in_addr_i_d1_proc;

	--RAM address is with the enable at REG_READ, and one clock after the enable at SDRAM read
	ram_adr_proc:
	ram_addr_in	<= 	ram_in_addr_i when (reg_cmp_en = '0')
					else ram_in_addr_i_d1;

end architecture rtl_tx_path_wbm;