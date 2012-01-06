------------------------------------------------------------------------------------------------
-- Model Name 	:	UART RX TestBench
-- File Name	:	uart_rx_tb.vhd
-- Generated	:	20.11.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		20.11.2010	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity checksum_tb is
	generic
	( 
		signed_checksum_g 	: boolean := false;
		reset_polarity_g	: std_logic := '0'
	);
end entity checksum_tb;

architecture arc_checksum_tb of checksum_tb is

component checksum_calc 
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
end component; 

signal clk			:	std_logic := '0';
signal rst			:	std_logic := '0';
signal data			:	std_logic_vector (7 downto 0) := (others => '0');	--Data to be calculated
signal dval			:	std_logic := '0';	--Data valid
signal reset_crc	:	std_logic := '0';	--Reset CRC
signal req_crc		:	std_logic := '0';	--Request for CRC result
signal crc_out		:	std_logic_vector (7 downto 0) := (others => '0');	--Checksum result
signal cval			:	std_logic := '0'; 	--Valid checksum

begin

	checksum_inst1 : checksum_calc 	generic map (signed_checksum_g => false,
												reset_polarity_g => reset_polarity_g)
									port map (
										clock			=>	clk,	
										reset			=>	rst,
										data			=>	data,	
										data_valid		=>	dval,
										reset_checksum	=>	reset_crc,
										req_checksum	=>	req_crc,	
											            
										checksum_out	=>	crc_out,	
										checksum_valid	=>	cval
									);
	
	clk <= not clk after 10 ns; --Clock
	rst <= reset_polarity_g, (not reset_polarity_g) after 30 ns; --Reset at startup
	
	calc_proc : process (clk)
	variable cnt : natural := 0;
	begin
		if rising_edge(clk) then
			data <= data - '1';
			dval <= '1';
			if cnt = 10 then
				req_crc <= '1';
				reset_crc <= '1';
				cnt := 0;
			else
				req_crc <= '0';
				reset_crc <= '0';
				cnt := cnt + 1;
			end if;
		end if;
	end process calc_proc;
end architecture arc_checksum_tb;