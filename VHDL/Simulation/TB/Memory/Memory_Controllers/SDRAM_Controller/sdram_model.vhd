library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_ARITH.all;
USE ieee.std_logic_textio.all;

LIBRARY std ;
USE std.textio.all;


ENTITY SDRAM_MODEL IS
	GENERIC (
		addr_bits : INTEGER := 12;
		data_bits : INTEGER := 16 ;
		col_bits  : INTEGER := 8
		);
	PORT (
		Dq		: INOUT STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => 'Z');
		Addr    : IN    STD_LOGIC_VECTOR (11 DOWNTO 0) ;-- := (OTHERS => '0');
		Ba      : IN    STD_LOGIC_VECTOR(1 DOWNTO 0);-- := "00";
		Clk     : IN    STD_LOGIC ;--:= '0';
		Cke     : IN    STD_LOGIC ;--:= '0';
		Cs      : IN    STD_LOGIC ;--:= '1';
		Ras     : IN    STD_LOGIC ;--:= '0';
		Cas     : IN    STD_LOGIC ;--:= '0';
		We      : IN    STD_LOGIC ;--:= '0';
		Dqm     : IN    STD_LOGIC_VECTOR(1 DOWNTO 0)-- := (OTHERS => 'Z')
		);
	
END ;


