------------------------------------------------------------------------------------------------
-- Model Name 	:	General FIFO
-- File Name	:	general_fifo.vhd
-- Generated	:	22.4.2004
-- Author		:	Eyal Hamburger
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The file implements a General FIFO, with generic number of elements.
-- 				It is possible to read and write at the same clock.
--				Available indication outputs:
--				(1) FIFO Full
--				(2) FIFO Empty
--				(3) FIFO Almost Full
--				(4) FIFO Almost Empty
--				(5) Current elements in FIFO
--
--				When data is being read, a 'dout_valid' flag will be rised, when the data
--				is valid.
--				
--				|------|
--				| data |	-- FIFO Full
--				|------|
--				| data |	-- FIFO Almost Full
--				|------|
--				.      .
--				.      .
--				.      .
--				|------|
--				| data |	-- FIFO Almost Empty
--				|------|
--				| data |	-- FIFO Empty
--				|------|
--				
-- Important Notes:
-- ----------------
--			(1) When FIFO is empty, if read and write are performed together - only WRITE will be 
--				performed, and READ will be ignored.
--			(2) When FIFO is full, if read and write are performed together - only READ will be
--				performed, and WRITE will be ignored.
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		22.4.2004	Eyal Hamburger		Creation
--			1.1			21.12.2010	Beeri Schreiber		(1) Change of signals names
--														(2) dout_valid has been added
--														(3) Added description
--			1.2			10.10.2011	Omer Shaked			(1) Fixed dout_valid bug: always low
--															when the fifo is empty
--														(2)	Added description
------------------------------------------------------------------------------------------------
--	Todo:
--	(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 

entity general_fifo is 
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
		 flush		: in	std_logic;									-- Flush data
		 dout 		: out 	std_logic_vector (width_g-1 downto 0);	    -- Output Data
		 dout_valid	: out 	std_logic;                                  -- Output data is valid
		 afull  	: out 	std_logic;                                  -- FIFO is almost full
		 full 		: out 	std_logic;	                                -- FIFO is full
		 aempty 	: out 	std_logic;                                  -- FIFO is almost empty
		 empty 		: out 	std_logic;                                  -- FIFO is empty
		 used 		: out 	std_logic_vector (log_depth_g  downto 0) 	-- Current number of elements is FIFO. Note the range. In case depth_g is 2^x, then the extra bit will be used
	     );
end entity general_fifo;

architecture arc_general_fifo of general_fifo is

--------------------------------- Types ------------------------------------------------------------------
type memory_type is array(0 to depth_g - 1) of std_logic_vector(width_g - 1 downto 0);

--------------------------------- Constants --------------------------------------------------------------
constant zero 			: std_logic_vector(depth_g downto 0) := (others => '0');

--------------------------------- Signals ----------------------------------------------------------------
signal mem 				: memory_type;  	 					--FIFO Data

signal write_addr 		: natural range 0 to depth_g - 1;		--Write address to FIFO
signal read_addr 		: natural range 0 to depth_g - 1;		--Read address from FIFO
signal read_addr_dup 	: natural range 0 to depth_g - 1;		--Duplicated Read address. Delayed by 1 clock after read_addr
signal count 			: natural range 0 to depth_g ;			--Current elements in FIFO	

signal ifull 			: std_logic;							--Internal FIFO Full signal
signal iempty 			: std_logic;							--Internal FIFO Empty signal

