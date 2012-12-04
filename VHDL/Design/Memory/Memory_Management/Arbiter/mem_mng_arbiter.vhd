------------------------------------------------------------------------------------------------
-- Model Name 	:	Arbiter for Memory Management
-- File Name	:	mem_mng_arbiter.vhd
-- Generated	:	19.4.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The arbiter arbits between two components:
--					(1) Mem_Ctrl_Wr - which writes data to the SDRAM
--					(2) Mem_Ctrl_Rd - which reads data from the SDRAM
--				By default, Mem_Ctrl_Wr grants the control on the busses to the SDRAM.
--				In case Mem_Ctrl_Rd requests for grant, and there is no request from the
--				Mem_Ctrl_Wr, then Mem_Ctrl_Rd will grant control on the SDRAM busses.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		29.4.2011	Beeri Schreiber			Creation
--			1.10		13.6.2012	Beeri Schreiber			Output GNT has been synchronized 
--															to the clock to improve timing
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mem_mng_arbiter is
	generic	(
			reset_polarity_g	:	std_logic	:= '0'					--When reset = reset_polarity_g, system is in RESET mode
			);
	port	(
			--Clock and Reset
			clk				:	in std_logic;							--Clock
			reset			:	in std_logic;							--Reset
									
			--Requests and grants						
			wr_req			:	in std_logic;							--Write request
			rd_req			:	in std_logic;							--Read Request
			wr_gnt			:	out std_logic;							--Write grant
			rd_gnt			:	out std_logic;							--Read grant
			
			-- Write: Wishbone Master signals to SDRAM
			wr_wbm_adr_o	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
			wr_wbm_dat_o	:	in std_logic_vector (15 downto 0);		--Data Out (16 bits)
			wr_wbm_we_o		:	in std_logic;							--Write Enable
			wr_wbm_tga_o	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
			wr_wbm_cyc_o	:	in std_logic;							--Cycle Command to interface
			wr_wbm_stb_o	:	in std_logic;							--Strobe Command to interface
			wr_wbm_stall_i	:	out std_logic;							--Slave is not ready to receive new data
			wr_wbm_err_i	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
			wr_wbm_ack_i	:	out std_logic;							--When Read Burst: DATA bus must be valid in this cycle
			
			-- Read: Wishbone Master signals to SDRAM
			rd_wbm_adr_o	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
			rd_wbm_we_o		:	in std_logic;							--Write Enable
			rd_wbm_tga_o	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
			rd_wbm_cyc_o	:	in std_logic;							--Cycle Command to interface
			rd_wbm_stb_o	:	in std_logic;							--Strobe Command to interface
			rd_wbm_dat_i	:	out std_logic_vector (15 downto 0);		--Data In (16 bits)
			rd_wbm_stall_i	:	out std_logic;							--Slave is not ready to receive new data
			rd_wbm_err_i	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
			rd_wbm_ack_i	:	out std_logic;							--When Read Burst: DATA bus must be valid in this cycle

			-- Wishbone Master signals to SDRAM, after arbitration
			wbm_adr_o		:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
			wbm_we_o		:	out std_logic;							--Write Enable
			wbm_tga_o		:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
			wbm_cyc_o		:	out std_logic;							--Cycle Command to interface
			wbm_stb_o		:	out std_logic;							--Strobe Command to interface
			wbm_dat_o		:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
			wbm_dat_i		:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
			wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data
			wbm_err_i		:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
			wbm_ack_i		:	in std_logic							--When Read Burst: DATA bus must be valid in this cycle
			);
end entity mem_mng_arbiter;

architecture rtl_mem_mng_arbiter of mem_mng_arbiter is
	---------------------------------  Signals	----------------------------------
	signal wr_gnt_i			:	std_logic;	--Internal write grant
	---------------------------------  Implementation	--------------------------
