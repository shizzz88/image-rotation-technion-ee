------------------------------------------------------------------------------------------------
-- Model Name 	:	TX_PATH
-- File Name	:	tx_path.vhd
-- Generated	:	4.4.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: A comprehensive component that includes all TX's relevant units, in order to work 
--				with Wishbone more easily.
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		4.4.2011	Alon Yavich			Creation
--			1.01		10.8.20011	Alon Yavich			Continuation
------------------------------------------------------------------------------------------------
--	Todo:	 		
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity tx_path is
   generic (
				--------------------- Common generic --------------------------------------------------------
				reset_polarity_g	:	std_logic 	:= '0'; 			--'0' = Active Low, '1' = Active High
				--------------------- mp_Enc's generics --------------------------------------------------------
				len_dec1_g			:	boolean := true;				--TRUE - Recieved length is decreased by 1 ,to save 1 bit
																		--FALSE - Recieved length is the actual length
				sof_d_g				:	positive := 1;					--SOF Depth
				type_d_g			:	positive := 1;					--Type Depth
				addr_d_g			:	positive := 3;					--Address Depth
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
				
				uart_serial_in		:	in std_logic_vector(databits_g -1 downto 0);	--Parallel data in
				uart_serial_out		:	out std_logic; 									--Serial data out		
				--wishbone ports
				rst					:	in std_logic;							--System Reset
				--------------------- Wishbone's common ports --------------------------------------------------------		
				clk_i 				:	in std_logic;							-- wishbone Clock
				--------------------- Wishbones Master's ports --------------------------------------------------------
				wbm_ack_i 			:	in std_logic;							-- When Read Burst: DATA bus must be valid in this cycle
				wbm_stall_i 		:	in std_logic;							-- Slave is not ready to receive new data
				wbm_err_i 			:	in std_logic;							-- Error flag: OOR Burst. Burst length is greater that 256-column address
				wbm_dat_i			:	in std_logic_vector(7 downto 0);		-- Input Data
				wbm_adr_o 			:	out std_logic_vector(9 downto 0);		-- Address 0-1023h
				wbm_cyc_o 			:	out std_logic;							-- Cycle Command to interface
				wbm_stb_o 			:	out std_logic;							-- Strobe Command to interface
				wbm_tga_o 			:	out std_logic_vector(9 downto 0);		-- Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
				wbm_tgc_o 			:	out std_logic;							-- Bus cycle tag: '1' write to REG, '0' write to RAM
				wbm_dat_o			:	out std_logic_vector(7 downto 0);		-- Output Data
				wbm_we_o			:	out std_logic;							-- Write Enable
				--------------------- Wishbones Slave's ports --------------------------------------------------------
				wbs_adr_i			:	in std_logic_vector (9 downto 0);		--Address in internal RAM
				wbs_tga_i			:	in std_logic_vector (9 downto 0);		--Burst Length
				wbs_dat_i			:	in std_logic_vector (7 downto 0);		--Data In (8 bits)
				wbs_cyc_i			:	in std_logic;							--Cycle command from WBM
				wbs_stb_i			:	in std_logic;							--Strobe command from WBM
				wbs_we_i			:	in std_logic;							--Write Enable
				wbs_tgc_i			:	in std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wbs_dat_o			:	out std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wbs_stall_o			:	out std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wbs_ack_o			:	out std_logic;							--Input data has been successfuly acknowledged
				wbs_err_o			:	out std_logic							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
			);	

end entity tx_path;

architecture arc_tx_path of tx_path is

-- ###############################################################################
component uart_tx 
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
end component;
----------------------------------------------------------------------------------
component ram_simple
	generic (
				reset_polarity_g:	std_logic 	:= '0';								--'0' - Active Low Reset, '1' Active High Reset
				width_in_g		:	positive 	:= 8;								--Width of data
				addr_bits_g		:	positive 	:= 10								--Depth of data	(2^10 = 1024 addresses)
			);
	port	(
				clk				:	in std_logic;									--System clock
				rst				:	in std_logic;									--System Reset
				addr_in			:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Output address
				aout_valid		:	in std_logic;									--Output address is valid
				data_in			:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid		:	in std_logic; 									--Input data valid
				data_out		:	out std_logic_vector (width_in_g - 1 downto 0);	--Output data
				dout_valid		:	out std_logic 									--Output data valid
			);
