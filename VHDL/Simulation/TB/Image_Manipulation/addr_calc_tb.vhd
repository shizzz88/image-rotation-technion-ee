------------------------------------------------------------------------------------------------
-- Model Name 	:	addr_calc_tb
-- File Name	:	addr_calc_tb.vhd
-- Generated	:	08/05/2012
-- Author		:	Uri & Ran
-- Project		:	Image Rotation
------------------------------------------------------------------------------------------------
-- Description: test bench file for address calculator
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		08/05/2012	
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use work.txt_util.all;

entity addr_calc_tb is
	generic
		(	
						reset_polarity_g		:	std_logic	:= '0';			--Reset active low

			file_name_g				:	string  	:= "test_modelsim.txt";		--out file name
			x_size_in_g				:	positive 	:= 384;		
			y_size_in_g				:	positive 	:= 512;		
			x_size_out_g				:	positive 	:= 600;
			y_size_out_g				:	positive 	:= 800;
			trig_frac_size			:	positive 	:= 7				-- number of digits after dot = resolution of fracture (binary)
			
		);
end entity addr_calc_tb;

architecture sim_addr_calc_tb of addr_calc_tb is

component addr_calc 
		generic (
			reset_polarity_g		:	std_logic	:= '0';			--Reset active low
			x_size_in_g				:	positive 	:= 96;				-- number of rows  in the input image
			y_size_in_g				:	positive 	:= 128;				-- number of columns  in the input image
			x_size_out_g				:	positive 	:= 600;				-- number of rows  in theoutput image
			y_size_out_g				:	positive 	:= 800;				-- number of columns  in the output image
			trig_frac_size_g			:	positive 	:= 7	;			-- number of digits after dot = resolution of fracture (binary)
			-- pipe_depth_g				:	positive	:= 12;
			valid_setup_g				:	positive	:= 5
			);

	port	(
				trigger_unit			:	in std_logic;
				zoom_factor			:	in signed (trig_frac_size+1 downto 0);	--zoom facotr given by user - x2,x4,x8 (zise fits to sin_teta)
				sin_teta			:	in signed (trig_frac_size+1 downto 0);	--sine of rotation angle - calculated by software. 7 bits of sin + 1 bit of signed
				cos_teta			:	in signed (trig_frac_size+1 downto 0);	--cosine of rotation angle - calculated by software. 
				
				
				row_idx_in			:	in signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed)
				col_idx_in			:	in signed (10 downto 0);		--the current column index of the output image
				x_crop_start	    :	in signed (10 downto 0);		--crop start index : the top left pixel for crop		
				y_crop_start		:	in signed (10 downto 0);		--crop start index : the top left pixel for crop
				
				ram_start_add_in	:	in std_logic_vector  (22 downto 0);		--SDram beginning address
				tl_out				:	out std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
				tr_out				:	out std_logic_vector (22 downto 0);		--top right pixel address in SDRAM
				bl_out				:	out std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
				br_out				:	out std_logic_vector (22 downto 0);		--bottom right pixel address in SDRAM
		
				delta_row_out		:	out	std_logic_vector		(trig_frac_size-1 downto 0);				--	 needed for bilinear interpolation
				delta_col_out		:	out	std_logic_vector		(trig_frac_size-1 downto 0);				--	 needed for bilinear interpolation
				
				enable					:	in std_logic;    	--enable unit port           
				unit_finish			:	out std_logic;
				out_of_range		:	out std_logic;							--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				data_valid_out			:	out std_logic;		--data valid indicator
				--Clock and Reset
				system_clk				:	in std_logic;							--SDRAM clock
				system_rst				:	in std_logic							--Reset (133MHz)
				
				-- -- Wishbone Master to Memory Management block
				-- wbm_dat_i			:	in std_logic_vector (7 downto 0);		--Data in (8 bits)
				-- wbm_stall_i			:	in std_logic;							--Slave is not ready to receive new data 
				-- wbm_ack_i			:	in std_logic;							--Input data has been successfuly acknowledged
				-- wbm_err_i			:	in std_logic;							--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				-- wbm_adr_o			:	out std_logic_vector (9 downto 0);		--Address
				-- wbm_tga_o			:	out std_logic_vector (9 downto 0);		--Address Tag : Read burst length-1 (0 represents 1 byte, 3FF represents 1023 bytes)
				-- wbm_cyc_o			:	out std_logic;							--Cycle command from WBM
				-- wbm_stb_o			:	out std_logic;							--Strobe command from WBM
				-- wbm_tgc_o			:	out std_logic							--Cycle Tag
			);
