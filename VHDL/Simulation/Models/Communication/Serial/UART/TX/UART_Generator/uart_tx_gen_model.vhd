------------------------------------------------------------------------------------------------
-- Model Name 	:	UART TX Generator
-- File Name	:	uart_tx_gen_model.vhd
-- Generated	:	16.11.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The generator generates UART transmission, from given files.
--				One byte is being read from the file in each transaction.
--				An output 'value' (one byte) is given for wave debug.
--
--				Generic Parameters:
--				(1) file_name_g		:	File name (i.e: uart_tx)		
--				(2) file_extension_g:	File extension (i.e: txt)
--				(3) file_max_idx_g	:	Maximum files to be transmitted, according to their index
--				(4) delay_g			:	Clock delays between two files transmission
--
--					Example:	uart_tx_1.txt, uart_tx_2.txt, uart_tx_3.txt
--					where _1, _2, _3 are derived from the file_max_idx_g
--			 
--				(5) clock_period_g	:	Clock Period (1 / Frequency)		
--
--				(6) parity_en_g		:	When TRUE - transmit parity bit, when FALSE - do not transmit
--				(7) parity_odd_g	:	When TRUE - '1' will be transmitted if odd number of '1' has been counted, '0' if even.
--										When FALSE - '1' will be transmitted if even number of '1' has been counted, '0' if odd.
--				(8) msb_first_g		:	When TRUE - Transmit MSB first. When FALSE - Transmit LSB first
--					Note that according to UART Standard - LSB is being transmitted first
--				(9) uart_idle_g		:	Idle line and stop bit will be represented by this value.
--										Start bit will be represented by the oposite value.
--
-- Clock:	115,200 Bits/sec frequency (8.68us period) is suggested.
--
-- Input file example:
--			FF	F5	43	32
--			4344
--			8A
------------------------------------------------------------------------------------------------
-- Changes:
--			Number		Date		Name				Description
--			(1)			16.11.2010	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
-- Input File Liminations:
--				(1) (Space / Tab / No space ) can separate between values (bytes).
--				(2)	Empty lines in the text file are not supported.
--				(3) Nibbles are not supported - only bytes. For example: 'A B' cannot be read.
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

entity uart_tx_gen_model is
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
			parity_en_g			:		natural range 0 to 1 := 0; 		--1 to Enable parity bit, 0 to disable parity bit
			parity_odd_g		:		boolean 	:= false; 			--TRUE = odd, FALSE = even
			msb_first_g			:		boolean 	:= false; 			--TRUE = MSB First, FALSE = LSB first
			uart_idle_g			:		std_logic 	:= '1' 				--Idle line value
           );
   port
   	   (
   	     system_clk	:	in std_logic := '0'; 				--System clock, for Valid for one clock
		 uart_out	:	out std_logic := '1';				--Serial data out (UART)
		 value		:	out std_logic_vector (7 downto 0) := (others => '0'); 	--Transmitted value (For user convenience - to see the transmitted value)
		 valid		:	out std_logic := '0'				--Valid value (8 bit) - Active for one clock (For Parallel data simulation)
   	   );
end uart_tx_gen_model;

architecture arc_uart_tx_gen_model of uart_tx_gen_model is

------------------  SIGNALS AND VARIABLES ------
FILE 	input				: 	text;					--Input File
signal 	clk_i				:	std_logic 	:= '0';		--Internal Clock
signal 	reopen_file			:	boolean 	:= true;	--After end of transmission - Reopen file
signal	reopen_file_delay	:	boolean 	:= false;	--After end of transmission - Wait some time
signal 	valid_i				: 	std_logic	:= '0';		--Data valid data, for one clock

shared variable file_index	: 	positive 	:= file_max_idx_g;	--File Index (filename_fileIndex.fileExtension)
shared variable file_status	: 	boolean 	:= true;	--TRUE = file is opened, FALSE = file is closed