begin

	--------------------------------------------------
	-------------- Process data_valid_proc -----------
	--------------------------------------------------
	-- The process rises the 'data_valid' flag when
	-- output data is valid.
	--------------------------------------------------	
	data_valid_proc: process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			dout_valid		<= '0';
		elsif rising_edge (clk) then
			if (rd_en = '1') and (iempty = '0') then
				dout_valid 	<= '1';
			else
				dout_valid 	<= '0';
			end if;
		end if;
	end process data_valid_proc;

	--------------------------------------------------
	-------- Process read_addr_dup_proc --------------
	--------------------------------------------------
	-- The process is the duplicated read_addr
	-- signal assignment, which comes in one clock
	-- delay after read_addr.
	--------------------------------------------------	
	read_addr_dup_proc : process (clk, rst)
	begin
		if (rst = reset_polarity_g) then
			read_addr_dup 	<= 0;							--Switch to first read address in FIFO
		elsif rising_edge (clk) then
				--Read from FIFO when FIFO is not empty
				--Note that this read address (read_addr_dup) is delayed by one clock
				--from the request, to supply the current requested data, instead of the next one.
			if (flush = '1') then
				read_addr_dup 	<= 0;							--Switch to first read address in FIFO
			else
				if (rd_en = '1') and (iempty = '0') then
					if (read_addr = depth_g - 1 ) then 			--Read Address = last address is FIFO
						read_addr_dup 	<= 0;					--Switch to first read address in FIFO
					else
						read_addr_dup 	<= read_addr + 1;		--Increment read address in FIFO by 1
					end if;
				else
					read_addr_dup 		<= read_addr;			--FIFO empty / on read => keep current read address
				end if;
			end if;
		end if;
	end process read_addr_dup_proc;
	
	--------------------------------------------------
	-------------- Process din_proc ------------------
	--------------------------------------------------
	-- The process writes a new data to the FIFO
	-- when wr_en = '1', when FIFO is not full
	--------------------------------------------------	
	din_proc: process(clk)	 
	begin  
		if (rising_edge(clk)) then 
			--Write data to FIFO
			if (wr_en='1') and (ifull = '0') then
				mem(write_addr) <= din;
			end if;
		end if;
	end process din_proc;
	
	--------------------------------------------------
	-------------- Process dout_proc -----------------
	--------------------------------------------------
	-- The process reads data when rd_en = '1'
	-- and FIFO is not empty.
	--------------------------------------------------	
	dout_proc: process(clk)	 
	begin  
		if (rising_edge(clk)) then 
			--Read data from FIFO
			if (rd_en = '1') then
				dout 	<= mem(read_addr_dup);
			end if;
		end if;
	end process dout_proc;	

	---------------------------------------------------
	-------------- Process addr_proc ------------------
	---------------------------------------------------
	-- The process places the new read/write address
	-- at the appropriate position
	---------------------------------------------------	
	addr_proc: process(rst,clk)	 
	begin  
		if (rst = reset_polarity_g) then
			write_addr 	<= 0;
			read_addr 	<= 0;
		elsif rising_edge(clk) then 
			if (flush = '1') then
				write_addr 	<= 0;
				read_addr 	<= 0;
			else
				--Write to FIFO - FIFO is not full
				if (wr_en = '1') and (ifull = '0') then
					if (write_addr = depth_g - 1) then	--Write Address = last address in FIFO
						write_addr <= 0;					--Switch to first address in FIFO
					else
						write_addr <= write_addr + 1;		--Increment write address by 1
					end if;
				end if;

				--Read from FIFO when FIFO is not empty
				if (rd_en = '1') and (iempty = '0') then	--Read Address = last address is FIFO
					if (read_addr= depth_g - 1) then	--Switch to first read address in FIFO
						read_addr <= 0;                     
					else                                    --Increment read address in FIFO by 1
						read_addr <= read_addr + 1;         
					end if;                                 
				end if;                                     --FIFO empty / on read => keep current read address
			end if;
		end if;
	end process addr_proc;	

	---------------------------------------------------
	-------------- Process count_proc -----------------
	---------------------------------------------------
	-- The process counts the current elements in the
	-- FIFO.
	---------------------------------------------------	
	count_proc: process(rst,clk)	 
	begin  
		if (rst = reset_polarity_g) then 
			count <= 0;
		elsif rising_edge(clk) then 
			if (flush = '1') then
				count 	<= 0;
			else
				if (wr_en = '1') and (rd_en = '1') and (ifull = '0') then 	--Both read and write
					if (iempty	=	'1') then -- Only write is being performed
						count	<=	count + 1;
					else
						count <= count;
					end if;
				elsif (wr_en = '1') and (ifull = '0') then					--Write
					count <= count + 1;
				elsif ((rd_en='1') and (iempty='0')) then					--Read
					count <= count - 1;
				end if;
			end if;
		end if;
	end process count_proc;	

	---------------------------------------------------
	-------------- Hidden Proccesses ------------------
	---------------------------------------------------
	-- Internal Flags
	fifo_empty_proc:
	iempty	<= '1' when (count = zero) else '0';
	
	fifo_full_proc:
	ifull 	<= '1' when (count = depth_g) else '0';
	 
	-- Output Flags
	fifo_almost_full_proc:
	afull	<= '1' when (count >= almost_full_g) else '0';
	
	fifo_almost_empty_proc:
	aempty	<= '1' when (count <= almost_empty_g) else '0';
	
	output_full_proc:
	full	<= ifull;
	
	output_empty_proc:
	empty	<= iempty;
	
	used_elements_proc:
	used	<= conv_std_logic_vector(count, log_depth_g + 1);
		
end architecture arc_general_fifo;