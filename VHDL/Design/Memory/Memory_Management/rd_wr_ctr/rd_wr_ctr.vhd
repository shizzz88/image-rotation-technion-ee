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
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity rd_wr_ctr is
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0'	--When rst = reset_polarity_g, system is in RESET mode
		);
  port (
		-- Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		
		-- Wishbone Slave signals from Image Manipulation Block
		-- Wishbone Slave signals to Read/Write interface
		wbs_adr_i	:	in std_logic_vector (22 downto 0);		--Address (Bank, Row, Col)
		wbs_dat_i	:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbs_we_i	:	in std_logic;							--Write Enable
		wbs_tga_i	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbs_cyc_i	:	in std_logic;							--Cycle Command from interface
		wbs_stb_i	:	in std_logic;							--Strobe Command from interface
		wbs_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data
		wbs_err_o	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbs_ack_o	:	out std_logic;							--When Read Burst: DATA bus must be valid in this cycle
																--When Write Burst: Data has been read from SDRAM and is valid		
	
	-- Wishbone Master signals to Arbiter/SDRAM
		wbm_adr_o	:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbm_dat_o	:	out std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbm_we_o	:	out std_logic;							--Write Enable
		wbm_tga_o	:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_cyc_o	:	out std_logic;							--Cycle Command from interface
		wbm_stb_o	:	out std_logic;							--Strobe Command from interface
		wbm_dat_i	:	in  std_logic_vector (15 downto 0);		--Data for write (16 bits)
		wbm_stall_i	:	in  std_logic;							--Slave is not ready to receive new data
		wbm_err_i	:	in  std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbm_ack_i	:	in  std_logic;							--When Write Burst: DATA bus must be valid in this cycle
																--When Read Burst: Data has been read from SDRAM and is valid

		-- Arbiter signals
		arbiter_gnt	:	in std_logic;							--Grant control on SDRAM from Arbiter
		arbiter_req	:	out std_logic_vector (1 downto 0)		--Request for control on SDRAM from Arbiter

		); 
end entity rd_wr_ctr;

