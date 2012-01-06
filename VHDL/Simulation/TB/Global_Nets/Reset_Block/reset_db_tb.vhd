------------------------------------------------------------------------------------------------
-- Model Name 	:	Reset Debouncer TB
-- File Name	:	reset_db_tb.vhd
-- Generated	:	07.02.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This is the Test Bench of reset_debouncer
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name				Description
--			1.00		07.02.2011	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity reset_db_tb is
generic (
			sys_clk_freq_g 		:	positive	:= 50000000;		--System Clock Frequency = 50MHz
			vesa_clk_freq_g		:	positive	:= 40000000;		--VESA Clock Frequency = 40MHz
			sdram_clk_freq_g	:	positive	:= 133333333;		--SDRAM Clock Frequency = 133MHz
			reset_polarity_g	:	std_logic	:= '1'				--Reset - active high
		);
end entity reset_db_tb;

architecture sim_reset_db_tb of reset_db_tb is

component reset_debouncer
	generic (
			reset_polarity_g	:	std_logic := '0'		--When '0' - Reset
			);
	port (
			fpga_in_clk		:	in std_logic ;				--Input clock to the FPGA
			rst_in			:	in std_logic ;				--Input reset
			pll_locked		:	in std_logic ;				--PLL locked indication. In case PLL is not in the design, connect VCC to this port
			sync_rst_out	:	out std_logic				--Output Synchronized reset
		);
end component reset_debouncer;

component sync_rst_gen
	generic (
				reset_polarity_g	:	std_logic := '0'		--When '0' - Reset
			);
 	port 	(		   
				clk             	: in  	std_logic; 			-- Clock from PLL
				sys_rst_in     		: in 	std_logic;  		-- System synchronized reset
				sync_rst_out    	: out  	std_logic 			-- Synchronic reset to the given clock 
			);	
end component sync_rst_gen;


-------------------------------  Signals   -------------------------------------
signal sys_clk		:	std_logic := '0';
signal vesa_clk		:	std_logic := '0';
signal sdram_clk	:	std_logic := '0';
signal sys_rst		:	std_logic := reset_polarity_g;
signal deb_rst		:	std_logic := reset_polarity_g;
signal vesa_rst_out	:	std_logic := reset_polarity_g;
signal sdram_rst_out:	std_logic := reset_polarity_g;
signal pll_locked	:	std_logic := '0';

begin
	rst_db_inst : reset_debouncer generic map
									( reset_polarity_g => reset_polarity_g)
								port map
									(
									  fpga_in_clk		=> sys_clk,
									  rst_in			=> sys_rst,
									  pll_locked		=> pll_locked,
									  sync_rst_out		=> deb_rst
									 );
	vesa_rst_inst : sync_rst_gen generic map
									( reset_polarity_g => reset_polarity_g)
								port map
									(
									  clk         	=> vesa_clk,
									  sys_rst_in  	=> deb_rst,
									  sync_rst_out	=> vesa_rst_out
									 );									 
									 
	sdram_rst_inst : sync_rst_gen generic map
									( reset_polarity_g => reset_polarity_g)
								port map
									(
									  clk         	=> sdram_clk,
									  sys_rst_in  	=> deb_rst,
									  sync_rst_out	=> sdram_rst_out
									 );									 
	--Clock stimulus process
	sys_clk_proc:
	sys_clk <= not sys_clk after (1 sec / (2.0 * real(sys_clk_freq_g)));

	vesa_clk_proc:
	vesa_clk <= not vesa_clk after (1 sec / (2.0 * real(vesa_clk_freq_g)));

	sdram_clk_proc:
	sdram_clk <= not sdram_clk after (1 sec / (2.0 * real(sdram_clk_freq_g)));
	
	--Reset and PLL Stimulus process
	rst_pll_proc : process
	begin
		pll_locked 		<= '0';
		sys_rst 		<= reset_polarity_g;
		wait for 10.01 * (1 sec / real(sys_clk_freq_g));
		sys_rst 		<= not reset_polarity_g;
		wait for 10.02 * (1 sec / real(sys_clk_freq_g));
		pll_locked 		<= '1';
		wait for 10.03 * (1 sec / real(sys_clk_freq_g));
		sys_rst 		<= reset_polarity_g;
		wait for 10.04 * (1 sec / real(sys_clk_freq_g));
		sys_rst 		<= not reset_polarity_g;
		wait for 10.05 * (1 sec / real(sys_clk_freq_g));
		pll_locked 		<= '0';
		wait;
	end process rst_pll_proc;
								
end architecture sim_reset_db_tb;