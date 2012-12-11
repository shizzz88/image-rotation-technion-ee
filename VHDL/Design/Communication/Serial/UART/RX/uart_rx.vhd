------------------------------------------------------------------------------------------------
-- Model Name 	:	UART Receiver
-- File Name	:	uart_rx.vhd
-- Generated	:	17.11.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This model implements the UART Receiver
-- 	The unit receives serial data in bursts of up to 11 bits, that includes:
--				1. Start bit
--				2. 5-8 data bits
--				3. parity bit
--				4. Stop bit
--	Generic:
--  All of the characteristic above are generic and can be changed as fit to the user.
-- 	In addition user can also choose to change the following characteristic:
--				1. parity mode - odd or even
--				2. UART's Baudrate - set to 115200 Kbit/sec
--				3. Clk's rate - set to 133 MHz
--				4. Bits polarity - Reset polarity and start bit polarity
--
--	The unit output data is a parallel, and also has parity flag error, stop bit flag
--	error and valid flag.
--	
--  System clock and Reset are provided to the unit. 
--
-- 	NOTE:
--	A problem may occur if the FPGA will rise up after the transmitting unit starts to transmit data.
--	This may cause mix ups between the data bits and the additional bits (start, stop) and will show
--	errors. This problems occurs due to a cyclic non stop transmission. 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name				Description
--			1.00		17.11.2010	Alon Yavich			Creation
--			1.10		6.11.2011	Alon Yavich			Parity Bug fixed
------------------------------------------------------------------------------------------------
--	Todo:
--							
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;

