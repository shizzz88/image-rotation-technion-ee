------------------------------------------------------------------------------------------------
-- Model Name 	:	MUX
-- File Name	:	mux_generic.vhd
-- Generated	:	13.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This file implements MUX with generic input and output:
--				(1) Input : std_logic_vector, sized (2^selector_g*width_g) bits.
--				(1) Output: std_logic_vector, sized (width_g) bits.
--
--				   											--> |\  	
--				   											--> | \ 	
--															--> |  |   	
--				   											--> |  |   	
--	Input ((2**selector_g) * width_g - 1) downto 0)			--> |  | -->	Output (width_g - 1 downto 0)
--				   											--> |  |   	
--				   											--> | /  	
--				   											--> |/|  	
--															  	  |
--															Sel (selector_g - 1 downto 0)
--
--	(*) Example : input = "102A3F4D52657A87"
--				"10" -->(7)|\  	
--		        "2A" -->(6)| \ 	
--		        "3F" -->(5)|  |   	
--		        "4D" -->(4)|  |   	
--		        "52" -->(3)|  | --> "65"
--		        "65" -->(2)|  |   	
--		        "7A" -->(1)| /  	
--		        "87" -->(0)|/|  	
--		              	     |
--					Sel (2 downto 0) = "010" [010b = 2d = 3rd choice]
--------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		13.12.2010	Beeri Shreiber					Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;

entity mux_generic is 
	generic	(
				width_g		:	positive := 8;	--Input / Output length
				selector_g	:	positive := 2	--Selector width
			);
	port ( 	
				sel		: in std_logic_vector (selector_g - 1 downto 0);				--Selector
				input	: in std_logic_vector ((2**selector_g)*width_g - 1 downto 0);	--Input
				output	: out std_logic_vector (width_g - 1 downto 0)					--Output
		);
end entity mux_generic;

architecture mux_generic_arc of mux_generic is

----------------------------   Types --------------------------------------------
type slv_vec is array (natural range <>) of std_logic_vector (width_g - 1 downto 0);

----------------------------   Signals ------------------------------------------
signal in_arr : slv_vec (0 to 2**selector_g - 1);

----------------------------   Implementation -----------------------------------
begin

	-- Convert long std_logic_vector into 'width_g' blocks of std_logic_vector
	in_arr_gen :
	for idx in 1 to 2**selector_g generate
		in_arr (idx - 1) <= input ( (width_g*idx - 1) downto (width_g*(idx - 1)) );
	end generate in_arr_gen;

    -------------------------------------------------------------------------------------
	--------------------------- Process mux_out_proc ------------------------------------
    -------------------------------------------------------------------------------------
	-- The process's output is the selected part of the input, by the 'sel' signal
    -------------------------------------------------------------------------------------
	mux_out_proc : 
	process (sel, in_arr)
    begin
		output <= in_arr (conv_integer(sel));
    end process mux_out_proc;

end architecture mux_generic_arc;
