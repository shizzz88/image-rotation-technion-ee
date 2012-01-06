------------------------------------------------------------------------------------------------
-- Model Name 	:	Reset Debouncer
-- File Name	:	reset_debouncer.vhd
-- Generated	:	18.10.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This model is a reset debouncer model. Pressing the RESET button
--				on the DE2 board will assert RESET only if button is pressed for 
--				at least 5 system clock cycles, and will be negated only if button is
--				released for at least 5 clock cycles.
--				Note that PLL must be locked in order to negate reset. In case PLL is not locked,
--			 	system reset will be active.
--				PLL is being filtered as well as the reset.
--				The output is a synchronized-to-the-clock reset.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name				Description
--			1.00		18.10.2010	Beeri Schreiber		Creation
--			1.01		07.02.2011	Beeri Schreiber		Added PLL, Polarity generic
--			1.02		27.02.2011	Beeri Schreiber		Added sync to the clock reset
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity reset_debouncer is
	generic (
			reset_polarity_g	:	std_logic := '0'		--When '0' - Reset
			);
	port (
			fpga_in_clk		:	in std_logic ;				--Input clock to the FPGA
			rst_in			:	in std_logic ;				--Input reset
			pll_locked		:	in std_logic ;				--PLL locked indication. In case PLL is not in the design, connect VCC to this port
			sync_rst_out	:	out std_logic				--Output Synchronized reset
		);
end entity reset_debouncer;

architecture rtl_reset_debouncer of reset_debouncer is

--------------------------------     Signals      ------------------------------------------

--Asynchronouse Reset
signal async_rst_i   	: std_logic;

--Reset Signals for Debouncing
signal reset_d1			:	std_logic;
signal reset_d2			:	std_logic;
signal reset_d3			:	std_logic;
signal reset_d4			:	std_logic;
signal reset_db			:	std_logic;
	
--PLL Signals	
signal pll_d1			:	std_logic;
signal pll_d2			:	std_logic;
signal pll_d3			:	std_logic;
signal pll_d4			:	std_logic;
signal pll_db			:	std_logic;

--Reset Signals for Synchronizing the reset to the clock
signal 	 sync_rst_d1   	: std_logic;
signal 	 sync_rst_d2   	: std_logic;
signal 	 sync_rst_d3   	: std_logic;

--------------------------   Implementation	--------------------
begin
	-----------------------------------------------------------------------
	-----------------	Process rst_db_proc		---------------------------
	-----------------------------------------------------------------------
	-- The process filters the input reset
	-----------------------------------------------------------------------
	rst_db_proc: process (fpga_in_clk) is
	begin
		if rising_edge(fpga_in_clk) then
			reset_d1 <= rst_in;
			reset_d2 <= reset_d1;
			reset_d3 <= reset_d2;
			reset_d4 <= reset_d3;
			if (reset_d2 = '1') and (reset_d3 = '1') and (reset_d4 = '1') then
				reset_db <= '1';
			elsif (reset_d2 = '0') and (reset_d3 = '0') and (reset_d4 = '0') then
				reset_db <= '0';
			else
				reset_db <= reset_db;
			end if;
		end if;
	end process rst_db_proc;

	-----------------------------------------------------------------------
	-----------------	Process pll_db_proc		---------------------------
	-----------------------------------------------------------------------
	-- The process filters the input PLL
	-----------------------------------------------------------------------
	pll_db_proc: process (fpga_in_clk) is
	begin
		if rising_edge(fpga_in_clk) then
			pll_d1 <= pll_locked;
			pll_d2 <= pll_d1;
			pll_d3 <= pll_d2;
			pll_d4 <= pll_d3;
			if (pll_d2 = '1') and (pll_d3 = '1') and (pll_d4 = '1') then
				pll_db <= '1';
			elsif (pll_d2 = '0') and (pll_d3 = '0') and (pll_d4 = '0') then
				pll_db <= '0';
			else
				pll_db <= pll_db;
			end if;
		end if;
	end process pll_db_proc;	
	
	-----------------------------------------------------------------------
	-----------------	Process rst_all_proc	---------------------------
	-----------------------------------------------------------------------
	-- The process is the reset out process. Reset will be activated,
	-- only if input reset is active, after it has been filtered, or in 
	-- case PLL is not locked.
	-----------------------------------------------------------------------
	rst_all_proc:
	async_rst_i <= (not reset_polarity_g) when ((pll_db = '1') and (reset_db = not reset_polarity_g))
				else reset_polarity_g;
				
	-----------------------------------------------------------------------
	-----------------	Process sync_rst_proc	---------------------------
	-----------------------------------------------------------------------
	-- The process synchronized that asynchronized debounced reset and PLL
	-- locked to the system clock.
	-----------------------------------------------------------------------
	sync_rst_proc: process(fpga_in_clk, async_rst_i)
	begin
		if (async_rst_i = reset_polarity_g) then
			sync_rst_d1 	<= reset_polarity_g;
		    sync_rst_d2 	<= reset_polarity_g;
		    sync_rst_d3 	<= reset_polarity_g;
			sync_rst_out 	<= reset_polarity_g;
 		elsif rising_edge(fpga_in_clk) then
		    sync_rst_d1 <= not reset_polarity_g;
		    sync_rst_d2 <= sync_rst_d1;
		    sync_rst_d3 <= sync_rst_d2;
			if (sync_rst_d2 = (not reset_polarity_g)) and (sync_rst_d3 = (not reset_polarity_g)) then
				sync_rst_out <= not reset_polarity_g;
			else 
				sync_rst_out <= reset_polarity_g;
			end if;
 		end if;
	end process sync_rst_proc;				

end architecture rtl_reset_debouncer;

