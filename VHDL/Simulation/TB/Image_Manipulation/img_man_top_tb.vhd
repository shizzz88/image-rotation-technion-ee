------------------------------------------------------------------------------------------------
-- Model Name 	:	addr_calc_tb
-- File Name	:	addr_calc_tb.vhd
-- Generated	:	08/05/2012
-- Author		:	Uri & Ran
-- Project		:	Image Rotation
------------------------------------------------------------------------------------------------
-- Description: test bench file for address calculator
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		08/05/2012	
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library work ;

entity img_man_top_tb is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				img_hor_pixels_g	:	positive					:= 128;	-- active pixels
				img_ver_pixels_g	:	positive					:= 96;	-- active lines
				trig_frac_size_g	: 	positive					:= 7
			);
end entity img_man_top_tb;

architecture sim_img_man_top_tb of img_man_top_tb is
component img_man_top is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				img_hor_pixels_g	:	positive					:= 128;	-- active pixels
				img_ver_pixels_g	:	positive					:= 96;	-- active lines
				trig_frac_size_g	: 	positive					:= 7
			);
	port	(
				--Clock and Reset
				system_clk				:	in std_logic;							--Clock
				system_rst				:	in std_logic;							--Reset
				req_trig				:	in std_logic;								-- Trigger for image manipulation to begin,

				-- Wishbone Slave (For Registers)
				wbs_adr_i			:	in std_logic_vector (9 downto 0);		--Address in internal RAM
				wbs_tga_i			:	in std_logic_vector (9 downto 0);		--Burst Length
				wbs_dat_i			:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
				wbs_cyc_i			:	in std_logic;							--Cycle command from WBM
				wbs_stb_i			:	in std_logic;							--Strobe command from WBM
				wbs_we_i			:	in std_logic;							--Write Enable
				wbs_tgc_i			:	in std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wbs_dat_o			:	out std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wbs_stall_o			:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wbs_ack_o			:	out std_logic;							--Input data has been successfuly acknowledged
				wbs_err_o			:	out std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
					-- Wishbone Master (mem_ctrl_wr)
				wr_wbm_adr_o		:	out std_logic_vector (9 downto 0);		--Address in internal RAM
				wr_wbm_tga_o		:	out std_logic_vector (9 downto 0);		--Burst Length
				wr_wbm_dat_o		:	out std_logic_vector (7 downto 0);		--Data In (8 bits)
				wr_wbm_cyc_o		:	out std_logic;							--Cycle command from WBM
				wr_wbm_stb_o		:	out std_logic;							--Strobe command from WBM
				wr_wbm_we_o			:	out std_logic;							--Write Enable
				wr_wbm_tgc_o		:	out std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wr_wbm_dat_i		:	in std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wr_wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wr_wbm_ack_i		:	in std_logic;							--Input data has been successfuly acknowledged
				wr_wbm_err_i		:	in std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

				-- Wishbone Master (mem_ctrl_rd)
				rd_wbm_adr_o 		:	out std_logic_vector (9 downto 0);		--Address in internal RAM
				rd_wbm_tga_o 		:   out std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				rd_wbm_cyc_o		:   out std_logic;							--Cycle command from WBM
				rd_wbm_tgc_o 		:   out std_logic;							--Cycle tag. '1' indicates start of transaction
				rd_wbm_stb_o		:   out std_logic;							--Strobe command from WBM
				rd_wbm_dat_i		:  	in std_logic_vector (7 downto 0);		--Data Out (8 bits)
				rd_wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				rd_wbm_ack_i		:   in std_logic;							--Input data has been successfuly acknowledged
				rd_wbm_err_i		:   in std_logic							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
			);
end component img_man_top;

--###############################################################################
-----------------------------	Signals		-----------------------------------
--Clock and Reset
signal tb_system_clk			:	std_logic := '0';
signal tb_system_rst			:	std_logic;
signal trigger				:	std_logic;

-- Wishbone Slave (For Registers)
signal tb_wbs_adr_i		:	std_logic_vector (9 downto 0);		--Address in internal RAM
signal tb_wbs_tga_i		:	std_logic_vector (9 downto 0);		--Burst Length
signal tb_wbs_dat_i		:	std_logic_vector (7 downto 0);		--Data In (8 bits)
signal tb_wbs_cyc_i		:	std_logic;							--Cycle command from WBM
signal tb_wbs_stb_i		:	std_logic;							--Strobe command from WBM
signal tb_wbs_we_i			:	std_logic;							--Write Enable
signal tb_wbs_tgc_i		:	std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
signal tb_wbs_dat_o		:	 std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
signal tb_wbs_stall_o		:	 std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal tb_wbs_ack_o		:	 std_logic;							--Input data has been successfuly acknowledged
signal tb_wbs_err_o		:	 std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

	-- Wishbone Master (mem_ctrl_wr)
