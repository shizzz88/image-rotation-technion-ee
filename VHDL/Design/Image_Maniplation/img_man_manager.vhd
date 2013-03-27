------------------------------------------------------------------------------------------------
-- Model Name 	:	Image Manipulation Manager (FSM)
-- File Name	:	img_man_manager.vhd
-- Generated	:	21.08.2012
-- Author		:	Uri Tsipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   Manager for Image manipulation Block
--					FSM for the image manipulation procces
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		21.08.2012	Uri					creation
--			1.1			28.08.2012	Uri,Moshe			removed init_st, not necessary. fixed false valid on last pixel
------------------------------------------------------------------------------------------------
-- TO DO:
--			fix constants to be derived from generics, don't forget addr_calc.vhd
--			fix	row/col_idx_out	to be generic length
--			
--					

------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity img_man_manager is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				img_hor_pixels_g	:	positive					:= 640;	--640 pixel in a coloum
				img_ver_pixels_g	:	positive					:= 480	--480 pixels in a row
			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;				-- clock
				sys_rst				:	in std_logic;				-- Reset
				
				req_trig			:	in std_logic;				-- Trigger for image manipulation to begin,
				--from addr_calc
				addr_calc_oor		:	in std_logic;				--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				addr_calc_valid		:	in std_logic;				--data valid indicator
				
				
				index_valid			:	out std_logic;				--valid signal for index
				row_idx_out			:	out signed (10 downto 0); 	--current row index           --fix to generic
				col_idx_out			:	out signed (10 downto 0); 	--corrent coloumn index		  --fix to generic
				
				-- Wishbone Master (mem_ctrl_wr)
				wr_wbm_adr_o		:	out std_logic_vector (9 downto 0);		--Address in internal RAM
				wr_wbm_tga_o		:	out std_logic_vector (9 downto 0);		--Burst Length
				wr_wbm_dat_o		:	out std_logic_vector (7 downto 0);		--Data In (8 bits)
				wr_wbm_cyc_o		:	out std_logic;							--Cycle command from WBM
				wr_wbm_stb_o		:	out std_logic;							--Strobe command from WBM
				wr_wbm_we_o			:	out std_logic;							--Write Enable
				wr_wbm_tgc_o		:	out std_logic;							--Cycle tag: '0' = Write to components, '1' = Write to registers
				wr_wbm_dat_i		:	in std_logic_vector (7 downto 0);		--Data Out for reading registers (8 bits)
				wr_wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				wr_wbm_ack_i		:	in std_logic;							--Input data has been successfuly acknowledged
				wr_wbm_err_i		:	in std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)

				-- Wishbone Master (mem_ctrl_rd)
				rd_wbm_adr_o 		:	out std_logic_vector (9 downto 0);		--Address in internal RAM
				rd_wbm_tga_o 		:   out std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				rd_wbm_cyc_o		:   out std_logic;							--Cycle command from WBM
				rd_wbm_tgc_o 		:   out std_logic;							--Cycle tag. '1' indicates start of transaction
				rd_wbm_stb_o		:   out std_logic;							--Strobe command from WBM
				rd_wbm_dat_i		:  	in std_logic_vector (7 downto 0);		--Data Out (8 bits)
				rd_wbm_stall_i		:	in std_logic;							--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				rd_wbm_ack_i		:   in std_logic;							--Input data has been successfuly acknowledged
				rd_wbm_err_i		:   in std_logic							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
			);
end entity img_man_manager;

architecture rtl_img_man_manager of img_man_manager is

	------------------------------	Constants	------------------------------------
	 ----fix to generic
	constant col_bits_c			:	positive 	:= 10;--integer(ceil(log(real(img_hor_pixels_g)) / log(2.0))) ; --Width of registers for coloum index
	constant row_bits_c			:	positive 	:= 10;--integer(ceil(log(real(img_ver_pixels_g)) / log(2.0))) ; --Width of registers for row index

	------------------------------	Types	------------------------------------
	type fsm_states is (
							fsm_idle_st,			-- Idle - wait to start 
							fsm_increment_coord_st,	-- increment coordinate by 1, if line is over move to next line
							fsm_address_calc_st,	-- send coordinates to Address Calc, if out of range WB BLACK_PIXEL(0) else continue
							fsm_READ_from_SDRAM_st, -- read 4 pixels from SDRAM according to result of addr_calc
							fsm_bilinear_st,		-- do a bilinear interpolation between the 4 pixels
							fsm_WB_to_SDRAM_st		-- Write Back result to SDRAM
						);
	type read_states is (		
							phase_1,
							phase_2,
							phase_3, 
							phase_4,
							phase_5
					);					
	------------------------------	Signals	------------------------------------
	-------------------------FSM
	signal cur_st			:	fsm_states;			-- Current State
	
	-------------------------Coordinate Counter Procces
	signal finish_image 		: std_logic;					-- flag indicating when image is complete, bottom left corner, working now on last pixel
	
	signal row_idx_sig		 :  signed (row_bits_c downto 0);	  --fix to generic
	signal col_idx_sig       :  signed (col_bits_c downto 0);  		--fix to generic
	
	------------------------Address Calculator
	--signal add_calc_OOR			:	std_logic;		--address calculator result is out of range (oor)
	--signal finish_addr_calc_st	:	std_logic;		--finish address calculate state
	--------------------------Read From SDRAM
	signal finish_read_st		:	std_logic;		--finish Read From SDRAM state
	signal en_read_proc		:	std_logic;		--start Read From SDRAM state
    signal phase_number 		:	read_states;
	--------------------------bilinear interpolation
	--signal finish_bilinear_st	:	std_logic;	--finish bilinear intepolation state
	--------------------------WB to SDRAM
	--signal finish_WB_st			:	std_logic;		--finish Write Back to SDRAM state

	--	###########################		Implementation		##############################	--
