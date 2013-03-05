------------------------------------------------------------------------------------------------
-- Model Name 	:	TX Path Test Bench
-- File Name	:	tx_path_tb.vhd
-- Generated	:	01.02.2012
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: TB for tx_path
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		01.02.2012	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;


entity tx_path_tb is
end entity tx_path_tb;

architecture arc_tx_path_tb of tx_path_tb is

-- ###############################################################################
component tx_path
   generic (
				--------------------- Common generic --------------------------------------------------------
				reset_polarity_g	:	std_logic 	:= '0'; 			--'0' = Active Low, '1' = Active High
				--------------------- mp_Enc's generics --------------------------------------------------------
				len_dec1_g			:	boolean := true;				--TRUE - Recieved length is decreased by 1 ,to save 1 bit
																		--FALSE - Recieved length is the actual length
				sof_d_g				:	positive := 1;					--SOF Depth
				type_d_g			:	positive := 1;					--Type Depth
				addr_d_g			:	positive := 1;					--Address Depth
				len_d_g				:	positive := 2;					--Length Depth
				crc_d_g				:	positive := 1;					--CRC Depth
				eof_d_g				:	positive := 1;					--EOF Depth		
				sof_val_g			:	natural := 100;					--(64h) SOF block value. Upper block is MSB
				eof_val_g			:	natural := 200;					--(C8h) EOF block value. Upper block is MSB
				width_g				:	positive := 8;					--Data Width (UART = 8 bits) and REG width
				--------------------- UART_TX's generics --------------------------------------------------------
				parity_en_g			:	natural	range 0 to 1 := 1; 		--Enable parity bit = 1, parity disabled = 0
				parity_odd_g		:	boolean 	:= false; 			--TRUE = odd, FALSE = even
				uart_idle_g			:	std_logic 	:= '1';				--Idle line value
				clkrate_g			:	positive 	:= 133333333;		--System Clock
				baudrate_g			:	positive	:= 115200;			--UART baudrate
				databits_g			:	natural range 5 to 8 := 8;		--Number of databits
				--------------------- RAM's generics --------------------------------------------------------
				width_in_g			:	positive 				:= 8;	--Width of data
				addr_bits_g			:	positive 				:= 10;	--Depth of data	(2^10 = 1024 addresses)
				--------------------- Checksum's generics --------------------------------------------------------		
				signed_checksum_g	:	boolean	:= false;				--TRUE to signed checksum, FALSE to unsigned checksum		
				checksum_init_val_g	:	integer	:= 0;					--Note that the initial value is given as an natural number, and not STD_LOGIC_VECTOR		
				checksum_out_width_g:	natural := 8;					--Output CheckSum width
				data_width_g		:	natural := 8;					--Input data width	 
				--------------------- FIFO's generics --------------------------------------------------------		
				depth_g 			: positive	:= 9;					-- Maximum elements in FIFO
				log_depth_g			: natural	:= 4;					-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
				almost_full_g		: positive	:= 8; 					-- Rise almost full flag at this number of elements in FIFO
				almost_empty_g		: positive	:= 1; 					-- Rise almost empty flag at this number of elements in FIFO
				--------------------- REG's generics ---------------------------------------------------------		
				addr_en_g			:	boolean		:= true;			--TRUE: Address enabled  - responde by register will occur only when specific address has been specified
				addr_val_g			:	natural		:= 0;				--Default register address
				addr_width_g		:	positive	:= 4;				--2^4 = 16 register address is supported
				read_en_g			:	boolean		:= true;			--Enabling read
				write_en_g			:	boolean		:= true;			--Enabling write
				clear_on_read_g		:	boolean		:= false;			--TRUE: Clear on read (set to default value), FALSE otherwise
				default_value_g		:	natural		:= 0				--Default value of register
				
           );
		   port	(
				
				uart_serial_out		:	out std_logic; 									--Serial data out		
				--wishbone ports
				rst					:	in std_logic;							--System Reset
				--------------------- Wishbone's common ports --------------------------------------------------------		
				clk_i 				:	in std_logic;							-- wishbone Clock
				--------------------- Wishbones Master's ports --------------------------------------------------------
				wbm_cyc_o 			:	out std_logic;							-- Cycle Command to interface
				wbm_tgc_o 			:	out std_logic;							-- Bus cycle tag: '1' write to REG, '0' write to RAM
				wbm_stb_o 			:	out std_logic;							-- Strobe Command to interface
				wbm_we_o			:	out std_logic;							-- Write Enable
				wbm_adr_o 			:	out std_logic_vector(9 downto 0);		-- Address 0-1023h
				wbm_tga_o 			:	out std_logic_vector(9 downto 0);		-- Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
				wbm_dat_i			:	in std_logic_vector(7 downto 0);		-- Input Data
				wbm_ack_i 			:	in std_logic;							-- When Read Burst: DATA bus must be valid in this cycle
				wbm_stall_i 		:	in std_logic;							-- Slave is not ready to receive new data
				wbm_err_i 			:	in std_logic;							-- Error flag: OOR Burst. Burst length is greater that 256-column address
				--------------------- Wishbones Slave's ports --------------------------------------------------------
				wbs_adr_i			:	in std_logic_vector (9 downto 0);		--Address in internal RAM
				wbs_tga_i			:	in std_logic_vector (9 downto 0);		--Burst Length
				wbs_dat_i			:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
				wbs_cyc_i			:	in std_logic;							--Cycle command from WBM
				wbs_stb_i			:	in std_logic;							--Strobe command from WBM
				wbs_we_i			:	in std_logic;							--Write Enable
				wbs_tgc_i			:	in std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wbs_dat_o			:	out std_logic_vector (7 downto 0);		--Data Out (8 bits)
				wbs_stall_o			:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wbs_ack_o			:	out std_logic;							--Input data has been successfuly acknowledged
				wbs_err_o			:	out std_logic							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
			);	

