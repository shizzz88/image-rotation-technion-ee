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
--			fix phase 2 at read_from_SDRAM to support address length of 2 register (16 bit).
--			fix top_fsm Read From SDRAM state to support to pixels burst of read.
--			check if index valid is necessary , fix to work according to calc coord proc
--			write to registers using ack response, wait for ack before next state		

------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity img_man_manager is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				trig_frac_size_g	:	positive := 7;				-- number of digits after dot = resolution of fracture (binary)
				img_hor_pixels_g	:	positive					:= 128;	--640 pixel in a coloum
				img_ver_pixels_g	:	positive					:= 96;	--480 pixels in a row
				display_hor_pixels_g	:	positive					:= 800;	--800 pixel in a coloum
				display_ver_pixels_g	:	positive					:= 600	--600 pixels in a row
			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;								-- clock
				sys_rst				:	in std_logic;								-- Reset					
				req_trig			:	in std_logic;								-- Trigger for image manipulation to begin,
					
				-- addr_calc					
				
				addr_row_idx_in			:	out signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed) --from coord calc process to address calc
				addr_col_idx_in			:	out signed (10 downto 0);		--the current column index of the output image                                    --from coord calc process to address calc
				
				addr_tl_out				:	in std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
				addr_bl_out				:	in std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
				addr_delta_row_out		:	in	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				addr_delta_col_out		:	in	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation

				addr_out_of_range		:	in std_logic;		--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				addr_data_valid_out		:	in std_logic;		--data valid indicator

				addr_unit_finish		:	in std_logic;                              --signal indicating addr_calc is finished
				addr_trigger_unit		:	out std_logic;                               --enable signal for addr_calc
				addr_enable				:	out std_logic;  
			--	-- bilinear
			--	bili_req_trig			:	out std_logic;				-- Trigger for image manipulation to begin,
			--	bili_tl_pixel			:	out	std_logic_vector(trig_frac_size_g downto 0);		--top left pixel
			--	bili_tr_pixel			:	out	std_logic_vector(trig_frac_size_g downto 0);		--top right pixel
			--	bili_bl_pixel           :   out	std_logic_vector(trig_frac_size_g downto 0);		--bottom left pixel
			--	bili_br_pixel           :   out	std_logic_vector(trig_frac_size_g downto 0);		--bottom right pixel
			--	bili_delta_row			:	out	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
			--	bili_delta_col			:	out	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
			--	bili_pixel_valid		:	in std_logic;				--valid signal for index
			--	bili_pixel_res			:	in std_logic_vector (trig_frac_size_g downto 0); 	--current row index           --fix to generic
				
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
	constant col_bits_c					:	positive 	:= 10;--integer(ceil(log(real(img_hor_pixels_g)) / log(2.0))) ; --Width of registers for coloum index
	constant row_bits_c					:	positive 	:= 10;--integer(ceil(log(real(img_ver_pixels_g)) / log(2.0))) ; --Width of registers for row index

	constant mem_mng_type_reg_addr_c	:	std_logic_vector (9 downto 0)		:= "0000001101";	--Type register address
	constant mem_mng_dbg_lsb_reg_addr_c		:	std_logic_vector (9 downto 0)		:= "0000000010";	--dbg register address
	constant mem_mng_dbg_msb_reg_addr_c		:	std_logic_vector (9 downto 0)		:= "0000000011";	--Type register address
