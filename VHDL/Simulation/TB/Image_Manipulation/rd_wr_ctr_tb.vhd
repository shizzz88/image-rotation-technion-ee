------------------------------------------------------------------------------------------------
-- Model Name 	:	read/write controller Test Bench
-- File Name	:	img_man_manager_tb.vhd
-- Generated	:	21.08.2012
-- Author		:	Uri Tsipin Ran Mizrahi
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   TB of read/write controller Block
--					
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		21.12.2012	Uri & Ran					creation
--					
------------------------------------------------------------------
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rd_wr_ctr_tb is
	generic
		(	---DELETE
			pipeline_depth			:	positive 	:= 4;
			trig_frac_size			:	positive 	:= 7				-- number of digits after dot = resolution of fracture (binary)
		);
end entity rd_wr_ctr_tb;


architecture sim_rd_wr_ctr of rd_wr_ctr_tb is
----------------------------------components-------------------------------
component rd_wr_ctr is
  generic
	   (
		reset_polarity_g	:	std_logic				:= '0'	--When rst = reset_polarity_g, system is in RESET mode
		);
  port (
		-- Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		
		-- Wishbone Slave signals from Image Manipulation Block
		-- Wishbone Slave signals to Read/Write interface
		wbs_adr_i	:	in std_logic_vector (22 downto 0);		--Address (Bank, Row, Col)
		wbs_dat_i	:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbs_we_i	:	in std_logic;							--Write Enable
		wbs_tga_i	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbs_cyc_i	:	in std_logic;							--Cycle Command from interface
		wbs_stb_i	:	in std_logic;							--Strobe Command from interface
		wbs_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data
		wbs_err_o	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbs_ack_o	:	out std_logic;							--When Read Burst: DATA bus must be valid in this cycle
																--When Write Burst: Data has been read from SDRAM and is valid		
	
	-- Wishbone Master signals to Arbiter/SDRAM
		wbm_adr_o	:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbm_dat_o	:	out std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbm_we_o	:	out std_logic;							--Write Enable
		wbm_tga_o	:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_cyc_o	:	out std_logic;							--Cycle Command from interface
		wbm_stb_o	:	out std_logic;							--Strobe Command from interface
		wbm_dat_i	:	in  std_logic_vector (15 downto 0);		--Data for write (16 bits)
		wbm_stall_i	:	in  std_logic;							--Slave is not ready to receive new data
		wbm_err_i	:	in  std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbm_ack_i	:	in  std_logic;							--When Write Burst: DATA bus must be valid in this cycle
																--When Read Burst: Data has been read from SDRAM and is valid

		-- Arbiter signals
		arbiter_gnt	:	in std_logic;							--Grant control on SDRAM from Arbiter
		arbiter_req	:	out std_logic_vector (1 downto 0)		--Request for control on SDRAM from Arbiter

		); 
end component rd_wr_ctr;
----------------------------------signals----------------------------------------
--Clock and Reset
signal system_clk			:	std_logic := '0';
signal system_rst			:	std_logic;
signal write_en	:	std_logic;
signal cycle_in	:	std_logic;
signal strobe_in:	std_logic;
signal grant_in:	std_logic;
				
begin
---------------------------		process + inst	-----------------------------------------
clk_133_proc:
system_clk	<=	not system_clk after 3.75 ns;

rst_133_proc:
system_rst	<=	'0', '1' after 97.5 ns;


rd_wr_inst: rd_wr_ctr
	generic map
		   (
			reset_polarity_g	=> '0'	--When rst = reset_polarity_g, system is in RESET mode
			)
	 port map (
			-- Clocks and Reset 
			clk_i		=>system_clk,		--Wishbone input clock
			rst			=>system_rst,		--Reset
			wbs_adr_i	=> "00000000000000000000100",	
			wbs_dat_i	=>(others => '0'),	
			wbs_we_i	=>write_en,			
			wbs_tga_i	=>(others => '0'),
			wbs_cyc_i	=>cycle_in,						
			wbs_stb_i	=>strobe_in,
			wbm_dat_i	=>  (others => '0'),
            wbm_stall_i	=>  '0',						
            wbm_err_i	=>  '0',						
			wbm_ack_i	=>  '0',
			arbiter_gnt => grant_in			
			
			
			); 
end architecture sim_rd_wr_ctr;