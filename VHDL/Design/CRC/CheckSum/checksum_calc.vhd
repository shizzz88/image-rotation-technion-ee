------------------------------------------------------------------------------------------------
-- Model Name 	:	CheckSum
-- File Name	:	CheckSum_calc.vhd
-- Generated	:	4.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
--	This file implements a CheckSum calculator.
--	Signed an Unsigned numbers are supported, according to a generic parameter.
--	Output checksum width may be equal or greater than the input data width.
--	
-- Instructions:
--		(1) Reset system, using the 'reset' line
--		(2) Supply data, using the 'data' line and 'data_valid' signal
--		(3) Aquire new CheckSum:
--			(a) Rise the 'req_checksum' signal
--			(b) checksum_valid flag will be raised, together with valid data.
--		(4) Reset CheckSum current value, using the 'reset_checksum' signal
--		Note that each clock - a new CheckSum will be calculated, although the
--		'checksum_valid' line is not raised.
--
--
------------------------------------------------------------------------------------------------
-- Waveforms examples:
--
--	(1) Option 1 	- Reset checksum to initial value
---					- Request checksum result AFTER all valid data
--	clock				-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
--
--	data_valid			____--__--__--______--___....___--__________
--	reset_checksum		__--_____________________...._______________
--	req_checksum		_________________________...._______--______
--	checksum_valid		_________________________...._________--____
--						  ||						  	      ||
--						New calculation					Valid CheckSum
--
--	(2) Option 2 	- Reset checksum to the first data
--					- Request checksum result at the same clock as the last
--					  calculated data, which will be included in the result
--	clock				-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-
--
--	data_valid			__--____--__--______--___....___--__--______
--	reset_checksum		__--_____________________...._______________
--	req_checksum		_________________________...._______--______
--	checksum_valid		_________________________...._________--____
--						  ||						  	      ||
--						New calculation					Valid CheckSum
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		4.12.2010	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--
------------------------------------------------------------------------------------------------
                    
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;

entity checksum_calc is 
   generic 	(
				reset_polarity_g	:	std_logic := '0'; 	--'0' = active low
				signed_checksum_g	:	boolean	:= false;	--TRUE to signed checksum, FALSE to unsigned checksum
				
				--IMPORTANT:
				--In case of a sign number, remmember that the MSB bit is reserved as the sign bit.
				--It means that the input / output data width represent a number sized (width-1)
				checksum_init_val_g	:	integer	:= 0;		--Note that the initial value is given as an natural number, and not STD_LOGIC_VECTOR
				
				--IMPORTANT:
				--checksum_out_width_g must be greater than or equal to data_width_g
				checksum_out_width_g:	natural := 8;		--Output CheckSum width
				data_width_g		:	natural := 8		--Input data width
			);
	port(           
           clock			: in  std_logic;	--Clock 
           reset			: in  std_logic; 	--Reset
           data				: in  std_logic_vector(data_width_g - 1 downto 0); --Data to calculate
           data_valid		: in  std_logic; 	--Data is Valid
		   reset_checksum	: in  std_logic;	--Reset the current checksum to the initial value
		   req_checksum		: in  std_logic;	--Request for valid checksum
           
		   checksum_out		: out std_logic_vector(checksum_out_width_g - 1 downto 0); --Checksum value
           checksum_valid	: out std_logic 	--CheckSum valid
       );
end entity checksum_calc; 

architecture arc_checksum_calc of checksum_calc is 

----------------------------- Signals -------------------------------------------------
 signal checksum_i				: std_logic_vector (checksum_out_width_g downto 0); --Current calculated checksum
 signal checksum_init_val 		: std_logic_vector (checksum_out_width_g downto 0);	--Initial value

 ----------------------------- Processes -------------------------------------------------
begin 
		  
cns1 : 
if signed_checksum_g generate
	checksum_init_val	<= std_logic_vector(to_signed(checksum_init_val_g, checksum_out_width_g + 1)); --Checksum Signed initial value
end generate;

cns2 :
if not signed_checksum_g generate
	checksum_init_val	<= std_logic_vector(to_unsigned(checksum_init_val_g, checksum_out_width_g + 1)); --Checksum Unsigned initial value; 
end generate;

checksum_out_proc:
checksum_out <= checksum_i (checksum_out_width_g - 1 downto 0); --Output checksum value		  

------------------------------------------------------------------
----------------- Process checksum_calc_process -------------------
------------------------------------------------------------------
-- The process calculates a new checksum, when the data_valid	-- 
-- flag is '1'.													--
-- Calculation:
-- [(Current Checksum) + (Supplied Data)] mod 2^(Checksum width)--
------------------------------------------------------------------
checksum_calc_process : process(clock, reset) 
begin                                    
 if (reset = reset_polarity_g) then  
	checksum_i <= checksum_init_val ;		--Reset System
 elsif rising_edge(clock) then
	if (reset_checksum = '1') then
		if (data_valid = '1') then --Reset checksum, and set initial value as the input data
			if signed_checksum_g then --Signed data
				checksum_i <= std_logic_vector(resize(signed(data), checksum_out_width_g + 1));
			else --Unsigned data
				checksum_i <= std_logic_vector(resize(unsigned(data), checksum_out_width_g + 1));
			end if;
		else --Reset checksum to initial value
			checksum_i <= checksum_init_val ;	--Reset CheckSum (Same as system reset)
		end if;

	elsif (data_valid = '1') then --Calculate new CheckSum
         if signed_checksum_g then --Signed checksum
			checksum_i <= std_logic_vector(resize(signed(checksum_i(checksum_out_width_g - 1 downto 0)) + signed(data), checksum_out_width_g + 1));
		else --Unsigned checksum
			checksum_i <= std_logic_vector(resize(unsigned(checksum_i(checksum_out_width_g - 1 downto 0)) + unsigned(data), checksum_out_width_g + 1));
		end if;
    end if; 
 end if;    
end process checksum_calc_process;      
    
------------------------------------------------------------------
----------------- Process checksum_valid_gen ---------------------
------------------------------------------------------------------
-- The process rises the CheckSum_valid flag, when the data 	--
-- provided request for the new CheckSum.						--
------------------------------------------------------------------

checksum_valid_gen : process(clock, reset) 
begin                                    
 if (reset = reset_polarity_g) then 
     checksum_valid <= '0'; 
 elsif rising_edge(clock) then 
    if (req_checksum = '1') then 
        checksum_valid <= '1'; --Checksum is valid
    else 
        checksum_valid <= '0'; 
    end if; 
 end if;    
end process checksum_valid_gen; 

end architecture arc_checksum_calc;