end component tx_path;

----	############	Signals	############
signal uart_serial_out		:	std_logic; 						
signal rst					:	std_logic;						
signal clk_i 				:	std_logic := '0';						
signal wbm_cyc_o 			:	std_logic;						
signal wbm_tgc_o 			:	std_logic;						
signal wbm_stb_o 			:	std_logic;						
signal wbm_we_o				:	std_logic;						
signal wbm_adr_o 			:	std_logic_vector(9 downto 0);	
signal wbm_tga_o 			:	std_logic_vector(9 downto 0);	
signal wbm_dat_i			:	std_logic_vector(7 downto 0);	
signal wbm_ack_i 			:	std_logic;						
signal wbm_stall_i 			:	std_logic;						
signal wbm_err_i 			:	std_logic;						
signal wbs_adr_i			:	std_logic_vector (9 downto 0) := (others => '0');	
signal wbs_tga_i			:	std_logic_vector (9 downto 0) := (others => '0');	
signal wbs_dat_i			:	std_logic_vector (7 downto 0) := (others => '0');	
signal wbs_cyc_i			:	std_logic := '0';						
signal wbs_stb_i			:	std_logic := '0';						
signal wbs_we_i				:	std_logic := '0';						
signal wbs_tgc_i			:	std_logic := '0';						
signal wbs_dat_o			:	std_logic_vector (7 downto 0);	
signal wbs_stall_o			:	std_logic;						
signal wbs_ack_o			:	std_logic;						
signal wbs_err_o			:	std_logic;
signal end_of_wbs			:	boolean := false;

--------------------------------- Constants   ------------------------------------
constant reg_width_c		:	positive 	:= 8;	--Width of registers
constant reg_addr_width_c	:	positive 	:= 4;	--Width of registers' address
constant type_reg_addr_c	:	natural		:= 1;	--Type register address
constant rd_burst_reg_addr_c:	natural		:= 9;	--Number of bytes to read from SDRAM/ bytes from Registers
constant rd_burst_reg_depth_c:	natural		:= 2;	--2*8 = 16 bits
constant dbg_cmd_reg_addr_c	:	natural		:= 11;	--Debug Command register
constant reg_addr_reg_addr_c:	natural		:= 12;	--Read address of register