end component addr_calc;

--###############################################################################
-----------------------------	Signals		-----------------------------------
--Clock and Reset
signal system_clk			:	std_logic := '0';
signal system_rst			:	std_logic;


--input signals for address calc component
signal				zoom_factor_sig			:	signed (trig_frac_size+1 downto 0);	--zoom facotr given by user - x2,x4,x8 (zise fits to sin_teta)
signal				sin_teta_sig			:	signed (trig_frac_size+1 downto 0);	--sine of rotation angle - calculated by software. 7 bits of sin + 1 bit of signed
signal				cos_teta_sig			:	signed (trig_frac_size+1 downto 0);	--cosine of rotation angle - calculated by software. 
				
signal				row_idx_sig				:	signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed)
signal				col_idx_sig				:	signed (10 downto 0);		--the current column index of the output image
signal				x_crop_start_sig	    : 	signed (10 downto 0);		--crop start index : the top left pixel for crop		
signal				y_crop_start_sig		:	signed (10 downto 0);		--crop start index : the top left pixel for crop
				
signal				ram_start_add_sig		:	 std_logic_vector  (22 downto 0);		--SDram beginning address

signal				tl_out_sig				:	 std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
signal				tr_out_sig				:	 std_logic_vector (22 downto 0);		--top right pixel address in SDRAM
signal				bl_out_sig				:	 std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
signal				br_out_sig				:	 std_logic_vector (22 downto 0);		--bottom right pixel address in SDRAM
				
signal				out_of_range_sig		:	std_logic;							--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
signal				data_valid_out_sig		:	std_logic;					
signal				delta_row_out_sig		:	std_logic_vector		(trig_frac_size-1 downto 0);				--	 needed for bilinear interpolation
signal				delta_col_out_sig		:	std_logic_vector		(trig_frac_size-1 downto 0);

signal 				trigger					:	std_logic;
signal 				en_unit					:	std_logic;	 	                                                                        
signal				start_tb				:std_logic;



----------------------------------------------------------------------  READ PROCESS	-------------------------------------------------------------------------
 SIGNAL    newValueRead     : BOOLEAN := FALSE;
 SIGNAL    newValueToSave   : BOOLEAN := FALSE;
 SIGNAL    dataReadFromFile : REAL;
 SIGNAL    dataToSaveToFile : REAL;
 SIGNAL    lineNumber       : INTEGER:=1;  -- add line number to output file
 
 file out_file				: TEXT open write_mode is file_name_g;
----------------------------------------------------------------------------------------------

type fsm_states is (
							fsm_idle_st,			-- Idle - wait to start 
							fsm_trigger_st,
							fsm_increment_coord_st,	-- increment coordinate by 1, if line is over move to next line
							fsm_address_calc_st	-- send coordinates to Address Calc, if out of range WB BLACK_PIXEL(0) else continue

						);
signal curr_st		: fsm_states;					
 --####################################################################################
---------------------------		process + inst	-----------------------------------------
begin



	
clk_100_proc:
system_clk	<=	not system_clk after 5 ns;



rst_100_proc:
system_rst	<=	'0', '1' after 100 ns;

start_tb_proc:
start_tb <=	'0', '1' after 100 ns, '0' after 110 ns;

