------------------------------------------------------------------------------------------------
-- Model Name 	:	Wishbone Slave to Register
-- File Name	:	wbs_reg.vhd
-- Generated	:	10.5.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The coponent translates Wishbone Cycles to registers commands.
--				Data is send to ALL registers, which connected to the WBS.
--				In case no register is connected at a required address, then WBS_ACK_O will
--				be '1', although 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		10.5.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity wbs_reg is
	generic	(
			reset_polarity_g	:	std_logic	:= '0';							--'0' = reset active
			width_g				:	positive	:= 8;							--Width: Registers width
			addr_width_g		:	positive	:= 4							--2^4 = 16 register address is supported
			);
	port	(
			rst			:	in	std_logic;										--Reset
			
			--Wishbone Slave Signals
			clk_i		:	in std_logic;										--Wishbone Clock
			wbs_cyc_i	:	in std_logic;										--Cycle command from WBM
			wbs_stb_i	:	in std_logic;										--Strobe command from WBM
			wbs_adr_i	:	in std_logic_vector (addr_width_g - 1 downto 0);	--Register's address
			wbs_we_i	:	in std_logic;										--Write enable
			wbs_dat_i	:	in std_logic_vector (width_g - 1 downto 0);			--Data In
			wbs_dat_o	:	out std_logic_vector (width_g - 1 downto 0);		--Data Out
			wbs_ack_o	:	out std_logic;										--Input data has been successfuly acknowledged
			wbs_stall_o	:	out std_logic;										--Not ready to receive data
			
			--Signals to Registers
			din_ack		:	in std_logic;										--Write command has been received
			dout		:	in std_logic_vector (width_g - 1 downto 0);			--Output data
			dout_valid	:	in std_logic;										--Output data is valid
			addr		:	out std_logic_vector (addr_width_g - 1 downto 0);	--Address to register.
			din			:	out std_logic_vector (width_g - 1 downto 0);		--Input data
			rd_en		:	out std_logic;										--Request for data
			wr_en		:	out std_logic										--Write data
			);
end entity wbs_reg;

architecture rtl_wbs_reg of wbs_reg is

  ---------------------------------  Signals	----------------------------------
  signal cyc_active	:	std_logic;	--Whishbone cycle is active
  
  ---------------------------------  Implementation	------------------------------
begin
	
	--Cycle is in progress, and requesting for data (read / write)
	cyc_proc:
	cyc_active	<=	wbs_cyc_i and wbs_stb_i;
	
	--Address to register
	addr_proc:
	addr		<=	wbs_adr_i;
	
	--Input data to register
	din_proc:
	din			<=	wbs_dat_i;
	
	--Input data to register is valid
	wr_en_proc:
	wr_en	<=	cyc_active and wbs_we_i;
	
	--Request for data
	rd_en_proc:
	rd_en	<=	cyc_active and (not wbs_we_i);
	
	--Output data from register
	dout_proc:
	wbs_dat_o	<=	dout;
	
	--WBS_ACK_O
	wbs_ack_o_proc:
	wbs_ack_o	<=	dout_valid when ((wbs_cyc_i = '1') and (wbs_we_i = '0'))	--Output data is valid
					else din_ack when ((wbs_cyc_i = '1') and (wbs_we_i = '1'))	--Input data has been acknowledged
					else '0';
					
	--WBS_STALL_O
	wbs_stall_o_proc:
	wbs_stall_o	<= not wbs_cyc_i;
					
end architecture rtl_wbs_reg;