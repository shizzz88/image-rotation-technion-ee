------------------------------------------------------------------------------------------------
-- Model Name 	:	UART Transmitter
-- File Name	:	uart_tx.vhd
-- Generated	:	27.11.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: This block implements the UART Transmitter
-- 		The unit receives Parallel data and produces serial data.
--		It receives data from a FIFO. Only when the FIFO is not empty and rising it's valid flag parallel data is ready to enter, data is entered 
--		a Shift register, and pull out of it with a right shift every clock.
--	Generic:
-- 		The user can choose to change the following characteristic:
--				1. Parity mode - if enabled and if so odd or even
--				2. UART's Baudrate - set to 115200 Kbit/sec
--				3. Clk's rate - set to 133 MHz
--				4. Bits polarity - Reset polarity and start bit polarity
--				5. Start bit entrance
--				6. Data bits length - 5-8 data bits
--
--  The unit output data is serial.
--  System clock and Reset are provided to the unit.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name				Description
--			1.00		27.11.2010	Alon Yavich			Creation
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--	Todo:
--			 
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;

entity uart_tx is
   generic (
			 parity_en_g		:		natural	range 0 to 1 := 1; 		--Enable parity bit = 1, parity disabled = 0
			 parity_odd_g		:		boolean 	:= false;			--TRUE = odd, FALSE = even
			 uart_idle_g		:		std_logic 	:= '1';				--Idle line value
			 baudrate_g			:		positive	:= 115200;			--UART baudrate [Hz]
			 clkrate_g			:		positive	:= 133000000;		--Sys. clock [Hz]
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
end entity uart_tx;

architecture arc_uart_tx of uart_tx is

------------------  	Constants	------
constant clk_div_factor		: positive := clkrate_g / baudrate_g;		--Clock Divide factor

------------------  	Types		------

-- Main FSM
type uart_tx_fsm_states is (	IDLE_ST,		--Waits for Valid from FIFO
								REGDATA_ST,		--FIFO ready
								TX_ST			--Transmits all UART bits & Count 1 UART clock period in between each bit
							);       


------------------  	Singals		------
signal cur_st 		: uart_tx_fsm_states;					 						--Final State Machine
signal pos_cnt 		: natural range 0 to databits_g+parity_en_g+1;		 			--Position in the data-in array
signal sample_cnt	: natural range 1 to clk_div_factor; 	 						--Sample counter - for UART clock
signal uart_clk		: std_logic; 							 						--UART clock
signal sr			: std_logic_vector (databits_g + parity_en_g + 1 downto 0 );	--Shift register

------------------	Processes	------------------
begin
	
	uart_clk_proc : process (clk, reset) 			--Counts one bit time length
	begin
		if reset = reset_polarity_g then
			sample_cnt <= 1;
			uart_clk   <= '0';			
			
		elsif rising_edge(clk) then
			if (cur_st = TX_ST) then 
				if sample_cnt = clk_div_factor then
					uart_clk 	<= '1';
					sample_cnt 	<= 1;
				else
					uart_clk 	<= '0';
					sample_cnt 	<= sample_cnt + 1;
				end if;		
			else
				uart_clk 	<= '0';
				sample_cnt 	<= 1;
			end if ;
		end if;
	end process uart_clk_proc;
	
-------------------------------------------------	
	uart_fsm_proc : process ( clk, reset )
	begin
		if reset = reset_polarity_g then	--System reset
			cur_st			<= IDLE_ST;
			pos_cnt			<= 0;
			fifo_rd_en 		<= '0';
			
			elsif rising_edge (clk) then
				case cur_st is
					when IDLE_ST => 			--Waits for not an empty FIFO
							
						---------------  Waiting For Valid from FIFO  -------------------------
							
							pos_cnt			<= 0;
							
							if fifo_empty = '0' then		
								fifo_rd_en 	<= '1';	--Data can be read from FIFO
								cur_st 		<= REGDATA_ST;
							else
								fifo_rd_en 	<= '0';
								cur_st 		<= IDLE_ST;
							end if;
			
					when REGDATA_ST	=>		--FIFO data is ready
							
							fifo_rd_en 	<= '0';
							pos_cnt	  	<= 0;
							
							if fifo_din_valid = '1' then
								cur_st <= TX_ST;
							else
								cur_st <= REGDATA_ST;
							end if;
					
					when TX_ST => 
							
						---------------  Sending all UART bits  -------------------------
						fifo_rd_en <= '0';
						if uart_clk = '1' then
							if pos_cnt = databits_g + parity_en_g + 1 then
								cur_st  <= IDLE_ST;
								pos_cnt <= 0;	
							else
								cur_st 	<= TX_ST;
								pos_cnt <= pos_cnt + 1;
							end if;
						else
							cur_st 	<= TX_ST;
							pos_cnt <= pos_cnt;
						end if;
				
						---------------  Error  ---------------------------
					
					when others => --This should never happen, since all states are covered
							cur_st 			<= IDLE_ST;
							pos_cnt			<= 0;
							fifo_rd_en 		<= '0';
							report "Time: " & time'image(now) & ", UART TX_ST: Unknown state in state machine"
							severity error;
					
				end case;
		end if;
	end process uart_fsm_proc;
		
	-----------------	
	tx_proc : process (clk, reset)		--Entering data into shift register
	begin
		if (reset = reset_polarity_g) then
			sr		   <= (0 => uart_idle_g, others => '0');
			dout	   <= uart_idle_g;
		elsif rising_edge(clk) then
			dout 		<= sr(0);
			if (cur_st = REGDATA_ST) then
				if fifo_din_valid = '1' then
					sr(0)					<= not uart_idle_g;						--Start Bit
					sr(databits_g downto 1) <= din(databits_g -1 downto 0);			--Data byte enters the sr
					if parity_en_g = 0 then
						sr(databits_g + 1) <= uart_idle_g;							--Stop bit
					else
						if parity_odd_g then
							sr(databits_g + 1) <= xor_reduce(din(databits_g -1 downto 0)); --Calculate parity
						else
							sr(databits_g + 1) <= xnor_reduce(din(databits_g -1 downto 0));--Calculate parity
						end if ;
						sr(databits_g + 2) <= uart_idle_g;							-- Stop bit
					end if ;
				end if;	
			elsif ((cur_st = TX_ST) and (uart_clk = '1')) then
				sr 	<= uart_idle_g & sr(databits_g + parity_en_g + 1 downto 1)  ;	--Shift Right
			end if;
		end if;
	end process tx_proc;
								
end architecture arc_uart_tx;