begin
	
	---------------------------------  Hidden processes	--------------------------
	--WBM Address
	wbm_adr_o_proc:
	wbm_adr_o		<= wr_wbm_adr_o	when (wr_gnt_i = '1')	else 	rd_wbm_adr_o;	
	
	--WBM Write Enable
	wbm_we_o_proc:
	wbm_we_o		<= wr_wbm_we_o	when (wr_gnt_i = '1')	else 	rd_wbm_we_o;
	
	--WBM Address Tag
	wbm_tga_o_proc:
	wbm_tga_o		<= wr_wbm_tga_o	when (wr_gnt_i = '1')	else 	rd_wbm_tga_o;	
	
	--WBM Cycle
	wbm_cyc_o_proc:
	wbm_cyc_o		<= wr_wbm_cyc_o	when (wr_gnt_i = '1')	else 	rd_wbm_cyc_o;	
	
	--WBM Strobe
	wbm_stb_o_proc:
	wbm_stb_o		<= wr_wbm_stb_o	when (wr_gnt_i = '1')	else 	rd_wbm_stb_o;	
	
	--WBM Data Out
	wbm_dat_o_proc:
	wbm_dat_o		<= wr_wbm_dat_o;		
	
	--WBM Data In
	wbm_dat_i_proc:
	rd_wbm_dat_i	<= wbm_dat_i;
	
	--Write WBM Stall
	wr_wbm_stall_i_proc:
	wr_wbm_stall_i	<= wbm_stall_i	when (wr_gnt_i = '1')	else '1';

	--Write WBM Error
	wr_wbm_err_i_proc:
	wr_wbm_err_i	<= wbm_err_i	when (wr_gnt_i = '1')	else '0';

	--Write WBM Acknowledge
	wr_wbm_ack_i_proc:
	wr_wbm_ack_i	<= wbm_ack_i	when (wr_gnt_i = '1')	else '0';
	
	--Read WBM Stall
	rd_wbm_stall_i_proc:
	rd_wbm_stall_i	<= wbm_stall_i	when (wr_gnt_i = '0')	else '1';

	--Read WBM Error
	rd_wbm_err_i_proc:
	rd_wbm_err_i	<= wbm_err_i	when (wr_gnt_i = '0')	else '0';

	--Read WBM Acknowledge
	rd_wbm_ack_i_proc:
	rd_wbm_ack_i	<= wbm_ack_i	when (wr_gnt_i = '0')	else '0';
	
	---------------------------------------------------------------------------------
	----------------------------- Process arbitration_proc	-------------------------
	---------------------------------------------------------------------------------
	-- The process grants control to write or read WBM, with higher priority to then
	-- Write WBM. Default grant: Write WBM
	---------------------------------------------------------------------------------
	arbitration_proc: process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			wr_gnt_i	<= '1';
		elsif rising_edge(clk) then
			if (wr_req = '1') then								--Write request for grant
				if (wr_gnt_i = '0') and (rd_req = '1') then		--Grant already given to read
					wr_gnt_i	<= '0';
				else
					wr_gnt_i	<= '1';
				end if;
			elsif (rd_req = '1') then							--Read request for grant
				if (wr_req = '0') then							--No request from write
					wr_gnt_i	<= '0';							--Read grant permitted
				else					
					wr_gnt_i	<= '1';							--Read grant forbiddened
				end if;
			else
				wr_gnt_i		<= '1';
			end if;
		end if;
	end process arbitration_proc;

	---------------------------------------------------------------------------------
	----------------------------- Process arb_sync_proc		-------------------------
	---------------------------------------------------------------------------------
	-- The process synchronized wr_cnt and rd_cnt to the clock
	---------------------------------------------------------------------------------
	arb_sync_proc: process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			wr_gnt	<= '0';
			rd_gnt	<= '0';
		elsif rising_edge(clk) then
			wr_gnt	<=	wr_gnt_i;
			rd_gnt	<=	not wr_gnt_i;
		end if;
	end process arb_sync_proc;

end architecture rtl_mem_mng_arbiter;