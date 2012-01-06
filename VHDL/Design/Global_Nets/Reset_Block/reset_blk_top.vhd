------------------------------------------------------------------------------------------------
-- Model Name 	:	Reset Block - TOP
-- File Name	:	reset_blk_top.vhd
-- Generated	:	06.03.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This block is the top block of the reset_debouncer and sync_rst_gen.
--				Inputs:
--					(1) Clocks:
--						(*) System Clock 	- 	50MHz
--						(*) SDRAM Clock		-	133MHz
--						(*)	VESA Clock		-	40MHz
--
--					(2) Asynchronous Reset to FPGA
--
--					(3) PLL-Locked signal
--
--				Outputs:
--					(1) Synchronous Resets:
--						(*) Synchronous Reset	-	133MHz
--						(*) Synchronous Reset	-	40MHz
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name				Description
--			1.00		06.03.2011	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity reset_blk_top is
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
end entity reset_blk_top;

architecture rtl_reset_blk_top of reset_blk_top is

---------------------------		Components		-------------------------------------

--Reset Debouncer
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

--Sync Reset
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

------------------------------		Signals		--------------------------------------
signal sync_rst_50_i	:	std_logic;	--Internal 50MHz synchronized reset

------------------------------	Implementation	--------------------------------------
begin
	--Reset Debouncer. Synchronizes the System async reset to 50MHz clock
	rst_deb_inst: reset_debouncer 
				generic map 
					( reset_polarity_g => reset_polarity_g )
				port map
					(
						fpga_in_clk		=>	fpga_clk,
						rst_in			=>	fpga_rst,
						pll_locked		=>	pll_locked,
						sync_rst_out	=>	sync_rst_50_i
					);
	
	--Sync reset generator. Synchronized the 50MHz reset to SDRAM clock
	sync_rst_sdram_inst: sync_rst_gen
				generic map 
					( reset_polarity_g => reset_polarity_g )
				port map
					(
						clk         	=>	sdram_clk,
						sys_rst_in  	=>	sync_rst_50_i,
						sync_rst_out	=>	sync_sdram_rst
					);

	--Sync reset generator. Synchronized the 50MHz reset to VESA clock
	sync_rst_vesa_inst: sync_rst_gen
				generic map 
					( reset_polarity_g => reset_polarity_g )
				port map
					(
						clk         	=>	vesa_clk,
						sys_rst_in  	=>	sync_rst_50_i,
						sync_rst_out	=>	sync_vesa_rst
					);

end architecture rtl_reset_blk_top;

