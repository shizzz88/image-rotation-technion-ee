------------------------------------------------------------------------------------------------
-- Model Name 	:	Generic Register
-- File Name	:	gen_reg.vhd
-- Generated	:	10.5.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The generic register is a simple register, with the following capabilities:
--					1. Generic width
--					2. Default value at reset
--					3. Clear register (set to default value)
--					4. Clear on read  (set to default value when reading register)
--					5. Write only / Read only
--					6. Enabling or disabling addressing to the register:
--						a. When enabled: register respond only when it is addressed.
--						b. When enabled: dout_valid will raise when the register is addressed.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		10.5.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity gen_reg is
	generic	(
			reset_polarity_g	:	std_logic	:= '0';					--When reset = reset_polarity_g, system is in RESET mode
			width_g				:	positive	:= 8;					--Width: Number of bits
			addr_en_g			:	boolean		:= true;				--TRUE: Address enabled  - responde by register will occur only when specific address has been specified
			addr_val_g			:	natural		:= 0;					--Default register address
			addr_width_g		:	positive	:= 4;					--2^4 = 16 register address is supported
			read_en_g			:	boolean		:= true;				--Enabling read
			write_en_g			:	boolean		:= true;				--Enabling write
			clear_on_read_g		:	boolean		:= false;				--TRUE: Clear on read (set to default value), FALSE otherwise
			default_value_g		:	natural		:= 0					--Default value of register
			);
	port	(
			--Clock and Reset
			clk				:	in std_logic;									--Clock
			reset			:	in std_logic;									--Reset

			--Address
			addr			:	in std_logic_vector (addr_width_g - 1 downto 0);--Address to register. Relevant only when addr_en_g = true
			
			--Input data handshake
			din				:	in std_logic_vector (width_g - 1 downto 0);		--Input data
			wr_en			:	in std_logic;									--Input data is valid
			clear			:	in std_logic;									--Set register value to its default value.
			din_ack			:	out std_logic;									--Data has been acknowledged
			
			--Output data handshake
			rd_en			:	in std_logic;									--Output data request
			dout			:	out std_logic_vector (width_g - 1 downto 0);	--Output data
			dout_valid		:	out std_logic									--Output data is valid
			);
end entity gen_reg;

architecture rtl_gen_reg of gen_reg is
	---------------------------------  Signals	----------------------------------
	signal reg_data		:	std_logic_vector (width_g - 1 downto 0);
	
	---------------------------------  Implementation	--------------------------
begin
	
	--Output value
	dout_proc:
	dout	<=	reg_data;

	------------------------------------------------------------------------------
	-----------------------		write_proc Process			----------------------
	------------------------------------------------------------------------------
	-- The process writes data to the FF
	------------------------------------------------------------------------------
	write_proc: process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			reg_data			<=	conv_std_logic_vector (default_value_g, width_g);
			din_ack				<=	'0';
		elsif rising_edge(clk) then
			if (addr = conv_std_logic_vector(addr_val_g, addr_width_g)) or (not addr_en_g) then
				if (clear = '1') then							--Clear register's value
					reg_data	<=	conv_std_logic_vector (default_value_g, width_g);
					din_ack		<=	'1';						--Command has been accepted
				elsif (clear_on_read_g and (rd_en = '1')) then	--Clear on read
					reg_data	<=	conv_std_logic_vector (default_value_g, width_g);
					din_ack		<=	'0';						--Command has been accepted
				elsif (wr_en = '1') and write_en_g then			--New data
					reg_data	<= din;	
					din_ack		<=	'1';						--Command has been accepted
				else											--Keep last value
					reg_data	<= reg_data;				
					din_ack		<=	'0';						--Command is not for this register
				end if;
			else
				reg_data		<= reg_data;
				din_ack			<=	'0';
			end if;
		end if;
	end process write_proc;

	------------------------------------------------------------------------------
	-----------------------		dout_val_proc Process		----------------------
	------------------------------------------------------------------------------
	-- The process controls the dout_valid signal
	------------------------------------------------------------------------------
	dout_val_proc: process (clk, reset)
	begin
		if (reset = reset_polarity_g) then
			dout_valid			<=	'0';
		elsif rising_edge(clk) then
			if ((addr = conv_std_logic_vector(addr_val_g, addr_width_g)) or (not addr_en_g))
			and (rd_en = '1') and read_en_g then
				dout_valid		<= '1';
			else
				dout_valid		<= '0';
			end if;
		end if;
	end process dout_val_proc;

end architecture rtl_gen_reg;
			