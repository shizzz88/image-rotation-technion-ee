------------------------------------------------------------------------------------------------
-- Model Name 	:	UART RX Compare Model
-- File Name	:	uart_rx_compare_model.vhd
-- Generated	:	24.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The model compares between received data from UART RX and a given file.
--				Errors will be reported at the following cases:
--					(1) Received data and expected data mismatch
--					(2) Parity bit error
--					(3) Stop bit error
------------------------------------------------------------------------------------------------
-- Changes:
--			Number		Date		Name				Description
--			(1)			24.12.2010	Beeri Schreiber		Creation
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

library work;
use work.txt_util_pkg.all;

entity uart_rx_compare_model is
   generic (
            test_number_g		:		positive 	:= 1;				--Test number (will be written as file output
			cycle_files_g		:		boolean		:= true;			--When last file reach - restart from first file
			
			--File name explanasion:
			--File name is being named <file_name_g>_<file_idx>.<file_extension_g>
			--i.e: uart_tx_1.txt, uart_tx_2.txt ....
			--file_max_idx_g is the maximum index for files. For example: suppose this
			--parameter is 2, then transmission file order will be:
			-- (1)uart_tx_1.txt (2)uart_tx_2.txt (3) uart_tx_1.txt (4) uart_tx_2.txt ...
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
end entity uart_rx_compare_model;

architecture arc_uart_rx_compare_model of uart_rx_compare_model is
------------------  SIGNALS AND VARIABLES ------
file 	ref_file				: 	text;					--Reference File

signal	end_file				:	boolean		:= false;	--TRUE when end of file has been reached
signal 	file_open_stat			:	boolean		:= false;	--TRUE when file is opened, FALSE when closed
signal 	test_passed_i			:	boolean		:= true;	--TRUE if test passed, FALSE otherwise

shared variable file_index		: 	positive 	:= 1;		--File Index (filename_fileIndex.fileExtension)

------------------  Design ----------------------
begin
	
	test_passed_proc:
	test_passed	<= test_passed_i;
	-------------------
	
	compare_proc : process
	variable ln 	:	line;
	variable val_in	:	std_logic_vector (7 downto 0);
	variable success:	boolean := true;
	variable chr	:	character;
	begin
		file_open(ref_file, file_name_g & "_" & positive'image(file_index) & "." & file_extension_g, read_mode); --Open file for reading	

		while not endfile (ref_file) loop
			
			readline(ref_file, ln); --Read line from text file
			while ln /= null loop

				if ln /= null and ln'length = 0 then
					deallocate(ln); --Free allocated memory
				elsif ln /= null then
					--Delete white spaces
					while (ln'length >=1) and (ln(1) = ' ' or ln(1) = HT) loop
					  read(ln, chr, success);
					  if not success then
						test_passed_i	<= false;
						report "Time: " & time'image(now) & ", uart_rx_compare_model, Test number " & integer'image(test_number_g) & " : Error deleting white spaces, while reading input file " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g 
						severity failure;
					  end if;
					end loop;
				end if;
				
				if ln /= null and ln'length = 0 then
					deallocate(ln); --Free allocated memory
				end if;
				
				if ln /= null then
					hread (ln, val_in, success); --Read value from file
					if not success then
						test_passed_i	<= false;
						report "Time: " & time'image(now) & ", uart_rx_compare_model, Test number " & integer'image(test_number_g) & " : Error reading input file " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g 
						severity failure;
					end if;
					
					--Wait for new data valid or error, and compare data
					wait until (din_valid = '1') or (parity_err = '1') or (stop_bit_err = '1');
					if din_valid = '1' then	--Valid data
						if din /= val_in then --Expected and actual value are not the same
							test_passed_i	<= false;
							report "Time: " & time'image(now) & ", uart_rx_compare_model, Test number " & integer'image(test_number_g) & " : Values mismatch. Received: " & hstr (din) &", Expected: " & hstr(val_in) & ", File: " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g 
							severity error;
						elsif parity_err = '1' then
							test_passed_i	<= false;
							report "Time: " & time'image(now) & ", uart_rx_compare_model, Test number " & integer'image(test_number_g) & " : Parity error detected , File: " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g 
							severity error;
						elsif stop_bit_err = '1' then
							test_passed_i	<= false;
							report "Time: " & time'image(now) & ", uart_rx_compare_model, Test number " & integer'image(test_number_g) & " : Stop bit error detected , File: " & file_name_g & "_" & positive'image(file_index) & "." & file_extension_g 
							severity error;
						end if;
					end if;
				end if;
				
			end loop;
		end loop;

		file_close (ref_file); 				--Close file
		if file_index = file_max_idx_g then	--Last index file
			file_index := 1;
			if not cycle_files_g then
				wait;						--End of test
			end if;
		else
			file_index :=  file_index + 1;
		end if;

	end process compare_proc;

end arc_uart_rx_compare_model;