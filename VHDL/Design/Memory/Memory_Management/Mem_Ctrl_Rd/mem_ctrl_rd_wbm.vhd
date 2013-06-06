------------------------------------------------------------------------------------------------
-- Model Name 	:	Memory Control Read Wishbone Master
-- File Name	:	mem_ctrl_rd_wbm.vhd
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
--			1.1			19.4.2013	Uri and Ran				ram_ready_sr_proc updated to 4 stage shift register to support debug mode for image manipulation
--			1.11		29.4.2013 	Uri						wbm_adr_o_proc edited to read from half of bank in normal	
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity mem_ctrl_rd_wbm is
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
		ram_ready	:	out std_logic;							--Active for 4 clock cycles, when data can be read from internal RAM 
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
		dbg_rd_bank_sw		:	in std_logic;						--selected bank to display
		dbg_rd_bank_sw_mux	:	in std_logic;						--mux to select if manual bank switching enabled

		dbg_rd_bank	:	out std_logic						--Current bank, which is Read from.
		); 
end entity mem_ctrl_rd_wbm;

architecture rtl_mem_ctrl_rd_wbm of mem_ctrl_rd_wbm is

  ---------------------------------  Types		----------------------------------
	
	--Wishbone Master State Machine
	type wbm_states is (
						wbm_idle_st,		--Idle state
						wbm_req_arb_st,		--Wait for grant on SDRAM from arbiter
						wbm_rx_st,			--Receiving data from SDRAM, and storing to RAM
						wbm_wait_burst_st,	--Pause between 256 words transaction
						wbm_bank_st			--Change read address from SDRAM
						);
  
  ---------------------------------  Constants	----------------------------------
	constant delay_sdram_ram_c		:	positive := 13;	--Number of words, which will be read from SDRAM to RAM, before enabling WBS to read data from RAM, to prevent empty RAM
	constant release_arb_c			:	std_logic_vector (11 downto 0) := x"560";	--Release arbiter, and try again
	
  ---------------------------------  Signals	----------------------------------
	--General signals
	signal ram_ready_i		:	std_logic;							--Internal RAM Ready
	signal ram_ready_sr		:	std_logic_vector (4 downto 0);		--Shift Register of RAM_Ready_i
	signal ack_i_cnt		:	natural range 0 to 256;				--Number of expected WBM_ACK_I
	signal err_i_status		:	std_logic;							--WBM_ERR_I has been received
	signal neg_cyc_bool		:	boolean;							--TRUE: Negate NOW (At this clock) WBM_CYC_O, FALSE otherwise
	signal dat_1st_bool		:	boolean;							--TRUE: First read data on ram at each transaction, FALSE otherwise
	signal wbm_cyc_internal	:	std_logic;							--Internal WBS_CYC_O
	signal wbm_stb_internal	:	std_logic;							--Internal WBS_STB_O
	signal cur_rd_addr		:	std_logic_vector(21 downto 0);		--Current read address from SDRAM
	signal rd_cnt 			:	natural range 0 to img_hor_pixels_g*img_ver_lines_g - 1;	--Number of read words (16 bits) to the SDRAM 
	signal rd_cnt_i			:	natural range 0 to img_hor_pixels_g*img_ver_lines_g - 1;	--Number of read words (16 bits) to the SDRAM at the beginning of the transaction
	signal first_rx_bool	:	boolean;							--TRUE: First image transmission. Relevant for rd_cnt_i. FALSE otherwise	
	--signal update_rdcnt_bool:	boolean;							--TRUE: Update rd_cnt_i
	signal addr_pipe		:	std_logic_vector(7 downto 0);		--For pipeline
	signal init_rd_d1		:	std_logic;							--init_rd in one clock delay
	signal init_rd_bool		:	boolean;							--Init SDRAM transaction upon RESTART_RD assertion
	signal restart_rd_d1	:	std_logic;							--Restart_rd in one clock delay
	signal restart_rd_bool	:	boolean;							--Restart SDRAM transaction upon RESTART_RD assertion
	signal release_arb_cnt	:	std_logic_vector (12 downto 0);		--To release ARBITER, for SDRAM Write
	
	--Signals for RAM
	signal ram_addr_in_i	:	std_logic_vector (8 downto 0);		--Write address to RAM
	
	--Signals derived from RAM transactions
	signal ram_words_left	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) waiting to be stored in RAM
	signal ram_words_cnt	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) that has not been transfered YET from SDRAM (Chunks of 256)
	signal ram_delay_cnt	:	natural range 0 to delay_sdram_ram_c;--Delay counter, from the start of SDRAM transaction to read from RAM
	
	--State machines
	signal wbm_cur_st		:	wbm_states;
	
	signal cur_rd_addr_temp		:	std_logic_vector(21 downto 0);		--Current read address from SDRAM

  ---------------------------------  Implementation	------------------------------
  begin
	
	------------------------------	Hidden processes	--------------------------
	
	--Write address to RAM
	ram_addr_in_proc:
	ram_addr_in		<=	ram_addr_in_i;
	
	--Input data to RAM
	ram_data_in_proc:
	ram_data_in		<=	wbm_dat_i;
	
	--Input data to RAM is valid
	ram_din_valid_proc:
	ram_din_valid	<=	wbm_ack_i;
	
	--Cycle to SDRAM (WBM_CYC_O)
	wbm_cyc_o_proc:
	wbm_cyc_o 	<= 	wbm_cyc_internal when (not neg_cyc_bool) 
					else '0'; --Negate CYC together with last ACK
	
	--Strobe to SDRAM (WBM_STB_O)
	wbm_stb_o_proc:
	wbm_stb_o	<= 	wbm_stb_internal;
						
	--Write enable to SDRAM (WBM_WE_O) is always '0' for this component
	wbm_we_o_proc:
	wbm_we_o 	<= '0';
	
	--Address out to SDRAM (WBM_ADR_O)
	-- original image [bank 0,msb 1], manipulated image [bank 0,msb 0]
	 -- wbm_adr_o_proc:
	 -- wbm_adr_o <=cur_rd_addr;
	
	--Address out to SDRAM (WBM_ADR_O)
	-- -- -- original image [bank 0,msb 0], manipulated image [bank 0,msb 1]
	 wbm_adr_o_proc:
	 wbm_adr_o(21)			<= 	cur_rd_addr_temp(21);
	 
	 -- wbm_adr_o(20)			<= 	not(type_reg(mode_g)); --when debug put 0- read from bottom half of bank, when normal put 1- read from top half of bank
	 wbm_adr_o(20) <= not(type_reg(mode_g)) when dbg_rd_bank_sw_mux='0'
					else dbg_rd_bank_sw;
	 
	 wbm_adr_o(19 downto 0)	<= 	cur_rd_addr_temp(19 downto 0) ;
	 cur_rd_addr_temp <=cur_rd_addr;
	

	--############################################################################--
	--						Start of Wishbone Master							  --
	--############################################################################--
	---------------------------------------------------------------------------------
	----------------------------- Process wbm_fsm_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process is the FSM of the Wishbone Master, which receives data from the 
	-- SDRAM and stores it to  the SDRAM.
	---------------------------------------------------------------------------------
	wbm_fsm_proc: process (clk_i, rst)
	begin

		if (rst = reset_polarity_g) then
			wbm_cur_st		<= wbm_idle_st;
            wbm_tga_o		<= (others => '0');
			cur_rd_addr		<= (others => '0');
			ram_addr_in_i	<= (others => '0');  
			ram_words_left	<= (others => '0');
            wbm_cyc_internal<= '0';
			wbm_stb_internal<= '0';
			ram_words_cnt	<= (others => '0');
			dat_1st_bool	<= true;
			addr_pipe		<= (others => '0');
			--update_rdcnt_bool	<= true;

		elsif rising_edge (clk_i) then
			case wbm_cur_st is
				when wbm_idle_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_in_i	<= (others => '0'); 
					ram_words_cnt	<= (others => '0');

					ram_words_left	<= ram_words_in;		--Latch number of words in RAM

					--Wait for init SDRAM transaction flag
					if (restart_rd_bool) then
						wbm_cur_st	<=	wbm_bank_st;		--Restart SDRAM transaction
					elsif (init_rd_bool) then				--Init SDRAM transaction
						--update_rdcnt_bool	<= false;
						wbm_cur_st	<= wbm_req_arb_st;
						if (type_reg(mode_g) = '0') then	--Normal Mode
							cur_rd_addr	<= cur_rd_addr;
							addr_pipe	<= conv_std_logic_vector (conv_integer(x"FF" - cur_rd_addr(7 downto 0)),8);	--For pipeline
						else								--Debug mode
							cur_rd_addr	<= rd_addr_reg;
							addr_pipe	<= conv_std_logic_vector (conv_integer(x"FF" - rd_addr_reg(7 downto 0)),8);	--For pipeline
						end if;
					else
						cur_rd_addr	<= cur_rd_addr;
						wbm_cur_st 	<= wbm_idle_st;
					end if;
				
				when wbm_req_arb_st =>
					ram_words_left		<= ram_words_left;
					cur_rd_addr			<= cur_rd_addr;
					ram_addr_in_i		<= ram_addr_in_i;
					
					if (restart_rd_bool) then
						wbm_cur_st	<=	wbm_bank_st;		--Restart SDRAM transaction
					elsif (arbiter_gnt = '1') then			--Grant on SDRAM from arbiter
						wbm_cyc_internal<= '1';
						wbm_stb_internal<= '1';
						wbm_cur_st		<= wbm_rx_st;
						dat_1st_bool	<= true;

						--First burst length to SDRAM
						
						if (type_reg(mode_g) = '0') then					--Normal mode
							if (rd_cnt_i > conv_integer(addr_pipe)) then	--Current SDRAM page's position is not start of page
								ram_words_cnt	<= '0' & addr_pipe;
								wbm_tga_o		<= addr_pipe;				--Maximum possible burst length
							else
								ram_words_cnt	<= conv_std_logic_vector (rd_cnt_i, 9);
								wbm_tga_o		<= conv_std_logic_vector(rd_cnt_i, 8);	--Burst length
							end if;

						else													--Debug mode
							if (ram_words_in > addr_pipe) then					--Current SDRAM page's position is not start of page
								ram_words_cnt	<= '0' & addr_pipe;
								wbm_tga_o		<= addr_pipe;					--Maximum possible burst length
							else
								ram_words_cnt	<= ram_words_in;
								wbm_tga_o		<= ram_words_in(7 downto 0);	--Burst length
							end if;
						end if;
					else
						wbm_cyc_internal	<= '0';
						wbm_stb_internal	<= '0';
						ram_addr_in_i		<= ram_addr_in_i;
						ram_words_cnt		<= ram_words_cnt;
						cur_rd_addr			<= cur_rd_addr;
						wbm_cur_st			<= wbm_req_arb_st;
					end if;
				
				when wbm_rx_st =>
					wbm_cyc_internal<= '1';
					if (restart_rd_bool) then
						wbm_cur_st	<=	wbm_bank_st;				--Restart SDRAM transaction
					elsif (release_arb_cnt (12) = '1') then			--Timeout
						wbm_cur_st		<= wbm_bank_st;
					elsif (ram_words_cnt = "000000000") then						--End of cycle
						ram_words_cnt	<= ram_words_cnt;
						ram_addr_in_i		<= ram_addr_in_i + '1';
						if (ram_words_left /= "000000000") then		
							ram_words_left	<= ram_words_left - '1';
						else										--End of total burst
							ram_words_left	<= ram_words_left;
						end if;
						addr_pipe		<= x"FE" - cur_rd_addr(7 downto 0);
						wbm_stb_internal<= '0';
						cur_rd_addr		<= cur_rd_addr + '1';
						wbm_cur_st		<= wbm_wait_burst_st;
						
					else											--Cycle in progress
						wbm_stb_internal<= '1';
						wbm_cur_st		<= wbm_rx_st;

						--Check SDRAM STALL_I status
						if (wbm_stall_i = '0') then					--Ready for next data	
							if dat_1st_bool then
								ram_addr_in_i		<= ram_addr_in_i;
								dat_1st_bool	<= false;
							else
								ram_addr_in_i		<= ram_addr_in_i + '1';
								dat_1st_bool	<= false;
							end if;
							cur_rd_addr		<= cur_rd_addr + '1';
							ram_words_left	<= ram_words_left - '1';
							ram_words_cnt	<= ram_words_cnt - '1';
						else										--Repeat last transaction
							ram_addr_in_i		<= ram_addr_in_i;
							cur_rd_addr		<= cur_rd_addr;
							ram_words_left	<= ram_words_left;
							ram_words_cnt	<= ram_words_cnt;
						end if;
					end if;

							
				when wbm_wait_burst_st =>

					cur_rd_addr		<= cur_rd_addr;
					ram_words_left	<= ram_words_left;

					if (wbm_ack_i = '1') then
						ram_addr_in_i		<= ram_addr_in_i + '1';
					else
						ram_addr_in_i		<= ram_addr_in_i;
					end if;
					
					--Burst length to SDRAM
					if (type_reg(mode_g) = '0') then						--Normal mode
						if (rd_cnt_i > (255 - conv_integer(cur_rd_addr(7 downto 0)))) then	--Current SDRAM page's position is not start of page
							ram_words_cnt	<= '0' & (x"FF" - cur_rd_addr(7 downto 0));
							wbm_tga_o		<= x"FF" - cur_rd_addr(7 downto 0);		--Maximum possible burst length
						else
							ram_words_cnt	<= conv_std_logic_vector(rd_cnt_i, 9);
							wbm_tga_o		<= conv_std_logic_vector(rd_cnt_i, 8);	--Burst length
						end if;

					else													--Debug mode
						if (ram_words_left > (255 - cur_rd_addr(7 downto 0))) then	--Current SDRAM page's position is not start of page
							ram_words_cnt	<= '0' & (x"FF" - cur_rd_addr(7 downto 0));
							wbm_tga_o		<= x"FF" - cur_rd_addr(7 downto 0);		--Maximum possible burst length
						else
							ram_words_cnt	<= ram_words_left;
							wbm_tga_o		<= ram_words_left(7 downto 0);			--Burst length
						end if;
					end if;

					if (wbm_stall_i = '1') then						--Not ready for next data	
						wbm_stb_internal	<= wbm_stb_internal;
					else
						wbm_stb_internal	<= '0';
					end if;

					if (err_i_status = '1') then	--An error has occured
						wbm_cyc_internal<= '0';
						wbm_cur_st		<= wbm_idle_st;
					elsif (rd_cnt_i = 0) then
						wbm_cyc_internal<= '0';
						wbm_cur_st		<= wbm_bank_st;
					elsif (ack_i_cnt = 0) then						--All data has been transmitted from SDRAM
						wbm_cyc_internal	<= '0';
						if (conv_integer(ram_words_left) = 0) then	--End of burst (Debug mode)
							if (type_reg(mode_g) = '0') then
								wbm_cur_st	<= wbm_idle_st;
							else
								wbm_cur_st	<= wbm_bank_st;			--cur_rd_addr should be ready for image transfer
							end if;
						else
							wbm_cur_st	<= wbm_rx_st;
							dat_1st_bool<= true;
						end if;
					elsif (restart_rd_bool) then
						wbm_cyc_internal<= '0';
						wbm_cur_st		<=	wbm_bank_st;			--Restart SDRAM transaction
					elsif (release_arb_cnt (12) = '1') then			--Timeout
						wbm_cyc_internal<= '0';
						wbm_cur_st		<= wbm_bank_st;
					else											--Cycle is in progress
						wbm_cyc_internal<= '1';
						wbm_cur_st		<= wbm_wait_burst_st;
					end if;
					
				when wbm_bank_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_in_i	<= (others => '0'); 
					
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');

					cur_rd_addr(21)	<= bank_val;
					cur_rd_addr(20 downto 0)	<= (others => '0');
					--update_rdcnt_bool	<= true;
					wbm_cur_st		<= wbm_idle_st;
				
				when others =>
					wbm_cur_st		<= wbm_idle_st;
					report "Time: " & time'image(now) & ", mem_ctrl_rd_wbm, wbm_fsm_proc >> Undeclared state has been received!"
					severity error;
			end case;
		end if;
	end process wbm_fsm_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process rd_cnt_i_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process controls the rd_cnt_i signal
	---------------------------------------------------------------------------------
	rd_cnt_i_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			rd_cnt_i	<= 0;
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_bank_st) then --or update_rdcnt_bool then				--New picture
				rd_cnt_i	<= rd_cnt;
			elsif first_rx_bool and (wr_cnt_en = '1') then	--First picture
				rd_cnt_i	<= conv_integer(wr_cnt_val);
			elsif (wbm_ack_i = '1') and (rd_cnt_i /= 0) then
				rd_cnt_i	<= rd_cnt_i - 1;
			else
				rd_cnt_i	<= rd_cnt_i;
			end if;
		end if;
	end process rd_cnt_i_proc;

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
			--or (wbm_cur_st = wbm_bank_st) then
				arbiter_req	<= '0';
			else
				arbiter_req	<= '1';
			end if;
		end if;
	end process arbiter_req_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process ack_i_cnt_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process counts the number of WBM_ACK_I that has been received, which
	-- suppose to be equal to the number of WBM_STB_O that has been transmitted.
	---------------------------------------------------------------------------------
	ack_i_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ack_i_cnt	<= 0;
			neg_cyc_bool<= false;
			
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_req_arb_st) 
			or ((wbm_cur_st = wbm_wait_burst_st) and (ack_i_cnt = 0)) then	--Setting SDRAM Burst Length = number of expected ABM_ACK_I
				if (ram_words_left > addr_pipe) then
					ack_i_cnt	<= conv_integer(addr_pipe) + 1;
				else
					ack_i_cnt	<= conv_integer(ram_words_left) + 1;
				end if;
				neg_cyc_bool	<= false;

			elsif (wbm_ack_i = '1') and (ack_i_cnt > 0) then				--WBM_ACK_I has been received
				if (ack_i_cnt = 1) then
					neg_cyc_bool	<= true;
				else
					neg_cyc_bool	<= false;
				end if;
				ack_i_cnt	<= ack_i_cnt - 1;
			else
				ack_i_cnt	<= ack_i_cnt;
				neg_cyc_bool<= false;
			end if;
		end if;
	end process ack_i_cnt_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process rd_cnt_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process sets the number of read transactions available from SDRAM.
	---------------------------------------------------------------------------------
	rd_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			rd_cnt		<= 0;
		elsif rising_edge(clk_i) then
			if (wr_cnt_en = '1') then	--wr_cnt_val from mem_ctrl_wr is valid
				rd_cnt	<= conv_integer(wr_cnt_val);
			else
				rd_cnt	<= rd_cnt;
			end if;
		end if;
	end process rd_cnt_proc;

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
	----------------------------- Process ram_ready_i_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_ready_i and ram_delay_cnt signals
	---------------------------------------------------------------------------------
	ram_ready_i_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_ready_i		<= '0';
			ram_delay_cnt	<= 0;		
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_rx_st) then
				if (ram_delay_cnt /= delay_sdram_ram_c) then	--Increment ram_delay_cnt
					ram_delay_cnt <= ram_delay_cnt + 1;
				else
					ram_delay_cnt <= ram_delay_cnt;
				end if;
			
				if (ram_delay_cnt = delay_sdram_ram_c - 1) then
					ram_ready_i	<= '1';
				else
					ram_ready_i	<= '0';
				end if;
			else
				ram_ready_i		<= '0';
				ram_delay_cnt	<= 0;
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
			ram_ready_sr (3 downto 0)	<= ram_ready_sr (4 downto 1);
			ram_ready_sr (4)			<= ram_ready_i;
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
	----------------------------- Process first_rx_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process controls the first_rx_bool signal
	---------------------------------------------------------------------------------
	first_rx_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			first_rx_bool		<= true;
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_bank_st) then
				first_rx_bool	<= false;
			else
				first_rx_bool	<= first_rx_bool;
			end if;
		end if;
	end process first_rx_proc;

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
	----------------------------- Process release_arb_proc	-------------------------
	---------------------------------------------------------------------------------
	-- Release Arbiter at end of transaction, in case of WBM_ACK_I timeout
	---------------------------------------------------------------------------------
	release_arb_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			release_arb_cnt		<=	'0' & release_arb_c;
			
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_wait_burst_st) or (wbm_cur_st = wbm_rx_st) then
				release_arb_cnt	<=	release_arb_cnt - '1';
			else
				release_arb_cnt	<=	'0' & release_arb_c;
			end if;
		end if;
	end process release_arb_proc;
			
	
	---------------------------------------------------------------------------------
	----------------------------- Process rd_cnt_zero_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process controls the 'rd_cnt_zero' signal:
	-- '1' rd_cnt_i = 0, '0' otherwise
	---------------------------------------------------------------------------------
	rd_cnt_zero_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			rd_cnt_zero		<= '1';	
		elsif rising_edge (clk_i) then
			if (rd_cnt_i = 0) then
				rd_cnt_zero	<= '1';
			else
				rd_cnt_zero	<= '0';
			end if;
		end if;
	end process rd_cnt_zero_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process init_rd_d1_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process is init_rd in one clock delay, AND derivates this signal
	---------------------------------------------------------------------------------
	init_rd_d1_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			init_rd_d1			<= '0';
			init_rd_bool		<= false;
		elsif rising_edge (clk_i) then
			init_rd_d1 		<=	init_rd;
			if (init_rd_d1 = '0') and (init_rd = '1') then	--Assertion of init_rd
				init_rd_bool	<= true;	--Init read from SDRAM
			else
				init_rd_bool	<= false;
			end if;
		end if;
	end process init_rd_d1_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process restart_rd_d1_proc	---------------------
	---------------------------------------------------------------------------------
	-- The process is restard_rd in one clock delay, AND derivates this signal
	---------------------------------------------------------------------------------
	restart_rd_d1_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			restart_rd_d1		<= '0';
			restart_rd_bool		<= false;
		elsif rising_edge (clk_i) then
			restart_rd_d1 		<=	restart_rd;
			if (restart_rd_d1 = '0') and (restart_rd = '1') then	--Assertion of restart_rd
				restart_rd_bool	<= true;	--Init read from SDRAM
			else
				restart_rd_bool	<= false;
			end if;
		end if;
	end process restart_rd_d1_proc;

	--Current written bank
	dbg_rd_bank_proc:
	dbg_rd_bank	<=	cur_rd_addr(21);
	
end architecture rtl_mem_ctrl_rd_wbm;