------------------------------------------------------------------------------------------------
-- Description: Transmit compressed data
-- 	'Tx_data' transmits a compressed data (from matlab) to the decompressor.
--
-- Compressed file structure:
--	Color Value (0-->FF)		Color Repetition (0-->FF)
--	FF							FF
--	01							AC
--
--	TX will send (1) FF and FF, and then (2) 01 and AC.
--	Data will be send once in (color value + repetition)'s depth clocks.
--	for example: suppose that color value is 8 bits, repetition is 8 bits,
--	then data will be transmitted once in [(8+8)/16)] a clock cycle.
--
-- Work Method:
--	When 'decomp' is ready to recieve new data (repetition = 0), it rises the
--	'rx_rdy' flag. the TX_DATA recieves this signal, and when ready, rises the
--	'data_rdy' flag. Then 'decomp' unrises the 'rx_rdy' signal, and data is
--	being recieved and decompressed.
--	When end of picture is reahced, 'end_pic' signal is being rised.
--
-----------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

use std.textio.all;

entity tx_data is
   generic (
             rep_size_g		:		natural := 7
           );
   port
   	   (
   	     clk		:	in std_logic; --Input clock
   	     flush		:	in std_logic;
   	     req_data   :	in std_logic;
   	     dout		:	out std_logic_vector (7 downto 0); --Color value (0--> 255 ==> 0-->FF) or repetitions
		 dout_val	:	out std_logic;
   	     end_pic	:	out boolean := false --TRUE when end of file
	   );
end entity tx_data;

architecture arc_tx_data of tx_data is

------------------  SIGNALS AND VARIABLES ------
FILE input, console : text;


------------------  Design ----------------------
begin
 
   -------------- Transmission Process ----------
   file_proc : process 
   variable f_status    : FILE_OPEN_STATUS; --File open status
   variable console_msg : line; --Messages to console
   variable i_val       : std_logic_vector (7 downto 0); --Color value (internal)
   variable ln	        : line; --Line for reading from text files
   variable success     : boolean; --Read success (for hread)
   variable f_open      : boolean := false; --Input file open status
   variable chr	        : character; --Character for deleting ' ' and horizontal tab from read line
   begin
  
    
      wait until rising_edge(clk);

        --File open status
        if not f_open then
          file_open(input, "H:/RunLen/VHDL/Simulation/TB/Video/Decompress/Runlen_Decompress/Input_Files/exp.txt", read_mode); --Open file for reading
          file_open(f_status, console, "STD_OUTPUT", write_mode); --Open "modelsim console" for writing messages
          f_open := true;
        end if;
        
        if (not endfile(input)) and (req_data = '1') then
          end_pic <= false; --Not end of picture
          
				readline(input, ln); --Read line from text file
        		--Remove white characters (space and TAB) from line
        		while (ln'length >=1) and (ln(1) = ' ' or ln(1) = HT) loop
					read(ln, chr, success);
					if not success then
						console_msg := new string'("Error deleting 'SPACE' and 'TAB'");
						writeline (console, console_msg);
						deallocate (console_msg);
					end if;
				end loop;

        		while (ln'length >=1) and (ln(1) = '#') loop
					readline(input, ln); --Read line from text file
				end loop;

  		        hread (ln, i_val, success); --Read value
		          if not success then
		            console_msg := new string'("Error reading value");
		            writeline (console, console_msg);
		            deallocate (console_msg);
		          end if;
				dout <= i_val;
	
          --Data is ready
          dout_val <= '1';
 	
		elsif (req_data = '0') then --RX is not ready. Wait for rx_rdy to rist data_rdy
			dout_val <= '0';
			
		elsif endfile(input) then --End of file
			dout_val <= '0';
			end_pic <= true; --End of picture
			console_msg := new string'("End file transmission");
		writeline(console, console_msg); --Write decimal value to console
			deallocate(console_msg); --Deallocate from memory
			file_close(input);
			file_close(console);
			f_open := false;
			wait for 150 ns;
		end if;
  
end process file_proc;

end arc_tx_data;		


