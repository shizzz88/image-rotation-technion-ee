------------------------------------------------------------------------------------------------
-- Model Name 	:	Intercon Package
-- File Name	:	intercon_pkg.vhd
-- Generated	:	23.04.2012
-- Author		:	Beeri Schreiber
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Address parameters for INTERCON connection
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		23.04.2012	Beeri Schreiber		Creation
--			1.1			28.04.2013	Uri Tsipin			added support for image manipulation registers
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package intercon_pkg is
	function get_wbs (	id	:	in string (1 to 3);
						tgc	:	in std_logic;
						adr	:	in std_logic_vector (9 downto 0)
					) return natural;
					
end package intercon_pkg;

package body intercon_pkg is
	function get_wbs (	id	:	in string (1 to 3);
						tgc	:	in std_logic;
						adr	:	in std_logic_vector (9 downto 0)
					) return natural is
	variable adrint	:	natural;
	begin
		adrint	:=	conv_integer (adr);
		case id is
			when "icz"	=>	--INTERCON Z
				if (tgc = '0') then	--Write to component (mem_management block)
					return 0;		
				
				else				--Write to registers
					case adrint is
						when 2 | 3 | 4 | 13 =>			--mem_management
							return 0;
							
						when 5 | 6 | 7 | 8 | 14	=>		--display controller
							return 1;
							
						when 9 | 10 | 11 | 12 | 15 =>	--tx_path
							return 2;
						when 16| 17| 19| 21| 23| 25 => 	--image_manipulation
							return 3;
						
						when others =>
							report "INTERCON (" & id & "): Unknown INTERCON address: 0x" & integer'image(adrint)
							severity failure;
							return 0;
					end case;
				end if;
			
			when "icy"	=>	--INTERCON Y
				return 0;
			
			when others =>
				report "INTERCON (" & id & "): Unknown INTERCON ID"
				severity failure;
				return 0;
				
		end case;
	end function get_wbs;
  
end package body intercon_pkg;