ARCHITECTURE SDRAM_MODEL OF SDRAM_MODEL IS
	
	-- ##############   TYPE   #######################################
	
	TYPE ram_type 	IS ARRAY (2**col_bits - 1 DOWNTO 0) OF STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0);
	TYPE ram_pntr 	IS ACCESS ram_type;
	TYPE ram_store 	IS ARRAY (2**addr_bits - 1 DOWNTO 0) OF ram_pntr;
	TYPE SDRAM_COMM_TYPE	 IS (NOP,ACTIVE,READ,WRITE,TERMINATE,PRECHARGE,REF,LOAD_MODE);
	-- ##############   VARIABLE   ###################################
	
	SHARED VARIABLE Bank0 : ram_store;
	SHARED VARIABLE Bank1 : ram_store;
	SHARED VARIABLE Bank2 : ram_store;
	SHARED VARIABLE Bank3 : ram_store;
	SHARED VARIABLE bank_index,Row_index, Col_index : INTEGER := 0;
	SHARED VARIABLE current_data : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
	--	SHARED VARIABLE	valid_do, do_en,do_en1,do_en2,do_en3,do_en4 : BOOLEAN;
	SHARED VARIABLE	valid_do : BOOLEAN;
	SHARED VARIABLE latency_pipe,latency_pipe1,latency_pipe2,latency_pipe3,latency_pipe4   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	-- ##############   SIGNALS   ###################################
	SIGNAL  curr_sd_val,curr_sd_val1,curr_sd_val2   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	do_en,do_en1,do_en2,do_en3,do_en4 : BOOLEAN;
	
	-- ##############   FUNCTIONS   ##################################
	
	FUNCTION conv_sd_command (
		we 	: STD_LOGIC;
		cas : STD_LOGIC;
		ras : STD_LOGIC ) RETURN SDRAM_COMM_TYPE IS
		VARIABLE    com_vector : STD_LOGIC_VECTOR(2 DOWNTO 0);
	BEGIN
		com_vector := ras & cas & we;
		CASE (com_vector) IS
			WHEN "000" =>       RETURN LOAD_MODE;
			WHEN "001" =>       RETURN REF;
			WHEN "010" =>       RETURN PRECHARGE;
			WHEN "011" =>       RETURN ACTIVE;
			WHEN "100" =>       RETURN WRITE;
			WHEN "101" =>       RETURN READ;
			WHEN "110" =>       RETURN TERMINATE;
			WHEN "111" =>       RETURN NOP;
			WHEN OTHERS =>  RETURN NOP;
		END CASE;        
	END FUNCTION conv_sd_command;
	
	
	
	-- ##############   PROCEDURE   ##################################
	PROCEDURE RD_RAM (
		bank_no		: IN  STD_LOGIC_VECTOR;
		data     	: OUT STD_LOGIC_VECTOR;
		--        dqm_mask 	: IN STD_LOGIC_VECTOR;
		valid_do 	: OUT BOOLEAN;
		row_addr 	: IN  STD_LOGIC_VECTOR;
		col_addr 	: IN  STD_LOGIC_VECTOR) IS
	BEGIN
		Row_index  := CONV_INTEGER(UNSIGNED(row_addr));
		Col_index  := CONV_INTEGER(UNSIGNED(Col_addr(7 DOWNTO 0)));
		bank_index := CONV_INTEGER(UNSIGNED(bank_no));
		valid_do := FALSE;
		CASE bank_index IS 
			WHEN 0 =>
			IF Bank0(Row_index) /= NULL THEN              -- Check to see if row empty
				data := Bank0(Row_index)(Col_index);
				valid_do := TRUE;
			END IF;
			WHEN 1 =>
			IF Bank1(Row_index) /= NULL THEN              -- Check to see if row empty
				data := Bank1(Row_index)(Col_index);
				valid_do := TRUE;
			END IF;
			WHEN 2 =>
			IF Bank2(Row_index) /= NULL THEN              -- Check to see if row empty
				data := Bank2(Row_index)(Col_index);
				valid_do := TRUE;
			END IF;
			WHEN 3 =>
			IF Bank3(Row_index) /= NULL THEN              -- Check to see if row empty
				data := Bank3(Row_index)(Col_index);
				valid_do := TRUE;
			END IF;
			WHEN OTHERS =>
			REPORT "WRONG BANK NO"
			SEVERITY ERROR ;
		END CASE;
	END RD_RAM;
	
	-- ====================================================
	-- ====================================================
	
	PROCEDURE WR_RAM (
		bank_no 	: IN STD_LOGIC_VECTOR;
		data    	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		dqm_mask 	: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		row_addr  	: IN STD_LOGIC_VECTOR;
		col_addr  	: IN STD_LOGIC_VECTOR)  IS
		VARIABLE cur_data : STD_LOGIC_VECTOR (15 DOWNTO 0) ;
		
	BEGIN
		
		Row_index  := CONV_INTEGER(UNSIGNED(row_addr));
		Col_index  := CONV_INTEGER(UNSIGNED(Col_addr(7 DOWNTO 0)));
		bank_index := CONV_INTEGER(UNSIGNED(bank_no));
		CASE bank_index IS   -- open and Fill new row with zeros then wr data    
			WHEN 0 =>
			IF Bank0(Row_index) = NULL THEN              -- Check to see if row empty
				Bank0 (Row_index) := NEW ram_type;       -- Open new row for access
				FOR i IN (2**col_bits - 1) DOWNTO 0 LOOP -- Filled row with zeros
					Bank0(Row_index)(i) := (OTHERS=>'1'); -- ????????????????????
				END LOOP;
			END IF;
			cur_data := Bank0 (Row_index)(Col_index);
			IF dqm_mask(1) = '0' THEN  cur_data(15 DOWNTO 8) := data(15 DOWNTO 8); END IF;
			IF dqm_mask(0) = '0' THEN  cur_data(7 DOWNTO 0) := data(7 DOWNTO 0); END IF;
			Bank0 (Row_index)(Col_index) :=cur_data;
			WHEN 1 =>	
			IF Bank1(Row_index) = NULL THEN              -- Check to see if row empty
				Bank1 (Row_index) := NEW ram_type;       -- Open new row for access
				FOR i IN (2**col_bits - 1) DOWNTO 0 LOOP -- Filled row with zeros
					Bank1(Row_index)(i) := (OTHERS=>'1');
				END LOOP;
			END IF;
			cur_data := Bank1 (Row_index)(Col_index);
			IF dqm_mask(1) = '0' THEN  cur_data(15 DOWNTO 8) := data(15 DOWNTO 8); END IF;
			IF dqm_mask(0) = '0' THEN  cur_data(7 DOWNTO 0) := data(7 DOWNTO 0); END IF;
			Bank1 (Row_index)(Col_index) :=cur_data;
			WHEN 2 =>
			IF Bank2(Row_index) = NULL THEN              -- Check to see if row empty
				Bank2 (Row_index) := NEW ram_type;       -- Open new row for access
				FOR i IN (2**col_bits - 1) DOWNTO 0 LOOP -- Filled row with zeros
					Bank2(Row_index)(i) := (OTHERS=>'1');
				END LOOP;
			END IF;
			cur_data := Bank2 (Row_index)(Col_index);
			IF dqm_mask(1) = '0' THEN  cur_data(15 DOWNTO 8) := data(15 DOWNTO 8); END IF;
			IF dqm_mask(0) = '0' THEN  cur_data(7 DOWNTO 0) := data(7 DOWNTO 0); END IF;
			Bank2 (Row_index)(Col_index) :=cur_data;
			WHEN 3 =>
			IF Bank3(Row_index) = NULL THEN              -- Check to see if row empty
				Bank3 (Row_index) := NEW ram_type;       -- Open new row for access
				FOR i IN (2**col_bits - 1) DOWNTO 0 LOOP -- Filled row with zeros
					Bank3(Row_index)(i) := (OTHERS=>'1');
				END LOOP;
			END IF;
			cur_data := Bank3 (Row_index)(Col_index);
			IF dqm_mask(1) = '0' THEN  cur_data(15 DOWNTO 8) := data(15 DOWNTO 8); END IF;
			IF dqm_mask(0) = '0' THEN  cur_data(7 DOWNTO 0) := data(7 DOWNTO 0); END IF;
			Bank3 (Row_index)(Col_index) :=cur_data;
			WHEN OTHERS	=>
			REPORT "WRONG BANK NO"
			SEVERITY ERROR ;
		END CASE;
		
	END PROCEDURE WR_RAM;	-- WR_RAM
	
	
	-- ==================================	
