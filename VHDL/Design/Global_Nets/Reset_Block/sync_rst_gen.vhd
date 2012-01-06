------------------------------------------------------------------------------------------------
-- Model Name 	:	Synchronous Reset Generator
-- File Name	:	sync_rst_gen.vhd
-- Generated	:	15.02.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The Synchronous Reset Generator receives, as an input, a synchronouse reset to 
--				the system clock (50 MHz, in case of DE2).
--				The output is synchronous reset, to a given clock.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name				Description
--			1.00		15.02.2011	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all; 

entity sync_rst_gen is
	generic (
				reset_polarity_g	:	std_logic := '0'		--When '0' - Reset
			);
 	port 	(		   
				clk             	: in  	std_logic; 			-- Clock from PLL
				sys_rst_in     		: in 	std_logic;  		-- System synchronized reset
				sync_rst_out    	: out  	std_logic 			-- Synchronic reset to the given clock 
			);	
end entity sync_rst_gen;

architecture rtl_sync_rst_gen of sync_rst_gen is 

--------------------------   Signals ---------------------------
signal 	 sync_rst_deb    	: std_logic;

--------------------------   Implementation	--------------------
begin 	  
	
	-----------------------------------------------------------------------
	-----------------	Process sync_rst_proc	---------------------------
	-----------------------------------------------------------------------
	-- The process converts the synchronized input reset to a given clock,
	-- which might be in a different clock domain.
	-----------------------------------------------------------------------	
	sync_rst_proc: process (clk, sys_rst_in)
	begin 
		if (sys_rst_in = reset_polarity_g) then
			sync_rst_deb 	<= reset_polarity_g;
			sync_rst_out	<= reset_polarity_g;
		elsif rising_edge(clk) then
			sync_rst_deb 	<= not reset_polarity_g;
			sync_rst_out 	<= sync_rst_deb;
		end if;
	end process sync_rst_proc;
					  			  				  
end architecture rtl_sync_rst_gen;