begin	
----------------------------------------------------------------------------------------
----------------------------		index valid  Processes			------------------------
----------------------------------------------------------------------------------------
----------------------------    the process controls when index output is valid    ------------------------
----------------------------------------------------------------------------------------
	index_valid_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			index_valid <= '0';
		elsif rising_edge (sys_clk) then	
			if (cur_st=fsm_increment_coord_st and finish_image='0') then
				index_valid		<= '1';
			else
				index_valid		<= '0';
			end if;	
		end if;
	end process index_valid_proc;	
----------------------------------------------------------------------------------------
----------------------------		fsm_proc Process			------------------------
----------------------------------------------------------------------------------------
----------------------------    This is the main FSM Process    ------------------------
----------------------------------------------------------------------------------------
	fsm_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			cur_st		<=	fsm_idle_st;
		elsif rising_edge (sys_clk) then
			case cur_st is
			------------------------------Idle State---------------------------------
				when fsm_idle_st =>
					wr_wbm_adr_o	<=	(others => '0');
					wr_wbm_tga_o	<=	(others => '0');
					wr_wbm_dat_o	<=	(others => '0');
					wr_wbm_cyc_o	<=	'0';
					wr_wbm_stb_o	<=	'0';
					wr_wbm_we_o		<=	'0';
					wr_wbm_tgc_o	<=	'0';
					rd_wbm_tga_o 	<=	(others => '0');	
					rd_wbm_cyc_o	<=	'0';	
					rd_wbm_stb_o	<=	'0';
					rd_wbm_adr_o	<=	(others => '0');	
					rd_wbm_tga_o	<=	(others => '0');	
					rd_wbm_cyc_o	<=	'0';
					rd_wbm_tgc_o	<=	'0';
					rd_wbm_stb_o	<=	'0';
					finish_read_st	<=	'0';						
					en_read_proc <=	'0';
					finish_image	<=	'0';
					
					if (req_trig='1')  then
						cur_st	<= 	fsm_increment_coord_st;
					else
						cur_st 	<= 	fsm_idle_st;	
					end if;				
			
			-----------------------------Increment coordinate state----------------------	
				when fsm_increment_coord_st	=>				
					if (finish_image = '1') then  			-- image is complete, back to idle
						cur_st	<=	fsm_idle_st;
					else
						cur_st 	<= 	fsm_address_calc_st;
					end if;
			
			-----------------------------Address calculate state----------------------						
				when fsm_address_calc_st =>
					if (addr_calc_oor ='1') then			--current index is out of range, WB black
						cur_st		<=	fsm_WB_to_SDRAM_st;
					elsif (addr_calc_valid ='1') then		--addr_calc is finish, continue to Read from SDRAM
						cur_st 	<= 	fsm_READ_from_SDRAM_st;	
					else
						cur_st 	<= 	fsm_address_calc_st;
					end if;	
			
			-----------------------------Read From SDRAM state----------------------					
				when fsm_READ_from_SDRAM_st =>
					en_read_proc	<= '1'; --start read process			
					if (finish_read_st='11')	then
						en_read_proc	<= '0'; --end read process	
						cur_st 	<= 	fsm_bilinear_st;			--for tb of coordinate process
					else if (finish_read_st='01')	then
						
					    cur_st	<=	fsm_READ_from_SDRAM_st;
					end if;	
			
			-----------------------------bilinear state----------------------
				when fsm_bilinear_st =>		
						cur_st 	<= 	fsm_WB_to_SDRAM_st;			--for tb of coordinate process
			
			-----------------------------Write Back to SDRAM state----------------------
				when fsm_WB_to_SDRAM_st =>
					if (finish_image ='0') then
						cur_st 	<= 	fsm_increment_coord_st;		--for tb of coordinate process
					else
						cur_st	<=	fsm_idle_st;
					end if;
			
			-----------------------------Debugg state, catch Unimplemented state
				when others =>
					cur_st	<=	fsm_idle_st;
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected" severity error;
				end case;
		end if;
	end process fsm_proc;