end component;	
----------------------------------------------------------------------------------
component checksum_calc 
   generic 	(
				reset_polarity_g	:	std_logic := '0'; 	--'0' = active low
				signed_checksum_g	:	boolean	:= false;	--TRUE to signed checksum, FALSE to unsigned checksum
				
				--IMPORTANT:
				--In case of a sign number, remmember that the MSB bit is reserved as the sign bit.
				--It means that the input / output data width represent a number sized (width-1)
				checksum_init_val_g	:	integer	:= 0;		--Note that the initial value is given as an natural number, and not STD_LOGIC_VECTOR
				
				--IMPORTANT:
				--checksum_out_width_g must be greater than or equal to data_width_g
				checksum_out_width_g:	natural := 8;		--Output CheckSum width
				data_width_g		:	natural := 8		--Input data width
			);
	port(           
           clock			: in  std_logic;	--Clock 
           reset			: in  std_logic; 	--Reset
           data				: in  std_logic_vector(data_width_g - 1 downto 0); --Data to calculate
           data_valid		: in  std_logic; 	--Data is Valid
		   reset_checksum	: in  std_logic;	--Reset the current checksum to the initial value
		   req_checksum		: in  std_logic;	--Request for valid checksum
           
		   checksum_out		: out std_logic_vector(checksum_out_width_g - 1 downto 0); --Checksum value
           checksum_valid	: out std_logic 	--CheckSum valid
       );
end component; 
----------------------------------------------------------------------------------
component mp_enc
   generic (
				reset_polarity_g	:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
				len_dec1_g			:	boolean := true;	--TRUE - Recieved length is decreased by 1 ,to save 1 bit
															--FALSE - Recieved length is the actual length
				
				sof_d_g				:	positive := 1;		--SOF Depth
				type_d_g			:	positive := 1;		--Type Depth
				addr_d_g			:	positive := 3;		--Address Depth
				len_d_g				:	positive := 2;		--Length Depth
				crc_d_g				:	positive := 1;		--CRC Depth
				eof_d_g				:	positive := 1;		--EOF Depth
						
				sof_val_g			:	natural := 100;		-- (64h) SOF block value. Upper block is MSB
				eof_val_g			:	natural := 200;		-- (C8h) EOF block value. Upper block is MSB
				
				width_g				:	positive := 8		--Data Width (UART = 8 bits)
           );
   port
   	   (
				--Inputs
				clk			:	in std_logic; 	--Clock
				rst			:	in std_logic; 	--Reset
				fifo_full	:	in std_logic;	--When '0' - Can receive data, When '0' - FIFO Full
				
				--Message Pack
				mp_done		:	out std_logic;	--Message Pack has been transmitted
				dout		:	out std_logic_vector (width_g - 1 downto 0); --Output data
				dout_valid	:	out std_logic;	--Output data is valid
				
				--Registers
				reg_ready	:	in std_logic; --All the registers are ready for reading
				type_reg	:	in std_logic_vector (width_g * type_d_g - 1 downto 0);
				addr_reg	:	in std_logic_vector (width_g * addr_d_g - 1 downto 0);
				len_reg		:	in std_logic_vector (width_g * len_d_g - 1 downto 0);
				
				--CRC / CheckSum
				data_crc_val:	out std_logic; --'1' when new data for CRC is valid, '0' otherwise
				data_crc	:	out std_logic_vector (width_g - 1 downto 0); --Data to be calculated by CRC
				reset_crc	:	out std_logic; --'1' to reset CRC value
				req_crc		:	out std_logic; --'1' to request for current caluclated CRC
				crc_in		:	in std_logic_vector (width_g * crc_d_g -1 downto 0); --CRC value
				crc_in_val	:	in std_logic;  --'1' when CRC is valid
				
				--Data (Payload)
				din			:	in std_logic_vector (width_g - 1 downto 0); --Input from RAM
				din_valid	:	in std_logic;	--Data from RAM is valid
				read_addr_en:	out std_logic;										--Output RAM address is valid
				read_addr	:	out std_logic_vector (width_g * len_d_g - 1 downto 0) --RAM Address
   	   );
