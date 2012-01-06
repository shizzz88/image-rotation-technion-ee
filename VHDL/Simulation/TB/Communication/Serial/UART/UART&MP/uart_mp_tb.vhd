------------------------------------------------------------------------------------------------
-- Model Name 	:	UART & Message Pack TestBench
-- File Name	:	uart_mp_tb.vhd
-- Generated	:	20.11.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
--
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		Date		Name				Description
--			1.00		20.11.2010	Beeri Schreiber		Creation
------------------------------------------------------------------------------------------------
--	Todo:
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity uart_mp_tb is
   generic (
				reset_polarity_g	:	std_logic 	:= '0'; 		--'0' = Active Low, '1' = Active High
				len_dec1_g			:	boolean 	:= true;		--TRUE - Recieved length is decreased by 1 ,to save 1 bit, FALSE - Recieved length is the actual length
				clkrate_g			:	positive 	:= 133333333;	--System Clock
				
				sof_d_g				:	positive := 1;				--SOF Depth
				type_d_g			:	positive := 1;				--Type Depth
				addr_d_g			:	positive := 3;				--Address Depth
				len_d_g				:	positive := 2;				--Length Depth
				crc_d_g				:	positive := 1;				--CRC Depth
				eof_d_g				:	positive := 1;				--EOF Depth
								
				sof_val_g			:	natural := 100;				--SOF block value. Upper block is MSB
				eof_val_g			:	natural := 200;				--EOF block value. Upper block is MSB
				
				ram_addr_len_g		:	natural 	:= 5; 			--2^10 = 1024 in RAM
				fifo_depth_g		:	positive 	:= 9;			--FIFO depth
				
				parity_en_g			:	natural range 0 to 1 := 0;
				width_g				:	positive := 8				--Data Width (UART = 8 bits)
           );

end entity uart_mp_tb;

architecture arc_uart_mp_tb of uart_mp_tb is

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

component ram_generic
	generic (
				reset_polarity_g	:	std_logic 	:= '0';	--'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 	:= 8;	--Width of data
				addr_bits_g			:	positive 	:= 10;	--Depth of data	(2^10 = 1024 addresses)
				power2_out_g		:	natural 	:= 1	--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide
				--TODO: power_sign_g:	integer range -1 to 1 := -1; -- '-1' => output width > input width ; '1' => input width > output width
			);
	port	(
				clk			:	in std_logic;									--System clock
				rst			:	in std_logic;									--System Reset
				addr_in		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out	:	in std_logic_vector ((addr_bits_g - power2_out_g) - 1 downto 0); 		--Output address
				aout_valid	:	in std_logic;									--Output address is valid
				data_in		:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid	:	in std_logic; 									--Input data valid
				data_out	:	out std_logic_vector ((width_in_g * (2**power2_out_g)) - 1 downto 0);	--Output data
				dout_valid	:	out std_logic 									--Output data valid
			);
end component;

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

component uart_rx
   generic (
			 parity_en_g		:		natural range 0 to 1 := 0; 		--1 to Enable parity bit, 0 to disable parity bit
			 parity_odd_g		:		boolean 	:= false; 			--TRUE = odd, FALSE = even
			 uart_idle_g		:		std_logic 	:= '1';				--Idle line value
			 baudrate_g			:		positive	:= 115200;			--UART baudrate
			 clkrate_g			:		positive	:= 133333333;		--Sys. clock
			 databits_g			:		natural range 5 to 8 := 8;		--Number of databits
			 reset_polarity_g	:		std_logic 	:= '0'	 			--'0' = Active Low, '1' = Active High
           );
   port
   	   (
			 din				:	in std_logic;				--Serial data in
			 clk				:	in std_logic;				--Sys. clock
			 reset				:	in std_logic;				--Reset
 			 dout				:	out std_logic_vector (databits_g + parity_en_g -1 downto 0);	--Parallel data out
			 valid				:	out std_logic;				--Parallel data valid
			 parity_err			:	out std_logic;				--Parity error
			 stop_bit_err		:	out	std_logic				--Stop bit error
   	   );
end component;

component mp_dec
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
				rst			:	in std_logic;	--Reset
				din			:	in std_logic_vector (width_g - 1 downto 0); --Input data_d_g
				valid		:	in std_logic;	--Data valid
				
				--Message Pack Status
				mp_done		:	out std_logic;	--Message Pack has been recieved
				eof_err		:	out std_logic;	--EOF has not found
				crc_err		:	out std_logic;	--CRC error
				
				--Registers
				type_reg	:	out std_logic_vector (width_g * type_d_g - 1 downto 0);
				addr_reg	:	out std_logic_vector (width_g * addr_d_g - 1 downto 0);
				len_reg		:	out std_logic_vector (width_g * len_d_g - 1 downto 0);

				--CRC / CheckSum
				data_crc_val:	out std_logic; --'1' when new data for CRC is valid, '0' otherwise
				data_crc	:	out std_logic_vector (width_g - 1 downto 0); --Data to be calculated by CRC
				reset_crc	:	out std_logic; --'1' to reset CRC value
				req_crc		:	out std_logic; --'1' to request for current caluclated CRC
				crc_in		:	in std_logic_vector (width_g * crc_d_g -1 downto 0); --CRC value
				crc_in_val	:	in std_logic;  --'1' when CRC is valid
				
				--Data (Payload)
				write_en	:	out std_logic; --'1' = Data is available (width_g length)
				write_addr	:	out std_logic_vector (width_g * len_d_g - 1 downto 0); --RAM Address
				dout		:	out std_logic_vector (width_g - 1 downto 0) --Data to RAM
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
end component;

