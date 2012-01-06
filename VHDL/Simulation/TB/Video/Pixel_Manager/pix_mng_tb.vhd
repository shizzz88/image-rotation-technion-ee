------------------------------------------------------------------------------------------------
-- Model Name 	:	Pixel Manager TB
-- File Name	:	pix_mng_tb.vhd
-- Generated	:	15.5.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: TB for pixel_manager
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		22.5.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;
use ieee.math_real.all;

use std.textio.all;

entity pix_mng_tb is
   generic (
			reset_polarity_g	:	std_logic	:= '0';		--Reset active low
			vsync_polarity_g	:	std_logic	:= '1';		--VSync Polarity
			screen_hor_pixels_g	:	positive	:= 800;		--800X600
			hor_pixels_g		:	positive	:= 640;		--640X480
			ver_lines_g			:	positive	:= 480;		--640X480
			req_lines_g			:	positive	:= 3;		--Number of lines to request from image transmitter, to hold in its FIFO
			rep_size_g			:	positive	:= 8		--2^7=128 => Maximum of 128 repetitions for pixel / line
           );
end pix_mng_tb;

architecture sim_pix_mng_tb of pix_mng_tb is

------------------  Components ----------------------
component pixel_mng 
   generic (
			reset_polarity_g	:	std_logic	:= '0';		--Reset active low
			vsync_polarity_g	:	std_logic	:= '1';		--VSync Polarity
			hor_pixels_g		:	positive	:= 640;		--640X480
			ver_lines_g			:	positive	:= 480;		--640X480
			req_lines_g			:	positive	:= 3;		--Number of lines to request from image transmitter, to hold in its FIFO
			rep_size_g			:	positive	:= 7		--2^7=128 => Maximum of 128 repetitions for pixel / line
           );
   port
   	   (
   	    clk_i			:	in std_logic; 						--Wishbone Clock
   	    rst				:	in std_logic;						--Reset
		
		-- Wishbown Signals
		wbm_ack_i		:	in std_logic;						--Wishbone Acknowledge
		wbm_err_i		:	in std_logic;						--Wishbone Error
		wbm_stall_i		:	in std_logic;						--Wishbone Stall
		wbm_dat_i		:	in std_logic_vector (7 downto 0);	--Wishbone Input Data
		wbm_cyc_o		:	out std_logic;						--Wishbone Cycle
		wbm_stb_o		:	out std_logic;						--Wishbone Strobe
		wbm_adr_o		:	out std_logic_vector (9 downto 0);	--Wishbone Address
		wbm_tga_o		:	out std_logic_vector (9 downto 0);	--Burst Length
		
		--Signals to FIFO
		fifo_wr_en		:	out std_logic;						--Write Enable to FIFO
		fifo_flush		:	out std_logic;						--Flush FIFO
		
		--Signals from VESA Generator (Clock Domain: 40MHz)
		pixels_req		:	in std_logic_vector(integer(ceil(log(real(screen_hor_pixels_g*req_lines_g)) / log(2.0))) - 1 downto 0); --Request for PIXELS*LINES pixels from FIFO
		req_ln_trig		:	in std_logic;						--Trigger to image transmitter, to load its FIFO with new data
		vsync			:	in std_logic
		
   	   );
end component pixel_mng;

------------------  SIGNALS AND VARIABLES ------
constant pix_w_c	:	natural := integer(ceil(log(real(screen_hor_pixels_g*req_lines_g)) / log(2.0)));
signal clk			:	std_logic := '0';
signal clk_40		:	std_logic := '0';
signal rst			:	std_logic;

