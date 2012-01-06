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

library work ;
use work.ram_generic_pkg.all;

entity mem_ctrl_rd is
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0';	--When rst = reset_polarity_g, system is in RESET mode
		mode_g				:	natural range 0 to 7 	:= 0;	--Relevant bit in type register, which represent Normal ('0') or Debug ('1') mode
		img_hor_pixels_g	:	positive				:= 640;	--640 activepixels
		img_ver_lines_g		:	positive				:= 480	--480 active lines
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
		wr_cnt_en	:	in std_logic							--wr_cnt write enable flag (Active for 1 clock)
		); 
end entity mem_ctrl_rd;

architecture rtl_mem_ctrl_rd of mem_ctrl_rd is

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
	
	--Wishbone Master State Machine
	type wbm_states is (
						wbm_idle_st,		--Idle state
						wbm_req_arb_st,		--Wait for grant on SDRAM from arbiter
						wbm_rx_st,			--Receiving data from SDRAM, and storing to RAM
						wbm_wait_burst_st,	--Pause between 256 words transaction
						wbm_bank_st			--Change read address from SDRAM
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

  ---------------------------------  Constants	----------------------------------
	constant delay_sdram_ram_c		:	positive := 13;	--Number of words, which will be read from SDRAM to RAM, before enabling WBS to read data from RAM, to prevent empty RAM
	
  ---------------------------------  Signals	----------------------------------
	--General signals
	signal ram_ready		:	std_logic;							--Active for 1 clock cycle, when all data has been stored to internal RAM
	signal ack_i_cnt		:	natural range 0 to 256;				--Number of expected WBM_ACK_I
	signal err_i_status		:	std_logic;							--WBM_ERR_I has been received
	signal neg_cyc_bool		:	boolean;							--TRUE: Negate NOW (At this clock) WBM_CYC_O, FALSE otherwise
	signal dat_1st_bool		:	boolean;							--TRUE: First read data on ram at each transaction, FALSE otherwise
	signal wbm_cyc_internal	:	std_logic;							--Internal WBS_CYC_O
	signal wbm_stb_internal	:	std_logic;							--Internal WBS_STB_O
	signal cur_rd_addr		:	std_logic_vector(21 downto 0);		--Current read address from SDRAM
	signal rd_cnt 			:	natural range 0 to img_hor_pixels_g*img_ver_lines_g - 1;	--Number of read words (16 bits) to the SDRAM 
	signal rd_cnt_i			:	natural range 0 to img_hor_pixels_g*img_ver_lines_g - 1;	--Number of read words (16 bits) to the SDRAM at the beginning of the transaction
	signal init_sdram_bool	:	boolean;							--TRUE: Init SDRAM read transaction, false otherwise
	signal ack_o_sr			:	std_logic;							--WBS_ACK_O Register
	signal first_rx_bool	:	boolean;							--TRUE: First image transmission. Relevant for rd_cnt_i. FALSE otherwise	
	signal update_rdcnt_bool:	boolean;							--TRUE: Update rd_cnt_i
	signal addr_pipe		:	std_logic_vector(7 downto 0);		--For pipeline

	--Latches registers values
	signal type_reg_i		:	std_logic_vector (7 downto 0);		--Internal Type Register
	signal addr_reg_i		:	std_logic_vector (21 downto 0);		--Write to SDRAM Address (Debug mode)
	
	--Signals for RAM
	signal ram_addr_in		:	std_logic_vector (8 downto 0);		--Write address to RAM
	signal ram_aout_val		:	std_logic;							--Read address from RAM is valid
	signal ram_dout_valid	:	std_logic;							--Output data from RAM is valid
	signal ram_dout			:	std_logic_vector (7 downto 0);		--Output data from RAM
	signal ram_expect_adr	:	std_logic_vector (9 downto 0);		--Current EXPECTED (and actual) read address from RAM
	
	--Signals derived from RAM transactions
	signal ram_words_in		:	std_logic_vector (8 downto 0);		--Number of words (16 bits) which will be stored in RAM at end of SDRAM transaction
	signal ram_words_left	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) waiting to be stored in RAM
	signal ram_words_cnt	:	std_logic_vector (8 downto 0);		--Number of words (16 bits) that has not been transfered YET from SDRAM (Chunks of 256)
	signal ram_delay_cnt	:	natural range 0 to delay_sdram_ram_c;--Delay counter, from the start of SDRAM transaction to read from RAM
	
	--State machines
	signal wbs_cur_st		:	wbs_states;
	signal wbm_cur_st		:	wbm_states;
	
  ---------------------------------  Implementation	------------------------------
  begin
	
	--Generic RAM: 16 bits input, 8 bits output
	ram1_inst: 	ram_generic
				generic map 
					(
					reset_polarity_g	=> reset_polarity_g,
					width_in_g		    => 16,	--16 bits input, 8 bits output 
					addr_bits_g		    => 9,	--RAM's size is 16 bits * 2^9
					power2_out_g	    => 1,	--Output size is 16 bits * 2^(-1) = 8 bits
					power_sign_g	    => -1	--Output port < Input port
					)
				port map
					(
					clk			=> clk_i,
					rst			=> rst,
					addr_in		=> ram_addr_in,
					addr_out	=> ram_expect_adr,
					aout_valid	=> ram_aout_val,
					data_in		=> wbm_dat_i,
					din_valid	=> wbm_ack_i,
					data_out	=> ram_dout,
					dout_valid	=> ram_dout_valid
					);
	
	------------------------------	Hidden processes	--------------------------
	--Output data to Data Requester (WBS_DAT_O)
	wbs_dat_o_proc:
	wbs_dat_o 	<= 	ram_dout;
	
	--Cycle to SDRAM (WBM_CYC_O)
	wbm_cyc_o_proc:
	wbm_cyc_o 	<= 	wbm_cyc_internal when (not neg_cyc_bool)
					else '0';

	--Acknowledge to Data Requester (WBS_ACK_O)
	wbs_ack_o_proc:
	wbs_ack_o	<=	ack_o_sr and ram_dout_valid;
	
	--Strobe to SDRAM (WBM_STB_O)
	wbm_stb_o_proc:
	wbm_stb_o	<= 	wbm_stb_internal;
						
	--Write enable to SDRAM (WBM_WE_O) is always '0' for this component
	wbm_we_o_proc:
	wbm_we_o 	<= '0';
	
	--Address out to SDRAM (WBM_ADR_O)
	wbm_adr_o_proc:
	wbm_adr_o	<= 	cur_rd_addr when ((wbm_cur_st = wbm_rx_st) or (wbm_cur_st = wbm_wait_burst_st))
					else (others => '0');
	
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
					
					if (wbs_cyc_i = '1') and (wbm_cur_st = wbm_idle_st) and (rd_cnt /= 0) then	--WBS Start of cycle
						wbs_cur_st		<= wbs_init_sdram_rx_st;
					else
						wbs_cur_st		<= wbs_idle_st;
					end if;
				
				when wbs_init_sdram_rx_st =>
					wbs_cur_st		<= wbs_wait_ram_rdy_st;
					
				when wbs_wait_ram_rdy_st =>
					if (ram_ready = '1') then
						wbs_cur_st	<= wbs_ram_delay_st;
					else
						wbs_cur_st	<= wbs_wait_ram_rdy_st;
					end if;
				
				when wbs_ram_delay_st =>
					wbs_cur_st		<= wbs_tx_st;
				
				when wbs_tx_st =>
					if (wbs_cyc_i = '1') and (wbs_stb_i = '1') then
						if (ram_expect_adr = "1111111111") then				--End of RAM addresses
							wbs_cur_st		<= wbs_wait_end_cyc_st;			--Wait for end of cycle
						else
							wbs_cur_st		<= wbs_tx_st;             	    
						end if;
					else													--End of burst
						wbs_cur_st			<= wbs_wait_end_cyc_st;             	    
					end if;
				
				when wbs_wait_end_cyc_st =>
					if (wbs_cyc_i = '1') then
						wbs_cur_st		<= wbs_wait_end_cyc_st;            	    
					else
						wbs_cur_st		<= wbs_done_st;             	    
					end if;
					
				when wbs_done_st =>
					wbs_cur_st		<= wbs_idle_st;
				
				when others =>
					wbs_cur_st		<= wbs_idle_st;
					report "Time: " & time'image(now) & ", mem_ctrl_rd, wbs_fsm_proc >> Undeclared state has been received!"
					severity error;
			end case;
		end if;
	end process wbs_fsm_proc;
	
	---------------------------------------------------------------------------------
	----------------------------- Process wbs_stall_o_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the wbs_stall_o signal
	---------------------------------------------------------------------------------
	wbs_stall_o_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			wbs_stall_o	<= '1';
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_ram_delay_st) 
			or ((wbs_cur_st = wbs_tx_st) and (wbs_cyc_i = '1') and (wbs_stb_i = '1')) then
				wbs_stall_o	<= '0';
			else
				wbs_stall_o	<= '1';
			end if;
		end if;
	end process wbs_stall_o_proc;
	
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
	----------------------------- Process init_sdram_bool_proc	---------------------
	---------------------------------------------------------------------------------
	-- The process controls the init_sdram_bool signal
	---------------------------------------------------------------------------------
	init_sdram_bool_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			init_sdram_bool	<= false;
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_init_sdram_rx_st) then
				init_sdram_bool	<= true;
			else
				init_sdram_bool	<= false;
			end if;
		end if;
	end process init_sdram_bool_proc;
	
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
			else
				ram_words_in	<= ram_words_in;
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
					report "Time: " & time'image(now) & ", mem_ctrl_rd, wbs_fsm_proc >> Expected RAM address does not match to actual input address!"
					severity error;
				end if;
			else
				ram_expect_adr	<= ram_expect_adr;
			end if;
		end if;
	end process ram_expect_adr_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process ram_aout_val_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_aout_val signal
	---------------------------------------------------------------------------------
	ram_aout_val_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_aout_val	<= '0';
		elsif rising_edge (clk_i) then
			if (wbs_cur_st = wbs_ram_delay_st) or (wbs_cur_st = wbs_tx_st) then
				ram_aout_val	<= '1';
			else
				ram_aout_val	<= '0';
			end if;
		end if;
	end process ram_aout_val_proc;
	
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
			if (wbs_cur_st = wbs_init_sdram_rx_st) then
				type_reg_i		<= type_reg;
				addr_reg_i		<= rd_addr_reg;		--Address register, for debug mode
			else
				type_reg_i		<= type_reg_i;
				addr_reg_i		<= addr_reg_i;		
			end if;
		end if;
	end process regs_proc;
	
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
			if (wbs_cyc_i = '1') and (ram_expect_adr = wbs_adr_i) then
				ack_o_sr <= wbs_stb_i;
			else
				ack_o_sr <= '0';
			end if;
		end if;
	end process ack_o_sr_proc;
	--############################################################################--
	--						End of Wishbone Slave								  --
	--############################################################################--
	
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
			ram_addr_in		<= (others => '0');
			ram_words_left	<= (others => '0');
            wbm_cyc_internal<= '0';
			wbm_stb_internal<= '0';
			ram_words_cnt	<= (others => '0');
			dat_1st_bool	<= true;
			addr_pipe		<= (others => '0');
			update_rdcnt_bool	<= true;

		elsif rising_edge (clk_i) then
			case wbm_cur_st is
				when wbm_idle_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_in		<= (others => '0');
					ram_words_cnt	<= (others => '0');

					ram_words_left	<= ram_words_in;		--Latch number of words in RAM

					--Wait for init SDRAM transaction flag
					if (wbs_tgc_i = '1') then
						wbm_cur_st	<=	wbm_bank_st;	--Restart SDRAM transaction
					elsif init_sdram_bool then				--Init SDRAM transaction
						update_rdcnt_bool	<= false;
						wbm_cur_st	<= wbm_req_arb_st;
						if (type_reg_i(mode_g) = '0') then	--Normal Mode
							cur_rd_addr	<= cur_rd_addr;
							addr_pipe	<= conv_std_logic_vector (conv_integer(x"FF" - cur_rd_addr(7 downto 0)),8);	--For pipeline
						else								--Debug mode
							cur_rd_addr	<= addr_reg_i;
							addr_pipe	<= conv_std_logic_vector (conv_integer(x"FF" - addr_reg_i(7 downto 0)),8);	--For pipeline
						end if;
					else
						cur_rd_addr	<= cur_rd_addr;
						wbm_cur_st 	<= wbm_idle_st;
					end if;
				
				when wbm_req_arb_st =>
					ram_words_left		<= ram_words_left;
					cur_rd_addr			<= cur_rd_addr;
					ram_addr_in			<= ram_addr_in;
					
					if (arbiter_gnt = '1') then								--Grant on SDRAM from arbiter
						wbm_cyc_internal<= '1';
						wbm_stb_internal<= '1';
						wbm_cur_st		<= wbm_rx_st;
						dat_1st_bool	<= true;

						--First burst length to SDRAM
						
						if (type_reg_i(mode_g) = '0') then					--Normal mode
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
						ram_addr_in			<= ram_addr_in;
						ram_words_cnt		<= ram_words_cnt;
						cur_rd_addr			<= cur_rd_addr;
						wbm_cur_st			<= wbm_req_arb_st;
					end if;
				
				when wbm_rx_st =>
					wbm_cyc_internal<= '1';
					
					if (ram_words_cnt = "000000000") then						--End of cycle
						ram_words_cnt	<= ram_words_cnt;
						ram_addr_in		<= ram_addr_in + '1';
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
								ram_addr_in		<= ram_addr_in;
								dat_1st_bool	<= false;
							else
								ram_addr_in		<= ram_addr_in + '1';
								dat_1st_bool	<= false;
							end if;
							cur_rd_addr		<= cur_rd_addr + '1';
							ram_words_left	<= ram_words_left - '1';
							ram_words_cnt	<= ram_words_cnt - '1';
						else										--Repeat last transaction
							ram_addr_in		<= ram_addr_in;
							cur_rd_addr		<= cur_rd_addr;
							ram_words_left	<= ram_words_left;
							ram_words_cnt	<= ram_words_cnt;
						end if;
					end if;
					
				when wbm_wait_burst_st =>

					cur_rd_addr		<= cur_rd_addr;
					ram_words_left	<= ram_words_left;

					if (wbm_ack_i = '1') then
						ram_addr_in		<= ram_addr_in + '1';
					else
						ram_addr_in		<= ram_addr_in;
					end if;
					
					--Burst length to SDRAM
					if (type_reg_i(mode_g) = '0') then						--Normal mode
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
							if (type_reg_i(mode_g) = '0') then
								wbm_cur_st	<= wbm_idle_st;
							else
								wbm_cur_st	<= wbm_bank_st;			--cur_rd_addr should be ready for image transfer
							end if;
						else
							wbm_cur_st	<= wbm_rx_st;
							dat_1st_bool<= true;
						end if;
					else											--Cycle is in progress
						wbm_cyc_internal<= '1';
						wbm_cur_st		<= wbm_wait_burst_st;
					end if;
					
				when wbm_bank_st =>
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					ram_addr_in		<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');

					cur_rd_addr(21)	<= bank_val;
					cur_rd_addr(20 downto 0)	<= (others => '0');
					update_rdcnt_bool	<= true;
					wbm_cur_st		<= wbm_idle_st;
				
				when others =>
					wbm_cur_st		<= wbm_idle_st;
					wbm_tga_o		<= (others => '0');
					wbm_cyc_internal<= '0';
					wbm_stb_internal<= '0';
					cur_rd_addr		<= (others => '0');
					ram_addr_in		<= (others => '0');
					ram_words_left	<= ram_words_left;
					ram_words_cnt	<= (others => '0');
					report "Time: " & time'image(now) & ", mem_ctrl_rd, wbm_fsm_proc >> Undeclared state has been received!"
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
			if (wbm_cur_st = wbm_bank_st) or update_rdcnt_bool then				--New picture
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
			if (wbm_cur_st = wbm_idle_st)
			or (wbm_cur_st = wbm_bank_st) then
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
	----------------------------- Process ram_ready_proc	-----------------------------
	---------------------------------------------------------------------------------
	-- The process controls the ram_ready and ram_delay_cnt signals
	---------------------------------------------------------------------------------
	ram_ready_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ram_ready		<= '0';
			ram_delay_cnt	<= 0;		
		elsif rising_edge (clk_i) then
			if (wbm_cur_st = wbm_rx_st) then
				if (ram_delay_cnt /= delay_sdram_ram_c) then	--Increment ram_delay_cnt
					ram_delay_cnt <= ram_delay_cnt + 1;
				else
					ram_delay_cnt <= ram_delay_cnt;
				end if;
			
				if (ram_delay_cnt = delay_sdram_ram_c - 1) then
					ram_ready	<= '1';
				else
					ram_ready	<= '0';
				end if;
			else
				ram_ready		<= '0';
				ram_delay_cnt	<= 0;
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
	
end architecture rtl_mem_ctrl_rd;