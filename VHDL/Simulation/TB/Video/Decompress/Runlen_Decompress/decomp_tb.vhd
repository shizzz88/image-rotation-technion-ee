------------------------------------------------------------------------------------------------
-- Description: Decompression Test Bench
--	The file connects between the 'tx_data' and 'decomp'.
--	Only clock should be stimulate, in order to active models. 
-----------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

use std.textio.all;

entity decomp_tb is
   generic (
             rep_size_g		:		natural := 2 --Maximum nibbles (4 bits) to represent number of repetition (4==> 2^16 = 65536 bits)
           );
end decomp_tb;

architecture arc_decomp_tb of decomp_tb is

------------------  Components ----------------------
component runlen_extractor
   generic (
			reset_polarity_g	:	std_logic	:= '0';		--Reset active low
			pixels_per_line_g	:	positive	:= 640;		--640X480
			rep_size_g			:	positive	:= 7;		--2^7=128 => Maximum of 128 repetitions for pixel / line
			width_g				:	positive	:= 8		--Input / output width
           );
   port
   	   (
   	     clk		:	in std_logic;       							--Input clock
   	     rst		:	in std_logic;									--Reset
		 fifo_full	:	in std_logic;									--Output FIFO is full
		 fifo_empty	:	in std_logic;									--Input FIFO is empty
		 flush		:	in std_logic;									--Restart component
		 din		:	in std_logic_vector (width_g - 1 downto 0);		--Input data
		 din_val	:	in std_logic;									--Input data is valid
		 req_data	:	out std_logic;									--Request for data
		 dout		:	out std_logic_vector (width_g - 1 downto 0);	--Output pixel
		 dout_val	:	out std_logic									--Output data is valid
   	   );
end component runlen_extractor;

component tx_data
   generic (
             rep_size_g		:		natural := 7
           );
   port
   	   (
   	     clk		:	in std_logic; --Input clock
   	     flush		:	in std_logic;
   	     req_data   :	in std_logic;
   	     dout		:	out std_logic_vector (7 downto 0); --Color value (0--> 255 ==> 0-->FF) or repetitions
		 dout_val	:	out std_logic;
   	     end_pic	:	out boolean := false --TRUE when end of file
	   );
end component tx_data;

------------------  SIGNALS AND VARIABLES ------
signal end_pic		:	boolean;
signal req_data		:	std_logic;
signal sc_fifo_dout	:	std_logic_vector (7 downto 0);
signal dc_fifo_dout	:	std_logic_vector (7 downto 0);
signal sc_fifo_dout_val		:	std_logic;
signal dc_fifo_dout_val		:	std_logic;
signal flush		:	std_logic;
signal fifo_full	:	std_logic := '0';
signal fifo_empty	:	std_logic := '0';

signal clk			:	std_logic := '0';
signal rst			:	std_logic;


------------------  Implementation ------
begin

	tx_inst: tx_data generic map (rep_size_g => 8)
					port map
					   (
						 clk		=>	clk,		
						 flush		=>	flush,
						 req_data   =>	req_data,
						 dout		=>	sc_fifo_dout,
						 dout_val	=>	sc_fifo_dout_val,
						 end_pic	=>	end_pic
					   );
					   
	runlen_inst : runlen_extractor generic map
						(
						reset_polarity_g	=>	'0',	
						pixels_per_line_g	=>	640,
						rep_size_g			=>	8,
						width_g				=>	8
					   )
					port map
					   (
						 clk		=>	clk,		
						 rst		=>	rst,
						 fifo_full	=>	fifo_full,
						 fifo_empty	=>	fifo_empty,
						 flush		=>	flush,
						 din		=>	sc_fifo_dout,
						 din_val	=>	sc_fifo_dout_val,
						 req_data	=>	req_data,
						 dout		=>	dc_fifo_dout,
						 dout_val	=>	dc_fifo_dout_val
					   );
		 
	clk_proc:
	clk <= not clk after 10 ns;
	
	rst_proc:
	rst	<=	'0', '1' after 30 ns;
end arc_decomp_tb;		