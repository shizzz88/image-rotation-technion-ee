------------------------------------------------------------------------------------------------
-- Model Name 	:	Seven Segment
-- File Name	:	hexss.vhd
-- Generated	:	July 2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	Lab 1
------------------------------------------------------------------------------------------------
-- Description: The model translate a decimal number, ranged 0 to 15, represented by 4 bits,
--				to a hexadecimal number, ranged 0 to F.
--				Input: 4 bits, represents a number
--				Output: Signals to 7 Segment (Active low)
------------------------------------------------------------------------------------------------
-- Changes:
--			Number		Date		Name				Description
--			(1)			07/2010		Alon and Beeri		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;

entity hexss is
	port (	
			din		: in std_logic_vector (3 downto 0); --Decimal Number
			ss		: out std_logic_vector (6 downto 0) := (others => '0') --Output to 7 Segment
		);
end hexss;

architecture arc_hexss of hexss is
begin
	with din select
	ss <=  "0000001" when "0000", 
			"1001111" when "0001", 
			"0010010" when "0010", 
			"0000110" when "0011", 
			"1001100" when "0100", 
			"0100100" when "0101",
			"0100000" when "0110", 
			"0001111" when "0111", 
			"0000000" when "1000", 
			"0000100" when "1001", 
			"0001000" when "1010", 
			"1100000" when "1011", 
			"0110001" when "1100", 
			"1000010" when "1101", 
			"0110000" when "1110", 
			"0111000" when others;
end arc_hexss;		