begin
-- ###############################################################################

	--clk_proc:
	clk_proc:
	clk_i	<=	not clk_i after 3.5 ns;
	
	--Wishbone slave process
	wbs_proc: process
	
	--Execute Data Burst
	procedure wbm_burst (constant blen_p, dat_p , addr_p: in natural) is
	variable min_val	:	natural;
	variable data_val	:	natural := dat_p;
	variable addr		:	natural := addr_p;
	variable blen		:	natural := blen_p;
	
	begin
		wbs_cyc_i		<= '0';
		wbs_stb_i		<= '0';
		wbs_dat_i		<= 	(others => '0');
		while blen > 0 loop
			min_val := blen - 1;
			wbs_adr_i	<= conv_std_logic_vector (addr, 10);
			wbs_tga_i	<= conv_std_logic_vector (min_val, 10);
			wait until rising_edge(clk_i);
			wbs_cyc_i	<= '1';
			wbs_stb_i	<= '1';
			wbs_tgc_i	<= '1';
			wbs_we_i	<=	'1';
			blen_loop:
			for idx in 0 to min_val loop	--Burst length
				wbs_dat_i	<= 	conv_std_logic_vector (data_val mod 256, 8);
				data_val	:=	data_val / 256;
				if (wbs_stall_o = '1') then
					wait until wbs_stall_o = '0';
					wait until rising_edge(clk_i);
				end if;
				wbs_adr_i	<= conv_std_logic_vector (addr, 10);
				addr		:= addr + 1;
				blen := blen - 1;

				if (idx = min_val) or (blen = 1) then
					wbs_stb_i	<= '0';
				end if;
				wait until rising_edge(clk_i);
				if (blen <= 1) then
					if (blen = 1) then
						wbs_stb_i	<= '0';
						blen := blen -1;
					end if;
					exit blen_loop;
				end if;
			end loop blen_loop;
			wait until wbs_ack_o 	= '0';
			wbs_cyc_i	<= '0';
			wbs_tgc_i	<= '0';
			wbs_we_i	<=	'0';
		end loop;
		end_of_wbs	<= true, false after 7 ns;
	end procedure wbm_burst;
	----------
	begin
		rst <= '0';
		wait for 100 ns;
		rst <= '1';
		wait for 100 ns;
		wbm_burst (blen_p => 1	, addr_p	=>	type_reg_addr_c, dat_p => 128 );	--Write 0x80 to Type Register (Read type reg)
		wait for 50 ns;
		wbm_burst (blen_p => 1	, addr_p	=>	reg_addr_reg_addr_c, dat_p => 7 );	--Read reg #7
		wait for 50 ns;
		wbm_burst (blen_p => 2	, addr_p	=>	rd_burst_reg_addr_c, dat_p => 0 );	--Read 1 bytes
		wait for 50 ns;
		wbm_burst (blen_p => 1	, addr_p	=>	dbg_cmd_reg_addr_c, dat_p => 1 );	--Execute transaction
		
		wait;
	
	end process wbs_proc;
	
	---- ###############---
	wbm_proc: process
	begin
		wbm_stall_i <= '1';
		wbm_ack_i	<= '0';
		wbm_err_i	<= '0';
		wbm_dat_i	<=	(others => '0');
		wait until wbm_cyc_o = '1';
		wait until rising_edge (clk_i);
		wbm_stall_i <= '0';
		wait until rising_edge (clk_i);
		wbm_dat_i	<=	(others => '1');
		wbm_ack_i	<= '1';
		wait until wbm_cyc_o = '0';
	end process wbm_proc;

--------------------------------------------------	Instatiations	---------------------------
	tx_path_inst : tx_path port map
		(
			uart_serial_out		=>	uart_serial_out	,
		    rst					=>	rst				,
		    clk_i 				=>	clk_i 			,
		    wbm_cyc_o 			=>	wbm_cyc_o 		,
		    wbm_tgc_o 			=>	wbm_tgc_o 		,
		    wbm_stb_o 			=>	wbm_stb_o 		,
		    wbm_we_o			=>	wbm_we_o		,
		    wbm_adr_o 			=>	wbm_adr_o 		,
		    wbm_tga_o 			=>	wbm_tga_o 		,
		    wbm_dat_i			=>	wbm_dat_i		,
		    wbm_ack_i 			=>	wbm_ack_i 		,
		    wbm_stall_i 		=>	wbm_stall_i 	,
		    wbm_err_i 			=>	wbm_err_i 		,
		    wbs_adr_i			=>	wbs_adr_i		,
		    wbs_tga_i			=>	wbs_tga_i		,
		    wbs_dat_i			=>	wbs_dat_i		,
		    wbs_cyc_i			=>	wbs_cyc_i		,
		    wbs_stb_i			=>	wbs_stb_i		,
		    wbs_we_i			=>	wbs_we_i		,
		    wbs_tgc_i			=>	wbs_tgc_i		,
		    wbs_dat_o			=>	wbs_dat_o		,
		    wbs_stall_o			=>	wbs_stall_o		,
		    wbs_ack_o			=>	wbs_ack_o		,
		    wbs_err_o			=>	wbs_err_o		
		);

	
end architecture arc_tx_path_tb;