end component;
----------------------------------------------------------------------------------
component general_fifo 
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
		 used 		: out 	std_logic_vector (log_depth_g downto 0) 	-- Current number of elements is FIFO
	     );
end component general_fifo;
----------------------------------------------------------------------------------
component gen_reg
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
end component gen_reg;
----------------------------------------------------------------------------------
component wbs_reg is
	generic	(
			reset_polarity_g	:	std_logic	:= '0';							--'0' = reset active
			width_g				:	positive	:= 8;							--Width: Registers width
			addr_width_g		:	positive	:= 4							--2^4 = 16 register address is supported
			);
	port	(
			rst			:	in	std_logic;										--Reset
			
			--Wishbone Slave Signals
			clk_i		:	in std_logic;										--Wishbone Clock
			wbs_cyc_i	:	in std_logic;										--Cycle command from WBM
			wbs_stb_i	:	in std_logic;										--Strobe command from WBM
			wbs_adr_i	:	in std_logic_vector (addr_width_g - 1 downto 0);	--Register's address
			wbs_we_i	:	in std_logic;										--Write enable
			wbs_dat_i	:	in std_logic_vector (width_g - 1 downto 0);			--Data In
			wbs_dat_o	:	out std_logic_vector (width_g - 1 downto 0);		--Data Out
			wbs_ack_o	:	out std_logic;										--Input data has been successfuly acknowledged
			wbs_stall_o	:	out std_logic;										--Not ready to receive data
			
			--Signals to Registers
			din_ack		:	in std_logic;										--Write command has been received
			dout		:	in std_logic_vector (width_g - 1 downto 0);			--Output data
			dout_valid	:	in std_logic;										--Output data is valid
			addr		:	out std_logic_vector (addr_width_g - 1 downto 0);	--Address to register.
			din			:	out std_logic_vector (width_g - 1 downto 0);		--Input data
			rd_en		:	out std_logic;										--Request for data
			wr_en		:	out std_logic										--Write data
			);
end component;
-- ###############################################################################

--------------------------------- Constants   ------------------------------------
constant reg_width_c		:	positive 	:= 8;	--Width of registers
constant reg_addr_width_c	:	positive 	:= 4;	--Width of registers' address
constant type_reg_addr_c	:	natural		:= 1;	--Type register address
constant rd_burst_reg_addr_c:	natural		:= 5;	--Number of words to read from SDRAM
constant dbg_com_reg_depth_c:	positive	:= 3;	--3*8 = 24 bits

	--Debug SDRAM register address range: 2-->4 (Total of 24 bits)
constant dbg_com_reg_addr_c	:	natural		:= 2;	--Debug SDRAM address (read / write)
----------------------------------------------------------------------------------
--------------------------------- Signals ----------------------------------------
signal clk					:	std_logic;  		--Clock
signal din					:	std_logic_vector (width_g - 1 downto 0);  --Input data_d_g
signal uart_serial			:	std_logic;  		--Serial data
signal valid				:	std_logic; 			--Data valid
signal parity_err			:	std_logic; 			--Parity bit error
signal sbit_err				:	std_logic; 			--Stop bit error

	--Message Pack Status
signal mp_dec_done			:	std_logic; 			--Message Pack (To Decoder) has been recieved
signal mp_enc_done			:	std_logic; 			--Message Pack (From Encoder) has been transmitted
signal eof_err				:	std_logic; 			--EOF has not found
signal crc_err				:	std_logic; 			--CRC error
		
	--Registers		
signal type_reg				:	std_logic_vector (width_g * type_d_g - 1 downto 0); 
signal addr_reg				:	std_logic_vector (width_g * addr_d_g - 1 downto 0); 
signal len_reg				:	std_logic_vector (width_g * len_d_g - 1 downto 0);  
		
	--Data (Payload)		