--	###########################		Components		##############################	--
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
							read_idle_st,
							write_type_reg_0x80_1_st,
							write_dbg_reg_lsb_1_st,write_dbg_reg_msb_1_st,
							write_type_reg_0x81_1_st, 
							wait_ack_1_st,
							write_type_reg_0x80_2_st,
							write_dbg_reg_lsb_2_st,write_dbg_reg_msb_2_st,
							write_type_reg_0x81_2_st,
							wait_ack_2_st
					);					
	------------------------------	Signals	------------------------------------
	signal index_valid		: std_logic; 		--  signal for coordinate incerement process
	-------------------------FSM
	signal cur_st			:	fsm_states;			-- Current State
	
	-------------------------Coordinate Counter Procces
	signal finish_image 		: std_logic;					-- flag indicating when image is complete, bottom left corner, working now on last pixel
	
	signal row_idx_sig		 :  signed (row_bits_c downto 0);	  --
	signal col_idx_sig       :  signed (col_bits_c downto 0);  	  --
	
	------------------------Address Calculator
	signal en_addr_calc_proc				:	std_logic_vector (1 downto 0);	
	signal addr_calc_oor			:	std_logic;		--address calculator result is out of range (oor)
	signal addr_calc_valid			:	std_logic;		--address calculator result is valid
	signal addr_calc_finish_st		:	std_logic;		--finish address calculate state
	signal addr_calc_tl				:	std_logic_vector (22 downto 0);
	signal addr_calc_bl				:	std_logic_vector (22 downto 0);
	signal addr_calc_d_row			:   std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
	signal addr_calc_d_col			:   std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
	
	--------------------------Read From SDRAM
	signal finish_read_pxl		:	std_logic_vector (1 downto 0);		--finish Read From SDRAM state
	signal en_read_proc			:	std_logic;		--start Read From SDRAM state
    signal read_SDRAM_state 		:	read_states;
	--------------------------bilinear interpolation
	signal en_bili_proc			:	std_logic;		--start bilinear
	signal tl_pixel		:	std_logic_vector (7 downto 0);		--top left pixel, first pair
	signal tr_pixel		:	std_logic_vector (7 downto 0);		--top right pixel, first pair
	signal bl_pixel		:	std_logic_vector (7 downto 0);		--bottom left pixel, second pair
	signal br_pixel		:	std_logic_vector (7 downto 0);		--bottom right pixel, second pair
	signal delta_row		:	std_logic_vector(trig_frac_size_g-1 downto 0);	
	signal delta_col		:	std_logic_vector(trig_frac_size_g-1 downto 0);		
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
			en_read_proc <=	'0';
			en_addr_calc_proc	<="00";

		
		elsif rising_edge (sys_clk) then
			case cur_st is
			------------------------------Idle State--------------------------------- --
				when fsm_idle_st =>
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
						cur_st 	<= 	fsm_address_calc_st;	-- finish calculate index 
						en_addr_calc_proc		<="01";		-- trigger addr_calc
					end if;
			
			-----------------------------Address calculate state----------------------						
				when fsm_address_calc_st =>
					en_addr_calc_proc		<="10";							--diable  addr_calc trigger
					
					if ((addr_calc_oor and addr_calc_valid) = '1') then		--current index is out of range, WB black
						en_addr_calc_proc	<="00";
						--cur_st			<=	fsm_WB_to_SDRAM_st;
						cur_st			<=fsm_increment_coord_st;
					elsif ((not(addr_calc_oor) and addr_calc_valid) ='1') then		--addr_calc is finish, continue to Read from SDRAM
						cur_st 			<= 	fsm_READ_from_SDRAM_st;
						--cur_st			<=fsm_increment_coord_st;
						en_addr_calc_proc	<="00";
					else
						cur_st 			<= 	fsm_address_calc_st;					
					end if;	
			
			-----------------------------Read From SDRAM state----------------------					
				when fsm_READ_from_SDRAM_st =>
					en_read_proc	<= '1'; 					--start read process			
					if (finish_read_pxl="11")	then			--finish read 2  adressess
						en_read_proc	<= '0';					--end read process	
						cur_st 	<= 	fsm_bilinear_st;			
					elsif (finish_read_pxl="01")	then			-- finish read 1st adresss
						cur_st	<=	fsm_READ_from_SDRAM_st;
					elsif (finish_read_pxl="00")	then			-- not finish read 1st adresss.
						cur_st	<=	fsm_READ_from_SDRAM_st;	
					end if;	
			
			-----------------------------bilinear state----------------------
				when fsm_bilinear_st =>	
					
					--	cur_st 	<= 	fsm_WB_to_SDRAM_st;			--for tb of coordinate process
			
			-----------------------------Write Back to SDRAM state----------------------
				when fsm_WB_to_SDRAM_st =>
					--if (finish_image ='0') then
					--	cur_st 	<= 	fsm_increment_coord_st;		--for tb of coordinate process
					--else
					--	cur_st	<=	fsm_idle_st;
					--end if;
			       
			-----------------------------Debugg state, catch Unimplemented state
				when others =>
					cur_st	<=	fsm_idle_st;
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected" severity error;
				end case;
		end if;
	end process fsm_proc;
	
