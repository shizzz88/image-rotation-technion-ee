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

entity addr_calc_tb is
	generic
		(
			x_size_out				:	positive 	:= 600;				-- number of rows  in theoutput image
			y_size_out				:	positive 	:= 800;				-- number of columns  in the output image
			trig_frac_size			:	positive 	:= 7				-- number of digits after dot = resolution of fracture (binary)
			
		);
end entity addr_calc_tb;

architecture sim_addr_calc_tb of addr_calc_tb is

component addr_calc 
		generic (
			reset_polarity_g		:	std_logic	:= '0';			--Reset active low
			x_size_in				:	positive 	:= 96;				-- number of rows  in the input image
			y_size_in				:	positive 	:= 128;				-- number of columns  in the input image
			x_size_out				:	positive 	:= 600;				-- number of rows  in theoutput image
			y_size_out				:	positive 	:= 800;				-- number of columns  in the output image
			trig_frac_size			:	positive 	:= 7	;			-- number of digits after dot = resolution of fracture (binary)
			pipe_depth				:	positive	:= 12
			);

	port	(
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
				
				out_of_range		:	out std_logic;							--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				data_valid_out			:	out std_logic;		--data valid indicator
				
				delta_row_out		:	out	std_logic_vector		(trig_frac_size-1 downto 0);				--	 needed for bilinear interpolation
				delta_col_out		:	out	std_logic_vector		(trig_frac_size-1 downto 0);				--	 needed for bilinear interpolation
				
				--Clock and Reset
				clk_133				:	in std_logic;							--SDRAM clock
				clk_40				:	in std_logic;							--VESA Clock
				rst_133				:	in std_logic;							--Reset (133MHz)
				rst_40				:	in std_logic							--Reset (40MHz)

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
signal clk_133			:	std_logic := '0';
signal rst_133			:	std_logic;
signal clk_40			:	std_logic := '0';
signal rst_40			:	std_logic;

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
				
signal				out_of_range_sig		:	 std_logic;							--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
signal				data_valid_out_sig			:	 std_logic;					
signal				delta_row_out_sig		:	 std_logic_vector		(trig_frac_size-1 downto 0);				--	 needed for bilinear interpolation
signal				delta_col_out_sig		:	 std_logic_vector		(trig_frac_size-1 downto 0);

signal				start_moving			:	 std_logic;	                                                                        
--####################################################################################
---------------------------		process + inst	-----------------------------------------
begin

clk_133_proc:
clk_133	<=	not clk_133 after 3.75 ns;

--clk_40_proc:
--clk_40	<=	not clk_40 after 12.5 ns;

rst_133_proc:
rst_133	<=	'0', '1' after 100 ns;

--rst_40_proc:
--rst_40	<=	'0', '1' after 100 ns;

--assign constant signal values

zoom_factor_sig			<=	"000100000";				--zoom factor=0.25
-- sin_teta_sig		    <=  "001101110";				--teta=60 deg
-- cos_teta_sig		    <=  "001000000";
sin_teta_sig		    <=  "000000000";				--teta=0 deg
cos_teta_sig		    <=  "010000000";

x_crop_start_sig	    <=  "00000011110"; 				--x_crop=30
y_crop_start_sig	    <=  "00000011101";  			--y_crop=29                
ram_start_add_sig	    <=  "00000000000000000000000";	--ram start addr=0                           

--row_idx_sig <= to_signed(301,11);		--row,col =301
--col_idx_sig <= to_signed(301,11);

test_proc : process (clk_133)
	variable row_cnt : natural := 301;
	variable col_cnt : natural := 300;
	variable flag	 : natural := 0;
	begin
		if (rst_133 ='1') then	
		if rising_edge(clk_133) then
			if (col_cnt<y_size_out)  then
				row_cnt:=row_cnt+1;
			end if;
			row_idx_sig <= to_signed(row_cnt,11);
			col_idx_sig <= to_signed(col_cnt,11);
		end if;
		end if;
	end process test_proc;
                  

addr_calc_inst :	 addr_calc				
			generic map(
			reset_polarity_g		=> '0',		--Reset active low
			x_size_in				=> 96,			-- number of rows  in the input image
			y_size_in				=> 128,				-- number of columns  in the input image
			x_size_out				=> 600,				-- number of rows  in theoutput image
			y_size_out				=> 800,				-- number of columns  in the output image
			trig_frac_size			=> 7,			-- number of digits after dot = resolution of fracture (binary)
			pipe_depth				=> 12
			)                     
			
			port map
			(
				clk_133			=>	clk_133	,			
				clk_40			=>	clk_40	,		
				rst_133			=>	rst_133	,		
				rst_40			=>	rst_40	,		
				
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
				data_valid_out => data_valid_out_sig             		
			);

-- wait20_proc : process (clk_133)
	-- variable cnt : natural := 1;
	
	-- begin
		
		-- if  (rst_133='1') then
		-- start_moving<='0';	
		
		-- elsif  rising_edge(clk_133) then	
			
			-- cnt:=cnt+1;
			
			-- if (cnt=20) then
			-- start_moving<='1';
			-- end if;
		
		
		
		-- end if;
		
		
	-- end process wait20_proc;
						
			
-- row_col_proc : process (clk_133)
	-- variable row_cnt : natural := 0;
	-- variable col_cnt : natural := 1;
	-- variable flag	 : natural := 0;
	-- begin
		-- if rising_edge(clk_133) then
			
			-- if (col_cnt<y_size_out) and (rst_133='1') then
				
				-- if (row_cnt=x_size_out) then
					-- row_cnt:=0;
					-- col_cnt:=col_cnt+1;
				-- end if;
				-- row_cnt:=row_cnt+1;
			-- end if;
				
			
			-- row_idx_sig <= to_signed(row_cnt,11);
			-- col_idx_sig <= to_signed(col_cnt,11);
				
		-- end if;
	-- end process row_col_proc;
			

			
end architecture sim_addr_calc_tb;