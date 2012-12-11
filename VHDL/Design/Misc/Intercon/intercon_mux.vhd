------------------------------------------------------------------------------------------------
-- Model Name 	:	Wishbone INTERCON
-- File Name	:	intercon_mux.vhd
-- Generated	:	21.1.2012
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Wishbone MUX INTERCON:
--				(*) Input: 	One Wishbone Master (WBM)
--				(*) Output:	Two WBM, which will be chosen according to the WBM_TGC_O
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		21.01.2012	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity intercon_mux is
		generic 	
			(
				adr_width_g			:	positive	:=	10;			--Address width
				blen_width_g		:	positive	:=	10;			--Maximum Burst length
				data_width_g		:	positive	:=	8			--Data Width
			);
		
		port
			(
				--'ic_' = INTERCON.
				--WBM/WBS ports should be connected to the same port.
				--i.e: wbm_dat_o of the WBM should be connected to inc(/outc)_wbm_dat_o of the INTERCON
				
				--Signals from INTERCON to the input WBM 
				inc_wbm_dat_i		:	out std_logic_vector (data_width_g - 1 downto 0);	--Data Out for reading registers (8 bits)
				inc_wbm_stall_i		:	out std_logic;					--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				inc_wbm_ack_i		:	out std_logic;					--Input data has been successfuly acknowledged
				inc_wbm_err_i		:	out std_logic;					--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				--Signals from Input WBM to INTERCON
				inc_wbm_adr_o		:	in std_logic_vector (adr_width_g - 1 downto 0);		--Address in internal RAM
				inc_wbm_tga_o		:	in std_logic_vector (blen_width_g - 1 downto 0);		--Burst Length
				inc_wbm_dat_o		:	in std_logic_vector (data_width_g - 1 downto 0);		--Data In (8 bits)
				inc_wbm_cyc_o		:	in std_logic;					--Cycle command from WBM
				inc_wbm_stb_o		:	in std_logic;					--Strobe command from WBM
				inc_wbm_we_o		:	in std_logic;					--Write Enable
				inc_wbm_tgc_o		:	in std_logic;					--Cycle tag: '0' = Write to components, '1' = Write to registers
				
				--Signals from INTERCON to output WBM (0)
				outc0_wbm_adr_o		:	out std_logic_vector (adr_width_g - 1 downto 0);		--Address in internal RAM
				outc0_wbm_tga_o		:	out std_logic_vector (blen_width_g - 1 downto 0);		--Burst Length
				outc0_wbm_dat_o		:	out std_logic_vector (data_width_g - 1 downto 0);		--Data In (8 bits)
				outc0_wbm_cyc_o		:	out std_logic;						--Cycle command from WBM
				outc0_wbm_stb_o		:	out std_logic;						--Strobe command from WBM
				outc0_wbm_we_o		:	out std_logic;						--Write Enable
				outc0_wbm_tgc_o		:	out std_logic;						--Cycle tag: '0' = Write to components, '1' = Write to registers

				--Signals from output WBM (0) to the INTERCON
				outc0_wbm_dat_i		:	in std_logic_vector (data_width_g - 1 downto 0);	--Data Out for reading registers (8 bits)
				outc0_wbm_stall_i	:	in std_logic;					--Slave is not ready to receive new data
				outc0_wbm_ack_i		:	in std_logic;					--Input data has been successfuly acknowledged
				outc0_wbm_err_i		:	in std_logic;					--Error

				--Signals from INTERCON to output WBM (1)
				outc1_wbm_adr_o		:	out std_logic_vector (adr_width_g - 1 downto 0);		--Address in internal RAM
				outc1_wbm_tga_o		:	out std_logic_vector (blen_width_g - 1 downto 0);		--Burst Length
				outc1_wbm_dat_o		:	out std_logic_vector (data_width_g - 1 downto 0);		--Data In (8 bits)
				outc1_wbm_cyc_o		:	out std_logic;						--Cycle command from WBM
				outc1_wbm_stb_o		:	out std_logic;						--Strobe command from WBM
				outc1_wbm_we_o		:	out std_logic;						--Write Enable
				outc1_wbm_tgc_o		:	out std_logic;						--Cycle tag: '0' = Write to components, '1' = Write to registers

				--Signals from output WBM (1) to the INTERCON
				outc1_wbm_dat_i		:	in std_logic_vector (data_width_g - 1 downto 0);	--Data Out for reading registers (8 bits)
				outc1_wbm_stall_i	:	in std_logic;					--Slave is not ready to receive new data
				outc1_wbm_ack_i		:	in std_logic;					--Input data has been successfuly acknowledged
				outc1_wbm_err_i		:	in std_logic					--Error

			);
end entity intercon_mux;

architecture intercon_mux_rtl of intercon_mux is

	---------------------------------		Constants		--------------------------------
	constant blen_zero	:	std_logic_vector (blen_width_g - 1 downto 0) := (others => '0');
	constant adr_zero	:	std_logic_vector (adr_width_g - 1 downto 0) := (others => '0');
	constant data_zero	:	std_logic_vector (data_width_g - 1 downto 0) := (others => '0');
	
	---------------------------------		Signals			--------------------------------

begin

inc_wbm_dat_i	<= outc0_wbm_dat_i		when (inc_wbm_tgc_o = '0')	else outc1_wbm_dat_i;			
inc_wbm_stall_i	<= outc0_wbm_stall_i	when (inc_wbm_tgc_o = '0')	else outc1_wbm_stall_i;	
inc_wbm_ack_i	<= outc0_wbm_ack_i		when (inc_wbm_tgc_o = '0')	else outc1_wbm_ack_i;		
inc_wbm_err_i	<= outc0_wbm_err_i		when (inc_wbm_tgc_o = '0')	else outc1_wbm_err_i;		

outc0_wbm_adr_o	<= inc_wbm_adr_o when (inc_wbm_tgc_o = '0') else adr_zero;
outc0_wbm_tga_o	<= inc_wbm_tga_o when (inc_wbm_tgc_o = '0') else blen_zero;	
outc0_wbm_dat_o	<= inc_wbm_dat_o when (inc_wbm_tgc_o = '0') else data_zero;	
outc0_wbm_cyc_o	<= inc_wbm_cyc_o when (inc_wbm_tgc_o = '0') else '0';	
outc0_wbm_stb_o	<= inc_wbm_stb_o when (inc_wbm_tgc_o = '0') else '0';	
outc0_wbm_we_o	<= inc_wbm_we_o	 when (inc_wbm_tgc_o = '0') else '0';
outc0_wbm_tgc_o	<= '0';

outc1_wbm_adr_o	<= inc_wbm_adr_o when (inc_wbm_tgc_o = '1') else adr_zero;
outc1_wbm_tga_o	<= inc_wbm_tga_o when (inc_wbm_tgc_o = '1') else blen_zero;	
outc1_wbm_dat_o	<= inc_wbm_dat_o when (inc_wbm_tgc_o = '1') else data_zero;	
outc1_wbm_cyc_o	<= inc_wbm_cyc_o when (inc_wbm_tgc_o = '1') else '0';	
outc1_wbm_stb_o	<= inc_wbm_stb_o when (inc_wbm_tgc_o = '1') else '0';	
outc1_wbm_we_o	<= inc_wbm_we_o	 when (inc_wbm_tgc_o = '1') else '0';
outc1_wbm_tgc_o	<= '1';

end architecture intercon_mux_rtl;