------------------------------------------------------------------------------------------------
-- Model Name 	:	IS42S16400 SDRAM Test Bench
-- File Name	:	sdram_tb.vhd
-- Generated	:	September 2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This model is a test bench for the IS42S16400 SDRAM Controller and Read/Write
--				test.
--
-- Instructions:
--				(1) Connect 133.33MHz to sdram_rw.vhd
--				(2) Connect 133.33MHz to sdram_controller.vhd
--				(3) Connect 133.33MHz to the SDRAM itslef
------------------------------------------------------------------------------------------------
-- Changes:
--			Number		Date		Name				Description
--			(1)			09/2010		Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sdram_tb is
	generic (reset_polarity_g : std_logic := '0');
end entity sdram_tb;

architecture sim_sdram_tb of sdram_tb is

component sdram_controller 
  generic
	   (
		reset_polarity_g	:	std_logic	:= '0' --When rst = reset_polarity_g, system is in RESET mode
		);
  port (
		--Clocks and Reset 
		clk_i		:	in std_logic;	--Wishbone input clock
		rst			:	in std_logic;	--Reset
		pll_locked	:	in std_logic;	--PLL Locked indication, for CKE (Clock Enable) signal to SDRAM
		
		--SDRAM Signals
		dram_addr	:	out std_logic_vector (11 downto 0);		--Address (12 bit)
		dram_bank	:	out std_logic_vector (1 downto 0);		--Bank
		dram_cas_n	:	out std_logic;							--Column Address is being transmitted
		dram_cke	:	out std_logic;							--Clock Enable
		dram_cs_n	:	out std_logic;							--Chip Select (Here - Mask commands)
		dram_dq		:	inout std_logic_vector (15 downto 0);	--Data in / Data out
		dram_ldqm	:	out std_logic;							--Byte masking
		dram_udqm	:	out std_logic;							--Byte masking
		dram_ras_n	:	out std_logic;							--Row Address is being transmitted
		dram_we_n	:	out std_logic;							--Write Enable
   
		-- Wishbone Slave signals to Read/Write interface
		wbs_adr_i	:	in std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
		wbs_dat_i	:	in std_logic_vector (15 downto 0);		--Data In (16 bits)
		wbs_we_i	:	in std_logic;							--Write Enable
		wbs_tga_i	:	in std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbs_cyc_i	:	in std_logic;							--Cycle Command from interface
		wbs_stb_i	:	in std_logic;							--Strobe Command from interface
		wbs_dat_o	:	out std_logic_vector (15 downto 0);		--Data Out (16 bits)
		wbs_stall_o	:	out std_logic;							--Slave is not ready to receive new data
		wbs_err_o	:	out std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
		wbs_ack_o	:	out std_logic							--When Read Burst: DATA bus must be valid in this cycle
   );
end component;

component sdram_rw 
  generic(
		reset_polarity :	std_logic := '0' --When rst = reset_polarity, system at RESET
	);
  port(
		--Clock and Reset
		clk_i		:	in std_logic;	--WISHBONE Clock
		rst			:	in std_logic;	--RESET
		
		--Signals to SDRAM controller
		wbm_adr_o	:	out std_logic_vector (21 downto 0);	--Address to read from / write to
		wbm_dat_i	:	in std_logic_vector (15 downto 0);	--Data out (to SDRAM)
		wbm_dat_o	:	out std_logic_vector (15 downto 0);	--Data in (from SDRAM)
		wbm_we_i	:	out std_logic;	--'1' - Write, '0' - Read
		wbm_tga_o	:	out std_logic_vector (7 downto 0);	--Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
		wbm_cyc_o	:	out std_logic;	--Transmit command to SDRAM controller
		wbm_stb_o	:	out std_logic;	--Transmit command to SDRAM controller
		wbm_stall_i	:	in std_logic;	--When '1', write data to SDRAM
		wbm_ack_i	:	in std_logic;	--when '1', data is ready to be read from SDRAM
		
		--Debug and test signals
		green_led	:	out std_logic;	--Test passed
		red_led		:	out std_logic;	--Test fail
		writing		:	out std_logic	--'1' when writing, '0' when reading
   );
end component;

