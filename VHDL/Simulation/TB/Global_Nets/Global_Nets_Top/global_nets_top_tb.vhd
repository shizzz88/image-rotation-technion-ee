------------------------------------------------------------------------------------------------
-- Model Name 	:	Global Nets - TOP
-- File Name	:	global_nets_top.vhd
-- Generated	:	07.03.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This block is the top block of the clocks and sync resets.
--				Input:
--					(*) System Clock 		- 	50MHz
--
--				Outputs:
--					(1) Clocks:
--						(*) SDRAM Clock		-	133MHz
--						(*)	VESA Clock		-	40MHz
--
--					(2) PLL-Locked signal indication
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name				Description
--			1.00		07.03.2011	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity global_nets_top_tb is
	generic (
			fpga_clk_freq_g		:	positive 	:= 50000000;	--50MHz
			reset_polarity_g	:	std_logic 	:= '0'			--When '0' - Reset
			);
end entity global_nets_top_tb;

architecture sim_global_nets_top_tb of global_nets_top_tb is

---------------------------------	Signals		----------------------------
signal fpga_clk		    : std_logic := '0';
signal fpga_rst		    : std_logic := reset_polarity_g;
signal sdram_clk		: std_logic := '0';
signal vesa_clk		    : std_logic := '0';
signal sync_sdram_rst	: std_logic := reset_polarity_g;
signal sync_vesa_rst	: std_logic := reset_polarity_g;

---------------------------------	Components		----------------------------
component global_nets_top 
	generic (
			reset_polarity_g	:	std_logic := '0'		--When '0' - Reset
			);
	port (
			fpga_clk		:	in std_logic ;				--Input clock to the FPGA (50MHz)
			fpga_rst		:	in std_logic ;				--Input reset from FPGA
			sdram_clk		:	out std_logic ;				--Output SDRAM clock (133MHz)
			vesa_clk		:	out std_logic ;				--Output VESA clock (40MHz)
			sync_sdram_rst	:	out std_logic ;				--Output Synchronized reset - 133MHz
			sync_vesa_rst	:	out std_logic				--Output Synchronized reset - 40MHz
		);
end component global_nets_top;

------------------------------	Implementation	--------------------------------------
begin
	global_nets_top_inst : global_nets_top 
						generic map
							(reset_polarity_g => reset_polarity_g)
						port map
							(
								fpga_clk		=> fpga_clk,		
							    fpga_rst		=> fpga_rst,		
							    sdram_clk		=> sdram_clk,		
							    vesa_clk		=> vesa_clk,		
							    sync_sdram_rst	=> sync_sdram_rst,	
							    sync_vesa_rst   => sync_vesa_rst	
							);
							
	--Generate clock
	clk_50_proc: 
	fpga_clk <= not fpga_clk after (1 sec / real(fpga_clk_freq_g*2));
	
	rst_proc:
	fpga_rst <= (not reset_polarity_g) after 100 ns, reset_polarity_g after 400 ns, (not reset_polarity_g) after 800 ns;

end architecture sim_global_nets_top_tb;