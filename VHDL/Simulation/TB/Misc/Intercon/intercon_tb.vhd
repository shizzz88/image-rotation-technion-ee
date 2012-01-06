------------------------------------------------------------------------------------------------
-- Model Name 	:	Wishbone INTERCON TB
-- File Name	:	intercon_tb.vhd
-- Generated	:	24.10.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Generic Wishbone INTERCON TB. 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		24.10.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity intercon_tb is
		generic 	
			(
				reset_polarity_g	:	std_logic 	:=	'0';		--Reset polarity: '0' is active low, '1' is active high
				num_of_wbm_g		:	positive	:=	1;			--Number of Wishbone Masters
				num_of_wbs_g		:	positive	:=	3;			--Number of Wishbone Slaves
				adr_width_g			:	positive	:=	10;			--Address width
				blen_width_g		:	positive	:=	10;			--Maximum Burst length
				data_width_g		:	positive	:=	8			--Data Width
			);
end entity intercon_tb;

architecture sim of intercon_tb is

component intercon 
		generic 	
			(
				reset_polarity_g	:	std_logic 	:=	'0';		--Reset polarity: '0' is active low, '1' is active high
				num_of_wbm_g		:	positive	:=	1;			--Number of Wishbone Masters
				num_of_wbs_g		:	positive	:=	3;			--Number of Wishbone Slaves
				adr_width_g			:	positive	:=	10;			--Address width
				blen_width_g		:	positive	:=	10;			--Maximum Burst length
				data_width_g		:	positive	:=	8			--Data Width
			);
		
		port
			(
				--Clock and Reset
				clk_i				:	in std_logic;
				rst					:	in std_logic;
				
				--'ic_' = INTERCON.
				--WBM/WBS ports should be connected to the same port.
				--i.e: wbm_dat_o of the WBM should be connected to ic_wbm_dat_o of the INTERCON
				
				--Signals from INTERCON to WBS
				ic_wbs_adr_i		:	out std_logic_vector (num_of_wbs_g * adr_width_g - 1 downto 0);		--Address in internal RAM
				ic_wbs_tga_i		:	out std_logic_vector (num_of_wbs_g * blen_width_g - 1 downto 0);	--Burst Length
				ic_wbs_dat_i		:	out std_logic_vector (num_of_wbs_g * data_width_g - 1 downto 0);	--Data In (8 bits)
				ic_wbs_cyc_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Cycle command from WBM
				ic_wbs_stb_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Strobe command from WBM
				ic_wbs_we_i			:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Write Enable
				ic_wbs_tgc_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Cycle tag: '0' = Write to components, '1' = Write to registers
				
				--Signals from INTERCON to WBM 
				ic_wbm_dat_i		:	out std_logic_vector (num_of_wbm_g * data_width_g - 1 downto 0);	--Data Out for reading registers (8 bits)
				ic_wbm_stall_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				ic_wbm_ack_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Input data has been successfuly acknowledged
				ic_wbm_err_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				--Signals from WBM to INTERCON
				ic_wbm_adr_o		:	in std_logic_vector (num_of_wbm_g * adr_width_g - 1 downto 0);		--Address in internal RAM
				ic_wbm_tga_o		:	in std_logic_vector (num_of_wbm_g * blen_width_g - 1 downto 0);		--Burst Length
				ic_wbm_dat_o		:	in std_logic_vector (num_of_wbm_g * data_width_g - 1 downto 0);		--Data In (8 bits)
				ic_wbm_cyc_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Cycle command from WBM
				ic_wbm_stb_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Strobe command from WBM
				ic_wbm_we_o			:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Write Enable
				ic_wbm_tgc_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Cycle tag: '0' = Write to components, '1' = Write to registers
				
				--Signals from WBS to INTERCON
				ic_wbs_dat_o		:	in std_logic_vector (num_of_wbs_g * data_width_g - 1 downto 0);		--Data Out for reading registers (8 bits)
				ic_wbs_stall_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0);					--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				ic_wbs_ack_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0);					--Input data has been successfuly acknowledged
				ic_wbs_err_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0)						--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
			);
end component intercon;

signal clk_i			:	std_logic := '0';
signal rst				:	std_logic;
--Signals from INTERCON to WBS
signal ic_wbs_adr_i		:	std_logic_vector (num_of_wbs_g * adr_width_g - 1 downto 0);	
signal ic_wbs_tga_i		:	std_logic_vector (num_of_wbs_g * blen_width_g - 1 downto 0);
signal ic_wbs_dat_i		:	std_logic_vector (num_of_wbs_g * data_width_g - 1 downto 0);
signal ic_wbs_cyc_i		:	std_logic_vector (num_of_wbs_g - 1 downto 0);				
signal ic_wbs_stb_i		:	std_logic_vector (num_of_wbs_g - 1 downto 0);				
signal ic_wbs_we_i		:	std_logic_vector (num_of_wbs_g - 1 downto 0);				
signal ic_wbs_tgc_i		:	std_logic_vector (num_of_wbs_g - 1 downto 0);				
--Signals from INTERCON to WBM 
signal ic_wbm_dat_i		:	std_logic_vector (num_of_wbm_g * data_width_g - 1 downto 0);
signal ic_wbm_stall_i	:	std_logic_vector (num_of_wbm_g - 1 downto 0);				
signal ic_wbm_ack_i		:	std_logic_vector (num_of_wbm_g - 1 downto 0);				
signal ic_wbm_err_i		:	std_logic_vector (num_of_wbm_g - 1 downto 0);				
--Signals from WBM to INTERCON
signal ic_wbm_adr_o		:	std_logic_vector (num_of_wbm_g * adr_width_g - 1 downto 0);	
signal ic_wbm_tga_o		:	std_logic_vector (num_of_wbm_g * blen_width_g - 1 downto 0);	
signal ic_wbm_dat_o		:	std_logic_vector (num_of_wbm_g * data_width_g - 1 downto 0);	
signal ic_wbm_cyc_o		:	std_logic_vector (num_of_wbm_g - 1 downto 0);				
signal ic_wbm_stb_o		:	std_logic_vector (num_of_wbm_g - 1 downto 0);				
signal ic_wbm_we_o		:	std_logic_vector (num_of_wbm_g - 1 downto 0);				
signal ic_wbm_tgc_o		:	std_logic_vector (num_of_wbm_g - 1 downto 0);				
--Signals from WBS to INTERCON
signal ic_wbs_dat_o		:	std_logic_vector (num_of_wbs_g * data_width_g - 1 downto 0);	
signal ic_wbs_stall_o	:	std_logic_vector (num_of_wbs_g - 1 downto 0);				
signal ic_wbs_ack_o		:	std_logic_vector (num_of_wbs_g - 1 downto 0);				
signal ic_wbs_err_o		:	std_logic_vector (num_of_wbs_g - 1 downto 0);					

