------------------------------------------------------------------------------------------------
-- Model Name 	:	UART Transmitter Test Bench
-- File Name	:	uart_tx_tb.vhd
-- Generated	:	27.11.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This model implements the UART Transmitter Test bench
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		1.12.2010	Alon Yavich & Beeri Shreiber	Creation			
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity uart_tx_tb is
	generic (
			 test_number_g		:		positive 	:= 1;				--Test Number
			 test_output_dir_g	:		string		:= "RunLen\VHDL\Simulation\TB\Communication\Serial\UART\TX\output_files\";	--Output test directory
			 test_output_f_g	:		string		:= "uart_test.txt";	--Output test file
			 parity_en_g		:		natural	range 0 to 1 := 1; 		--Enable parity bit
			 parity_odd_g		:		boolean 	:= false; 			--TRUE = odd, FALSE = even
			 uart_idle_g		:		std_logic 	:= '1';				--Idle line value
			 tx_baudrate_g		:		positive	:= 115200;			--UART baudrate [Hz]
			 rx_baudrate_g		:		positive	:= 115200;			--UART baudrate [Hz]
			 clkrate_g			:		positive	:= 133000000;		--Sys. clock [Hz]
			 databits_g			:		natural range 5 to 8 := 8;		--Number of databits
			 reset_polarity_g	:		std_logic	:= '0'				--reset polarity
			 );
	port (
			end_test			:		std_logic	:= '0'				--'1' = End of test_number_g
		);
end entity uart_tx_tb;

architecture arc_uart_tx_tb of uart_tx_tb is

component uart_tx
   generic (
			 parity_en_g		:		natural	range 0 to 1 := 1; 		--Enable parity bit = 1, parity disabled = 0
			 parity_odd_g		:		boolean 	:= false; 			--TRUE = odd, FALSE = even
			 uart_idle_g		:		std_logic 	:= '1';				--Idle line value
			 baudrate_g			:		positive	:= 115200;			--UART baudrate
			 clkrate_g			:		positive	:= 133000000;		--Sys. clock
			 databits_g			:		natural range 5 to 8 := 8;		--Number of databits
			 reset_polarity_g	:		std_logic	:= '0'				--reset polarity
		
           );
        
   port
		(
			din					:	in std_logic_vector (databits_g -1 downto 0);		--Parallel data in
			clk					:	in std_logic;						--Sys. clock
			reset				:	in std_logic;						--Reset
			fifo_empty			:	in std_logic;						--FIFO is not empty
			fifo_din_valid		:   in std_logic;						--FIFO Ready to transmitte new data to tx
			fifo_rd_en			:	out std_logic;						--Controls FIFO rd_en 
			dout				:	out std_logic						--Serial data out
		  );
end component;

component uart_tx_gen_model 
   generic (
			--File name explanasion:
			--File name is being named <file_name_g>_<file_idx>.<file_extension_g>
			--i.e: uart_tx_1.txt, uart_tx_2.txt ....
			--file_max_idx_g is the maximum index for files. For example: suppose this
			--parameter is 2, then transmission file order will be:
			-- (1)uart_tx_1.txt (2)uart_tx_2.txt (3) uart_tx_1.txt (4) uart_tx_2.txt ...
			file_name_g			:		string 		:= "uart_tx"; 		--File name to be transmitted
			file_extension_g	:		string		:= "txt";			--File extension
			file_max_idx_g		:		positive	:= 2;				--Maximum file index.
			delay_g				:		positive	:= 10;				--Number of clock cycles delay between two files transmission
			 
			clock_period_g		:		time		:= 8.68 us;			--8.68us = 115,200 Bits/sec
			parity_en_g			:		natural range 0 to 1 := 1; 		--1 to Enable parity bit, 0 to disable parity bit
			parity_odd_g		:		boolean 	:= false; 			--TRUE = odd, FALSE = even
			uart_idle_g			:		std_logic 	:= '1' 				--Idle line value
		   );
   port
	   (
		 system_clk	:	in std_logic := '0'; 				--System clock, for Valid for one clock
		 uart_out	:	out std_logic := '1';				--Serial data out (UART)
		 value		:	out std_logic_vector (7 downto 0) := (others => '0'); 	--Transmitted value (For user convenience - to see the transmitted value)
		 valid		:	out std_logic := '0'				--Valid value (8 bit) - Active for one clock (For Parallel data simulation)
	   );
end component;

