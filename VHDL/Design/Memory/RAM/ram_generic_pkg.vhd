------------------------------------------------------------------------------------------------
-- Model Name 	:	Generic RAM
-- File Name	:	ram_generic_pkg.vhd
-- Generated	:	13.3.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		13.3.2011	Beeri Schreiber					Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

package ram_generic_pkg is

	--------------------------------------------------------------------------------------
	---------------			Function data_wcalc		--------------------------------------
	--------------------------------------------------------------------------------------
	-- The function calculated the required output data width, according to its inputs.
	--	(*) width_in	-	Input port width
	--	(*)	power2_out	-	Power of 2, of the output size
	--	(*)	power_sign	-	1 	for multiply 	(Output > input), 
	--						-1 	for divide 		(Input  > Output)
	--------------------------------------------------------------------------------------
	function data_wcalc (	constant width_in 	: in positive; 				--Input Data Width
							constant power2_out	: in natural;				--2^(power2_out)
							constant power_sign	: in integer range -1 to 1	--Multiply (1) or divide (-1)
						) return natural;

end package ram_generic_pkg;

package body ram_generic_pkg is

	--------------------------------------------------------------------------------------
	---------------			Function data_wcalc		--------------------------------------
	--------------------------------------------------------------------------------------
	function data_wcalc (	constant width_in 	: in positive; 				--Input Data Width
							constant power2_out	: in natural;				--2^(power2_out)
							constant power_sign	: in integer range -1 to 1	--Multiply (1) or divide (-1)
						) return natural is
	begin
		if (power_sign = -1) then
			return ( width_in / (2**power2_out) );
		elsif (power_sign = 1) then
			return ( width_in * (2**power2_out) );
		else
			report "RAM Generic Package, Data_WCalc Function: Allowed values for power_sign are 1 and -1"
				severity error;
			return width_in;
		end if;
	end function data_wcalc;

end package body ram_generic_pkg;