--	-- ==================================	
	PROCEDURE fill_proc (
		burst_addr 	 : IN  STD_LOGIC_VECTOR(21 DOWNTO 0);
		burst_data 	 : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		burst_length : IN  NATURAL) IS
		
		VARIABLE curr_sdram_val : STD_LOGIC_VECTOR(15 DOWNTO 0); 
		VARIABLE curr_sdram_add : STD_LOGIC_VECTOR(21 DOWNTO 0); 
		ALIAS row_add 	:STD_LOGIC_VECTOR(11 DOWNTO 0) IS curr_sdram_add(19 DOWNTO 8);
		ALIAS ba	 	:STD_LOGIC_VECTOR(1 DOWNTO 0) IS curr_sdram_add(21 DOWNTO 20);
		ALIAS col_add 	:STD_LOGIC_VECTOR(7 DOWNTO 0) IS curr_sdram_add(7 DOWNTO 0);
	BEGIN
		curr_sdram_val := burst_data;
		curr_sdram_add := burst_addr;
		FOR len IN 1 TO burst_length LOOP	   -- burst counter
			WR_RAM(	bank_no  => ba, 
			data     =>	curr_sdram_val,
			dqm_mask => "00",
			row_addr => row_add,
			col_addr => col_add);
			curr_sdram_add := curr_sdram_add + x"10";
--			curr_sdram_val := STD_LOGIC_VECTOR(UNSIGNED(curr_sdram_val) + 1);
		END LOOP;
	END PROCEDURE fill_proc;	-- fill_proc
	
	-- ==================================	
--	-- ==================================	
	
	-- ################################################################	
BEGIN
	
	latency_pipe_proc:	
		PROCESS
	BEGIN
		WAIT UNTIL Clk'EVENT AND Clk = '1' ;
		curr_sd_val1 <= curr_sd_val;   do_en1 <= do_en;
		curr_sd_val2 <= curr_sd_val1;  do_en2 <= do_en1;
	END PROCESS latency_pipe_proc;
	
	Dq    <= curr_sd_val2 WHEN do_en2 ELSE (OTHERS=>'Z');
	
	PROCESS
		VARIABLE burst_row_add   : STD_LOGIC_VECTOR(11 DOWNTO 0);
		VARIABLE burst_col_add   : STD_LOGIC_VECTOR(7 downto 0);
		VARIABLE current_command : SDRAM_COMM_TYPE;
		VARIABLE latancy_pipe	 : STD_LOGIC_VECTOR(15 DOWNTO 0);
	BEGIN
		
		WAIT UNTIL Clk'EVENT AND Clk = '1' AND Cke = '1';
		do_en <= FALSE;
		CASE conv_sd_command(we,cas,ras) IS
			WHEN LOAD_MODE 	 =>
				current_command := LOAD_MODE; 
			WHEN REF       	 =>
				current_command := REF; 
			WHEN PRECHARGE 	 =>
				current_command := PRECHARGE; 
			WHEN ACTIVE    	 =>
				current_command := ACTIVE; 
				burst_row_add := addr;
			WHEN WRITE     	 =>
				current_command := WRITE; 
				burst_col_add   := addr (7 downto 0);
				WR_RAM(	bank_no  => ba, 
				data     =>	dq,
				dqm_mask => Dqm,
				row_addr => burst_row_add,
				col_addr => burst_col_add);
			WHEN READ      	 =>
				current_command := READ;
				burst_col_add   := addr (7 downto 0) - '1'; -- (- '1') is specific to the SDRAM Controller used in the Runlen project
				do_en <= TRUE;
				RD_RAM(	
				bank_no  => ba, 
				data     =>	latency_pipe,
				valid_do => valid_do,
				row_addr => burst_row_add,
				col_addr => burst_col_add);
				
				curr_sd_val <= latency_pipe;
				
			WHEN TERMINATE 	 =>
				current_command := TERMINATE; 
			WHEN NOP       	 =>	
				CASE current_command IS
					WHEN WRITE    	 =>
					burst_col_add  := burst_col_add + '1';
					WR_RAM(	bank_no  => ba, 
					data     =>	dq,
					dqm_mask => Dqm,
					row_addr => burst_row_add,
					col_addr => burst_col_add);
					WHEN READ    	 =>
					burst_col_add  := burst_col_add + '1';
					do_en <= TRUE;
					RD_RAM(	
					bank_no  => ba, 
					data     =>	latency_pipe,
					valid_do => valid_do,
					row_addr => burst_row_add,
					col_addr => burst_col_add);
					
					curr_sd_val <= latency_pipe;
					
					WHEN OTHERS		 => NULL;
				END CASE;
			WHEN OTHERS		 =>
		END CASE;
	END PROCESS;
	
	-- =================================================================
	-- =================================================================
	
END ARCHITECTURE SDRAM_MODEL; 