component uart_rx 
   generic (
			 parity_en_g		:		natural range 0 to 1 := 1; 		--1 to Enable parity bit, 0 to disable parity bit
			 parity_odd_g		:		boolean 	:= false; 			--TRUE = odd, FALSE = even
			 uart_idle_g		:		std_logic 	:= '1';				--IDLE_ST line value
			 baudrate_g			:		positive	:= 115200;			--UART baudrate [Hz]
			 clkrate_g			:		positive	:= 133333333;		--Sys. clock [Hz]
			 databits_g			:		natural range 5 to 8 := 8;		--Number of databits
			 reset_polarity_g	:		std_logic 	:= '0'	 			--'0' = Active Low, '1' = Active High
           );
   port
   	   (
			 din				:	in std_logic;				--Serial data in
			 clk				:	in std_logic;				--Sys. clock
			 reset				:	in std_logic;				--Reset
 			 dout				:	out std_logic_vector (databits_g - 1 downto 0);	--Parallel data out
			 valid				:	out std_logic;				--Parallel data valid
			 parity_err			:	out std_logic;				--parity error
			 stop_bit_err		:	out	std_logic				--Stop bit error
   	   );
end component;

component general_fifo is 
	generic(	 
		reset_polarity_g	: std_logic	:= '0';	-- Reset Polarity
		width_g				: positive	:= 8; 	-- Width of data
		depth_g 			: positive	:= 9;	-- Maximum elements in FIFO
		log_depth_g			: natural	:= 4;	-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
		almost_full_g		: positive	:= 8; 	-- Rise almost full flag at this number of elements in FIFO
		almost_empty_g		: positive	:= 1 	-- Rise almost empty flag at this number of elements in FIFO
		);
	 port(
		 clk 		: in 	std_logic;									-- Clock
		 rst 		: in 	std_logic;                                  -- Reset
		 din 		: in 	std_logic_vector (width_g-1 downto 0);      -- Input Data
		 wr_en 		: in 	std_logic;                                  -- Write Enable
		 rd_en 		: in 	std_logic;                                  -- Read Enable (request for data)
		 dout 		: out 	std_logic_vector (width_g-1 downto 0);	    -- Output Data
		 dout_valid	: out 	std_logic;                                  -- Output data is valid
		 afull  	: out 	std_logic;                                  -- FIFO is almost full
		 full 		: out 	std_logic;	                                -- FIFO is full
		 aempty 	: out 	std_logic;                                  -- FIFO is almost empty
		 empty 		: out 	std_logic;                                  -- FIFO is empty
		 used 		: out 	std_logic_vector (log_depth_g  downto 0) 	-- Current number of elements is FIFO. Note the range. In case depth_g is 2^x, then the extra bit will be used
	     );
end component general_fifo;

