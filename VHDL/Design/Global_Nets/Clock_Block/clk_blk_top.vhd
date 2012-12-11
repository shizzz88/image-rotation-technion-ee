------------------------------------------------------------------------------------------------
-- Model Name 	:	Clocks Block - TOP
-- File Name	:	clk_blk_top.vhd
-- Generated	:	07.03.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This block is the top block of the clocks.
--				Input:
--					(*) System Clock 		- 	50MHz
--
--				Outputs:
--					(1) Clocks:
--						(*) SDRAM Clock		-	133MHz
--						(*) System Clock	-	100MHz
--						(*)	VESA Clock		-	40MHz
--
--					(2) PLL-Locked signal indication
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name				Description
--			1.00		07.03.2011	Beeri Schreiber		Creation
--			1.10		16.02.2012	Beeri Schreiber		Added 100MHz clock domain
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity clk_blk_top is
	port (
			fpga_clk		:	in std_logic ;				--Input clock to the FPGA (50MHz)
			sdram_clk		:	out std_logic ;				--Output SDRAM clock (133MHz)
			system_clk		:	out std_logic ;				--Output System clock (100MHz)
			vesa_clk		:	out std_logic ;				--Output VESA clock (40MHz)
			pll_locked		:	out std_logic 				--PLL locked indication. 
		);
end entity clk_blk_top;

architecture rtl_clk_blk_top of clk_blk_top is

---------------------------		Components		-------------------------------------

--PLL
component pll
	port
	(
		inclk0	: in 	std_logic  := '0';
		c0		: out 	std_logic ;
		c1		: out 	std_logic ;
		c2		: out 	std_logic ;
		locked	: out 	std_logic 
	);
end component pll;

------------------------------	Implementation	--------------------------------------
begin
	--PLL Instance. Input clock is 50MHz, Outputs are 133MHz, 100MHz, 40MHz, pll-locked indication
	pll_inst : pll port map (
					inclk0	=> fpga_clk,
					c0		=> sdram_clk,
					c1		=> system_clk,
					c2		=> vesa_clk,
					locked	=> pll_locked
					);
					
end architecture rtl_clk_blk_top;