---------------------------------------------------------------------------------------
----------------------------	read_from_SDRAM process	-----------------------------------
---------------------------------------------------------------------------------------
-- the process will manage the read transaction from the sdram
-- the read will be executed in 4 phase, 2 phases for each address
-- 
-- 
---------------------------------------------------------------------------------------	
read_from_SDRAM : process (sys_clk,sys_rst)			
	begin
		if (sys_rst =reset_polarity_g) then	
			wr_wbm_adr_o	<=	(others => '0');
			wr_wbm_tga_o	<=	(others => '0');
			wr_wbm_dat_o	<=	(others => '0');
			wr_wbm_cyc_o	<=	'0';
			wr_wbm_stb_o	<=	'0';
			wr_wbm_we_o		<=	'0';
			wr_wbm_tgc_o	<=	'0';
			rd_wbm_tga_o 	<=	(others => '0');	
			rd_wbm_cyc_o	<=	'0';	
			rd_wbm_stb_o	<=	'0';
			finish_read_st	<=	'0';
		
		elsif rising_edge(sys_clk)  then
				
			case phase_number is		
				when phase_1 =>
					if (en_read_proc='1')  then
						--write 0x80 to Type register
						wr_wbm_adr_o	<=	"0000001101";
						wr_wbm_tga_o	<=	(others => '0');
						wr_wbm_dat_o	<=	"10000000";
						wr_wbm_cyc_o	<=	'1';
						wr_wbm_stb_o	<=	'1';
						wr_wbm_we_o		<=	'1';
						wr_wbm_tgc_o	<=	'1';
						phase_number <= phase_2;
					else
						phase_number	<= 	phase_1;
					end if;
				when phase_2 =>
					--write address to DBG_address_register		-- add another reg - 16 bit address
					wr_wbm_adr_o	<=	"0000000010";
					wr_wbm_dat_o	<=	"00110000";--address to be
					phase_number <=	phase_3;
				when phase_3 =>
					--write 0x81 to Type register
					wr_wbm_adr_o	<=	"0000001101";
					wr_wbm_dat_o	<=	"10000001";
					phase_number <=	phase_4;
				when phase_4 =>
					rd_wbm_tga_o 	<=	"0000000010";	
					rd_wbm_cyc_o	<=	'1';	
					rd_wbm_stb_o	<=	'1';
					if (rd_wbm_ack_i='1') then		--recieve ack on read
						finish_read_1st_pixel	<=	'1';
						phase_number	<=	phase_1;
					else
						finish_read_1st_pixel	<=	'0';
						phase_number		<=	phase_4;
					end if;	
					
				when others =>
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected in read sdram process" severity error;
				end case;	
		end if;	
	end process read_from_SDRAM;
---------------------------------------------------------------------------------------
----------------------------	coordinate process	-----------------------------------
---------------------------------------------------------------------------------------
-- THE process will advance the row/col indexes until end of image
-- when image is over a flag will rise - finish_image
-- reset will set the coordinates at (0,0)
-- init will set the coordinates at (1,1)
---------------------------------------------------------------------------------------	
coord_proc : process (sys_clk,sys_rst)			
	begin
		if (sys_rst =reset_polarity_g) then	
			finish_image <='0';
			row_idx_sig <=(others => '0');
			col_idx_sig <=(others => '0');
		elsif rising_edge(sys_clk) then
			if (cur_st=fsm_idle_st) then 				--initialize row and col counter
				--row_idx_sig(row_idx_sig'left downto 1) <=(others => '0');  --row starts with 0d1 
				--row_idx_sig(0)<='1';
				row_idx_sig <=(others => '0');
				col_idx_sig(row_idx_sig'left downto 1) <=(others => '0');  --col starts with 0d1 
				col_idx_sig(0)<='1';	
				finish_image <='0';
			elsif (cur_st=fsm_increment_coord_st)  then	--increment row if possible, else move to new col
				if (row_idx_sig< img_ver_pixels_g) then --increment row
					row_idx_sig<=row_idx_sig+1;
					finish_image <='0';
				else  	--(row_idx_sig == img_ver_pixels_g) -> co is over, move to new col
					if (col_idx_sig<img_hor_pixels_g) then
						row_idx_sig(row_idx_sig'left downto 1) <=(others => '0');
						row_idx_sig(0)<='1';
						col_idx_sig<=col_idx_sig+1;
					end if;	
				end if;
			elsif (cur_st=fsm_address_calc_st) and (col_idx_sig=img_hor_pixels_g) and (row_idx_sig=img_ver_pixels_g) then
				finish_image <='1';
			end if;
		end if;	
	end process coord_proc;
	-------------------Wire coordinates to out ports
	
	row_idx_out_proc:
	row_idx_out<=row_idx_sig;
	
	col_idx_out_proc:
	col_idx_out<=col_idx_sig;
							
--	###########################		Instances		##############################	--


end architecture rtl_img_man_manager;