component uart_rx_compare_model 
   generic (
            test_number_g		:		positive 	:= 1;				--Test number (will be written as file output
			cycle_files_g		:		boolean		:= true;			--When last file reach - restart from first file
			
			file_name_g			:		string 		:= "uart_tx"; 		--File name to be transmitted
			file_extension_g	:		string		:= "txt";			--File extension
			file_max_idx_g		:		positive	:= 2				--Maximum file index.
           );
   port
   	   (
			din 		:	in std_logic_vector (7 downto 0);		--Input Data from UART
			din_valid	:	in std_logic;							--Input from UART is valid
			parity_err	:	in std_logic;							--Parity Error
			stop_bit_err:	in std_logic;							--Stop bit error
			
			test_passed	:	out boolean								--Test passed / failed
   	   );
end component uart_rx_compare_model;


	
	signal data_gen2fifo		: std_logic_vector (7 downto 0);
	signal data_fifo2tx 		: std_logic_vector (7 downto 0);
	signal uart_tx2rx			: std_logic;
	signal data_outrx 			: std_logic_vector (7 downto 0);
	signal gen_valid			: std_logic;
	signal cont					: std_logic;
	signal fifo_valid			: std_logic;
	signal rx_valid				: std_logic;
	signal fifo_empty			: std_logic;
	signal clk					: std_logic := '0';
	signal reset				: std_logic := '0';
	
	signal rx_parity_err		: std_logic;
	signal rx_stop_bit_err		: std_logic;
	signal test_passed			: boolean;
	
begin
	cmp_inst : uart_rx_compare_model generic map (
										test_number_g		=>	test_number_g,
	                                    --cycle_files_g		=>	
	                                                        
										--Beeri's Computer
										file_name_g => "D:\ModelSim\MyDesign\RunLen\VHDL\Simulation\Models\Communication\Serial\UART\TX\UART_Generator\Input_Files\uart_tx"
										--Alon's Computer:
										--file_name_g => "D:\Technion\Project\VHDL\Simulation\Models\Communication\Serial\UART\TX\UART_Generator\Input_Files\uart_tx"
	                                    --file_extension_g	=>
	                                    --file_max_idx_g		=>
									)
									
									port map (
										din 		 => data_outrx,
										din_valid	 => rx_valid,
	                                    parity_err	 => rx_parity_err,
	                                    stop_bit_err => rx_stop_bit_err,
										test_passed	 => test_passed
									);
	
	gen_inst : uart_tx_gen_model 	generic map (
										--Alon's Computer:
										--file_name_g => "D:\Technion\Project\VHDL\Simulation\Models\Communication\Serial\UART\TX\UART_Generator\Input_Files\uart_tx",
										
										--Technion Computer
										--file_name_g => "H:\RunLen\VHDL\Simulation\Models\Communication\Serial\UART\TX\UART_Generator\Input_Files\uart_tx",

										--Beeri's Computer
										file_name_g => "D:\ModelSim\MyDesign\RunLen\VHDL\Simulation\Models\Communication\Serial\UART\TX\UART_Generator\Input_Files\uart_tx",
										
										
										--file_max_idx_g	
										--delay_g			
										 
										--clock_period_g	
										
										parity_odd_g	=> parity_odd_g,
										parity_en_g		=>	 parity_en_g,
										uart_idle_g		=> uart_idle_g	
										)
									port map ( 
										system_clk => clk,	
										--uart_out	
										value	=>	data_gen2fifo,
										valid	=>	gen_valid
										);
	
	fifo_inst : general_fifo 	generic map(	 
								depth_g 	=>  1040,
								log_depth_g	=>	11
								)
								port map (
								clk 		=> clk, 
								rst 		=> reset,
								din 		=> data_gen2fifo,
								wr_en 		=> gen_valid,
								rd_en 		=> cont,
								dout 		=> data_fifo2tx,
								dout_valid	=> fifo_valid,
								empty 		=> fifo_empty
							);
								
	tx_inst : uart_tx 	generic map (
								 parity_en_g		=>	 parity_en_g		,	
	                             parity_odd_g		=>   parity_odd_g		,
	                             uart_idle_g		=>   uart_idle_g		,
	                             baudrate_g			=>   tx_baudrate_g		,
	                             clkrate_g			=>   clkrate_g			,
	                             databits_g			=>   databits_g			,
	                             reset_polarity_g	=>   reset_polarity_g	
								 )
	
							port map (
								din			=> data_fifo2tx,
                                clk			=> clk,	
                                reset		=> reset,	
                                fifo_empty 	=> fifo_empty,
                                dout 		=> uart_tx2rx,
                                fifo_rd_en		=> cont,
								fifo_din_valid => fifo_valid
								);
								
	rx_inst : uart_rx generic map (
								 parity_en_g		=>	 parity_en_g		,	
	                             parity_odd_g		=>   parity_odd_g		,
	                             uart_idle_g		=>   uart_idle_g		,
	                             baudrate_g			=>   rx_baudrate_g		,
	                             clkrate_g			=>   clkrate_g			,
	                             databits_g			=>   databits_g			,
	                             reset_polarity_g	=>   reset_polarity_g	
								 )
							port map (
								din				=>	uart_tx2rx,		
                                clk				=> 	clk,	
                                reset 			=> 	reset,		
                                dout 			=> 	data_outrx,		
                                valid			=> 	rx_valid,	
                                parity_err		=>	rx_parity_err,
                                stop_bit_err	=>	rx_stop_bit_err
								);
	
	clk_proc:
	clk <= not clk after (1 sec /real(clkrate_g*2));	--133MHz
	
	rst_proc:
	reset <= reset_polarity_g, (not reset_polarity_g) after 20 ns;
	
	--------------------
	
	----------------------------------------------------
	---------- Process test_proc -----------------------
	----------------------------------------------------
	-- The process writes PASSED / FAILED into the 
	-- test file, when the test is done, according to
	-- the 'end_test' port.
	----------------------------------------------------
	test_proc : process (end_test)
	file		test_file	:	text;
	variable	ln			:	line;
	begin
		if rising_edge(end_test) then
			--Open file in Append Mode (unless test number is 1 - then overwrite current file), and write "Test number <test_number_g> has PASSED / FAILED"
			if test_number_g = 1 then
				file_open(test_file, test_output_dir_g & test_output_f_g, write_mode);
			else
				file_open(test_file, test_output_dir_g & test_output_f_g, append_mode);
			end if;
			
			if test_passed then
				write (ln, "Test number " & positive'image (test_number_g) & " had PASSED");
			else
				write (ln, "Test number " & positive'image (test_number_g) & " had FAILED");
			end if;
			writeline(test_file, ln);
			deallocate (ln);
			file_close (test_file); --Close file
		end if;
	end process test_proc;
	
end architecture arc_uart_tx_tb;