---------------------------------------------------------------------------------------
----------------------------	addr_calc process	-----------------------------------
---------------------------------------------------------------------------------------
-- THE process will activate the address calculator
-- input coordinate from coord_proc
-- output 4 pixel addreses (need only two)+ 2 delta fractions 
---------------------------------------------------------------------------------------	
addr_calc_proc : process (sys_clk,sys_rst)			
	begin
		if (sys_rst =reset_polarity_g) then	
			addr_trigger_unit		<=	'0';
			addr_row_idx_in			<=(others => '0');
			addr_col_idx_in			<=(others => '0');
			
			addr_calc_tl		<=  (others => '0');
			addr_calc_bl		<=  (others => '0');
			addr_calc_d_row		<=  (others => '0');	                
			addr_calc_d_col		<=  (others => '0'); 
			
			addr_calc_oor		<=  '0';
			addr_calc_valid		<=  '0' ;
			addr_enable			<= '0';
			
		elsif rising_edge(sys_clk) then
			--trigger addres calculator
			if (  en_addr_calc_proc ="01")  then --begin address calculation , send trigger to addr_calc
				addr_trigger_unit	<='1';
				addr_enable			<='1';
			elsif ( en_addr_calc_proc ="10") then -- calculation in progress ,disable trigger
				addr_trigger_unit	<=	'0';
				addr_enable			<='1';
			elsif ( en_addr_calc_proc ="00") then -- calculation is finished or not begun
				addr_enable			<='0';
			end if;	
			addr_row_idx_in		<=  row_idx_sig;	--from coord calc process to address calc
			addr_col_idx_in		<=  col_idx_sig;	--from coord calc process to address calc
			addr_calc_tl		<=  addr_tl_out;
			addr_calc_bl		<=  addr_bl_out;
			addr_calc_d_row		<=  addr_delta_row_out;	                
			addr_calc_d_col		<=  addr_delta_col_out; 
			addr_calc_oor		<=  addr_out_of_range;
			addr_calc_valid		<=  addr_data_valid_out ;
				
		end if;	
		
end process addr_calc_proc;	



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
			finish_read_pxl	<=	(others => '0');			
			read_SDRAM_state	<=	read_idle_st;
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
			finish_read_pxl	<=	(others => '0');							
			finish_image	<=	'0';
			
		elsif rising_edge(sys_clk)  then	
			case read_SDRAM_state is		
				
				when read_idle_st =>
					finish_read_pxl<="00";   			--reset read pixel counter 
					if ((en_read_proc='1') and (finish_read_pxl /="11"))  then
						read_SDRAM_state	<= 	write_type_reg_0x80_1_st;
					else
						read_SDRAM_state	<= 	read_idle_st;
						rd_wbm_tga_o 	<=	"0000000000";	
						rd_wbm_cyc_o	<=	'0';	
						rd_wbm_stb_o	<=	'0';
						wr_wbm_adr_o	<=	(others => '0');
						wr_wbm_tga_o	<=	(others => '0');
						wr_wbm_dat_o	<=	(others => '0');
						wr_wbm_cyc_o	<=	'0';
						wr_wbm_stb_o	<=	'0';
						wr_wbm_we_o		<=	'0';
						wr_wbm_tgc_o	<=	'0';
					end if;
				when write_type_reg_0x80_1_st =>
						--write 0x80 to Type register in mem_mng
						wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						wr_wbm_tga_o	<=	(others => '0');
						wr_wbm_dat_o	<=	"10000000";
						wr_wbm_cyc_o	<=	'1';
						wr_wbm_stb_o	<=	'1';
						wr_wbm_we_o		<=	'1';
						wr_wbm_tgc_o	<=	'1';
						read_SDRAM_state <= write_dbg_reg_lsb_1_st;

				when write_dbg_reg_lsb_1_st =>
					--write address to DBG_address_register(0x2) - bottom bits of address in mem_mng
					wr_wbm_adr_o	<=	mem_mng_dbg_lsb_reg_addr_c;
					wr_wbm_dat_o	<=	addr_calc_tl(7 downto 0);	--address from addr_calc
					read_SDRAM_state <=	write_dbg_reg_msb_1_st;

				when write_dbg_reg_msb_1_st =>
					--write address to DBG_address_register(0x3) - top bits of address in mem_mng
					wr_wbm_adr_o	<=	mem_mng_dbg_lsb_reg_addr_c;
					wr_wbm_dat_o	<=	addr_calc_tl(15 downto 8); --address from addr_calc
					read_SDRAM_state <=	write_type_reg_0x81_1_st;
								
				when write_type_reg_0x81_1_st =>
					--write 0x81 to Type register in mem_mng
					wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
					wr_wbm_dat_o	<=	"10000001";
					read_SDRAM_state <=	wait_ack_1_st;
				when wait_ack_1_st =>
					rd_wbm_tga_o 	<=	"0000000010";	
					rd_wbm_cyc_o	<=	'1';	
					rd_wbm_stb_o	<=	'1';
					if (rd_wbm_ack_i='1') then		--recieve ack on read
						finish_read_pxl	<= "01";	-- finish first pixels pair
						
						read_SDRAM_state	<=	write_type_reg_0x80_2_st;
					else
						finish_read_pxl	<=	"00";
						read_SDRAM_state		<=	wait_ack_1_st;
					end if;	
				
				when write_type_reg_0x80_2_st =>
						--terminate read req
						rd_wbm_tga_o 	<=	"0000000000";	
						rd_wbm_cyc_o	<=	'0';	
						rd_wbm_stb_o	<=	'0';
						--write 0x80 to Type register
						wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
						wr_wbm_tga_o	<=	(others => '0');
						wr_wbm_dat_o	<=	"10000000";
						wr_wbm_cyc_o	<=	'1';
						wr_wbm_stb_o	<=	'1';
						wr_wbm_we_o		<=	'1';
						wr_wbm_tgc_o	<=	'1';
						read_SDRAM_state <= write_dbg_reg_lsb_2_st;
				when write_dbg_reg_lsb_2_st =>
					--write address to DBG_address_register(0x2) - bottom bits of address
					wr_wbm_adr_o	<=	mem_mng_dbg_msb_reg_addr_c;
					wr_wbm_dat_o	<=	addr_calc_bl(7 downto 0);--address from addr_calc
					read_SDRAM_state <=	write_dbg_reg_msb_2_st;

				when write_dbg_reg_msb_2_st =>
					--write address to DBG_address_register(0x3) - top bits of address
					wr_wbm_adr_o	<=	mem_mng_dbg_msb_reg_addr_c;
					wr_wbm_dat_o	<=	addr_calc_bl(15 downto 8);--address from addr_calc
					read_SDRAM_state <=	write_type_reg_0x81_2_st;
				when write_type_reg_0x81_2_st =>
					--write 0x81 to Type register
					wr_wbm_adr_o	<=	mem_mng_type_reg_addr_c;
					wr_wbm_dat_o	<=	"10000001";
					read_SDRAM_state <=	wait_ack_2_st;
					read_SDRAM_state <=	wait_ack_2_st;
				when wait_ack_2_st =>
					rd_wbm_tga_o 	<=	"0000000010";	
					rd_wbm_cyc_o	<=	'1';	
					rd_wbm_stb_o	<=	'1';
					if (rd_wbm_ack_i='1') then			-- recieve ack on read
						finish_read_pxl	<= "11";		-- finish second pixels pair
						read_SDRAM_state	<=	read_idle_st;
					else
						finish_read_pxl	<=	"01";
						read_SDRAM_state		<=	wait_ack_2_st;
					end if;							
				
				when others =>
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected in read sdram process" severity error;
				end case;	
		end if;	
	end process read_from_SDRAM;
	---------------------------------------------------------------------------------------