signal wbm_ack_i	:	std_logic;							
signal wbm_err_i	:	std_logic;						
signal wbm_stall_i	:	std_logic;						
signal wbm_dat_i	:	std_logic_vector (7 downto 0);
signal wbm_cyc_o	:	std_logic;						
signal wbm_stb_o	:	std_logic;						
signal wbm_adr_o	:	std_logic_vector (9 downto 0);
signal wbm_tga_o	:	std_logic_vector (9 downto 0);
signal fifo_wr_en	:	std_logic;
signal fifo_flush	:	std_logic;
signal pixels_req	:	std_logic_vector(pix_w_c - 1 downto 0); 
signal req_ln_trig	:   std_logic;
signal vsync		:	std_logic;


------------------  Implementation ------
begin
   pix_mng_inst : pixel_mng generic map (
					reset_polarity_g	=>	reset_polarity_g,
					vsync_polarity_g	=>	vsync_polarity_g,
					hor_pixels_g		=>  hor_pixels_g,	
					ver_lines_g			=>  ver_lines_g,		
					req_lines_g			=>  req_lines_g,		
					rep_size_g			=>  rep_size_g		
					)
				port map (
					clk_i			=>	clk,			
					rst				=>	rst,
					wbm_ack_i		=>	wbm_ack_i	,
					wbm_err_i		=>	wbm_err_i	,
					wbm_stall_i		=>	wbm_stall_i	,
					wbm_dat_i		=>	wbm_dat_i	,
					wbm_cyc_o		=>	wbm_cyc_o	,
					wbm_stb_o		=>	wbm_stb_o	,
					wbm_adr_o		=>	wbm_adr_o	,
					wbm_tga_o		=>	wbm_tga_o	,
					fifo_wr_en		=>	fifo_wr_en	,
					fifo_flush		=>	fifo_flush	,
					pixels_req		=>	pixels_req	,
					req_ln_trig		=>	req_ln_trig	,
					vsync			=>	vsync		
				);
		 
	clk_proc:
	clk <= not clk after 3.75 ns;
	
	clk_40_proc:
	clk_40 <= not clk_40 after 12.5 ns;
	
	rst_proc:
	rst	<=	'0', '1' after 30 ns;
	
	--VESA Process
	vesa_proc: process
	begin
		req_ln_trig		<=	'0';
		pixels_req		<=	(others => '0');
		wait for 500 ns;
		wait until rising_edge(clk_40);
		pixels_req		<=	conv_std_logic_vector (640*3, pix_w_c);
		req_ln_trig		<=	'1';
		wait until rising_edge(clk_40);
		req_ln_trig		<=	'0';
		wait for 1 us;
		wait for 100 ns;
		wait until rising_edge(clk_40);
		wait for 1 us;
	end process vesa_proc;
	
	vsync_proc: process
	begin
		vsync			<=	not vsync_polarity_g;
		wait for 1.6 ms;
		vsync			<=	vsync_polarity_g;
		for idx in 1 to 80 loop
			wait until rising_edge(clk_40);
		end loop;
	end process vsync_proc;

	
	--Wishbone Process
	wbm_proc: process
	variable tx_col	:	std_logic_vector (7 downto 0);	--Color
	variable tx_rep	:	std_logic_vector (7 downto 0);	--Repetition
	begin
		tx_col := x"10";
		tx_rep := x"03";
		wbm_stall_i	<=	'1';
		wbm_ack_i	<=	'0';
		wbm_err_i	<= 	'0';
		wait until (wbm_cyc_o = '1') and (wbm_stb_o = '1');
		while (wbm_cyc_o = '1') and (wbm_stb_o = '1') loop
			if (wbm_stall_i	= '1') then
				wbm_stall_i	<=	'0';	--Negate STALL
				wbm_dat_i	<=	tx_col;
			end if;
			wait until rising_edge(clk);
			if (wbm_stb_o = '1') then
				wbm_ack_i	<=	'1';	--Data valid
				wbm_dat_i	<=	tx_rep;
				wait until rising_edge(clk);
				wbm_dat_i	<=	tx_col;
				tx_col 		:=	tx_col + '1';
			else
				wbm_ack_i	<= '0';
			end if;
		end loop;
	end process wbm_proc;
	
end sim_pix_mng_tb;		