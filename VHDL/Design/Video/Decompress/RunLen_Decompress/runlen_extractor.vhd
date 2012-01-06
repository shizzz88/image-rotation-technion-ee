------------------------------------------------------------------------------------------------
-- Model Name 	:	Run-Length Extractor
-- File Name	:	runlen_extractor.vhd
-- Generated	:	18.5.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This component is Run-Length Exctractor, which supports two types of operations:
--					1. Normal Run-Length Operation (8 bits color / 8 bits repetition)
--					2. Extended Run-Length Operation (8 bits color / 7 bits repetition / 1 bit 
--						repetition type, '0' for pixel repetition, '1' for line repetition)
--
--				Extended Run-Length Algorithm:
--					a. (8 downto 1): Repetitions is represented as 7 bits (0-->127).
--					b. (0 downto 0): '0' for pixel repetition (Same as Normal Run-Length)
--									 '1' for line repetition, according to generic parameter.
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		18.5.2011	Beeri Schreiber					Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity runlen_extractor is
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
end entity runlen_extractor;

architecture rtl_runlen_extractor of runlen_extractor is

------------------  Constants	------------------
constant zero_c 		: std_logic_vector (rep_size_g - 1 downto 0) := (others => '0'); --Zero
constant rep_kind_pos_c	: natural := width_g - rep_size_g;	--MSB bit of repetition kind

------------------  Types	 ---------------------
type exctractor_states is (
							rx_col_st,	--Requesting for color data / receiving color data
							rx_rep_st,	--Requesting for repetition data / receiving repetition data
							decomp_st,	--Decompress data, and transmit it
							flush_st	--Restart
						);

------------------  Signals  ---------------------
alias reps_in		: std_logic_vector (rep_size_g - 1 downto 0) is din (width_g - 1 downto rep_kind_pos_c);--Repetitions
signal pix_val		: std_logic_vector (width_g - 1 downto 0);			--Pixel value
signal reps_val		: std_logic_vector (rep_size_g - 1 downto 0);		--Repetitions left
signal rep_type		: std_logic;										--'0' for pixel repetition, '1' for line repetition
signal line_cnt		: natural range 0 to pixels_per_line_g - 1;			--Pixels per line counter
signal cur_st		: exctractor_states;								--FSM

------------------  Design ----------------------
begin
	
	--FSM process
	fsm_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then			--Reset
			cur_st		<=	rx_col_st;
			pix_val		<=	(others => '0');
			reps_val	<=	(others => '0');
			dout		<=	(others => '0');
			line_cnt	<=	0;
			req_data	<=	'0';
			rep_type	<= 	'0';
			dout_val	<=	'0';
		elsif rising_edge (clk) then
			case cur_st is
				when rx_col_st 	=>
					dout_val		<=	'0';
					if (flush = '1') then
						req_data	<=	'0';			--Request for data
						cur_st		<=	flush_st;
					elsif (fifo_empty = '0') then
						if (din_val = '1') then
							pix_val	<=	din;			--Latch pixel value
							req_data<=	'0';
							cur_st	<=	rx_rep_st;
						else
							pix_val	<=	pix_val;
							req_data<=	'1';
							cur_st	<=	cur_st;
						end if;
					else
						req_data <= '0';
						cur_st	<=	cur_st;
					end if;

				when rx_rep_st 	=>
					dout_val		<=	'0';
					if (flush = '1') then
						req_data	<= '0';
						cur_st		<=	flush_st;
					elsif (fifo_empty = '0') then
						if (din_val = '1') then
							req_data	<=	'0';			--Stop data requesting
							reps_val	<=	reps_in;		--Latch repetition value
							
							--Normal / Extended Run-Length Algorithm and Type of decompression
							if (rep_kind_pos_c = 0) 
							or (din(0) = '0') then	--Normal Run-Length algorithm
								rep_type	<=	'0';		
								line_cnt	<= 0;
							else
								rep_type	<=	'1';
								line_cnt	<= 	pixels_per_line_g - 1;	--Lines repetition
							end if;
							
							cur_st		<=	decomp_st;
						else	
							req_data	<=	'1';			--Request for data
							reps_val	<=	reps_val;
							rep_type	<=	rep_type;
							cur_st		<=	cur_st;
						end if;
					else
						req_data	<=	'0';			--Request for data
						cur_st		<=	cur_st;
					end if;

				when decomp_st 	=>
					if (flush = '1') then
						cur_st			<=	flush_st;
						dout_val		<=	'0';
						req_data		<=	'0';
					else
						if (fifo_full = '0') then		--FIFO is not full
							dout		<=	pix_val;
							dout_val	<=	'1';
							
							if (line_cnt = 0) then
								if (reps_val = zero_c) then		--End of repetitions
									if (fifo_empty = '0') then
										req_data	<= '1';
									else
										req_data	<= '0';
									end if;
									cur_st		<=	rx_col_st;
								else							--End of line, not repetition
									reps_val	<=	reps_val - '1';
									req_data	<= 	'0';
									cur_st		<= 	cur_st;
								end if;
								
								if (rep_type = '0') then
									line_cnt <= 0;
								else
									line_cnt <= pixels_per_line_g - 1; 
								end if;
							else								--Line repetition		
								req_data	<= 	'0';
								reps_val	<=	reps_val;		
								line_cnt	<=	line_cnt - 1;
								cur_st		<=	cur_st;
							end if;
						else
							req_data<= 	'0';
							dout_val<=	'0';
							cur_st	<=	cur_st;
						end if;
					end if;

				when flush_st =>
					req_data<= 	'0';
					dout_val<=	'0';
					cur_st	<= 	rx_col_st;
				
				when others		=>
					report "Time: " & time'image(now) & "Run-Length Decompressor : Unimplemented state has been detected" severity error;
					cur_st	<=	rx_col_st;
			end case;
		end if;
	end process fsm_proc;

end architecture rtl_runlen_extractor;		