--assign constant signal values
--------------------------	ZOOM (from 256, not 128)!!!	-------------------------------------------------------------------
zoom_factor_sig			<=	"010000000";				--zoom factor=1 (x1)
--zoom_factor_sig			<=	"000100000";				--zoom factor=0.25 (x2)
--zoom_factor_sig			<=	"000010000";				--zoom factor=0.125 (x4)
--zoom_factor_sig			<=	"000001000";				--zoom factor=0.0625 (x8)
--zoom_factor_sig			<=	"000000100";				--zoom factor= (x16)


--------------------------	ANGLE (from 256, not 128)!!!	-------------------------------------------------------------------
--sin_teta_sig		    <=  "001101111";				--teta=60 deg
--cos_teta_sig		    <=  "001000000";
sin_teta_sig		    <=  "000000000";				--teta=0 deg
cos_teta_sig		    <=  "010000000";
--sin_teta_sig		    <=  "001110100";				--teta=153 deg
--cos_teta_sig		    <=  "100011100";
-- sin_teta_sig		    <=  "100000000";				--teta=90 deg
-- cos_teta_sig		    <=  "000000000";
--sin_teta_sig		    <=  "010110101";				--teta=45 deg
--cos_teta_sig		    <=  "010110101";
--sin_teta_sig		    <=  "000000000";				--teta=180 deg
--cos_teta_sig		    <=  "110000000";
--sin_teta_sig		    <=  "100101100";				--teta=304 deg
--cos_teta_sig		    <=  "010001111";
--sin_teta_sig		    <=  "100010000";				--teta=250 deg
--cos_teta_sig		    <=  "110101001";


---------------------------	CROP	-------------------------------------------------------------------
--x_crop_start_sig	    <=  "00000011110"; 				--x_crop=30
--y_crop_start_sig	    <=  "00000011101";  			--y_crop=29 
--x_crop_start_sig	    <=  "00000001010"; 				--x_crop=10
--y_crop_start_sig	    <=  "00000001010";  			--y_crop=10
-- x_crop_start_sig	    <=  "00000101101"; 				--x_crop=45
-- y_crop_start_sig	    <=  "00000101000";  			--y_crop=40  
x_crop_start_sig	    <=  "00000000001"; 				--x_crop=1
y_crop_start_sig	    <=  "00000000001";  			--y_crop=1                   
ram_start_add_sig	    <=  "00000000000000000000000";	--ram start addr=0                           

-- row_idx_sig <= to_signed(301,11);		--row,col =301
-- col_idx_sig <= to_signed(301,11);

fsm_proc: process (system_clk, system_rst)
	variable row_cnt : natural := (x_size_out_g-x_size_in_g)/2+1;
	variable col_cnt : natural := (y_size_out_g-y_size_in_g)/2+1;
	variable row_cnt_final_val : natural := row_cnt+x_size_in_g-1;
	variable col_cnt_final_val : natural := col_cnt+y_size_in_g-1;
	begin
		if (system_rst = reset_polarity_g) then
				trigger<='0';
				en_unit<='0';
				curr_st<=fsm_idle_st;
		elsif rising_edge (system_clk) then
			case curr_st is
			------------------------------Idle State--------------------------------- --
				when fsm_idle_st =>
					if(start_tb='1') then
						en_unit <='1';
						curr_st 	<= 	fsm_trigger_st;
					end if;	
            -----------------------------fsm_trigger_st-------------------------------
				when fsm_trigger_st=>
					trigger<='1';
					curr_st 	<= 	fsm_address_calc_st;
			-----------------------------Address calculate state----------------------						
				when fsm_address_calc_st =>
					trigger<='0';
					if (data_valid_out_sig='1') then
						curr_st<=fsm_increment_coord_st;						
					end if;	
			
			-----------------------------Increment coordinate state----------------------	
				when fsm_increment_coord_st	=>				
					if (col_cnt=col_cnt_final_val)   then	
						row_cnt:=row_cnt+1;
						col_cnt:=(y_size_out_g-y_size_in_g)/2+1;
						curr_st<=fsm_trigger_st;

					elsif (row_cnt<=row_cnt_final_val) then
						col_cnt:=col_cnt+1;
						curr_st<=fsm_trigger_st;

					else
						curr_st<=fsm_idle_st;
					end if;


			-----------------------------Debugg state, catch Unimplemented state
				when others =>
					curr_st	<=	fsm_idle_st;
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected" severity error;
				end case;
			row_idx_sig <= to_signed(row_cnt,11);
			col_idx_sig <= to_signed(col_cnt,11);
		end if;
	end process fsm_proc;
	

	
	
    
    