signal tb_wr_wbm_adr_o		:	 std_logic_vector (9 downto 0);		--Address in internal RAM
signal tb_wr_wbm_tga_o		:	 std_logic_vector (9 downto 0);		--Burst Length
signal tb_wr_wbm_dat_o		:	 std_logic_vector (7 downto 0);		--Data In (8 bits)
signal tb_wr_wbm_cyc_o		:	 std_logic;							--Cycle command from WBM
signal tb_wr_wbm_stb_o		:	 std_logic;							--Strobe command from WBM
signal tb_wr_wbm_we_o		:	 std_logic;							--Write Enable
signal tb_wr_wbm_tgc_o		:	 std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
signal tb_wr_wbm_dat_i		:	std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
signal tb_wr_wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal tb_wr_wbm_ack_i		:	std_logic;							--Input data has been successfuly acknowledged
signal tb_wr_wbm_err_i		:	std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

-- Wishbone Master (mem_ctrl_rd)
signal tb_rd_wbm_adr_o 	:	 std_logic_vector (9 downto 0);		--Address in internal RAM
signal tb_rd_wbm_tga_o 	:    std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
signal tb_rd_wbm_cyc_o		:    std_logic;							--Cycle command from WBM
signal tb_rd_wbm_tgc_o 	:    std_logic;							--Cycle tag. '1' indicates start of transaction
signal tb_rd_wbm_stb_o		:    std_logic;							--Strobe command from WBM
signal tb_rd_wbm_dat_i		:  	std_logic_vector (7 downto 0);		--Data Out (8 bits)
signal tb_rd_wbm_stall_i	:	std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
signal tb_rd_wbm_ack_i		:   std_logic;							--Input data has been successfuly acknowledged
signal tb_rd_wbm_err_i		:   std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)


--####################################################################################
---------------------------		process + inst	-----------------------------------------
begin

clk_100_proc:
tb_system_clk	<=	not tb_system_clk after 5 ns;



rst_100_proc:
tb_system_rst	<=	'0', '1' after 100 ns;

trigger_proc:
trigger <=	'0', '1' after 100 ns, '0' after 110 ns;

img_man_top_inst : img_man_top 
	generic map(
				reset_polarity_g 	=> '0',
				img_hor_pixels_g	=> 128,	-- active pixels
				img_ver_pixels_g	=> 96,	-- active lines
				trig_frac_size_g	=> 7
	)
	port map(
			--Clock and Reset
			system_clk			=>	tb_system_clk,
			system_rst			=>	tb_system_rst,
	        req_trig			=>  trigger,
			
			-- Wishbone Slave (For R_egisters)
			wbs_adr_i			=>	tb_wbs_adr_i,	
			wbs_tga_i			=>  tb_wbs_tga_i,	
			wbs_dat_i			=>  tb_wbs_dat_i,	
			wbs_cyc_i			=>  tb_wbs_cyc_i,	
			wbs_stb_i			=>  tb_wbs_stb_i,	
			wbs_we_i			=>  tb_wbs_we_i,	
			wbs_tgc_i			=>  tb_wbs_tgc_i,	
			wbs_dat_o			=>  tb_wbs_dat_o,	
			wbs_stall_o			=>  tb_wbs_stall_o,	
			wbs_ack_o			=>  tb_wbs_ack_o,	
			wbs_err_o			=>  tb_wbs_err_o,	
			                        
				-- Wishbone Master (mem_ctrl_wr)
			wr_wbm_adr_o		=>	tb_wr_wbm_adr_o,	
			wr_wbm_tga_o		=>  tb_wr_wbm_tga_o,	
			wr_wbm_dat_o		=>  tb_wr_wbm_dat_o,	
			wr_wbm_cyc_o		=>  tb_wr_wbm_cyc_o,	
			wr_wbm_stb_o		=>  tb_wr_wbm_stb_o,	
			wr_wbm_we_o			=>  tb_wr_wbm_we_o	,	
			wr_wbm_tgc_o		=>  tb_wr_wbm_tgc_o,	
			wr_wbm_dat_i		=>  tb_wr_wbm_dat_i,	
			wr_wbm_stall_i		=>  tb_wr_wbm_stall_i,	
			wr_wbm_ack_i		=>  tb_wr_wbm_ack_i,	
			wr_wbm_err_i		=>  tb_wr_wbm_err_i,	
	                                
			-- Wishbone Master (mem_ctrl_rd)
			rd_wbm_adr_o 		=>	tb_rd_wbm_adr_o ,	
			rd_wbm_tga_o 		=>  tb_rd_wbm_tga_o ,	
			rd_wbm_cyc_o		=>  tb_rd_wbm_cyc_o	,
			rd_wbm_tgc_o 		=>  tb_rd_wbm_tgc_o 	,
			rd_wbm_stb_o		=>  tb_rd_wbm_stb_o	,
			rd_wbm_dat_i		=>  tb_rd_wbm_dat_i	,
			rd_wbm_stall_i		=>  tb_rd_wbm_stall_i	,
			rd_wbm_ack_i		=>  tb_rd_wbm_ack_i	,
			rd_wbm_err_i		=>  tb_rd_wbm_err_i	
			
	);
		
end architecture sim_img_man_top_tb;