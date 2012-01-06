------------------------------------------------------------------------------------------------
-- Model Name 	:	Generic RAM
-- File Name	:	ram_generic.vhd
-- Generated	:	8.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This model implements a dual port RAM, which supports different sizes of input
--				and output ports.
--
-- Inputs and Outputs:	(1) Input width is being set by a generic parameter. 
--						(2) Output width might be multiplied / divided by power of 2, 
--							according to generic parameter.
--					i.e (a): 	Input width = 8 bits,
--								Output width = 8/16/32/64... bits (Powers of 2).
--					i.e (b): 	Input width = 16 bits,
--								Output width = 8/4/2/1 bits (Powers of ½).
--
-- Addressing:			(1) Input address: According to std_logic_vector, sized 'addr_bits_g'.
--						(2) Output address: Same as input address.
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
--			Suppose 'power2_out_g = 1'. Then:
--				Input address 	(0) = AA
--				Input address 	(1) = BB
--				Input address 	(2) = cc
--				Input address 	(3) = DD
--				Output address 	(0) = AABB
--				Output address 	(1) = CCDD
--				Note that there is not such address 'Output address (2)'
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		8.12.2010	Beeri Schreiber					Creation			
--			1.01		15.5.2011	Beeri Schreiber					2 clock delay improvment to 1
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;

library work ;
use work.ram_generic_pkg.all;

entity ram_generic is
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
end entity ram_generic;

architecture rtl_ram_generic of ram_generic is

------------------	Components	----------
component ram_simple 
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
end component ram_simple;


--MUX will be used for output < input
component mux_generic 
	generic	(
				width_g		:	positive := 8;	--Input / Output length
				selector_g	:	positive := 2	--Selector width
			);
	port ( 	
				sel		: in std_logic_vector (selector_g - 1 downto 0);				--Selector
				input	: in std_logic_vector ((2**selector_g)*width_g - 1 downto 0);	--Input
				output	: out std_logic_vector (width_g - 1 downto 0)					--Output
		);
end component mux_generic;

--DEC will be used for output >= input
component dec_generic 
	generic	(
				selector_g	:	positive := 2	--Selector width
			);
	port ( 	
				sel		: in 	std_logic_vector (selector_g - 1 downto 0);
				input	: in 	std_logic;
				output	: out 	std_logic_vector (2**selector_g - 1 downto 0)
		);
end component;

------------------  	Constants		------
constant reduce_width_c:	natural	:= data_wcalc(width_in_g, power2_out_g, power_sign_g);

------------------  	Signals		------
signal dout_valid_s	:	std_logic_vector (2**power2_out_g - 1 downto 0 );	--Internal dout_valid
signal aout_valid_s	:	std_logic_vector (2**power2_out_g - 1 downto 0 );	--Internal aout_valid

--Input < Output
signal bank_en		:	std_logic_vector (2**power2_out_g - 1 downto 0);	--RAM Bank enable

--Input > Output
signal ram2mux		:	std_logic_vector (width_in_g - 1 downto 0);			--Data: RAM to MUX 

------------------  Implementation	------
begin
	--##############################################################################--
	--								Output 	<	Input								--
	--##############################################################################--
	
	--MUX instance, for Output < Input
	power_sign_mux:
	if (power_sign_g = (-1)) and (power2_out_g > 0) generate

		dout_valid_proc: 
  		dout_valid <= or_reduce (dout_valid_s);	--If one of the valids is '1', then dout_valid is '1'

		MUX_inst_data : mux_generic generic map (
								width_g 	=> reduce_width_c,
								selector_g	=> power2_out_g
								)
								port map 	(
								sel		=> addr_out (power2_out_g - 1 downto 0),
								input	=> ram2mux,
								output	=> data_out
								);

		DEC_inst_aout : dec_generic generic map 	(
									selector_g => power2_out_g
								)
								port map	(
									sel		=>	addr_out (power2_out_g - 1 downto 0),
									input	=>	aout_valid,
									output	=>	aout_valid_s
								);

		--RAM Banks instance
		ram_gen : 
		for idx in 0 to (2**power2_out_g - 1) generate
			
			RAM_inst : ram_simple generic map (
									reset_polarity_g	=> reset_polarity_g,			--Same reset polarity
									width_in_g 			=> reduce_width_c,				
									addr_bits_g			=> addr_bits_g
								)
					port map	(
									clk			=> clk,
									rst			=> rst,
									addr_in		=> addr_in, 
									addr_out	=> addr_out (addr_bits_g + power2_out_g - 1 downto power2_out_g),	
									aout_valid	=> aout_valid_s (idx),	
									data_in		=> data_in ( (2**power2_out_g - idx)*reduce_width_c - 1 downto (2**power2_out_g - idx - 1)*reduce_width_c ),		
									din_valid	=> din_valid,	
									data_out	=> ram2mux ( (2**power2_out_g - idx)*reduce_width_c - 1 downto (2**power2_out_g - idx - 1)*reduce_width_c ),
									dout_valid	=> dout_valid_s (idx)
								);
		end generate ram_gen;
						
	end generate power_sign_mux;

	
	--##############################################################################--
	--								Output 	>=	Input								--
	--##############################################################################--
	
	--Decoder instance, for Input <= Output
	power_sign_dec:
	if (power_sign_g = 1) generate
		dec_gen1:	--Output width > Input width
		if (power2_out_g /= 0) generate
			DEC_inst : dec_generic generic map 	(
										selector_g => power2_out_g
									)
									port map	(
										sel		=>	addr_in (power2_out_g - 1 downto 0),
										input	=>	din_valid,
										output	=>	bank_en
									);
		end generate dec_gen1;

		dec_gen2:	--Output width = input width
		if (power2_out_g = 0) generate
			bank_en (0) <= din_valid;
		end generate dec_gen2;
	

		--RAM Banks instance
		ram_gen : 
		for idx in 0 to (2**power2_out_g - 1) generate
			RAM_inst : ram_simple generic map (
									reset_polarity_g	=> reset_polarity_g,			--Same reset polarity
									width_in_g 			=> width_in_g,					--Same width
									addr_bits_g			=> addr_bits_g - power2_out_g	--Different addressing
								)
					port map	(
									clk			=> clk,
									rst			=> rst,
									addr_in		=> addr_in (addr_bits_g - 1 downto power2_out_g),
									addr_out	=> addr_out,	
									aout_valid	=> aout_valid,	
									data_in		=> data_in,		
									din_valid	=> bank_en (idx),	
									data_out	=> data_out ((width_in_g * (2**power2_out_g - 2**idx + 1) - 1) downto (width_in_g * (2**power2_out_g - 2**idx))),
									dout_valid	=> dout_valid_s (idx)
								);
		end generate;

	dout_valid_proc:	--Internal dout_valid
	dout_valid <= dout_valid_s(0);

	end generate power_sign_dec;
	
end architecture rtl_ram_generic;