------------------  Design ----------------------
begin
	
   -------------- Clock Process ----------
	clk_i <= not clk_i after clock_period_g/2;
 
   ----------File open delay Process --------
   --A delay between two files transmission is being executed here
	f_open_delay_proc : process (clk_i)
	variable cnt : natural := 0;	--Delay counter
	begin
		if rising_edge(clk_i) then
			reopen_file <= false;
			if reopen_file_delay then	--End of file transmission
				cnt := delay_g;
			end if;
			if cnt = 1 then	--Open file for transmission
				reopen_file <= true; --Active for one clock
			end if;
			if cnt > 0 then
				cnt := cnt - 1;
			end if;
		end if;
	end process f_open_delay_proc;
   
   -------------- Open file process ----------
   --Opens files at startup and after end of file + delay
	file_load_proc : process (clk_i)
	begin
	--File open status
		if rising_edge(clk_i) then
			if reopen_file then
				if file_index = file_max_idx_g then --Maximum file index has been reached
					file_index := 1;
				else
					file_index := file_index + 1; --Increment file index
				end if;
				report "Time: " & time'image(now) & ", Opening file " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g
				severity note;
				file_open(input, file_name_g & "_" & positive'image(file_index) & "." & file_extension_g, read_mode); --Open file for reading
				file_status := true; --File is opened
			end if;
		end if;
	end process file_load_proc;
	
   
   -------------- Valid process -----------------
   -- Valid for one system clock only
	valid_proc : process (system_clk, valid_i)
	begin
		if rising_edge(valid_i) then
			valid <= '1';
		elsif rising_edge(system_clk) then
			valid <= '0';
		end if;
	end process valid_proc;

   
   -------------- Transmission Process ----------
   --File is being transmitted in this process
   
   file_proc : process (clk_i)
   variable success     : boolean; --Read success (for hread)
   variable f_open      : boolean := false; --Input file open status
   variable	clk_cnt		: natural range 0 to 10:= 0;	--Number of bit to transmit
   variable ln			: line;	--Line read from text file
   variable val_in		: std_logic_vector (7 downto 0); --Read value from file
   variable chr			: character; --Character for space / Horizontal Tab remove
   variable parity_val	: std_logic := '0'; --Current parity bit value
   begin
  
    
      if rising_edge(clk_i) then
        reopen_file_delay <= false;
		valid_i <= '0';
        if file_status and ((not endfile(input)) or (parity_en_g = 1 and clk_cnt < 10) or ((parity_en_g = 0) and clk_cnt < 9) or ln'length /= 0) then
          if clk_cnt = 0 then --Ready to new transmit data
				if ln /= null and ln'length = 0 then
					deallocate(ln); --Free allocated memory
				end if;
				if ln = null then
					readline(input, ln); --Read line from text file
				end if;

				-- uri ran
               --Remove Comments
           		while (ln'length >=1) and (ln(1) = '#') loop
					readline(input, ln); --Read line from text file
				end loop;
  		        hread (ln, val_in, success); --Read value from file
		          if not success then
					report "Time: " & time'image(now) & ", uart_tx_gen_model from file: Error deleting 'SPACE' and 'TAB' from input file " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g 
					severity failure;
		          end if;

				value (7 downto 0) <= val_in (7 downto 0); --Debug output value
				valid_i <= '1';
		
        		--Remove white characters (space and TAB) from line
        		while ln'length >=1 and (ln(1) = ' ' or ln(1) = HT) loop
        		  read(ln, chr, success);
				  if not success then
					report "Time: " & time'image(now) & ", uart_tx_gen_model from file: Error while reading input file " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g 
					severity failure;
        		  end if;
        		end loop;
				
				uart_out <= not uart_idle_g; --Start bit
				parity_val := '0'; --Reset parity bit
	
	  	  --Transmit stop bit
		  elsif ((parity_en_g = 0) and clk_cnt = 9) or (parity_en_g = 1 and clk_cnt = 10) then
				uart_out <= uart_idle_g; --Stop bit
    	  
		  --Transmit data, calculate parity
		  elsif clk_cnt < 9 then --valid data
				parity_val := parity_val xor val_in(8 - clk_cnt);
				if msb_first_g then
					uart_out <= val_in(8 - clk_cnt); --MSB First (NOT UART Standard)
				else
					uart_out <= val_in(clk_cnt-1); --LSB First (According to UART Standard)
				end if;
		  
		  --Transmit parity bit
		  elsif clk_cnt = 9 and parity_en_g = 1 then --Parity enable
			if parity_odd_g then
				uart_out <= not parity_val; --Odd parity
			else
				uart_out <= parity_val; --Even parity
			end if;
		  end if;
		  
          --Increment counter
		  if (clk_cnt = 9 and (parity_en_g = 0)) or (clk_cnt = 10 and parity_en_g = 1) then
            clk_cnt := 0;
          else
            clk_cnt := clk_cnt + 1;
          end if;
          
	elsif file_status and endfile(input) then --End of file
		report "Time: " & time'image(now) & ", uart_tx_gen_model from file: End transmission from " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g
		severity note;
		uart_out <= uart_idle_g; --Stop bit
		file_close(input); --Close file
		file_status := false; --File is closed
		reopen_file_delay <= true; --Wait some time before transmission of new file
    end if;
  end if; --rising edge if statement
end process file_proc;

end arc_uart_tx_gen_model;		