signal write_en				:	std_logic;  												--'1' = Data is available (width_g length)
signal write_addr			:	std_logic_vector (width_g * len_d_g - 1 downto 0);  		--RAM Address
--signal dec2ram				:	std_logic_vector (width_g - 1 downto 0); 					--Data to RAM
		
	--FIFO		
signal fifo_full			:	std_logic; 		--'1' = FIFO full, '0' = FIFO can receive data
signal fifo_empty			:	std_logic; 		--'1' = FIFO empty, '0' = FIFO not empty
signal mp2fifo				:	std_logic_vector (width_g - 1 downto 0); 
signal enc_dout_val			:	std_logic;  	--Data from MP encoder is valid
		
	--UART TX		
signal fifo2tx_data			:	std_logic_vector (width_g - 1 downto 0); 					--Data from FIFO
signal fifo2tx_val			:	std_logic; 													--Data valid for TX
signal uart_tx_out			:	std_logic; 													--Serial UART output
signal fifo_rd_en			:	std_logic; 													--FIFO Read Enable

	--CRC
	--Encoder:
signal enc2crc_valid		:	std_logic; 	--'1' when new data for CRC is valid, '0' otherwise
signal enc2crc_data	    	:   std_logic_vector (width_g - 1 downto 0); 					--Data to be calculated by CRC
signal enc2crc_rst			:   std_logic; 	--'1' to reset CRC value
signal enc2crc_req			:   std_logic; 	--'1' to request for current caluclated CRC
signal crc2enc_data			:   std_logic_vector (width_g * crc_d_g -1 downto 0); 			--CRC value
signal crc2enc_valid		:   std_logic;  --'1' when CRC is valid

	--RAM
signal ram_read_addr		:	std_logic_vector (width_g * len_d_g - 1 downto 0);
signal ram_dout				:	std_logic_vector (width_g - 1 downto 0);
signal ram_dout_valid		:	std_logic; 
signal enc2ram_rd_en		:	std_logic; 

	--WBS Signals
signal wbs_reg_din_ack		:	std_logic;													--WBS Register din acknowledged
signal wbs_reg_dout			:   std_logic_vector (reg_width_c - 1 downto 0);				--WBS Register dout
signal wbs_reg_dout_valid	:   std_logic;													--WBS Register dout_valid
signal wbs_reg_cyc			:	std_logic;													--Cycle for Registers
signal wbs_reg_ack_o		:	std_logic;						--WBS_ACK_O from registers
signal wbs_reg_stall_o		:	std_logic;						--WBS_STALL_O from registers
signal wbs_reg_stb			:	std_logic;						--WBS_STB_O to registers
	
	--Signals to registers	
signal reg_addr				:	std_logic_vector (reg_addr_width_c - 1 downto 0);			--Address to register. Relevant only when addr_en_g = true
signal reg_din				:	std_logic_vector (reg_width_c - 1 downto 0);				--Input data
signal reg_wr_en			:	std_logic;													--Input data is valid
signal reg_rd_en			:	std_logic;													--Request for data from registers
	
	--Type register signals	
signal type_reg_din_ack		:	std_logic;													--Data has been acknowledged
signal type_reg_rd_en		:	std_logic;													--Read Enable
signal type_reg_dout		:	std_logic_vector (reg_width_c - 1 downto 0);				--Output data
signal type_reg_dout_valid	:	std_logic;													--Output data is valid

	--Debug SDRAM register signals
signal dbg_com_reg_din_ack		:	std_logic_vector (dbg_com_reg_depth_c - 1 downto 0);	--Data has been acknowledged
signal dbg_com_reg_rd_en		:	std_logic_vector (dbg_com_reg_depth_c - 1 downto 0);	--Read Enable
signal dbg_com_reg_dout			:	std_logic_vector (dbg_com_reg_depth_c * reg_width_c - 1 downto 0);		--Output data
signal dbg_com_reg_dout_valid	:	std_logic_vector (dbg_com_reg_depth_c - 1 downto 0);					--Output data is valid

	--Rd Burst Len register signals