------------------------------	bilinear process	-----------------------------------
-----------------------------------------------------------------------------------------
---- THE process will cotrol the  bilinear interpolation execution using the bilinear.vhd block
---- reminder: input 4 pixels, output 1 pixel
--
-----------------------------------------------------------------------------------------	
--bili_proc : process (sys_clk,sys_rst)			
--	begin
--		if (sys_rst =reset_polarity_g) then	
--			
--		elsif rising_edge(sys_clk) then
--			if (en_bili_proc='1') then
--				bili_tl_pixel 	<=	tl_pixel ;
--				bili_tr_pixel 	<=	tr_pixel; 
--				bili_bl_pixel 	<=	bl_pixel ;
--				bili_br_pixel 	<=	br_pixel ;
--				bili_delta_row	<=  delta_row;
--				bili_delta_col	<=  delta_col;
--				--bili_req_trig	<= '1';
--			bili_pixel_valid		:	in std_logic;				--valid signal for index
--			bili_pixel_res			:	in std_logic_vector (trig_frac_size_g downto 0); 	--current row index           --fix to generic	
--			
--			
--		end if;	
--	end process bili_proc;

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
				if (row_idx_sig< display_ver_pixels_g) then --increment row
					row_idx_sig<=row_idx_sig+1;
					finish_image <='0';
				else  	--(row_idx_sig == display_ver_pixels_g) -> co is over, move to new col
					if (col_idx_sig<display_hor_pixels_g) then
						row_idx_sig(row_idx_sig'left downto 1) <=(others => '0');
						row_idx_sig(0)<='1';
						col_idx_sig<=col_idx_sig+1;
					end if;	
				end if;
			elsif (cur_st=fsm_address_calc_st) and (col_idx_sig=display_hor_pixels_g) and (row_idx_sig=display_ver_pixels_g) then
				finish_image <='1';
			end if;
		end if;	
end process coord_proc;

							
--	###########################		Instances		##############################	--


end architecture rtl_img_man_manager;