------------------------------------------------------------------------------------------------
-- Model Name 	:	Generic RAM TB
-- File Name	:	generic_ram_tb.vhd
-- Generated	:	15.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		15.12.2010	Beeri Schreiber					Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) Extend RAM to use input width > output width
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

library work ;
use work.ram_generic_pkg.all;

entity generic_ram_tb is
	generic (
				read_loop_iter_g	:	positive	:= 7;	--Number of read
				
				reset_polarity_g	:	std_logic 	:= '0';	--'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 	:= 16;	--Width of data
				addr_bits_g			:	positive 	:= 10;	--Depth of data	(2^10 = 1024 addresses)
				power2_out_g		:	natural 	:= 1;	--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide
				power_sign_g		:	integer range -1 to 1 := -1 -- '-1' => output width > input width ; '1' => input width > output width
			);
end entity generic_ram_tb;

architecture arc_generic_ram_tb of generic_ram_tb is

component ram_generic 
	generic (
				reset_polarity_g	:	std_logic 				:= '0';	--'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 				:= 8;	--Width of data
				addr_bits_g			:	positive 				:= 10;	--Depth of data	(2^10 = 1024 addresses)
				power2_out_g		:	natural 				:= 1;	--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide
				power_sign_g		:	integer range -1 to 1 	:= 1 	-- '-1' => output width > input width ; '1' => input width > output width
			);
	port	(
				clk			:	in std_logic;									--System clock
				rst			:	in std_logic;									--System Reset
				addr_in		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out	:	in std_logic_vector ((addr_bits_g - power2_out_g*power_sign_g) - 1 downto 0); 		--Output address
				aout_valid	:	in std_logic;									--Output address is valid
				data_in		:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid	:	in std_logic; 									--Input data valid
				data_out	:	out std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0);	--Output data
				dout_valid	:	out std_logic 									--Output data valid
			);
end component ram_generic;

----------------------   Signals   ------------------------------

--Signals to RAM
signal clk			: std_logic := '0';													--System clock
signal rst			: std_logic := '0';													--System Reset
signal addr_in		: std_logic_vector (addr_bits_g - 1 downto 0) := (others => '0'); 	--Input address
signal addr_out	    : std_logic_vector ((addr_bits_g - power2_out_g*power_sign_g) - 1 downto 0) := (others => '0'); 		--Output address
signal aout_valid	: std_logic := '0';													--Output address is valid
signal data_in		: std_logic_vector (width_in_g - 1 downto 0) := (others => '0');	--Input data
signal din_valid	: std_logic := '0'; 												--Input data valid
signal data_out	    : std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0) := (others => '0');	--Output data
signal dout_valid	: std_logic := '0'; 												--Output data valid

--Internal Signals
signal end_din		: boolean := false;													--TRUE when end of writing to RAM

-------------------  Implementation ----------------------------
begin

RAM_inst : ram_generic generic map (
								reset_polarity_g	=> reset_polarity_g,	
                                width_in_g			=> width_in_g,
                                addr_bits_g			=> addr_bits_g,			
                                power2_out_g		=> power2_out_g,
								power_sign_g		=> power_sign_g
								)
						port map (
								clk			=> clk,
								rst			=> rst,			
								addr_in		=> addr_in,		
								addr_out	=> addr_out,	
								aout_valid	=> aout_valid,	
								data_in		=> data_in,		
								din_valid	=> din_valid,	
								data_out	=> data_out,	
								dout_valid	=> dout_valid		
								);

clk_proc : 
	clk <= not clk after 10 ns;
	
rst_proc :
	rst <= reset_polarity_g, not reset_polarity_g after 40 ns;

	------

	din_proc : process 
	begin
		end_din <= false;
		for idx in 0 to read_loop_iter_g * (2**power2_out_g) - 1 loop
			wait until rising_edge(clk);
			addr_in 	<= conv_std_logic_vector (idx, addr_bits_g); 	--Input address 
			data_in 	<= conv_std_logic_vector (idx, width_in_g); 	--Input data 
			din_valid	<= '1';	--Data Valid
		end loop;
		end_din <= true;
		wait;
	end process din_proc;

	------

	dout_proc : process
	variable idx : natural := 0;
	begin
		wait until end_din;
		while true loop
			wait until rising_edge(clk);
			addr_out 	<= conv_std_logic_vector (idx, addr_bits_g - power2_out_g*power_sign_g); --Input address
			aout_valid	<= '1'; --Address Valid
			idx := idx + 1;
		end loop;
		wait;
	end process dout_proc;

end architecture arc_generic_ram_tb;