entity uart_rx is
   generic (
			 parity_en_g		:		natural range 0 to 1 := 0; 		--1 to Enable parity bit, 0 to disable parity bit
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
end entity uart_rx;

architecture arc_uart_rx of uart_rx is

------------------  	Constants	------
constant clk_div_factor		: positive := clkrate_g / baudrate_g;		--Clock Divide factor

------------------  	Types		------
type uart_rx_fsm_states is (	IDLE_ST,		--Wait for Start bit
								STARTBIT_ST,	--Count 1 UART clock period (start of first data bit)
								RX_ST,			--Recieve data bits
								PARITY_ST,		--Recieve parity bit (if enabled)
								STOPBIT_ST		--Recieve stop bit
						);       
------------------  SIGNALS --------------------
signal cur_st 		: uart_rx_fsm_states;							--Final State Machine
signal dout_i		: std_logic_vector (databits_g - 1 downto 0); 	--Internal data out	
signal din_d1		: std_logic;									--Prevent Metastability  (1)
signal din_d2		: std_logic;									--Prevent Metastability  (2)

--Signals for uart_fsm_proc FSM
signal sample_cnt	: natural range 0 to clk_div_factor + 1;--Number of data samples (5 will be taken)
signal pos_cnt		: natural range 0 to databits_g;		--Position in the data-out array
signal one_cnt		: natural range 0 to 5;					--Number of '1's that has been counted. Each bit will be sampled 5 times
signal parity_bit	: std_logic;							--parity bit value
signal parity_err_i	: std_logic; 							--Internal parity bit
------------------	Processes	----------------

begin

	-----------------------------------------------------------------------------
	-------------------		din_samp_proc Process  	-----------------------------
	-----------------------------------------------------------------------------
	-- The process prevent from metastability situation to enter the UART logic.
	-----------------------------------------------------------------------------
	din_samp_proc : process ( clk, reset )
	begin
		if reset = reset_polarity_g then	
			din_d1		<= uart_idle_g;
			din_d2		<= uart_idle_g;
		elsif rising_edge (clk) then
			din_d1		<= din;
			din_d2		<= din_d1;
		end if;
	end process din_samp_proc;
	
	-----------------------------------------------------------------------------
	-------------------		uart_fsm_proc Process  	-----------------------------
	-----------------------------------------------------------------------------
	-- The process is the main FSM of the UART
	-----------------------------------------------------------------------------
	uart_fsm_proc : process ( clk, reset )
	begin
		if reset = reset_polarity_g then	--System reset
			cur_st 			<= IDLE_ST;
			dout			<= (others => '0');
			dout_i			<= (others => '0');
			valid			<= '0';
			parity_err 		<= '0';
			parity_err_i	<= '0';
			stop_bit_err	<= '0';
			pos_cnt			<= 0;
			one_cnt			<= 0;
			sample_cnt		<= 0;
			parity_bit 		<= '0';
			
		elsif rising_edge (clk) then
			case cur_st is
				when IDLE_ST =>	--Wait for start bit
							--Reset parameters
							dout_i			<= (others => '0');
							valid			<= '0';
							parity_err 		<= '0';
							parity_err_i	<= '0';
							stop_bit_err	<= '0';
							parity_bit 		<= '0';
							pos_cnt			<= 0;
							
							--Look for start bit
							if (din_d2 = not uart_idle_g) and (one_cnt < 5) then --5 start bits required. Spike Robustness
								one_cnt <= one_cnt + 1;
							elsif (one_cnt > 0) and (one_cnt < 5) then
								one_cnt <= one_cnt - 1;
							end if;
							
							if (one_cnt = 5) then
								if sample_cnt = clk_div_factor/2 then --Middle of bit
									cur_st 		<= STARTBIT_ST;
									sample_cnt 	<= one_cnt + 1;
									one_cnt		<= 0;
								else 								  --Wait for more samples to be sampled
									cur_st 		<= IDLE_ST;
									sample_cnt 	<= sample_cnt + 1;
									one_cnt		<= one_cnt;
								end if;
							else
								sample_cnt 	<= sample_cnt;
								cur_st 		<= IDLE_ST;
							end if;
				
				when STARTBIT_ST =>								  --First bit (start bit)
							dout_i			<= (others => '0');
							valid			<= '0';
							parity_err 		<= '0';
							parity_err_i	<= '0';
							stop_bit_err	<= '0';
							parity_bit 		<= '0';								
							pos_cnt			<= 0;
							one_cnt			<= 0;
							
							if sample_cnt = clk_div_factor then   --Start of first bit
								sample_cnt 		<= 0;								
								cur_st 			<= RX_ST;
							else 
								cur_st		<= STARTBIT_ST;
								sample_cnt 	<= sample_cnt + 1;
							end if;

				when RX_ST =>	--Recieve data
							valid			<= '0';
							parity_err 		<= '0';
							parity_err_i	<= '0';
							stop_bit_err	<= '0';
								
							if (sample_cnt >= 0) and (sample_cnt <= 4) then
								if din_d2 = '1' then
									one_cnt <= one_cnt + 1; --Count number of '1's
								end if;						
								
							elsif sample_cnt = 5 then 	--5 samples has been taken
								dout_i (databits_g - 2 downto 0) <= dout_i (databits_g - 1 downto 1);
								if one_cnt > 2 then 	--'1' in input
									dout_i (databits_g - 1) <= '1';
								else 					--'0' in input
									dout_i (databits_g - 1) <= '0';
								end if;
								
								pos_cnt <= pos_cnt + 1;	 	--Bit number in output data
							end if;

							sample_cnt 	<= sample_cnt + 1; 	--Increment number of samples
							-----------------
							
							if sample_cnt = clk_div_factor then --Current position is next data (or parity / stop) bit
								sample_cnt 	<= 0;
								one_cnt 	<= 0;
								if (pos_cnt = databits_g) then --End of data recieve. Next step: stop bit / parity bit
									if (parity_en_g = 1) then --parity enabled
										if parity_odd_g then
											parity_bit <= xor_reduce(dout_i(databits_g -1 downto 0));
										else
											parity_bit <= xnor_reduce(dout_i(databits_g -1 downto 0));
										end if;
										cur_st <= PARITY_ST;
									else 
										cur_st <= STOPBIT_ST;
									end if;
								else
									cur_st <= RX_ST;
								end if;
							end if;
				
				when PARITY_ST =>
							valid			<= '0';
							stop_bit_err	<= '0';
							parity_bit 		<= parity_bit;
							pos_cnt			<= 0;							
								
							if (sample_cnt >=0) and (sample_cnt <= 4) then	--counting samples
								if din_d2 = '1' then 							--'1' has been detected
									one_cnt <= one_cnt + 1;
								end if;
								
							elsif sample_cnt = 5 then
								if (not parity_odd_g) then --Odd parity
									if (one_cnt > 2 and parity_bit /= '1') or (one_cnt < 3 and parity_bit /= '0') then -- comparing the sampeled din_d2 with parity value calculated in RX_ST
											parity_err 		<= '1';				-- parity bit error
											parity_err_i	<= '1';				-- Internal parity bit error, for not asserting 'valid'
									else
											parity_err 		<= '0';
											parity_err_i	<= '0';
									end if;
								else		 				--Even parity
									if (one_cnt > 2 and parity_bit /= '0') or (one_cnt < 3 and parity_bit /= '1') then -- comparing the sampeled din_d2 with parity value calculated in RX_ST
											parity_err 		<= '1';				-- parity bit error
											parity_err_i	<= '1';				-- Internal parity bit error, for not asserting 'valid'
									else
											parity_err 		<= '0';
											parity_err_i	<= '0';
									end if;
								end if;
							end if;
									
							
							-- Keep counting until next bit (stop bit) position is achieved
							
							if sample_cnt = clk_div_factor then
								sample_cnt 		<= 0;
								one_cnt 		<= 0;
								cur_st 			<= STOPBIT_ST;
							else
								sample_cnt <= sample_cnt + 1;
							end if;

				when STOPBIT_ST =>
							pos_cnt			<= 0;
							parity_bit 		<= '0';
								
							if (sample_cnt >= 0) and (sample_cnt <= 4) then
								if din_d2 = uart_idle_g then --Stop bit has been detected
									one_cnt <= one_cnt + 1; --here one_cnt is number of stop_bits
								end if;
								
							elsif sample_cnt = 5 then
								if one_cnt < 3 then --Not enough stop bits have been detected
									stop_bit_err 	<= '1';
									sample_cnt 		<= 0;
									cur_st <= IDLE_ST; --Back to IDLE_ST
								end if;					
							end if;
							
							sample_cnt <= sample_cnt + 1; 
							
							--End of transaction
							if (sample_cnt = clk_div_factor/2) or ((sample_cnt > 5) and (din_d2 /= uart_idle_g)) then
								sample_cnt 	<= 0;
								one_cnt 	<= 0;											
								if parity_err_i = '0' then --There is not parity bit error
									dout 	<= dout_i;
									valid 	<= '1';
								end if;
								cur_st 	<= IDLE_ST;
							else 
								cur_st <= STOPBIT_ST;
							end if;
							
				when others => --This should never happen, since all states are covered
							cur_st 			<= IDLE_ST;
							stop_bit_err	<= '1';	--Assert both errors, since general error has occured
							parity_err		<= '1';
							report "Time: " & time'image(now) & ", UART RX_ST: Unknown state in state machine"
							severity error;
							
				end case;
		end if;
	end process uart_fsm_proc;
	
end architecture arc_uart_rx;
			