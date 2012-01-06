------------------------------------------------------------------------------------------------
-- Model Name 	:	Global Nets - TOP
-- File Name	:	global_nets_top.vhd
-- Generated	:	07.03.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This block is the top block of the clocks and sync resets.
--				Input:
--					(1) System Clock 		- 	50MHz
--					(2) System Reset (Asynchronous)
--
--				Outputs:
--					(1) Clocks:
--						(*) SDRAM Clock		-	133MHz
--						(*)	VESA Clock		-	40MHz
--
--					(2) Synchronized Resets for:
--						(*) SDRAM Clock
--						(*)	VESA Clock
--
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

entity global_nets_top is
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
end entity global_nets_top;

architecture rtl_global_nets_top of global_nets_top is

---------------------------		Components		-------------------------------------

--Clock Block - TOP
component clk_blk_top
	port (
			fpga_clk		:	in std_logic ;				--Input clock to the FPGA (50MHz)
			sdram_clk		:	out std_logic ;				--Output SDRAM clock (133MHz)
			vesa_clk		:	out std_logic ;				--Output VESA clock (40MHz)
			pll_locked		:	out std_logic 				--PLL locked indication. 
		);
end component clk_blk_top;

--Reset Block - TOP
component reset_blk_top 
	generic (
			reset_polarity_g	:	std_logic := '0'		--When '0' - Reset
			);
	port (
			fpga_clk		:	in std_logic ;				--Input clock to the FPGA (50MHz)
			sdram_clk		:	in std_logic ;				--Input SDRAM clock (133MHz)
			vesa_clk		:	in std_logic ;				--Input VESA clock (40MHz)
			fpga_rst		:	in std_logic ;				--Input reset from FPGA
			pll_locked		:	in std_logic ;				--PLL locked indication. In case PLL is not in the design, connect VCC to this port
			sync_sdram_rst	:	out std_logic ;				--Output Synchronized reset - 133MHz
			sync_vesa_rst	:	out std_logic				--Output Synchronized reset - 40MHz
		);
end component reset_blk_top;

------------------------------		Signals		--------------------------------------
signal sdram_clk_i	:	std_logic;	--Internal SDRAM Clock
signal vesa_clk_i   :	std_logic;	--Internal VESA Clock
signal pll_locked_i :	std_logic;	--Internal pll-locked indication

------------------------------	Implementation	--------------------------------------
begin
	--Clock block instance
	clk_blk_inst : clk_blk_top port map (
					fpga_clk	=> fpga_clk,
					sdram_clk	=> sdram_clk_i,
					vesa_clk	=> vesa_clk_i,
					pll_locked	=> pll_locked_i
					);

	--Reset block instance
	reset_blk_inst : reset_blk_top generic map (
						reset_polarity_g => reset_polarity_g
					)
					port map (
					fpga_clk		=> fpga_clk,
					sdram_clk		=> sdram_clk_i,
					vesa_clk		=> vesa_clk_i,
					fpga_rst		=> fpga_rst,
					pll_locked		=> pll_locked_i,
					sync_sdram_rst	=> sync_sdram_rst,
					sync_vesa_rst	=> sync_vesa_rst
					);
					
	--SDRAM Clock to output
	sdram_clk_proc : 
	sdram_clk <= sdram_clk_i;
					
	--VESA Clock to output
	vesa_clk_proc : 
	vesa_clk <= vesa_clk_i;

end architecture rtl_global_nets_top;