architecture rtl_rd_wr_ctr of rd_wr_ctr is

  ---------------------------------  Types		----------------------------------
	
	--Wishbone Master State Machine
	type wbm_states is (
						wbm_idle_st,		--Idle state
						wbm_read_st,		--Receiving data from SDRAM, 
						wbm_write_st		--Write Data to SDRAM
						);
  
  ---------------------------------  Constants	----------------------------------
	constant delay_sdram_ram_c		:	positive := 13;	--Number of words, which will be read from SDRAM to RAM, before enabling WBS to read data from RAM, to prevent empty RAM
	
  ---------------------------------  Signals	----------------------------------
	--General signals
	signal signal_name		: std_logic;							--
	signal	adrress_in          : std_logic_vector (22 downto 0);		--Address (Bank, Row, Col)
	signal	data_in          : std_logic_vector (15 downto 0);		--Data In (16 bits)
	signal	we_in            : std_logic;							--Write Enable
	signal	tga_in           : std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represen
	signal  cyc_in           : std_logic;							--Cycle Command from interface
	signal  stb_in           : std_logic;							--Strobe Command from interface
	signal  dat_in		:	std_logic_vector (15 downto 0);		--Data Out (16 bits)
	signal  stall_in	:  std_logic;							--Slave is not ready to receive new data
	signal  err_in		:std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
	signal  ack_in		: std_logic;							--When Read Burst: DATA bus must be valid in this cycle
	
		--State machines
	signal wbm_cur_st		:	wbm_states;
	
  ---------------------------------  Implementation	------------------------------
  begin
	--wire inputs from wbs to inner signal
	adrress_in<=wbs_adr_i ;
	data_in   <=wbs_dat_i ;
	we_in     <=wbs_we_i  ;
	tga_in    <=wbs_tga_i ;
	cyc_in    <=wbs_cyc_i ;
	stb_in    <=wbs_stb_i ;
	
	--wire inputs from wbm to inner signal
	dat_in	 <=  wbm_dat_i	  ;
	stall_in <=  wbm_stall_i  ;
	err_in	 <=  wbm_err_i	  ;
	ack_in	 <=  wbm_ack_i	  ;
	
	wbm_fsm_proc: process (clk_i, rst)
	begin

		if (rst = reset_polarity_g) then
			wbm_cur_st		 <= wbm_idle_st;
			wbs_dat_o		 <=(others => '0');
            wbs_stall_o	     <='0';
            wbs_err_o		 <='0';
            wbs_ack_o		 <='0';
			wbm_adr_o        <=(others => '0');
			wbm_dat_o        <=(others => '0');
            wbm_we_o         <='0';
            wbm_tga_o        <=(others => '0');
			wbm_cyc_o        <='0';
            wbm_stb_o        <='0';
			arbiter_req		 <=(others => '0');
			
		elsif rising_edge (clk_i) then
			case wbm_cur_st is
				
				when wbm_idle_st =>
				   if (wbs_cyc_i='1') and (wbs_stb_i='1')  then
						if (wbs_we_i='1')  then
							wbm_cur_st <= wbm_write_st;
						elsif (wbs_we_i='0')  then
							wbm_cur_st <= wbm_read_st;
						end if;
					else
						wbm_cur_st <= wbm_cur_st;
					end if;						
					arbiter_req	<= "00";

				
				when wbm_read_st =>
					wbm_adr_o(21) <= '0';	--read pixels from bank 0
					wbm_adr_o(20 downto 0)	<= adrress_in(20 downto 0);
					wbm_dat_o	<= data_in ;  
					wbm_we_o	<= we_in  ;   
					wbm_tga_o	<= tga_in  ;  
					wbm_cyc_o	<= cyc_in  ;  
					wbm_stb_o	<= stb_in  ;
					wbs_dat_o	<=  dat_in	;
					wbs_stall_o	<=  stall_in;
					wbs_err_o	<=  err_in	;
					wbs_ack_o	<=  ack_in	;
					arbiter_req	<= "01";

					if (wbs_cyc_i='1') and (wbs_stb_i='1') and (wbm_ack_i='1') then
						wbm_cur_st<=wbm_idle_st;
					else			
						wbm_cur_st<=wbm_cur_st;
					end if;
					
				when wbm_write_st =>
					wbm_adr_o(21) <= '1';		---write new pixel to bank 1
					wbm_adr_o(20 downto 0)	<= adrress_in(20 downto 0);
					wbm_dat_o	<= data_in ;  
					wbm_we_o	<= we_in  ;   
					wbm_tga_o	<= tga_in  ;  
		            wbm_cyc_o	<= cyc_in  ;  
		            wbm_stb_o	<= stb_in  ;  
					
					wbs_dat_o	<=  dat_in	;
					wbs_stall_o	<=  stall_in;
					wbs_err_o	<=  err_in	;
					wbs_ack_o	<=  ack_in	;
					arbiter_req	<= "10";

					if (wbs_cyc_i='1') and (wbs_stb_i='1') and (wbm_ack_i='1') then
						wbm_cur_st<=wbm_idle_st;
					else			
						wbm_cur_st<=wbm_cur_st;
					end if;

				
				when others =>
					wbm_cur_st		<= wbm_idle_st;
					report "Time: " & time'image(now) & ", mem_ctrl_rd_wbm, wbm_fsm_proc >> Undeclared state has been received!"
					severity error;

			end case;
		end if;
	end process wbm_fsm_proc;


	---------------------------------------------------------------------------------
	----------------------------- Process arbiter_req_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process controls the arbiter_req signal
	---------------------------------------------------------------------------------
	-- arbiter_req_proc: process (clk_i, rst)
	-- begin
		
		-- if (rst = reset_polarity_g) then
			-- arbiter_req	<= "00";
		-- elsif rising_edge (clk_i) then
			-- if (wbm_cur_st = wbm_idle_st) then
				-- arbiter_req	<= "00";
			-- elsif  (wbm_cur_st = wbm_read_st) then
				-- arbiter_req	<= "01";
			-- elsif  (wbm_cur_st = wbm_write_st) then
				-- arbiter_req	<= "10";
			-- end if;	
		-- end if;
	-- end process arbiter_req_proc;
	



end architecture rtl_rd_wr_ctr;