begin
clk_proc: 
clk_i	<=	not clk_i after 5 ns;

rst_proc: 
rst <= reset_polarity_g, not reset_polarity_g after 30 ns;

wbm_drv_proc: process
begin
	--Initilize default values:
	--Address from WBM to INTERCON
	ic_wbm_adr_o (3 * adr_width_g - 1 downto 2 * adr_width_g)	<=	conv_std_logic_vector (2, adr_width_g);
	ic_wbm_adr_o (2 * adr_width_g - 1 downto 1 * adr_width_g)	<=	conv_std_logic_vector (1, adr_width_g);
	ic_wbm_adr_o (1 * adr_width_g - 1 downto 0 * adr_width_g)	<=	conv_std_logic_vector (0, adr_width_g);
	
	--Burst Length from WBM to INTERCON
	ic_wbm_tga_o (3 * blen_width_g - 1 downto 2 * blen_width_g)	<=	conv_std_logic_vector (2, blen_width_g);
	ic_wbm_tga_o (2 * blen_width_g - 1 downto 1 * blen_width_g)	<=	conv_std_logic_vector (1, blen_width_g);
	ic_wbm_tga_o (1 * blen_width_g - 1 downto 0 * blen_width_g)	<=	conv_std_logic_vector (0, blen_width_g);
	
	--DATA from WBM to INTERCON
	ic_wbm_dat_o (3 * data_width_g - 1 downto 2 * data_width_g)	<=	conv_std_logic_vector (2, data_width_g);
	ic_wbm_dat_o (2 * data_width_g - 1 downto 1 * data_width_g)	<=	conv_std_logic_vector (1, data_width_g);
	ic_wbm_dat_o (1 * data_width_g - 1 downto 0 * data_width_g)	<=	conv_std_logic_vector (0, data_width_g);
	
	
end process wbm_drv_proc;

intercon_inst : intercon generic map
							(
							reset_polarity_g	=>	reset_polarity_g ,
                             num_of_wbm_g	 	=>	num_of_wbm_g	 ,
                             num_of_wbs_g	 	=>	num_of_wbs_g	 ,
                             adr_width_g		=>	adr_width_g		,	
                             blen_width_g	 	=>	blen_width_g	 ,
                             data_width_g	 	=>	data_width_g	 
							 )
						port map (
							clk_i			=>	clk_i			,
						    rst				=>	rst				,
						    ic_wbs_adr_i	=>	ic_wbs_adr_i	,	
						    ic_wbs_tga_i	=>	ic_wbs_tga_i	,	
						    ic_wbs_dat_i	=>	ic_wbs_dat_i	,	
						    ic_wbs_cyc_i	=>	ic_wbs_cyc_i	,	
						    ic_wbs_stb_i	=>	ic_wbs_stb_i	,	
						    ic_wbs_we_i		=>	ic_wbs_we_i		,
						    ic_wbs_tgc_i	=>	ic_wbs_tgc_i	,	
						    ic_wbm_dat_i	=>	ic_wbm_dat_i	,	
						    ic_wbm_stall_i	=>	ic_wbm_stall_i	,
						    ic_wbm_ack_i	=>	ic_wbm_ack_i	,	
						    ic_wbm_err_i	=>	ic_wbm_err_i	,	
						    ic_wbm_adr_o	=>	ic_wbm_adr_o	,	
						    ic_wbm_tga_o	=>	ic_wbm_tga_o	,	
						    ic_wbm_dat_o	=>	ic_wbm_dat_o	,	
						    ic_wbm_cyc_o	=>	ic_wbm_cyc_o	,	
						    ic_wbm_stb_o	=>	ic_wbm_stb_o	,	
						    ic_wbm_we_o		=>	ic_wbm_we_o		,
                            ic_wbm_tgc_o	=>	ic_wbm_tgc_o	,	
                            ic_wbs_dat_o	=>	ic_wbs_dat_o	,	
                            ic_wbs_stall_o	=>	ic_wbs_stall_o	,
                            ic_wbs_ack_o	=>	ic_wbs_ack_o	,	
                            ic_wbs_err_o	=>	ic_wbs_err_o);		


end architecture sim;