addr_calc_inst :	 addr_calc				
			generic map(
			reset_polarity_g		=> '0',		--Reset active low
			x_size_in_g				=> x_size_in_g,				-- number of rows  in the input image
			y_size_in_g				=> y_size_in_g,				-- number of columns  in the input image
			x_size_out_g			=> x_size_out_g,				-- number of rows  in theoutput image
			y_size_out_g			=> y_size_out_g,				-- number of columns  in the output image
			trig_frac_size_g			=> 7,			-- number of digits after dot = resolution of fracture (binary)
			-- pipe_depth_g				=> 12,
			valid_setup_g				=> 8
			)                     
			
			port map
			(
				system_clk			=>	system_clk	,			
				system_rst			=>	system_rst	,		
					
				
				zoom_factor		=>	zoom_factor_sig,	
				sin_teta		=>	sin_teta_sig,	
				cos_teta		=>	cos_teta_sig,			
				x_crop_start	=>	x_crop_start_sig,			
				y_crop_start	=>	y_crop_start_sig, 	
				ram_start_add_in	=>	ram_start_add_sig, 		
					
				row_idx_in		=>	row_idx_sig	, 	
				col_idx_in		=>	col_idx_sig	, 
					
				tl_out		   	=>	tl_out_sig,
				tr_out		    =>	tr_out_sig,           		
				bl_out		    =>	bl_out_sig,           		
				br_out		    =>	br_out_sig,
				out_of_range    =>	out_of_range_sig,
				delta_row_out   =>	delta_row_out_sig,
				delta_col_out   =>	delta_col_out_sig,			
				data_valid_out 	=> data_valid_out_sig,
				trigger_unit	=> trigger,
				enable				=>en_unit    	--enable unit port           

			);

print(out_file, "col row tl tr bl br d_row d_col oor");

writeProcess : PROCESS(system_clk)

  BEGIN

    if rising_edge(system_clk) then

		IF (data_valid_out_sig = '1') THEN
			--print(out_file, "0x"&hstr(tl_out_sig)& " 0x"&hstr(tr_out_sig)& " 0x"&hstr(bl_out_sig)& " 0x"&hstr(br_out_sig)& " "&str(delta_row_out_sig)& " "&str(delta_col_out_sig)& "   " &str(out_of_range_sig));
			--print tl,tr,bl,br,delta_row,delta_col (decimal) , out_of_range //str((row_idx_sig))& " "&str((col_idx_sig))& 
			print(out_file, str(to_integer(col_idx_sig)-2)&" "&str(to_integer(row_idx_sig))&" "&str(CONV_INTEGER(tl_out_sig))& " "&str(CONV_INTEGER(tr_out_sig))& " "&str(CONV_INTEGER(bl_out_sig))& " "&str(CONV_INTEGER(br_out_sig))& " "&str(CONV_INTEGER(delta_row_out_sig))& " "&str(CONV_INTEGER(delta_col_out_sig))& " " &str(out_of_range_sig));
		END IF;
		
	end if;

  END PROCESS writeProcess;

			
end architecture sim_addr_calc_tb;