component sdram_model
	GENERIC (
		addr_bits : INTEGER := 12;
		data_bits : INTEGER := 16 ;
		col_bits  : INTEGER := 8
		);
	PORT (
		Dq		: inout std_logic_vector (15 downto 0) := (others => 'Z');
		Addr    : in    std_logic_vector (11 downto 0) ;-- := (others => '0');
		Ba      : in    std_logic_vector(1 downto 0);-- := "00";
		Clk     : in    std_logic ;--:= '0';
		Cke     : in    std_logic ;--:= '0';
		Cs      : in    std_logic ;--:= '1';
		Ras     : in    std_logic ;--:= '0';
		Cas     : in    std_logic ;--:= '0';
		We      : in    std_logic ;--:= '0';
		Dqm     : in    std_logic_vector(1 downto 0)-- := (others => 'Z')
		);
	
END component;

--Clock and Reset
signal clk_133		:	std_logic := '0'; --133 MHz
signal rst			:	std_logic := '0'; --Reset

--SDRAM Signals
signal dram_addr	:	std_logic_vector (11 downto 0);
signal dram_bank	:	std_logic_vector (1 downto 0);
signal dram_cas_n	:	std_logic;
signal dram_cke		:	std_logic;
signal dram_cs_n	:	std_logic;
signal dram_dq		:	std_logic_vector (15 downto 0);
signal dram_ldqm	:	std_logic;
signal dram_udqm	:	std_logic;
signal dram_ras_n	:	std_logic;
signal dram_we_n	:	std_logic;

--Read / Write signals to SDRAM
signal addr			: 	std_logic_vector (21 downto 0);
signal dat_tb2ram	:	std_logic_vector (15 downto 0);
signal dat_ram2tb	: 	std_logic_vector (15 downto 0);
signal we_i			: 	std_logic;
signal stall_i		: 	std_logic;
signal cyc_o		:	std_logic;
signal err_o		:	std_logic;
signal ack_i		:	std_logic;
signal stb_o		:	std_logic;
signal burst_len	:	std_logic_vector (7 downto 0);

--LEDs
signal green_led	: 	std_logic;
signal red_led		: 	std_logic;
signal writing		: 	std_logic;

begin
	--Clock process
	clk_proc:
	clk_133 <= not clk_133 after 3.75 ns;
	
	rst_proc:
	rst 	<= reset_polarity_g, not reset_polarity_g after 400 ns;
	
	--Componenets:
	sdr_ctrl : sdram_controller 	generic map (
										reset_polarity_g  	=> reset_polarity_g
										)
									port map(
										clk_i		=> clk_133,
	                                    rst			=> rst,
	                                    pll_locked	=> '1',
	                                    
	                                    dram_addr	=> dram_addr,	
	                                    dram_bank	=> dram_bank,	
	                                    dram_cas_n	=> dram_cas_n,	
	                                    dram_cke	=> dram_cke,	
	                                    dram_cs_n	=> dram_cs_n,	
	                                    dram_dq		=> dram_dq,		
	                                    dram_ldqm	=> dram_ldqm,	
	                                    dram_udqm	=> dram_udqm,	
	                                    dram_ras_n	=> dram_ras_n,	
	                                    dram_we_n	=> dram_we_n,	
	                                    
	                                    wbs_adr_i	=> addr,	
	                                    wbs_dat_i	=> dat_tb2ram,	
										wbs_we_i	=> we_i,	
										wbs_tga_i	=> burst_len,	
										wbs_cyc_i	=> cyc_o,
										wbs_stb_i	=> stb_o,	
										wbs_dat_o	=> dat_ram2tb,
										wbs_stall_o	=> stall_i,
										wbs_err_o	=> err_o,
										wbs_ack_o	=> ack_i
									);
									
	sdr_rw : sdram_rw port map		(
										clk_i		=> clk_133,
										rst			=> rst,
										
										wbm_adr_o	=> addr,
										wbm_dat_i	=> dat_ram2tb,
	                                    wbm_dat_o	=> dat_tb2ram,
										wbm_we_i	=> we_i,
                                        wbm_tga_o	=> burst_len,
                                        wbm_cyc_o	=> cyc_o,
                                        wbm_stb_o	=> stb_o,
										wbm_stall_i	=> stall_i,
                                        wbm_ack_i	=> ack_i,

										green_led	=> green_led,
										red_led		=> red_led,
										writing		=> writing
									);
	sdram_model_inst : sdram_model port map (
										Dq		=> dram_dq,	
	                                    Addr    => dram_addr,
	                                    Ba      => dram_bank,
	                                    Clk     => clk_133,
	                                    Cke     => dram_cke,
	                                    Cs      => dram_cs_n,
	                                    Ras     => dram_ras_n,
	                                    Cas     => dram_cas_n,
	                                    We      => dram_we_n,
	                                    Dqm(0)  => dram_ldqm,
	                                    Dqm(1)  => dram_udqm
									);
									
end architecture sim_sdram_tb;