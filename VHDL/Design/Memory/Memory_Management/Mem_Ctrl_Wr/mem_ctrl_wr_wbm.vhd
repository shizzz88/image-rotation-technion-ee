------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Control Write Wisbone Master
-- File Name	:	mem_ctrl_wr_wbm.vhd
-- Generated	:	19.4.2011
-- Author		:	Beeri Schreiber
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The components stores RAM data 	into the SDRAM.
--
--				Way of operation:
--				A request for SDRAM BUS grant is executed.
--				When grant from the arbiter has been received, the data from the internal RAM is 
--				transmitted to the SDRAM. In case SDRAM's page is over (Column Address is
--				255), the burst will stop, and re-initilize from the next address in the SDRAM.
--
--				Modes of operation:
--				(a)	Normal mode: As described above
--				(b)	Debug mode: One write burst to a specific SDRAM address is performed.
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

entity mem_ctrl_wr_wbm is
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
end entity mem_ctrl_wr_wbm;

architecture rtl_mem_ctrl_wr_wbm of mem_ctrl_wr_wbm is

  ---------------------------------  Types		----------------------------------
	--Wishbone Master State Machine
	type wbm_states is (
						wbm_idle_st,		--Idle state
						wbm_req_arb_st,		--Wait for grant on SDRAM from arbiter
						wbm_tx_st,			--Transmitting data to SDRAM
						wbm_wait_burst_st,	--Pause between 256 words transaction
						wbm_wait_switch_st,	--Wait for switch to happen, and asserts, if needed, BANK_SWITCH
						wbm_wait2_switch_st,--Wait for switch to happen (Reason: BANK_SWITCH will affect BANK_VAL in next clock)
						wbm_bank_switch_st,	--Switch double banks for writing / reading to / from SDRAM ('00' --> '10' or '10' --> '00')
						wbm_bank_st,		--Change write address to SDRAM
						wbm_wait_sum_st,	--Prepare RAM with first data for summary calculations
						wbm_sum_st			--Summary chunk (Number of transmitted bytes in current image)
						);

  ---------------------------------  Signals	----------------------------------
	--General signals
	signal ack_i_cnt		:	std_logic_vector (8 downto 0);		--Number of expected WBM_ACK_I (0-->256)
	signal err_i_status		:	std_logic;							--WBM_ERR_I has been received
	signal dat_1st_bool		:	boolean;							--TRUE: First read data on ram at each transaction, FALSE otherwise
	signal neg_cyc_bool		:	boolean;							--TRUE: Negate NOW (At this clock) WBM_CYC_O, FALSE otherwise
	signal wbm_cyc_internal	:	std_logic;							--Internal WBS_CYC_O
	signal wbm_stb_internal	:	std_logic;							--Internal WBS_STB_O
	signal cur_wr_addr		:	std_logic_vector(21 downto 0);		--Current write address to SDRAM
	signal wr_cnt 			:	natural range 0 to img_hor_pixels_g*img_ver_lines_g - 1;	--Number of written words (16 bits) to the SDRAM 
	signal wr_cnt_to_rd		:	natural range 0 to img_hor_pixels_g*img_ver_lines_g - 1;	--Latched wr_cnt, for mem_ctrl_rd
	signal sum_wr_cnt 		:	natural range 0 to img_hor_pixels_g*img_ver_lines_g ;		--Summary chunk value
	signal addr_pipe		:	std_logic_vector(7 downto 0);		--For pipeline
	signal sum_pipe_bool	:	boolean;							--For pipeline
	signal ram_cnt_zero_bool:	boolean;							--Indicates ram_words_cnt = x"01" (next is zero)

	--Latches registers values
	signal ram_ready_der	:	std_logic;							--Derivate of RAM_READY = '1' (Active for 1 clock when RAM_READY changes from '0' to '1')
	
	--Signals derived from RAM transactions
	signal ram_1st_data		:	std_logic_vector (15 downto 0);		--Holds first data of RAM at each transaction
	signal ram_words_left	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) stored in RAM, that has not been transfered YET to SDRAM
	signal ram_words_cnt	:	std_logic_vector (7 downto 0);		--Number of words (16 bits) that has not been transfered YET to SDRAM (Chunks of 256)
	signal ram_addr_out_i	:	std_logic_vector (8 downto 0); 		--Output address to RAM
	signal ram_samp_dt		:	std_logic_vector (15 downto 0);		--Latched data from RAM (to improve timing)
	signal inc_sum_wr_cnt	:	std_logic_vector (1 downto 0);		--Command to the sum_wr_cnt: "00": Do nothing ; "01" : Add ram_samp_dt to sum_wr_cnt ; "10" : Reset sum_wr_cnt to 0
	signal ram_latch_1st_dat:	boolean;							--TRUE: at wbm_wait_burst_st --> latches 1st RAM data for 1 clock only
	
	--State machine
	signal wbm_cur_st		:	wbm_states;
	
  ---------------------------------  Implementation	------------------------------
  begin
	
	------------------------------	Hidden processes	--------------------------
						
	--Output address to RAM
	ram_addr_out_proc:
	ram_addr_out	<=	ram_addr_out_i;
	
	--Cycle to SDRAM (WBM_CYC_O)
	wbm_cyc_o_proc:
	wbm_cyc_o <= 	wbm_cyc_internal when (not neg_cyc_bool) 
					else '0'; --Negate CYC together with last ACK
	
	--Strobe to SDRAM (WBM_STB_O)
	wbm_stb_o_proc:
	wbm_stb_o	<= 	wbm_stb_internal;
						
	--Write enable to SDRAM (WBM_WE_O) is always '1' for this component
	wbm_we_o_proc:
	wbm_we_o <= '1';
	
	--Data out (WBM_DAT_O)
	wbm_dat_o_proc:
	wbm_dat_o  <= 	ram_1st_data when dat_1st_bool
					else ram_data_out;
	
	--Address out to SDRAM (WBM_ADR_O)
	wbm_adr_o_proc:
	wbm_adr_o		<= 	cur_wr_addr;
	
	--Write counter to Mem_Ctrl_Read
	wr_cnt_proc:
	wr_cnt_val <= conv_std_logic_vector(wr_cnt_to_rd,integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))));
	
	--############################################################################--
	--						Start of Wishbone Master							  --
	--############################################################################--
	---------------------------------------------------------------------------------
	
	---------------------------------------------------------------------------------
	----------------------------- Process wbm_fsm_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process is the FSM of the Wishbone Master, which transmit data from the 
	-- internal RAM to the SDRAM.
	-- Handled output signals in this process:
	-- * wbm_tga_o	-	Burst length to SDRAM
	---------------------------------------------------------------------------------
	wbm_fsm_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbm_cur_st		<= wbm_idle_st;
            wbm_tga_o		<= (others => '0');
			cur_wr_addr		<= (others => '0');
			ram_addr_out_i	<= (others => '0');
			ram_words_left	<= (others => '0');
            wbm_cyc_internal<= '0';
			wbm_stb_internal<= '0';
			ram_words_cnt	<= (others => '0');
			--ram_aout_valid	<= '0';
			addr_pipe		<= (others => '0');
			sum_pipe_bool	<= false;

		elsif rising_edge (clk_i) then
			case wbm_cur_st is
				when wbm_idle_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out_i	<= (others => '0');
					ram_words_cnt	<= (others => '0');
					--ram_aout_valid	<= '1';

					ram_words_left	<= ram_num_words;			--Latch number of words in RAM

					--Check whether all data from data provider has been stored to RAM
					if (ram_ready_der = '1') then					--RAM is ready. Transmit data to SDRAM
						if (type_reg(message_g) = '0') then	--Image chunk
							wbm_cur_st	<= wbm_req_arb_st;
							if (type_reg(mode_g) = '0') then	--Normal Mode
								cur_wr_addr	<= cur_wr_addr;
								addr_pipe	<= conv_std_logic_vector (conv_integer(x"FF" - cur_wr_addr(7 downto 0)),8);	--For pipeline
							else								--Debug mode
								cur_wr_addr	<= wr_addr_reg;
								addr_pipe	<= conv_std_logic_vector (conv_integer(x"FF" - wr_addr_reg(7 downto 0)),8);	--For pipeline
							end if;
						else									--Summary chunk
							cur_wr_addr		<= cur_wr_addr;
							wbm_cur_st		<= wbm_wait_sum_st;
						end if;
					else
						cur_wr_addr	<= cur_wr_addr;
						wbm_cur_st 	<= wbm_idle_st;
					end if;
				
				when wbm_req_arb_st =>
					ram_words_left		<= ram_words_left;
					--ram_aout_valid		<= '1';
					cur_wr_addr			<= cur_wr_addr;
					
					if (arbiter_gnt = '1') then								--Grant on SDRAM from arbiter
						wbm_cyc_internal<= '1';
						wbm_stb_internal<= '1';
						ram_addr_out_i	<= ram_addr_out_i + '1';
						wbm_cur_st		<= wbm_tx_st;

						--First burst length to SDRAM
						if (ram_num_words > addr_pipe) then	--Current SDRAM page cannot contain all RAM information
							ram_words_cnt	<= addr_pipe;
							wbm_tga_o		<= addr_pipe;		--Maximum possible burst length
						else
							ram_words_cnt	<= ram_num_words(7 downto 0);
							wbm_tga_o		<= ram_num_words(7 downto 0);			--Burst length
						end if;
							
					else
						wbm_cyc_internal	<= '0';
						wbm_stb_internal	<= '0';
						ram_addr_out_i		<= ram_addr_out_i;
						ram_words_cnt		<= ram_words_cnt;
						cur_wr_addr			<= cur_wr_addr;
						wbm_cur_st			<= wbm_req_arb_st;
					end if;
				
				when wbm_tx_st =>
					wbm_cyc_internal<= '1';
					
					if ram_cnt_zero_bool then						--End of cycle
						ram_words_left	<= ram_words_left;
						ram_words_cnt	<= ram_words_cnt;
						if (wbm_stall_i = '0') and (ram_words_left /= "000000000") then		
							ram_addr_out_i	<= ram_addr_out_i + '1';
							ram_words_left	<= ram_words_left - '1';
						else										--End of total burst
							ram_addr_out_i	<= ram_addr_out_i;
							ram_words_left	<= ram_words_left;
						end if;
						if (wbm_stall_i = '1') then					--Not ready for next data	
							wbm_stb_internal	<= wbm_stb_internal;
						else
							wbm_stb_internal	<= '0';
						end if;
						cur_wr_addr		<= cur_wr_addr + '1';
						addr_pipe		<= conv_std_logic_vector (conv_integer(x"FE" - cur_wr_addr(7 downto 0)),8);	--For pipeline
						--ram_aout_valid	<= '0';
						wbm_cur_st		<= wbm_wait_burst_st;
						
					else											--Cycle in progress
						--ram_aout_valid	<= '1';
						wbm_stb_internal<= '1';
						wbm_cur_st		<= wbm_tx_st;

						--Check SDRAM STALL_I status
						if (wbm_stall_i = '0') then					--Ready for next data	
							ram_addr_out_i 	<= ram_addr_out_i + '1';
							cur_wr_addr		<= cur_wr_addr + '1';
							ram_words_left	<= ram_words_left - '1';
							ram_words_cnt	<= ram_words_cnt - '1';
						else										--Repeat last transaction
							ram_addr_out_i	<= ram_addr_out_i;
							cur_wr_addr		<= cur_wr_addr;
							ram_words_left	<= ram_words_left;
							ram_words_cnt	<= ram_words_cnt;
						end if;
					end if;
					
				when wbm_wait_burst_st =>

					ram_addr_out_i	<= ram_addr_out_i;
					cur_wr_addr		<= cur_wr_addr;
					ram_words_left	<= ram_words_left;

					--Burst length to SDRAM
					if (ram_words_left > addr_pipe(7 downto 0)) then	--Current SDRAM page cannot contain all RAM information
						ram_words_cnt	<= addr_pipe(7 downto 0);
						wbm_tga_o		<= addr_pipe(7 downto 0);		--Maximum possible burst length
					else
						ram_words_cnt	<= ram_words_left(7 downto 0);
						wbm_tga_o		<= ram_words_left(7 downto 0);			--Burst length
					end if;

					if (wbm_stall_i = '1') then						--Not ready for next data	
						wbm_stb_internal	<= wbm_stb_internal;
					else
						wbm_stb_internal	<= '0';
					end if;

					if (err_i_status = '1') then					--An error has occured
						wbm_cyc_internal<= '0';
						wbm_cur_st		<= wbm_idle_st;
					elsif (ack_i_cnt(8) = '1') then					--All data has been transmitted to SDRAM
						wbm_cyc_internal	<= '0';
						if (conv_integer(ram_words_left) = 0) then	--End of burst
							if (type_reg(mode_g) = '1') then		--Debug mode
								wbm_cur_st	<= wbm_bank_st;			--cur_wr_addr should be ready for image transfer
							else									--Normal mode
								wbm_cur_st	<= wbm_idle_st;
							end if;
						else
							wbm_cur_st	<= wbm_tx_st;
						end if;
					else											--Cycle is in progress
						wbm_cyc_internal<= '1';
						wbm_cur_st		<= wbm_wait_burst_st;
					end if;
					
				when wbm_wait_sum_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					cur_wr_addr		<= cur_wr_addr;
					ram_addr_out_i	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (ram_words_left(6 downto 0) & '0') + '1'; -- *2 + 1
					sum_pipe_bool	<= false;	--For pipeline
					--ram_aout_valid	<= '1';
					wbm_cur_st		<= wbm_sum_st;
				
				when wbm_sum_st =>
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					cur_wr_addr		<= cur_wr_addr;
					ram_words_left	<= ram_words_left;

					if (sum_pipe_bool) then
						ram_addr_out_i 	<= ram_addr_out_i;
					else
						ram_addr_out_i 	<= ram_addr_out_i + '1';
					end if;

					if ram_cnt_zero_bool then			--End of calculation
						ram_words_cnt	<= ram_words_cnt;
						--ram_aout_valid	<= '0';
						wbm_cur_st		<= wbm_bank_switch_st;
						sum_pipe_bool	<= sum_pipe_bool;
					
					else								--Calculation in progress
						sum_pipe_bool	<= (ram_words_cnt(0) = '1');
						ram_words_cnt	<= ram_words_cnt - '1';
						wbm_cur_st		<= wbm_sum_st;
						--ram_aout_valid	<= '1';
					end if;
				
				when wbm_bank_switch_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out_i	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');
					cur_wr_addr		<= cur_wr_addr;
					wbm_cur_st		<= wbm_wait_switch_st;

				when wbm_wait_switch_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out_i	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');
					cur_wr_addr		<= cur_wr_addr;
					wbm_cur_st		<= wbm_wait2_switch_st;

				when wbm_wait2_switch_st =>
					wbm_cur_st		<= wbm_bank_st;

				when wbm_bank_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out_i	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');

					cur_wr_addr(21)	<= bank_val;
					cur_wr_addr(20 downto 0)	<= (others => '0');
					wbm_cur_st		<= wbm_idle_st;
				
				when others =>
					wbm_cur_st		<= wbm_idle_st;
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					cur_wr_addr		<= (others => '0');
					ram_addr_out_i	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');
					report "Time: " & time'image(now) & ", mem_ctrl_wr_wbm, wbm_fsm_proc >> Undeclared state has been received!"
					severity error;
			end case;
		end if;
	end process wbm_fsm_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process arbiter_req_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the arbiter_req signal
	---------------------------------------------------------------------------------
	arbiter_req_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			arbiter_req	<= '0';
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_idle_st) then
			-- if (ram_ready_der = '0')	--RAM is not ready ; cur_st = WBM_IDLE_ST
			-- or (wbm_cur_st = wbm_bank_switch_st) 
			-- or (wbm_cur_st = wbm_bank_st) then
				arbiter_req	<= '0';
			else
				arbiter_req	<= '1';
			end if;
		end if;
	end process arbiter_req_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process wr_cnt_en_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the wr_cnt_en signal, which signals that the wr_cnt
	-- is valid, and latches wr_cnt, to transmit to Mem_Mng_Rd
	---------------------------------------------------------------------------------
	wr_cnt_en_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wr_cnt_en		<= '0';
			wr_cnt_to_rd	<= 0;
		elsif rising_edge (clk_i) then
			-- if (wbm_cur_st = wbm_sum_st)
			-- and ram_cnt_zero_bool then 	--End of calculation
			if (wbm_cur_st = wbm_wait_switch_st) 
			and (sum_wr_cnt = wr_cnt*2) then --Image is OK. End of image transmission
				wr_cnt_to_rd	<= wr_cnt;		--Latch value, for Mem_Mng_Rd
				wr_cnt_en		<= '1';
			else
				wr_cnt_en		<= '0';
				wr_cnt_to_rd	<= wr_cnt_to_rd;
			end if;
		end if;
	end process wr_cnt_en_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process bank_switch_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the bank_switch signal
	---------------------------------------------------------------------------------
	bank_switch_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			bank_switch		<= '0';
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_wait_switch_st) 
			and (sum_wr_cnt = wr_cnt*2) then --Image is OK. Note that sum_wr_cnt count BYTES, while wr_cnt count WORDS
				bank_switch		<= '1';			--Switch banks
			else
				bank_switch		<= '0';	
			end if;
		end if;
	end process bank_switch_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process first_data_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_1st_data signal, for first data transfer, and
	-- the dat_1st_bool signal, which indicates whether to use or not use the
	-- ram_1st_data signal.
	---------------------------------------------------------------------------------
	first_data_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_1st_data	<= (others => '0');
			dat_1st_bool	<= true;
		
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_req_arb_st) then
				dat_1st_bool		<= true;			--Use ram_1st_data as input to SDRAM
				if (arbiter_gnt = '1') then 			--Grant on SDRAM from arbiter
					ram_1st_data	<= ram_data_out;	--Output value of RAM
				else
					ram_1st_data	<= ram_1st_data;	--Keep last value
				end if;
			
			elsif (wbm_cur_st = wbm_tx_st) then
				ram_1st_data		<= ram_1st_data;	--Keep last value
				if ram_cnt_zero_bool then
					dat_1st_bool	<= true;
				elsif (wbm_stall_i = '0') then
					if dat_1st_bool then				--WBM_DAT_O indication
						dat_1st_bool<= false;
					else
						dat_1st_bool<= dat_1st_bool;	--Keep last value
					end if;
				else
					dat_1st_bool	<= dat_1st_bool;	--Keep last value
				end if;
				
			elsif (wbm_cur_st = wbm_wait_burst_st) and (ram_latch_1st_dat) then
				ram_1st_data		<= ram_data_out;	--Output value of RAM
				dat_1st_bool		<= true;			--Use ram_1st_data as input to SDRAM
				
			else
				ram_1st_data		<= ram_1st_data;	--Keep last value
				dat_1st_bool		<= dat_1st_bool;	--Keep last value
			end if;
		end if;
	end process first_data_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process ack_i_cnt_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process counts the number of WBM_ACK_I that has been received, which
	-- suppose to be equal to the number of WBM_STB_O that has been transmitted.
	---------------------------------------------------------------------------------
	ack_i_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ack_i_cnt	<= (others => '1'); --MSB Bit = '1' indicates on end of counting
			neg_cyc_bool<= false;
			
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_req_arb_st) 
			or ((wbm_cur_st = wbm_wait_burst_st) and (ack_i_cnt(8) = '1')) then	--Setting SDRAM Burst Length = number of expected ABM_ACK_I
				if (ram_words_left > (addr_pipe(7 downto 0))) then
					ack_i_cnt(7 downto 0)	<= addr_pipe(7 downto 0);
					ack_i_cnt(8)			<= '0';
				else
					ack_i_cnt(7 downto 0)	<= ram_words_left (7 downto 0);
					ack_i_cnt(8)			<= '0';
				end if;
				neg_cyc_bool	<= false;

			elsif (wbm_ack_i = '1') then --TODO: Remove me: and (ack_i_cnt > 0) then				--WBM_ACK_I has been received
				if (ack_i_cnt = '0' & x"00") then
					neg_cyc_bool	<= true;
				else
					neg_cyc_bool	<= false;
				end if;
				ack_i_cnt	<= ack_i_cnt - '1';
			else
				ack_i_cnt	<= ack_i_cnt;
				neg_cyc_bool<= false;
			end if;
		end if;
	end process ack_i_cnt_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process wr_cnt_internal_proc	---------------------
	---------------------------------------------------------------------------------
	-- The process counts the number of transmitted words to SDRAM, according to
	-- WBM_ACK_I indication.
	---------------------------------------------------------------------------------
	wr_cnt_internal_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wr_cnt			<= 0;
		elsif rising_edge(clk_i) then
			if (wbm_cur_st = wbm_bank_st) 	--Switch banks
			or ((ram_ready_der = '1') and (type_reg (0) = '1')) then	--Debug mode
				wr_cnt		<= 0;
			elsif (wbm_ack_i = '1') then	--WBM_ACK_I has been received
				wr_cnt		<= wr_cnt + 1;
			else
				wr_cnt		<= wr_cnt;
			end if;
		end if;
	end process wr_cnt_internal_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process ctrl_sum_wr_cnt_proc	---------------------
	---------------------------------------------------------------------------------
	-- The process controls the sum_wr_cnt_proc control signals:
	-- (1) Latched data from RAM ; (2) Command to change the sum_wr_cnt
	---------------------------------------------------------------------------------
	ctrl_sum_wr_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_samp_dt		<= (others => '0');
			inc_sum_wr_cnt	<= (others => '0');
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_sum_st) then
				if (ram_words_cnt(0) = '1') then
					ram_samp_dt		<=	x"00" & ram_data_out (7 downto 0);
				else
					ram_samp_dt	<=	ram_data_out (15 downto 8) & x"00";
				end if;
				inc_sum_wr_cnt	<=	"01";	--Add data to sum_wr_cnt at next clock
			elsif (wbm_cur_st = wbm_bank_st) then
				inc_sum_wr_cnt	<=	"10";
			else
				inc_sum_wr_cnt	<=	"00";	--Do nothing with sum_wr_cnt (keep current value)
			end if;
		end if;
	end process ctrl_sum_wr_cnt_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process sum_wr_cnt_ff_proc	---------------------
	---------------------------------------------------------------------------------
	-- The process controls the sum_wr_cnt_proc signal, which holds the number of 
	-- bytes, that has been sent by the host.
	---------------------------------------------------------------------------------
	sum_wr_cnt_ff_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			sum_wr_cnt	<= img_hor_pixels_g*img_ver_lines_g;
		elsif rising_edge (clk_i) then
			if (inc_sum_wr_cnt = "01") then	--Add data
				sum_wr_cnt	<= img_hor_pixels_g*img_ver_lines_g;
				--sum_wr_cnt	<= sum_wr_cnt + conv_integer(ram_samp_dt);
			elsif (inc_sum_wr_cnt = "10") then --Reset counter
				sum_wr_cnt	<= img_hor_pixels_g*img_ver_lines_g;

				--sum_wr_cnt	<= 0;
			else
				sum_wr_cnt	<= img_hor_pixels_g*img_ver_lines_g;
				--sum_wr_cnt	<=	sum_wr_cnt;
			end if;
		end if;
	end process sum_wr_cnt_ff_proc;

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
	----------------------------- Process ram_cnt_bool	-----------------------------
	---------------------------------------------------------------------------------
	-- The process is pipeline for ram_words_cnt
	---------------------------------------------------------------------------------
	ram_cnt_bool_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_cnt_zero_bool	<= false;
		elsif rising_edge (clk_i) then
			ram_cnt_zero_bool	<= (ram_words_cnt = x"01")	;
		end if;
	end process ram_cnt_bool_proc;

	---------------------------------------------------------------------------------
	-------------------- Process ram_ready_der_proc	---------------------------------
	---------------------------------------------------------------------------------
	-- The process derivates the RAM_READY signal, when it changes from '0' to '1',
	-- and the current state is WBM_IDLE_ST
	---------------------------------------------------------------------------------
	ram_ready_der_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_ready_der		<= '0';
		elsif rising_edge (clk_i) then
			if (ram_ready = '1') and (wbm_cur_st = wbm_idle_st) then
				ram_ready_der	<= '1';
			else
				ram_ready_der	<= '0';
			end if;
		end if;
	end process ram_ready_der_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process wbm_busy_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process controls the 'wbm_busy' signal:
	-- '1' when WBM_CUR_ST /= WBM_IDLE_ST, '0' otherwise
	---------------------------------------------------------------------------------
	wbm_busy_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbm_busy		<= '1';	--At reset - signal that WBM is busy, until reset recovery
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_idle_st) then
				wbm_busy	<= '0';
			else
				wbm_busy	<= '1';
			end if;
		end if;
	end process wbm_busy_proc;
	
	---------------------------------------------------------------------------------
	--------------------- Process ram_1st_data_st_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process controls the signal, to assure first RAM data correctness
	---------------------------------------------------------------------------------
	ram_1st_data_st_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_latch_1st_dat	<=	true;
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_wait_burst_st) then
				ram_latch_1st_dat	<=	false;
			else
				ram_latch_1st_dat	<=	true;
			end if;
		end if;
	end process ram_1st_data_st_proc;
	
	--Current written bank
	dbg_wr_bank_proc:
	dbg_wr_bank	<=	cur_wr_addr(21);
	
end architecture rtl_mem_ctrl_wr_wbm;