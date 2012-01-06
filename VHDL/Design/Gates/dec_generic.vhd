------------------------------------------------------------------------------------------------
-- Model Name 	:	Decoder
-- File Name	:	dec_generic.vhd
-- Generated	:	14.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The file implements Decoder, with single bit input, and generic output:
--				There is a std_logic vector, sized (2^selector_g) bits.
--
--				      /| -->
--				     / | -->
--					|  | -->
--				    |  | -->
--				--> |  | -->	Output (2**selector_g - 1 downto 0)
--				    |  | -->
--				     \ | -->
--				     |\| -->
--					 |  
--					Sel (selector_g - 1 downto 0)
--
--	(*) Example 1:
--				      /| --> '0'
--				     / | --> '0'
--					|  | --> '1'
--				    |  | --> '0'
--			'1'	--> |  | --> '0'
--				    |  | --> '0'
--				     \ | --> '0'
--				     |\| --> '0'
--					 |  
--					Sel (2 downto 0) = "010"
--
--	(*) Example 2:
--				      /| --> '0'
--				     / | --> '0'
--					|  | --> '0'
--				    |  | --> '0'
--			'0'	--> |  | --> '0'
--				    |  | --> '0'
--				     \ | --> '0'
--				     |\| --> '0'
--					 |  
--					Sel (2 downto 0) = "111"
--
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		14.12.2010	Beeri Shreiber					Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;

entity dec_generic is 
	generic	(
				selector_g	:	positive := 2									--Selector width
			);
	port ( 	
				sel		: in 	std_logic_vector (selector_g - 1 downto 0);		--Selector
				input	: in 	std_logic;										--Single Bit Input
				output	: out 	std_logic_vector (2**selector_g - 1 downto 0)	--Output
		);
end entity dec_generic;

architecture dec_generic_arc of dec_generic is

begin

  dec_out_proc : 
	process (sel, input)
    begin
		output <= (others => '0'); 				--All outputs are '0', except for the selected bit, which might be '0' or '1', according to the input
		output (conv_integer(sel)) <= input;	--Selected bit is '0' or '1', according to the input
    end process dec_out_proc;
	
end architecture dec_generic_arc;