--------------------------------  Signals ----------------------------------------
signal clk			:	std_logic := '0'; 	--Clock
signal rst			:	std_logic := not reset_polarity_g; 	--Reset
signal din			:	std_logic_vector (width_g - 1 downto 0) := (others => '0'); --Input data_d_g
signal uart_serial	:	std_logic := '0'; 	--Serial data
signal valid		:	std_logic := '0';	--Data valid
signal parity_err	:	std_logic := '0';	--Parity bit error
signal sbit_err		:	std_logic := '0';	--Stop bit error

	--Message Pack Status
signal mp_dec_done	:	std_logic := '0';	--Message Pack (To Decoder) has been recieved
signal mp_enc_done	:	std_logic := '0';	--Message Pack (From Encoder) has been transmitted
signal eof_err		:	std_logic := '0';	--EOF has not found
signal crc_err		:	std_logic := '0';	--CRC error

	--Registers
signal type_reg		:	std_logic_vector (width_g * type_d_g - 1 downto 0) := (others => '0');
signal addr_reg		:	std_logic_vector (width_g * addr_d_g - 1 downto 0) := (others => '0');
signal len_reg		:	std_logic_vector (width_g * len_d_g - 1 downto 0) := (others => '0');

	--Data (Payload)
signal write_en		:	std_logic := '0'; --'1' = Data is available (width_g length)
signal write_addr	:	std_logic_vector (width_g * len_d_g - 1 downto 0) := (others => '0'); --RAM Address
signal dec2ram		:	std_logic_vector (width_g - 1 downto 0) := (others => '0'); --Data to RAM

	--FIFO
signal fifo_full	:	std_logic := '0'; --'1' = FIFO full, '0' = FIFO can receive data
signal fifo_empty	:	std_logic := '0'; --'1' = FIFO empty, '0' = FIFO not empty
signal mp2fifo		:	std_logic_vector (width_g - 1 downto 0) := (others => '0');
signal enc_dout_val	:	std_logic := '0'; --Data from MP encoder is valid

--UART TX
signal fifo2tx_data	:	std_logic_vector (width_g - 1 downto 0) := (others => '0'); --Data from FIFO
signal fifo2tx_val	:	std_logic := '0'; 											--Data valid for TX
signal uart_tx_out	:	std_logic := '0'; 											--Serial UART output
signal fifo_rd_en	:	std_logic := '0';											--FIFO Read Enable

--CRC
--Encoder:
signal enc2crc_valid	:	std_logic; --'1' when new data for CRC is valid, '0' otherwise
signal enc2crc_data	    :   std_logic_vector (width_g - 1 downto 0); --Data to be calculated by CRC
signal enc2crc_rst		:   std_logic; --'1' to reset CRC value
signal enc2crc_req		:   std_logic; --'1' to request for current caluclated CRC
signal crc2enc_data		:   std_logic_vector (width_g * crc_d_g -1 downto 0); --CRC value
signal crc2enc_valid	:   std_logic;  --'1' when CRC is valid
--Decoder:
signal dec2crc_valid	: std_logic; --'1' when new data for CRC is valid, '0' otherwise
signal dec2crc_data	    : std_logic_vector (width_g - 1 downto 0); --Data to be calculated by CRC
signal dec2crc_rst   	: std_logic; --'1' to reset CRC value
signal dec2crc_req	    : std_logic; --'1' to request for current caluclated CRC
signal crc2dec_data	    : std_logic_vector (width_g * crc_d_g -1 downto 0); --CRC value
signal crc2dec_valid   	: std_logic;  --'1' when CRC is valid

--RAM
signal ram_read_addr		:	std_logic_vector (width_g * len_d_g - 1 downto 0);
signal ram_dout				:	std_logic_vector (width_g - 1 downto 0);
signal ram_dout_valid		:	std_logic := '0';
signal enc2ram_rd_en		:	std_logic := '0';


