------------------------------------------------------------------------------------------------
-- Model Name 	:	RAM
-- File Name	:	ram_simple.vhd
-- Generated	:	8.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This model implements a dual port RAM.
--
-- Inputs and Outputs:	(1) Input width is being set by a generic parameter. 
--						(2) Output width is the same as the input width
--
-- Addressing:			(1) Input / Output address: According to std_logic_vector, sized 'addr_bits_g'.

--		Example:
--			Address 	RAM Content
--						|----------|
--			(0)			|	AA     |
--						|----------|
--			(1)			|	BB     |
--						|----------|
--			(2)			|	CC     |
--						|----------|
--			(3)			|	DD     |
--						|----------|
--				Input address 	(0) = AA
--				Output address 	(0) = AA
--				Output address 	(1) = BB
--				Output address 	(2) = CC
--				Output address 	(3) = DD
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		8.12.2010	Alon Yavich & Beeri Schreiber	Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------
library ieee ;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity ram_simple is
	generic (
				reset_polarity_g	:	std_logic 	:= '0';	--'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 	:= 8;	--Width of data
				addr_bits_g			:	positive 	:= 10	--Depth of data	(2^10 = 1024 addresses)
			);
	port	(
				clk			:	in std_logic;									--System clock
				rst			:	in std_logic;									--System Reset
				addr_in		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out	:	in std_logic_vector (addr_bits_g - 1 downto 0); --Output address
				aout_valid	:	in std_logic;									--Output address is valid
				data_in		:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid	:	in std_logic; 									--Input data valid
				data_out	:	out std_logic_vector (width_in_g - 1 downto 0);	--Output data
				dout_valid	:	out std_logic 									--Output data valid
			);
end entity ram_simple;

architecture arc_ram_simple of ram_simple is
------------------  	Types		------
type ram_arr is array (natural range <> ) of std_logic_vector (width_in_g - 1 downto 0);

------------------  	Signals		------
signal ram_data		:	ram_arr (0 to 2**addr_bits_g - 1);

------------------  Implementation	------
begin
	
	------------------------------------------
	---------	Process din_proc 	----------
	------------------------------------------
	-- The process writes a given data into
	-- a given address, when data is valid.
	------------------------------------------
	din_proc : process (clk)
	begin
		if rising_edge(clk) then
			if din_valid = '1' then
				ram_data (conv_integer(unsigned(addr_in))) <= data_in;
			end if;
		end if;
	end process din_proc;
	
	------------------------------------------
	---------	Process dout_proc 	----------
	------------------------------------------
	-- The process' output is the required 
	-- data from a given address, when the 
	-- given address is valid.
	------------------------------------------
	dout_proc : process (clk)
	begin
		if rising_edge(clk) then
			if aout_valid = '1' then 	--Output address is valid
				data_out <= ram_data (conv_integer(unsigned(addr_out)));
			end if;
		end if;
	end process dout_proc;

	------------------------------------------
	------- Process data_out_valid_proc ------
	------------------------------------------
	-- The process raises the valid flag, when
	-- the data is valid.
	------------------------------------------
	data_out_valid_proc : process (clk, rst)
    begin
		if rst = reset_polarity_g then  --System Reset
			dout_valid      <= '0';
        elsif rising_edge(clk) then
			dout_valid <= aout_valid;
        end if;
    end process data_out_valid_proc;
	
end architecture arc_ram_simple;
				