signal rd_burst_reg_din_ack		:	std_logic;												--Data has been acknowledged
signal rd_burst_reg_rd_en		:	std_logic;												--Read Enable
signal rd_burst_reg_dout		:	std_logic_vector (reg_width_c - 1 downto 0);			--Output data
signal rd_burst_reg_dout_valid	:	std_logic;												--Output data is valid												--Output data is valid


--	###########################		Implementation		##############################

begin	
	
	--Cycle is active for registers
	wbs_reg_cyc_proc:
	wbs_reg_cyc	<=	wbs_cyc_i and wbs_tgc_i;
	
	--Strobe is active for registers
	wbs_reg_stb_proc:
	wbs_reg_stb	<=	wbs_stb_i and wbs_tgc_i;
	
	--WBS_ACK_O
	wbs_ack_o_proc:
	wbs_ack_o	<= 	wbs_reg_ack_o when (wbs_reg_cyc = '1');
	
	--WBS_STALL_O
	wbs_stall_o_proc:
	wbs_stall_o	<=	wbs_reg_stall_o when (wbs_reg_cyc = '1');
	
	--MUX, to route addressed register data to the WBS
	wbs_reg_dout_proc:
	wbs_reg_dout	<=	type_reg_dout when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c)) 
						else rd_burst_reg_dout when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = rd_burst_reg_addr_c))
						else dbg_com_reg_dout (3 * reg_width_c - 1 downto 2 * reg_width_c) 	when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_com_reg_addr_c + 2)) 
						else dbg_com_reg_dout (2 * reg_width_c - 1 downto reg_width_c) 		when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_com_reg_addr_c + 1)) 
						else dbg_com_reg_dout (reg_width_c - 1 downto 0)  					when ((wbs_reg_cyc = '1') and (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_com_reg_addr_c))
						else (others => '0');

	--MUX, to route addressed register dout_valid to the WBS
	wbs_reg_dout_valid_proc:
	wbs_reg_dout_valid	<=	type_reg_dout_valid 
							or dbg_com_reg_dout_valid 
							or rd_burst_reg_dout_valid ;

	--MUX, to route addressed register din_ack to the WBS
	wbs_reg_din_ack_proc:
	wbs_reg_din_ack	<=	type_reg_din_ack 
						or dbg_com_reg_din_ack
						or rd_burst_reg_din_ack;
						
	--Read Enables processes:
	type_reg_rd_en_proc:
	type_reg_rd_en	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = type_reg_addr_c) and (reg_rd_en = '1')
						else '0';
					
	rd_burst_reg_rd_en_proc:
	rd_burst_reg_rd_en	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = rd_burst_reg_addr_c) and (reg_rd_en = '1')
								else '0';

	dbg_com_reg_rd_en_2proc:
	dbg_com_reg_rd_en(2)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_com_reg_addr_c + 2) and (reg_rd_en = '1')
							else '0';

	dbg_com_reg_rd_en_1proc:
	dbg_com_reg_rd_en(1)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_com_reg_addr_c + 1) and (reg_rd_en = '1')
							else '0';

	dbg_com_reg_rd_en_0proc:
	dbg_com_reg_rd_en(0)	<=	'1' when (conv_integer(wbs_adr_i (reg_addr_width_c - 1 downto 0)) = dbg_com_reg_addr_c) and (reg_rd_en = '1')
							else '0';
								
							
	--Componenets:	
	uart_tx_c : uart_tx 		generic map ( 
										parity_en_g		=> parity_en_g,		
										parity_odd_g	=> parity_odd_g,	
										uart_idle_g	    => uart_idle_g,	    
										baudrate_g		=> baudrate_g,		
										clkrate_g		=> clkrate_g,		
										databits_g		=> databits_g,		
										reset_polarity_g=> reset_polarity_g
									)
								port map (
										din				=> fifo2tx_data, 		
										clk				=> clk_i,          		
										reset			=> rst,	         	
										fifo_empty		=> fifo_empty,	 	
										fifo_din_valid	=> fifo2tx_val,	 
										fifo_rd_en		=> fifo_rd_en,
										dout			=> uart_serial_out			
									);
																
	mp_enc1 : mp_enc			generic map (
										len_dec1_g	=> len_dec1_g,	
										sof_d_g		=> sof_d_g,	
										type_d_g	=> type_d_g,	
										addr_d_g	=> addr_d_g,	
										len_d_g		=> len_d_g,		
										crc_d_g		=> crc_d_g,		
										eof_d_g		=> eof_d_g,		
										sof_val_g	=> sof_val_g,	
										eof_val_g	=> eof_val_g,	
										width_g		=> width_g		
									)
								port map (
										--Inputs
	                                    clk			=> clk_i,
	                                    rst			=> rst,
	                                    fifo_full	=> fifo_full,	
	                                    --Message Pack
	                                    mp_done		=> mp_enc_done,
	                                    dout		=> mp2fifo,
	                                    dout_valid	=> enc_dout_val,
										--Registers
	                                    reg_ready	=> mp_dec_done,	
	                                    type_reg	=> type_reg,	
	                                    addr_reg	=> addr_reg,
	                                    len_reg		=> len_reg,		                          
	                                    --CRC / CheckSum
	                                    data_crc_val=>	enc2crc_valid,	
	                                    data_crc	=>	enc2crc_data,
	                                    reset_crc	=>	enc2crc_rst,	
	                                    req_crc		=>	enc2crc_req,
	                                    crc_in		=>	crc2enc_data,	
	                                    crc_in_val	=>	crc2enc_valid,	                                    
	                                    --Data (Payload)
	                                    din			=> ram_dout,
	                                    din_valid	=> ram_dout_valid,
										read_addr_en=> enc2ram_rd_en,
										read_addr	=> ram_read_addr
									);
									
	checksum_inst_enc : checksum_calc 	
								generic map (
										reset_polarity_g	 => reset_polarity_g,	
										signed_checksum_g	 => signed_checksum_g,	
										checksum_init_val_g	 => checksum_init_val_g,	
										checksum_out_width_g => checksum_out_width_g,
										data_width_g		 => data_width_g		
											)
								port map (
										clock			=>	clk_i,	
										reset			=>	rst,
										data			=>	enc2crc_data,	
										data_valid		=>	enc2crc_valid,
										reset_checksum	=>	enc2crc_rst,
										req_checksum	=>	enc2crc_req,		            
										checksum_out	=>	crc2enc_data,	
										checksum_valid	=>	crc2enc_valid
									);
					
	ram_inst1 : ram_simple 		generic map (
										reset_polarity_g=> reset_polarity_g,
										width_in_g		=> width_in_g,		
										addr_bits_g		=> addr_bits_g									  
									) 	
								port map (	
										clk			=>	clk_i,
										rst			=>	rst,
	                                    addr_in		=>	write_addr(ram_addr_len_g - 1 downto 0), 
	                                    addr_out	=>	ram_read_addr(ram_addr_len_g - 1 downto 0),
	                                    aout_valid	=>	enc2ram_rd_en,
	                                    data_in		=>	wbs_dat_i,
	                                    din_valid	=>	write_en,
	                                    data_out	=>	ram_dout,
	                                    dout_valid	=>	ram_dout_valid
									);
	
	fifo_inst1 : general_fifo 	generic map ( 
										reset_polarity_g 	=> reset_polarity_g,
										depth_g				=> depth_g,
										width_g 			=> width_g
										)
								port map (
										clk 		=> clk_i,
							            rst 		=> rst, 
							            din 		=> mp2fifo,
							            wr_en 		=> enc_dout_val,
							            rd_en 		=> fifo_rd_en,
							            dout 		=> fifo2tx_data,
										dout_valid  => fifo2tx_val,
							           	full 		=> fifo_full,							       
							            empty 		=> fifo_empty
							         
									);
	gen_reg_type_inst	:	gen_reg 
								generic map (
										reset_polarity_g	=>	reset_polarity_g,	
										width_g				=>	reg_width_c,
										addr_en_g			=>	true,
										addr_val_g			=>	type_reg_addr_c,
										addr_width_g		=>	reg_addr_width_c,
										read_en_g			=>	true,
										write_en_g			=>	true,
										clear_on_read_g		=>	false,
										default_value_g		=>	0
									)
								port map (
										clk					=>	clk_i,
										reset		        =>	rst,
										addr		        =>	reg_addr,
										din			        =>	reg_din,
										wr_en		        =>	reg_wr_en,
										clear		        =>	'0',
										din_ack		        =>	type_reg_din_ack,
										rd_en				=>	type_reg_rd_en,
										dout		        =>	type_reg_dout,
										dout_valid	        =>	type_reg_dout_valid
									);
			
	gen_rd_burst_reg_inst	:	gen_reg 
								generic map (
										reset_polarity_g	=>	reset_polarity_g,	
										width_g				=>	reg_width_c,
										addr_en_g			=>	true,
										addr_val_g			=>	rd_burst_reg_addr_c,
										addr_width_g		=>	reg_addr_width_c,
										read_en_g			=>	true,
										write_en_g			=>	true,
										clear_on_read_g		=>	false,
										default_value_g		=>	0
									)
								port map (
										clk					=>	clk_i,
									    reset		        =>	rst,
										addr		        =>	reg_addr,
										din			        =>	reg_din,
										wr_en		        =>	reg_wr_en,
										clear		        =>	'0',
										din_ack		        =>	rd_burst_reg_din_ack,
										rd_en				=>	rd_burst_reg_rd_en,
										dout		        =>	rd_burst_reg_dout,
										dout_valid	        =>	rd_burst_reg_dout_valid																																										
									);
						
	dbg_com_reg_generate:
	for idx in (dbg_com_reg_depth_c - 1) downto 0 generate
		gen_dbg_com_reg_inst	:	gen_reg generic map (
										reset_polarity_g	=>	reset_polarity_g,	
										width_g				=>	reg_width_c,
										addr_en_g			=>	true,
										addr_val_g			=>	(dbg_com_reg_addr_c + idx),
										addr_width_g		=>	reg_addr_width_c,
										read_en_g			=>	true,
										write_en_g			=>	true,
										clear_on_read_g		=>	false,
										default_value_g		=>	0
									)
									port map (
										clk					=>	clk_i,
									    reset		        =>	rst,
									    addr		        =>	reg_addr,
									    din			        =>	reg_din,
									    wr_en		        =>	reg_wr_en,
									    clear		        =>	'0',
                                        din_ack		        =>	dbg_com_reg_din_ack (idx),
                                        rd_en				=>	dbg_com_reg_rd_en (idx),
                                        dout		        =>	dbg_com_reg_dout (((idx + 1) * reg_width_c - 1) downto (idx * reg_width_c)),
                                        dout_valid	        =>	dbg_com_reg_dout_valid (idx)
									);
	end generate dbg_com_reg_generate;
												
	wbs_reg_inst:	wbs_reg 	
								generic map (
										reset_polarity_g=>	reset_polarity_g,
										width_g			=>	reg_width_c,
										addr_width_g	=>	reg_addr_width_c
									)
								port map (
										rst				=>	rst,
										clk_i			=> 	clk,
										wbs_cyc_i	    =>	wbs_reg_cyc,	
										wbs_stb_i	    => 	wbs_stb_i,	
										wbs_adr_i	    =>	wbs_adr_i,	
										wbs_we_i	    => 	wbs_we_i,	
										wbs_dat_i	    => 	wbs_dat_i,	
										wbs_dat_o	    => 	wbs_dat_o,	
										wbs_ack_o	    => 	wbs_ack_o,	
										wbs_stall_o		=>	wbs_stall_o,
										
										din_ack			=>	wbs_reg_din_ack,
										dout		    =>	wbs_reg_dout,
										dout_valid	    =>	wbs_reg_dout_valid,
										addr		    =>	reg_addr,
										din			    =>	reg_din,
										rd_en		    =>	reg_rd_en,
										wr_en		    =>	reg_wr_en
									);
	
end architecture arc_tx_path;        	            