begin
	clk_proc:
	clk <= not clk after (1 sec /real(clkrate_g*2));	--133MHz
	
	rst_proc:
	rst <= reset_polarity_g, (not reset_polarity_g) after 400 ns;
	
	--Componenets:	
	uart_tx_c : uart_tx generic map ( 
										clkrate_g 			=> 133000000,
										reset_polarity_g	=> reset_polarity_g
								)
						port map (
										din				=> fifo2tx_data, 		
										clk				=> clk,          		
										reset			=> rst,	         	
										fifo_empty		=> fifo_empty,	 	
										fifo_din_valid	=> fifo2tx_val,	 
										fifo_rd_en		=> fifo_rd_en,
										dout			=> uart_tx_out			
								);
	
	uart_rx_c : uart_rx generic map ( 
										clkrate_g 		=> 133000000
								)
						port map (
										din		     => uart_serial,
	                                    clk		     => clk,
	                                    reset		 => rst,
	                                    dout		 => din,
	                                    valid		 => valid,
	                                    parity_err	 => parity_err,
	                                    stop_bit_err => sbit_err
								);
	
	
	uart_gen : uart_tx_gen_model generic map (
									--Comment / Uncomment, according to the computer this simulation is running on
									--Technion Directory:
									--file_name_g => "H:\RunLen\VHDL\Simulation\Models\Communication\Serial\UART\TX\UART_Generator\Input_Files\uart_tx")
									--Beeri's Computer:
									file_name_g => "D:\ModelSim\MyDesign\RunLen\VHDL\Simulation\Models\Communication\Serial\UART\TX\UART_Generator\Input_Files\uart_tx")
								 port map (
										system_clk	=> clk,
										uart_out 	=> uart_serial
										--value		=> din,	
										--valid		=> valid
										);
										
	mp_dec1 : mp_dec			generic map (sof_d_g 	=> sof_d_g,
											 sof_val_g	=> sof_val_g,
											 len_dec1_g  => len_dec1_g)
								port map (
										clk			=> clk,			
										rst			=> rst,
	                                    din			=> din,
	                                    valid		=> valid,
	                                                             
	                                    mp_done		=> mp_dec_done,		
	                                    eof_err		=> eof_err,		
	                                    crc_err		=> crc_err,		
                                                                 
	                                    type_reg	=> type_reg,	
	                                    addr_reg	=> addr_reg,	
	                                    len_reg		=> len_reg,		
			
										data_crc_val=> dec2crc_valid,	
                                        data_crc	=> dec2crc_data,
                                        reset_crc	=> dec2crc_rst,
                                        req_crc		=> dec2crc_req,	
                                        crc_in		=> crc2dec_data,	
                                        crc_in_val	=> crc2dec_valid,
                                                       
	                                    write_en	=> write_en,	
	                                    write_addr	=> write_addr,	
	                                    dout		=> dec2ram
										);
							
	fifo_inst1 : general_fifo generic map ( reset_polarity_g => reset_polarity_g,
											depth_g			=> fifo_depth_g,
											width_g => width_g )
							port map	(clk 		=> clk,
							             rst 		=> rst, 
							             din 		=> mp2fifo,
							             wr_en 		=> enc_dout_val,
							             rd_en 		=> fifo_rd_en,
							             dout 		=> fifo2tx_data,
										 dout_valid => fifo2tx_val,
							             --afull  =>
							             full 		=> fifo_full,
							             -- aempty =>
							             empty 		=> fifo_empty
							             --used 	=>
										);
							
	mp_enc1 : mp_enc			generic map (sof_d_g => sof_d_g,
											 sof_val_g	=> sof_val_g,
											 len_dec1_g  => len_dec1_g)
								port map (
										--Inputs
	                                    clk			=> clk,
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
									
	checksum_inst_enc : checksum_calc 	generic map (signed_checksum_g => false)
									port map (
										clock			=>	clk,	
										reset			=>	rst,
										data			=>	enc2crc_data,	
										data_valid		=>	enc2crc_valid,
										reset_checksum	=>	enc2crc_rst,
										req_checksum	=>	enc2crc_req,	
											            
										checksum_out	=>	crc2enc_data,	
										checksum_valid	=>	crc2enc_valid
									);

	checksum_inst_dec : checksum_calc 	generic map (signed_checksum_g => false)
									port map (
										clock			=>	clk,	
										reset			=>	rst,
										data			=>	dec2crc_data,	
										data_valid		=>	dec2crc_valid,
										reset_checksum	=>	dec2crc_rst,
										req_checksum	=>	dec2crc_req,	
											            
										checksum_out	=>	crc2dec_data,	
										checksum_valid	=>	crc2dec_valid
									);

									
	ram_inst1 : ram_generic generic map (
										reset_polarity_g	=> reset_polarity_g,
										power2_out_g	 	=> 0,	--Input width = output width
										addr_bits_g			=> ram_addr_len_g
								)
					port map (	
										clk			=>	clk,
										rst			=>	rst,
	                                    addr_in		=>	write_addr(ram_addr_len_g - 1 downto 0), 
	                                    addr_out	=>	ram_read_addr(ram_addr_len_g - 1 downto 0),
	                                    aout_valid	=>	enc2ram_rd_en,
	                                    data_in		=>	dec2ram,
	                                    din_valid	=>	write_en,
	                                    data_out	=>	ram_dout,
	                                    dout_valid	=>	ram_dout_valid
									);
	
end architecture arc_uart_mp_tb;        	            