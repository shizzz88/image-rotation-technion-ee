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
--			1.01		24.1.2012	Ran&Uri					sum_wr_cnt signal was modified, to support 128*96 res input
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

entity mem_ctrl_wr is
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
		--##wbs_tgd_i (flag)
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
		--##type_reg2 (constant, not port)
		--##wr_addr_reg2
		wr_addr_reg	:	in std_logic_vector (21 downto 0);		--Write to SDRAM Address (Debug mode)
		
		-- Mem_Ctrl_Read signals
		wr_cnt_val	:	out std_logic_vector(integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))) - 1 downto 0);	--wr_cnt value
		wr_cnt_en	:	out std_logic							--wr_cnt write enable flag (Active for 1 clock)
		); 
end entity mem_ctrl_wr;

architecture rtl_mem_ctrl_wr of mem_ctrl_wr is

  ---------------------------------  Types		----------------------------------
	--Wishbone Slave State Machine
	type wbs_states is (
						wbs_idle_st,		--Idle state
						wbs_neg_stall_st,	--Negate STALL_O
						wbs_rx_st,			--Receiving data from data provider
						wbs_wait_end_cyc_st,--End of RAM, but not end of cycle
						wbs_done_st			--Done cycle. Next state: wbs_idle_st
						);
	
	--Wishbone Master State Machine
	type wbm_states is (
						wbm_idle_st,		--Idle state
						wbm_req_arb_st,		--Wait for grant on SDRAM from arbiter
						wbm_tx_st,			--Transmitting data to SDRAM
						wbm_wait_burst_st,	--Pause between 256 words transaction
						wbm_bank_switch_st,	--Switch double banks for writing / reading to / from SDRAM ('00' --> '10' or '10' --> '00')
						wbm_wait_switch_st,	--Wait for switch to happen
						wbm_bank_st,		--Change write address to SDRAM
						wbm_wait_sum_st,	--Prepare RAM with first data for summary calculations
						wbm_sum_st			--Summary chunk (Number of transmitted bytes in current image)
						);
  
  ---------------------------------  Components		------------------------------
  --RAM Generic
  component ram_generic
	generic (
				reset_polarity_g	:	std_logic 				:= '0';	--'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 				:= 8;	--Width of data
				addr_bits_g			:	positive 				:= 10;	--Depth of data	(2^10 = 1024 addresses)
				power2_out_g		:	natural 				:= 1;	--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide
				power_sign_g		:	integer range -1 to 1 	:= 1 	-- '-1' => output width < input width ; '1' => input width < output width
			);
	port	(
				clk					:	in std_logic;									--System clock
				rst					:	in std_logic;									--System Reset
				addr_in				:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out			:	in std_logic_vector ((addr_bits_g - power2_out_g*power_sign_g) - 1 downto 0); 		--Output address
				aout_valid			:	in std_logic;									--Output address is valid
				data_in				:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid			:	in std_logic; 									--Input data valid
				data_out			:	out std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0);	--Output data
				dout_valid			:	out std_logic 									--Output data valid
			);
  end component ram_generic;

  ---------------------------------  Signals	----------------------------------
	--General signals
	signal ram_ready		:	std_logic;							--Active for 1 clock cycle, when all data has been stored to internal RAM
	signal ack_i_cnt		:	std_logic_vector (8 downto 0);		--Number of expected WBM_ACK_I (0-->256)
	signal err_i_status		:	std_logic;							--WBM_ERR_I has been received
	signal dat_1st_bool		:	boolean;							--TRUE: First read data on ram at each transaction, FALSE otherwise
	signal neg_cyc_bool		:	boolean;							--TRUE: Negate NOW (At this clock) WBM_CYC_O, FALSE otherwise
	signal wbm_cyc_internal	:	std_logic;							--Internal WBS_CYC_O
	signal wbm_stb_internal	:	std_logic;							--Internal WBS_STB_O
	signal cur_wr_addr		:	std_logic_vector(21 downto 0);		--Current write address to SDRAM
	signal wr_cnt 			:	natural range 0 to img_hor_pixels_g*img_ver_lines_g - 1;	--Number of written words (16 bits) to the SDRAM 
	signal sum_wr_cnt 		:	natural range 0 to img_hor_pixels_g*img_ver_lines_g ;		--Summary chunk value----uri ran 17.1 added -1, 128x96 work without -1
	signal addr_pipe		:	std_logic_vector(7 downto 0);		--For pipeline
	signal sum_pipe_bool	:	boolean;							--For pipeline
	signal ram_cnt_zero_bool:	boolean;							--Indicates ram_words_cnt = x"01" (next is zero)
	--Latches registers values
	signal type_reg_i		:	std_logic_vector (7 downto 0);		--Internal Type Register
	signal addr_reg_i		:	std_logic_vector (21 downto 0);		--Write to SDRAM Address (Debug mode)
	
	--Signals for RAM
	signal ram_addr_out		:	std_logic_vector (8 downto 0);		--Read address from RAM
	signal ram_aout_val		:	std_logic;							--Read address from RAM is valid
	signal ram_din_valid	:	std_logic;							--Written data to RAM is valid
	signal ram_dout_valid	:	std_logic;							--Output data from RAM is valid
	signal ram_dout			:	std_logic_vector (15 downto 0);		--Output data from RAM
	signal ram_expect_adr	:	std_logic_vector (9 downto 0);		--Current EXPECTED (and actual) write address to RAM
	signal ram_1st_data		:	std_logic_vector (15 downto 0);		--Holds first data of RAM at each transaction
	
	--Signals derived from RAM transactions
	signal ram_words_out	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) stored in RAM
	signal ram_words_left	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) stored in RAM, that has not been transfered YET to SDRAM
	signal ram_words_cnt	:	std_logic_vector (7 downto 0);		--Number of words (16 bits) that has not been transfered YET to SDRAM (Chunks of 256)
	
	--State machines
	signal wbs_cur_st		:	wbs_states;
	signal wbm_cur_st		:	wbm_states;
	
  ---------------------------------  Implementation	------------------------------
  begin
	
	--Generic RAM: 8 bits input, 16 bits output
	ram1_inst: 	ram_generic
				generic map 
					(
					reset_polarity_g	=> reset_polarity_g,
					width_in_g		    => 8,	--8 bits input, 16 bits output 
					addr_bits_g		    => 10,	--RAM's size is 8 bits * 2^10
					power2_out_g	    => 1,	--Output size is 8 bits * 2^1
					power_sign_g	    => 1	--Output port > Input port
					)
				port map
					(
					clk			=> clk_i,
					rst			=> rst,
					addr_in		=> ram_expect_adr,
					addr_out	=> ram_addr_out,
					aout_valid	=> ram_aout_val,
					data_in		=> wbs_dat_i,
					din_valid	=> ram_din_valid,
					data_out	=> ram_dout,
					dout_valid	=> ram_dout_valid
					);
	
	------------------------------	Hidden processes	--------------------------
	--Input data to RAM is valid when receiving data from Wishbone Master
	din_valid_proc:
	ram_din_valid	<= '1' when (wbs_cur_st = wbs_rx_st)
						else '0';
						
	--Cycle to SDRAM (WBM_CYC_O)
	wbm_cyc_o_proc:
	wbm_cyc_o <= 	wbm_cyc_internal when (not neg_cyc_bool)
					else '0';
	
	--Strobe to SDRAM (WBM_STB_O)
	wbm_stb_o_proc:
	wbm_stb_o	<= 	wbm_stb_internal;
						
	--Write enable to SDRAM (WBM_WE_O) is always '1' for this component
	wbm_we_o_proc:
	wbm_we_o <= '1';
	
	--Data out (WBM_DAT_O)
	wbm_dat_o_proc:
	wbm_dat_o  <= 	ram_1st_data when dat_1st_bool
					else ram_dout;
	
	--Address out to SDRAM (WBM_ADR_O)
	wbm_adr_o_proc:
	wbm_adr_o		<= 	cur_wr_addr when ((wbm_cur_st = wbm_tx_st) or (wbm_cur_st = wbm_wait_burst_st))
						else (others => '0');
	
	--Write counter to Mem_Ctrl_Read
	wr_cnt_proc:
	wr_cnt_val <= conv_std_logic_vector(wr_cnt,integer(ceil(log(real(img_hor_pixels_g*img_ver_lines_g)) / log(2.0))));
	
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
			ram_expect_adr	<= (others => '0');
			
		elsif rising_edge(clk_i) then
			case wbs_cur_st is
				when wbs_idle_st =>
					wbs_err_o		<= '0';
					ram_expect_adr	<= ram_expect_adr;
					wbs_stall_o		<= '1';								--Not ready for next transaction
					wbs_ack_o 		<= '0';								--Data not acknowledged
					
					if (wbs_cyc_i = '1') and (wbm_cur_st = wbm_idle_st) then	--SDRAM write cycle is NOT in progress, and input transaction has just opened
						wbs_cur_st		<= wbs_neg_stall_st;
					else
						wbs_cur_st		<= wbs_idle_st;
					end if;
				
				when wbs_neg_stall_st =>
					wbs_err_o		<= '0';
					ram_expect_adr	<= (others => '0');
					wbs_stall_o		<= '0';								--Ready for next transaction
					wbs_ack_o 		<= '0';								--Data not acknowledged
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
						else
							wbs_cur_st		<= wbs_rx_st;             	    
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
					wbs_cur_st		<= wbs_idle_st;
					wbs_stall_o		<= '1';
					wbs_ack_o		<= '0';
					wbs_err_o		<= '0';
					ram_expect_adr	<= ram_expect_adr;
				
				when others =>
					wbs_cur_st		<= wbs_idle_st;
					wbs_stall_o		<= '1';
					wbs_ack_o		<= '0';
					wbs_err_o		<= '0';
					ram_expect_adr	<= ram_expect_adr;
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
			ram_words_out		<= (others => '0');					
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_neg_stall_st) then
				ram_words_out	<= wbs_tga_i (9 downto 1);		--Latch burst length / 2 (8 bits --> 16 bits)
			else
				ram_words_out	<= ram_words_out;
			end if;
		end if;
	end process burst_len_proc;	

	---------------------------------------------------------------------------------
	----------------------------- Process ram_ready_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_ready signal, to signal the WBM to start writing
	-- to the SDRAM
	---------------------------------------------------------------------------------
	ram_ready_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_ready	<= '0';
		elsif rising_edge (clk_i) then
			if ((wbs_cur_st = wbs_rx_st) 
			and (ram_expect_adr(9 downto 1) = '0' & ram_words_out(8 downto 1))) then	--Half of the data has been stored to RAM
				ram_ready	<= '1';
			else
				ram_ready	<= '0';
			end if;
		end if;
	end process ram_ready_proc;	

	--############################################################################--
	--						End of Wishbone Slave								  --
	--############################################################################--
	
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
			ram_addr_out	<= (others => '0');
			ram_words_left	<= (others => '0');
            wbm_cyc_internal<= '0';
			wbm_stb_internal<= '0';
			ram_words_cnt	<= (others => '0');
			ram_aout_val	<= '0';
			addr_pipe		<= (others => '0');

		elsif rising_edge (clk_i) then
			case wbm_cur_st is
				when wbm_idle_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out	<= (others => '0');
					ram_words_cnt	<= (others => '0');
					ram_aout_val	<= '1';

					ram_words_left	<= ram_words_out;			--Latch number of words in RAM

					--Check whether all data from data provider has been stored to RAM
					if (ram_ready = '1') then					--RAM is ready. Transmit data to SDRAM
						if (type_reg_i(message_g) = '0') then	--Image chunk
							wbm_cur_st	<= wbm_req_arb_st;
							if (type_reg_i(mode_g) = '0') then	--Normal Mode
								cur_wr_addr	<= cur_wr_addr;
								addr_pipe	<= conv_std_logic_vector (conv_integer(x"FF" - cur_wr_addr(7 downto 0)),8);	--For pipeline
							else								--Debug mode
								cur_wr_addr	<= addr_reg_i;
								addr_pipe	<= conv_std_logic_vector (conv_integer(x"FF" - addr_reg_i(7 downto 0)),8);	--For pipeline
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
					ram_aout_val		<= '1';
					cur_wr_addr			<= cur_wr_addr;
					
					if (arbiter_gnt = '1') then								--Grant on SDRAM from arbiter
						wbm_cyc_internal<= '1';
						wbm_stb_internal<= '1';
						ram_addr_out	<= ram_addr_out + '1';
						wbm_cur_st		<= wbm_tx_st;

						--First burst length to SDRAM
						if (ram_words_out > addr_pipe) then	--Current SDRAM page cannot contain all RAM information
							ram_words_cnt	<= addr_pipe;
							wbm_tga_o		<= addr_pipe;		--Maximum possible burst length
						else
							ram_words_cnt	<= ram_words_out(7 downto 0);
							wbm_tga_o		<= ram_words_out(7 downto 0);			--Burst length
						end if;
							
					else
						wbm_cyc_internal	<= '0';
						wbm_stb_internal	<= '0';
						ram_addr_out		<= ram_addr_out;
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
							ram_addr_out	<= ram_addr_out + '1';
							ram_words_left	<= ram_words_left - '1';
						else										--End of total burst
							ram_addr_out	<= ram_addr_out;
							ram_words_left	<= ram_words_left;
						end if;
						if (wbm_stall_i = '1') then					--Not ready for next data	
							wbm_stb_internal	<= wbm_stb_internal;
						else
							wbm_stb_internal	<= '0';
						end if;
						cur_wr_addr		<= cur_wr_addr + '1';
						addr_pipe		<= conv_std_logic_vector (conv_integer(x"FE" - cur_wr_addr(7 downto 0)),8);	--For pipeline
						ram_aout_val	<= '0';
						wbm_cur_st		<= wbm_wait_burst_st;
						
					else											--Cycle in progress
						ram_aout_val	<= '1';
						wbm_stb_internal<= '1';
						wbm_cur_st		<= wbm_tx_st;

						--Check SDRAM STALL_I status
						if (wbm_stall_i = '0') then					--Ready for next data	
							ram_addr_out 	<= ram_addr_out + '1';
							cur_wr_addr		<= cur_wr_addr + '1';
							ram_words_left	<= ram_words_left - '1';
							ram_words_cnt	<= ram_words_cnt - '1';
						else										--Repeat last transaction
							ram_addr_out	<= ram_addr_out;
							cur_wr_addr		<= cur_wr_addr;
							ram_words_left	<= ram_words_left;
							ram_words_cnt	<= ram_words_cnt;
						end if;
					end if;
					
				when wbm_wait_burst_st =>

					ram_addr_out	<= ram_addr_out;
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
					elsif (ack_i_cnt(8) = '1') then						--All data has been transmitted to SDRAM
						wbm_cyc_internal	<= '0';
						if (conv_integer(ram_words_left) = 0) then	--End of burst
							if (type_reg_i(mode_g) = '1') then		--Debug mode
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
					ram_addr_out	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (ram_words_left(6 downto 0) & '0') + '1'; -- *2 + 1
					sum_pipe_bool	<= false;	--For pipeline
					ram_aout_val	<= '1';
					wbm_cur_st		<= wbm_sum_st;
				
				when wbm_sum_st =>
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					cur_wr_addr		<= cur_wr_addr;
					ram_words_left	<= ram_words_left;

					if (sum_pipe_bool) then
						ram_addr_out 	<= ram_addr_out;
					else
						ram_addr_out 	<= ram_addr_out + '1';
					end if;

					if ram_cnt_zero_bool then			--End of calculation
						ram_words_cnt	<= ram_words_cnt;
						ram_aout_val	<= '0';
						wbm_cur_st		<= wbm_bank_switch_st;
						sum_pipe_bool	<= sum_pipe_bool;
					
					else								--Calculation in progress
						sum_pipe_bool	<= (ram_words_cnt(0) = '1');
						ram_words_cnt	<= ram_words_cnt - '1';
						wbm_cur_st		<= wbm_sum_st;
						ram_aout_val	<= '1';
					end if;
				
				when wbm_bank_switch_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');
					cur_wr_addr		<= cur_wr_addr;
					wbm_cur_st		<= wbm_wait_switch_st;

				when wbm_wait_switch_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');
					cur_wr_addr		<= cur_wr_addr;
					wbm_cur_st		<= wbm_bank_st;

				when wbm_bank_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_out	<= (others => '0');
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
					ram_addr_out	<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');
					report "Time: " & time'image(now) & ", Mem_Ctrl_Wr, wbm_fsm_proc >> Undeclared state has been received!"
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
			if ((wbm_cur_st = wbm_idle_st) and (ram_ready = '0'))
			or (wbm_cur_st = wbm_bank_switch_st) 
			or (wbm_cur_st = wbm_bank_st) then
				arbiter_req	<= '0';
			else
				arbiter_req	<= '1';
			end if;
		end if;
	end process arbiter_req_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process wr_cnt_en_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the wr_cnt_en signal, which signals that the wr_cnt_val
	-- is valid.
	---------------------------------------------------------------------------------
	wr_cnt_en_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wr_cnt_en		<= '0';
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_sum_st)
			and ram_cnt_zero_bool then 	--End of calculation
				wr_cnt_en	<= '1';
			else
				wr_cnt_en	<= '0';
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
			bank_switch	<= '0';
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_bank_switch_st) 
			and (sum_wr_cnt = wr_cnt*2) then --Image is OK. Note that sum_wr_cnt count BYTES, while wr_cnt count WORDS
				bank_switch	<= '1';			--Switch banks
			else
				bank_switch	<= '0';			--Switch banks
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
					ram_1st_data	<= ram_dout;		--Output value of RAM
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
				
			elsif (wbm_cur_st = wbm_wait_burst_st) then
				ram_1st_data		<= ram_dout;		--Output value of RAM
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
			or ((wbs_cur_st = wbs_neg_stall_st) and (type_reg_i (0) = '1')) then	--Debug mode
				wr_cnt		<= 0;
			elsif (wbm_ack_i = '1') then	--WBM_ACK_I has been received
				wr_cnt		<= wr_cnt + 1;
			else
				wr_cnt		<= wr_cnt;
			end if;
		end if;
	end process wr_cnt_internal_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process sum_wr_cnt_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the sum_wr_cnt_proc signal, which holds the number of 
	-- bytes, that has been sent by the host.
	---------------------------------------------------------------------------------
	sum_wr_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			sum_wr_cnt	<= 0;
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_sum_st) then
				if (ram_words_cnt(0) = '1') then
					sum_wr_cnt	<= sum_wr_cnt + conv_integer(ram_dout (7 downto 0));
				else
					sum_wr_cnt	<= sum_wr_cnt + 256*conv_integer(ram_dout (15 downto 8));
				end if;
			elsif (wbm_cur_st = wbm_bank_st) then
				sum_wr_cnt		<= 0;
			else
				sum_wr_cnt		<= sum_wr_cnt;
			end if;
		end if;
	end process sum_wr_cnt_proc;

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
	----------------------------- Process regs_proc	---------------------------------
	---------------------------------------------------------------------------------
	-- The process latches the registers values
	---------------------------------------------------------------------------------
	regs_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			type_reg_i			<= (others => '0');
			addr_reg_i			<= (others => '0');					
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_neg_stall_st) then
				--#Add another 'if' for flag (wbs_tgd_i)
				type_reg_i		<= type_reg;
				addr_reg_i		<= wr_addr_reg;		--Address register, for debug mode
			else
				type_reg_i		<= type_reg_i;
				addr_reg_i		<= addr_reg_i;		
			end if;
		end if;
	end process regs_proc;

end architecture rtl_mem_ctrl_wr;