------------------------------------------------------------------------------------------------
-- Model Name 	:	Address Calculator
-- File Name	:	Addr_Calc.vhd
-- Generated	:	27.03.1012
-- Author		:	Ran Mizrahi&Uri Tzipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   Claculates 4 pixels from input image in order to build the output image
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		27.3.2012	Ran&Uri					creation
--			1.01		3.6.2012	Ran&Uri					organize, separte processes, add enable input and total valid output port.
--			1.02		08.04.2013	uri						change valid bit, valid counts valid_setup_g cycles after trigger and rises for one cycle 
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 		check optimal sine and cosine fraction resolution - now its 2 decimal digit resolution [0 downto -7]
--			(2)			add valid/notvalid port for some signals
--			(3)			singular cases - teta =90,180,270,0 
--			(4)			fix size_calc_proc Process	
--			(5)			improve "convert [i,j] matrix form addreses to SDRAM address" to simple +1,+128
--			(6)			delete unneccesery output ports, top right and bottom left and all corresponding signals and calculations
----------------------------------------------------------------------------------------------
--                       MATH Functionality- EXPLAINED
--
--						- - - - Col,y - - - - 
--				 		---------------------
--				 |		|                   | 
--				 |		|                   | 
--				 |		|                   | 
--			Row,x		|     	Image       | 
--				 |		|                   | 
--				 |		|                   | 
--				 |		|                   | 
--				 		---------------------
--						
--          row=vertical=x
--          col=horizontal=y         
--
--          RowSizeIn=96;
--          ColSizeIn=128;
--          RowStart=30;
--          ColStart=29;
--          Row_size_after_crop=RowSizeIn+1-RowStart;%m=67
--          Col_size_after_crop=ColSizeIn+1-ColStart;%n=100
--          
--          row_fraction_calc =(  ZoomFactor*(RowIndexIn - VerResOut/2)*cos(teta) + ZoomFactor* (ColIndexIn - HorResOut/2)*sin(teta)+Row_size_after_crop/2);
--          col_fraction_calc =( -ZoomFactor*(RowIndexIn - VerResOut/2)*sin(teta) + ZoomFactor* (ColIndexIn - HorResOut/2)*cos(teta)+Col_size_after_crop/2);
--
--
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work ;

entity addr_calc is
	generic (
			reset_polarity_g		:	std_logic	:= '0';			--Reset active low
			x_size_in_g				:	positive 	:= 96;				-- number of rows  in the input image
			y_size_in_g				:	positive 	:= 128;				-- number of columns  in the input image

			x_size_out_g				:	positive 	:= 600;				-- number of rows  in theoutput image
			y_size_out_g				:	positive 	:= 800;				-- number of columns  in the output image
			trig_frac_size_g			:	positive 	:= 7;				-- number of digits after dot = resolution of fracture (binary)
			pipe_depth_g				:	positive	:= 12;				-- 
			valid_setup_g				:	positive	:= 10
			);
	port	(
				
				zoom_factor			:	in signed (trig_frac_size_g+1 downto 0);	--zoom facotr given by user - x2,x4,x8 (zise fits to sin_teta)
				sin_teta			:	in signed (trig_frac_size_g+1 downto 0);	--sine of rotation angle - calculated by software. 
				cos_teta			:	in signed (trig_frac_size_g+1 downto 0);	--cosine of rotation angle - calculated by software. 
				
				row_idx_in			:	in signed (10 downto 0);		--the current row index of the output image (2^10==>9 downto 0 + 1 bit of signed)
				col_idx_in			:	in signed (10 downto 0);		--the current column index of the output image
				x_crop_start	    :	in signed (10 downto 0);		--crop start index : the top left pixel for crop ,1 for full image		
				y_crop_start		:	in signed (10 downto 0);		--crop start index : the top left pixel for crop,1 for full image
				ram_start_add_in	:	in std_logic_vector  (22 downto 0);		--SDram beginning address
				
                tl_out				:	out std_logic_vector (22 downto 0);		--top left pixel address in SDRAM
				tr_out				:	out std_logic_vector (22 downto 0);		--top right pixel address in SDRAM
				bl_out				:	out std_logic_vector (22 downto 0);		--bottom left pixel address in SDRAM
				br_out				:	out std_logic_vector (22 downto 0);		--bottom right pixel address in SDRAM
				delta_row_out		:	out	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				delta_col_out		:	out	std_logic_vector		(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				
				out_of_range		:	out std_logic;		--asserts '1' while the input calculated pixel is out of range (negative value or exceeding img size after crop
				data_valid_out		:	out std_logic;		--data valid indicator
				
				--CLK, RESET, ENABLE
				enable					:	in std_logic;    	--enable unit port           
				unit_finish				:	out std_logic;                              --signal indicating addr_calc is finished
				trigger_unit			:	in std_logic;                               --enable signal for addr_calc
				system_clk				:	in std_logic;							--SDRAM clock
				system_rst				:	in std_logic							--Reset (133MHz)
			);
end entity addr_calc;

architecture arc_addr_calc of addr_calc is

--	###########################		Costants		##############################	--
constant x_vector_size					:	positive 	:= integer (ceil(log(real(x_size_out_g)) / log(2.0))) -1 ;	--Width of vector for rows :=9
constant y_vector_size					:	positive 	:= integer (ceil(log(real(y_size_out_g)) / log(2.0))) -1 ;	--Width of vector for columns :=9
constant x_signed_vector_size			:	positive 	:=	x_vector_size+1;			--Width of signed vector for rows :=10
constant y_signed_vector_size			:	positive 	:=	y_vector_size+1;            --Width of signed vector for columns :=10
constant coordinate_size_shifted_7		:	positive	:= x_vector_size+1+7;										--original size + signed +shift_7 = 17
constant coordinate_size_shifted_21		:	positive	:= x_vector_size+1+21	;									--original size + signed +shift_21 = 31
constant result_size					:	positive	:= coordinate_size_shifted_7 + zoom_factor'left + sin_teta'left + 2  ;--cos_teta_size + zoom_factor_size + x_size_out_g_shift + 2  = 8+17+8+2 = 35
constant shift_3_times					: 	positive	:= trig_frac_size_g * 3 ;


--###########################	Signals		###################################--

signal new_frame_x_size 		:	integer range 0 to x_size_out_g; 		--size of row after crop 
signal new_frame_y_size 		:	integer range 0 to y_size_out_g; 		--size of column after crop 

signal row_fraction_calc		: 	signed (result_size downto 0);	-- holds a temp calc of row index in the origin image
signal col_fraction_calc		: 	signed (result_size downto 0);

-------------------------------------------------------------------- temp pipeline signals------------------------------------------------
signal a1						: 	signed (coordinate_size_shifted_7 downto 0);		
signal b1						: 	signed (coordinate_size_shifted_7 downto 0);	
signal c1						: 	signed (coordinate_size_shifted_21 downto 0);	

signal a2						: 	signed (coordinate_size_shifted_7 + x_vector_size downto 0);	
signal b2						: 	signed (coordinate_size_shifted_7 + x_vector_size downto 0);	
signal c2						: 	signed (coordinate_size_shifted_21 downto 0);	

signal a3						: 	signed (result_size downto 0);	
signal b3						: 	signed (result_size downto 0);	
signal c3						: 	signed (coordinate_size_shifted_21 downto 0);	

signal x1						: 	signed (coordinate_size_shifted_7 downto 0);		
signal y1						: 	signed (coordinate_size_shifted_7 downto 0);	
signal z1						: 	signed (coordinate_size_shifted_21 downto 0);	

signal x2						: 	signed (coordinate_size_shifted_7 + x_vector_size downto 0);	
signal y2						: 	signed (coordinate_size_shifted_7 + x_vector_size downto 0);	
signal z2						: 	signed (coordinate_size_shifted_21 downto 0);	

signal x3						: 	signed (result_size downto 0);	
signal y3						: 	signed (result_size downto 0);	
signal z3						: 	signed (coordinate_size_shifted_21 downto 0);	

signal 	delta_row_out_pipe1		:  	std_logic_vector		(trig_frac_size_g-1 downto 0);
signal 	delta_row_out_pipe2		:  	std_logic_vector		(trig_frac_size_g-1 downto 0);
signal	delta_col_out_pipe1		:	std_logic_vector		(trig_frac_size_g-1 downto 0);
signal	delta_col_out_pipe2		:	std_logic_vector		(trig_frac_size_g-1 downto 0);
------------------------------------------------------------------------------------------------------------------------------------



--signals shifted left by 7, 21 accordingly
signal x_size_out_shift			:	signed (coordinate_size_shifted_7 downto 0);	
signal y_size_out_shift			:	signed (coordinate_size_shifted_7 downto 0);	
signal new_frame_x_size_shift	:	signed (coordinate_size_shifted_21 downto 0 );
signal new_frame_y_size_shift	:	signed (coordinate_size_shifted_21 downto 0 );

--Signals
signal tl_x						:	std_logic_vector (row_idx_in'left - 1 downto 0);		--top left row coordinate pixel in input image(9 downto 0)
signal tl_y						:	std_logic_vector (row_idx_in'left - 1 downto 0);		--top left column coordinate pixel in input image
signal tr_x						:	std_logic_vector (row_idx_in'left - 1 downto 0);		--top right row coordinate pixel in input image
signal tr_y						:	std_logic_vector (row_idx_in'left - 1 downto 0);		--top right column coordinate pixel in input image
signal bl_x						:	std_logic_vector (row_idx_in'left - 1 downto 0);		--bottom left row coordinate pixel in input image
signal bl_y						:	std_logic_vector (row_idx_in'left - 1 downto 0);		--bottom left column coordinate pixel in input image
signal br_x						:	std_logic_vector (row_idx_in'left - 1 downto 0);		--bottom right row coordinate pixel in input image
signal br_y						:	std_logic_vector (row_idx_in'left - 1 downto 0);		--bottom right column coordinate pixel in input image
                                                    
signal row_idx_in_shift			: signed (coordinate_size_shifted_7 downto 0);		--the current row index of the output image with shift left by 7
signal col_idx_in_shift		    : signed (coordinate_size_shifted_7 downto 0);		--the current column index of the output image	with shift left by 7
-- signal x_crop_start_shift		: signed (coordinate_size_shifted_7 downto 0);		--x_crop in in with shift left by 7
-- signal y_crop_start_shift       : signed (coordinate_size_shifted_7 downto 0);		--y_crop in in with shift left by 7
           
signal row_fraction_calc_after_crop		: 	signed (result_size downto 0); -- holds a temp calc of row index in the origin image + with crop command
signal col_fraction_calc_after_crop    	: 	signed (result_size downto 0); -- holds a temp calc of col index in the origin image + with crop command

signal a_if_1	 		     : boolean; 			--temp signals for  pipeline of "out of range if"
signal a_if_2	 		 	 : boolean; 			--temp signals for  pipeline of "out of range if"
signal a_if_3				 : boolean; 			--temp signals for  pipeline of "out of range if"
signal a_if_4	  			 : boolean; 			--temp signals for  pipeline of "out of range if"
signal a_if_5	 		     : boolean; 			--temp signals for  pipeline of "out of range if"
signal a_if_6	  	    	 : boolean; 			--temp signals for  pipeline of "out of range if"
signal in_range       : boolean; 	--temp signals for  pipeline of "out of range if"


signal tl_out_phase_1 : std_logic_vector (20 downto 0);				--pipeline signals for calculation of output addr.
signal tr_out_phase_1 : std_logic_vector (20 downto 0);				--pipeline signals for calculation of output addr.
signal bl_out_phase_1 : std_logic_vector (20 downto 0);				--pipeline signals for calculation of output addr.
signal br_out_phase_1 : std_logic_vector (20 downto 0);				--pipeline signals for calculation of output addr.

--valid proc signals
--signal pipe_counter				: integer range 0 to pipe_depth_g-1;		--pipe counter
signal en_valid_count			: std_logic;							    -- indicates if this is the first time we count to pipe length
signal valid_counter			: integer range 0 to valid_setup_g-1;		--valid counter
signal	data_valid_out_sig		:	 std_logic;
--unit finish proc signals
signal total_counter		: integer range 0 to y_size_out_g*x_size_out_g;		--total counter=800*600
signal unit_finish_sig		: std_logic;									--local signal indicating unit finish calc
--
signal enable_unit			: std_logic;				--enable(1) or disable(0) unit signal

--****************************************************************************************************************
---------------------------------------------------BEGIN----------------------------------------------------------
--****************************************************************************************************************
begin
----------------------------------------------------------------------------------------
	----------------------------		size_calc_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- a process that calculates different frame sizes 
    -- active on trigger
    -- reset on unit_finish or system reset
	----------------------------------------------------------------------------------------

	-- if (system_rst = reset_polarity_g) then				--RESET
		-- new_frame_x_size			<= 0;
		-- new_frame_y_size            <= 0;
		-- new_frame_x_size_shift		<= (others =>'0');	
		-- new_frame_y_size_shift		<= (others =>'0');
		-- row_idx_in_shift			<= (others =>'0');
		-- col_idx_in_shift			<= (others =>'0');
		-- x_size_out_shift			<= (others =>'0');
		-- y_size_out_shift			<= (others =>'0');
	-- end if;
	
	--if	(enable_unit='1') then
	--calc new frame size = frame size after crop
			new_frame_x_size			<= 	x_size_in_g + 1 - conv_integer(std_logic_vector(x_crop_start));                                            
			new_frame_y_size			<= 	y_size_in_g + 1 - conv_integer(std_logic_vector(y_crop_start));                                            
			
	--divide by 2 and shift left by 21 (shift_left_by_21 ==> multiply by 128^3, divide by 2=> shift right by 1)						
			new_frame_x_size_shift(new_frame_x_size_shift'left  )					<= '0' ;
			new_frame_x_size_shift(new_frame_x_size_shift'left-1 downto new_frame_x_size_shift'left-2-x_vector_size)	<= to_signed(new_frame_x_size,x_signed_vector_size+1) ;
			new_frame_x_size_shift(new_frame_x_size_shift'left-2-x_vector_size-1 downto 0 ) 							<=( others => '0') ;
			
			new_frame_y_size_shift(new_frame_y_size_shift'left  )					<= '0' ;
			new_frame_y_size_shift(new_frame_y_size_shift'left-1 downto new_frame_y_size_shift'left-2-y_vector_size) 	<= to_signed(new_frame_y_size,y_signed_vector_size+1) ;
			new_frame_y_size_shift(new_frame_y_size_shift'left-2-y_vector_size-1 downto 0 )							    <=( others => '0') ;---------------------------synthesis error new_frame_y_size_shift(new_frame_y_size_shift'left-2-y_vector_size downto 0 )							    <=( others => '0') ;
			
			--uri wrote:
			--new_frame_y_size_shift(new_frame_y_size_shift'left  )					<= '0' ;
			--new_frame_y_size_shift(new_frame_y_size_shift'left-1 downto new_frame_y_size_shift'left-2-y_vector_size) 	<= to_signed(new_frame_y_size,y_signed_vector_size+1) ;
			--new_frame_y_size_shift(new_frame_y_size_shift'left-2- y_vector_size downto 0 )							    <=( others => '0') ;---------------------------synthesis error new_frame_y_size_shift(new_frame_y_size_shift'left-2-y_vector_size downto 0 )							    <=( others => '0') ;

			
	--shift left by 7 (shift_left_by_7 ==> multiply by 128)
			row_idx_in_shift(row_idx_in_shift'left downto trig_frac_size_g )	<= row_idx_in	;
			row_idx_in_shift(trig_frac_size_g -1 downto 0)	<=( others => '0') ;
			
			col_idx_in_shift(col_idx_in_shift'left downto trig_frac_size_g )	<= col_idx_in	;
			col_idx_in_shift(trig_frac_size_g -1 downto 0)	<=( others => '0') ;

	--divide by 2 and shift left by 7 (shift_left_by_7 ==> multiply by 128,  divide by 2=> shift right by 1)
			x_size_out_shift(x_size_out_shift'left)					<='0' ;		-- =shift_left_by_7(x_size_out/2)
			x_size_out_shift(x_size_out_shift'left-1 downto x_size_out_shift'left-2-x_vector_size)  <= to_signed(x_size_out_g,x_signed_vector_size+1);
			x_size_out_shift(x_size_out_shift'left-2-x_vector_size-1 downto 0) 						<= ( others => '0') ;
			
			y_size_out_shift(y_size_out_shift'left ) 					<='0' ;--=shift_left_by_7(y_size_out_g/2)
			y_size_out_shift(y_size_out_shift'left-1 downto y_size_out_shift'left-2-y_vector_size)  <= to_signed(y_size_out_g,y_signed_vector_size+1);
			y_size_out_shift(y_size_out_shift'left-2-y_vector_size-1 downto 0) 						<= ( others => '0') ;
			
			--uri wrote:
			--y_size_out_shift(y_size_out_shift'left downto y_size_out_shift'left-1) 					<=( others => '0') ;--=shift_left_by_7(y_size_out_g/2)
			--y_size_out_shift(y_size_out_shift'left-2 downto y_size_out_shift'left-3-y_vector_size)  <= to_signed(y_size_out_g,y_signed_vector_size+1);
			--y_size_out_shift(y_size_out_shift'left-y_vector_size-3 downto 0) 						<= ( others => '0') ;			
			
			
			
    --end if;

----------------------------------------------------------------------------------------
	----------------------------		trig_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- a process that controls internal enable signal for the whole system according to external trigger
    -- when trigger rises -> enable_unit asserts 1
    -- when unit_finish_sig rises -> enable_unit asserts 0
	----------------------------------------------------------------------------------------
trig_proc: process (system_clk, system_rst)
begin
	if (system_rst = reset_polarity_g) then				--RESET
		enable_unit<='0';
	elsif (rising_edge (system_clk))   then 		
		if ((not(enable) or unit_finish_sig) ='1') then		--unit_finish_sig is 1 or enable is 0
			enable_unit <='0';
		elsif 	( (trigger_unit and enable) ='1') then		-- trigger and enable
			enable_unit<='1';
		elsif  (not(trigger_unit) and enable and enable_unit) ='1' then  	--enable after trigger, calc not completed
			enable_unit<='1';
			-- if (valid_counter = valid_setup_g-1) then
				-- en_valid_count <= "11";
			-- else
				-- en_valid_count <= "10";
			-- end if;				
		end if;
	end if;	
end process trig_proc;
----------------------------------------------------------------------------------------
	----------------------------		valid_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- a process indicating when data output is valid
    -- after reset, the proccess counts until pipe_depth_g then data_valid_out_sig='1'
    -- aftewards every valid_setup_g-1 clocks data_valid_out_sig='1'
	----------------------------------------------------------------------------------------
valid_proc: process (system_clk, system_rst)
begin
	if (system_rst = reset_polarity_g) then                         --RESET
		data_valid_out_sig <= '0';
		valid_counter<=0;
		en_valid_count <='0';
	elsif (rising_edge (system_clk))   then  							--rising edge+enable+notRESET
		
		if ((not(enable) or unit_finish_sig) ='1') then		--unit_finish_sig is 1 or enable is 0
			valid_counter <= valid_counter;
			data_valid_out_sig <= '0';
		
		elsif (   not(trigger_unit) and  not(en_valid_count) and enable) ='1' then --wait for trigger
			valid_counter <= valid_counter;
			data_valid_out_sig <= '0';
		
		elsif 	( (trigger_unit and enable and  not(en_valid_count)) ='1') then		-- trigger and enable
			valid_counter <= 0;
			en_valid_count <= '1';
			data_valid_out_sig <= '0';
			
		elsif (   ( en_valid_count and enable) ='1') then  	--enable after trigger, calc not completed
			if  (valid_counter < valid_setup_g-1) then
				valid_counter <= valid_counter+1;
				data_valid_out_sig <= '0';
				en_valid_count <= '1';
				
			elsif(valid_counter = valid_setup_g-1) then		--finished calcl, restart and wait for trigger
				valid_counter <= 0;
				data_valid_out_sig <= '1';
				en_valid_count <='0';
			end if;	
		end if;	
	
	end if;	
end process valid_proc;
data_valid_out<=data_valid_out_sig;                                 --connect data_valid_out port to data_valid_out_sig

----------------------------------------------------------------------------------------
	-- ----------------------------		valid_proc Process			------------------------
	-- ----------------------------------------------------------------------------------------
	-- -- a process indicating when data output is valid
    -- -- after reset, the proccess counts until pipe_depth_g then data_valid_out_sig='1'
    -- -- aftewards every valid_setup_g-1 clocks data_valid_out_sig='1'
	-- ----------------------------------------------------------------------------------------
-- valid_proc: process (system_clk, system_rst)
-- begin
		-- if (system_rst = reset_polarity_g) then                         --RESET
		-- data_valid_out_sig <= '0';
		-- en_valid_count<= true;
		-- valid_counter<=0;
		-- pipe_counter<=0;
	-- elsif (rising_edge (system_clk))   then  							--rising edge+enable+notRESET
		-- if (enable_unit='1')  then
			-- if (pipe_counter < pipe_depth_g-1) then                     --counting for the first time
				-- pipe_counter <= pipe_counter+1;
				-- data_valid_out_sig <= '0';
			-- elsif (en_valid_count=false) then                         --not counting for the first time :wait for valid_setup_g-1 cycles before 
																		-- --because data is inputed every valid_setup_g-1 cycles
				
				-- if (valid_counter =valid_setup_g-1) then                --setup time is over
					-- data_valid_out_sig <= '1';
					-- valid_counter<=0;
				-- else 
					-- valid_counter<=valid_counter+1;                     --still in setup time
					-- data_valid_out_sig <= '0';
				-- end if;
		
			-- elsif (pipe_counter = pipe_depth_g-1) then                  --first time count - latency=pipe_depth_g-1=11
				-- data_valid_out_sig <= '1';
				-- en_valid_count<=false;
			-- end if;
		-- end if;	
	-- end if;	
-- end process valid_proc;
-- data_valid_out<=data_valid_out_sig;                                 --connect data_valid_out port to data_valid_out_sig

----------------------------------------------------------------------------------------
	----------------------------		unit_finish Process			------------------------
	----------------------------------------------------------------------------------------
	-- a process indicating when the unit is finished calculating all the pixels addresses
    -- the unit counts upto y_size_out_g*x_size_out_g where total_counter is incremented every time data_valid_out_sig='1'
	----------------------------------------------------------------------------------------
	
unit_finish_proc: process (system_clk, system_rst)
begin
	
	if (system_rst = reset_polarity_g) then                         --RESET
		unit_finish_sig <= '0';
		total_counter<=0;
	elsif (rising_edge (system_clk))   then  --rising edge+enable+notRESET
		if  (enable_unit='1')  then
			if (data_valid_out_sig='1') then                             --increment counter   
				total_counter<=total_counter+1;		
			end if;
			if (total_counter=y_size_out_g*x_size_out_g-1) then            --assert finish   
				unit_finish_sig<='1';
				total_counter<=0;
			else
				unit_finish_sig<='0';
			end if;
		end if;
	end if;	
end process unit_finish_proc;			
unit_finish<=unit_finish_sig;

----------------------------------------------------------------------------------------
	----------------------------		in_range_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- The process pipelines a complex if condition which tests if calculated pixels are in/out of range
    --  out of range condition:if  
    --                             row_fraction_calc>1 &&
    --                             col_fraction_calc>1 &&
    --                             row_fraction_calc<=Row_size_after_crop-1 &&
    --                             col_fraction_calc<=Col_size_after_crop-1 
    --                         then
    --                              out of range='0'
    --                         else
    --                              out of range='1'
---------------------------------------------before PIPE------------------------------------------------------------------------
--5 top bits are Unnecessary: 2 multiply operations + 3 signed bits
		-- if  (
				-- (row_fraction_calc(row_fraction_calc'left) = '0') and (row_fraction_calc ( result_size - 5 downto shift_3_times) >  "0000000001") and 		-- if row_fraction_calc > 0
				-- (col_fraction_calc(col_fraction_calc'left) = '0') and (col_fraction_calc ( result_size - 5 downto shift_3_times) >  "0000000001") and		-- test if indexes are in range
			    -- (row_fraction_calc(row_fraction_calc'left downto 1) < new_frame_x_size_shift) and
			    -- (col_fraction_calc(col_fraction_calc'left downto 1) < new_frame_y_size_shift) 
			-- ) then
	----------------------------------------------------------------------------------------
is_out_of_range_proc: process (system_clk, system_rst)
begin
	if (system_rst = reset_polarity_g) then
		a_if_1	<=	false;	--a1--6 are boolean;
		a_if_2	<=	false;
		a_if_3	<=	false;
		a_if_4	<=	false;
		a_if_5	<=	false;
		a_if_6	<=	false;
		in_range <= false;
	elsif (rising_edge (system_clk))  then
		if (enable_unit='1') then
			a_if_1	<= row_fraction_calc(row_fraction_calc'left) = '0';
			a_if_2	<= row_fraction_calc ( result_size - 5 downto shift_3_times) >=  "0000000001";
			a_if_3	<= col_fraction_calc(col_fraction_calc'left) = '0';
			a_if_4	<= col_fraction_calc ( result_size - 5 downto shift_3_times) >=  "0000000001";
			a_if_5	<= row_fraction_calc(row_fraction_calc'left downto 1) <= new_frame_x_size_shift;
			a_if_6	<= col_fraction_calc(col_fraction_calc'left downto 1) <= new_frame_y_size_shift;
			in_range	<=	a_if_1 and a_if_2 and a_if_3 and a_if_4 and a_if_5 and a_if_6;
		end if;
	end if;
end process is_out_of_range_proc;


----------------------------------------------------------------------------------------
	----------------------------		calc_out_img_size_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- The process calculates  coloum and row index of output image
--              row_fraction_calc =(  ZoomFactor*(RowIndexIn - VerResOut/2)*cos(teta) + ZoomFactor* (ColIndexIn - HorResOut/2)*sin(teta)+Row_size_after_crop/2);
--              col_fraction_calc =( -ZoomFactor*(RowIndexIn - VerResOut/2)*sin(teta) + ZoomFactor* (ColIndexIn - HorResOut/2)*cos(teta)+Col_size_after_crop/2);
	----------------------------------------------------------------------------------------
	calc_out_img_size_proc: process (system_clk, system_rst)
	begin
		if (system_rst = reset_polarity_g) then
			--new_frame_x_size				<=	0;
			--new_frame_y_size				<=	0;
			row_fraction_calc		        <= (others =>'0');
			col_fraction_calc		        <= (others =>'0');
			a1						        <= (others =>'0');
			a2						        <= (others =>'0');
			a3						        <= (others =>'0');
			b1						        <= (others =>'0');
			b2						        <= (others =>'0');
			b3						        <= (others =>'0');
			c1						        <= (others =>'0');
			c2						        <= (others =>'0');
			c3						        <= (others =>'0');
			x1						        <= (others =>'0');
			x2						        <= (others =>'0');
			x3						        <= (others =>'0');
			y1						        <= (others =>'0');
			y2						        <= (others =>'0');
			y3						        <= (others =>'0');
			z1						        <= (others =>'0');
			z2						        <= (others =>'0');
			z3						        <= (others =>'0');
			--x_size_out_shift		        <= (others =>'0');
			--y_size_out_shift		        <= (others =>'0');
			--new_frame_x_size_shift	    <= (others =>'0');
			--new_frame_y_size_shift        <= (others =>'0');
			--row_idx_in_shift		        <= (others =>'0');
			--col_idx_in_shift		        <= (others =>'0');
			
		elsif (rising_edge (system_clk))   then
		if 	(enable_unit='1') then
			----calc new frame size = frame size after crop
			--new_frame_x_size			<= 	x_size_in_g + 1 - conv_integer(std_logic_vector(x_crop_start));                                            
			--new_frame_y_size			<= 	y_size_in_g + 1 - conv_integer(std_logic_vector(y_crop_start));                                            
			--
			----divide by 2 and shift left by 21 (shift_left_by_21 ==> multiply by 128^3, divide by 2=> shift right by 1)						
			--new_frame_x_size_shift(new_frame_x_size_shift'left downto new_frame_x_size_shift'left-1 )					<=( others => '0') ;
			--new_frame_x_size_shift(new_frame_x_size_shift'left-2 downto new_frame_x_size_shift'left-2-x_vector_size)	<= to_signed(new_frame_x_size,x_signed_vector_size) ;
			--new_frame_x_size_shift(new_frame_x_size_shift'left-2-x_vector_size-1 downto 0 ) 							<=( others => '0') ;
			--
			--new_frame_y_size_shift(new_frame_y_size_shift'left downto new_frame_y_size_shift'left-1 )					<=( others => '0') ;
			--new_frame_y_size_shift(new_frame_y_size_shift'left-2 downto new_frame_y_size_shift'left-2-y_vector_size) 	<= to_signed(new_frame_y_size,y_signed_vector_size) ;
			--new_frame_y_size_shift(new_frame_y_size_shift'left-2-y_vector_size downto 0 )							    <=( others => '0') ;
			--
			----shift left by 7 (shift_left_by_7 ==> multiply by 128)
			--row_idx_in_shift(row_idx_in_shift'left downto trig_frac_size_g )	<= row_idx_in	;
			--row_idx_in_shift(trig_frac_size_g -1 downto 0)	<=( others => '0') ;
			--
			--col_idx_in_shift(col_idx_in_shift'left downto trig_frac_size_g )	<= col_idx_in	;
			--col_idx_in_shift(trig_frac_size_g -1 downto 0)	<=( others => '0') ;
			
			--divide by 2 and shift left by 7 (shift_left_by_7 ==> multiply by 128,  divide by 2=> shift right by 1)
			--x_size_out_shift(x_size_out_shift'left downto x_size_out_shift'left-1)					<=( others => '0') ;		-- =shift_left_by_7(x_size_out/2)
			--x_size_out_shift(x_size_out_shift'left-2 downto x_size_out_shift'left-2-x_vector_size)  <= to_signed(x_size_out_g,x_signed_vector_size);
			--x_size_out_shift(x_size_out_shift'left-2-x_vector_size-1 downto 0) 						<= ( others => '0') ;
			--
			--y_size_out_shift(y_size_out_shift'left downto y_size_out_shift'left-1) 					<=( others => '0') ;--=shift_left_by_7(y_size_out_g/2)
			--y_size_out_shift(y_size_out_shift'left-2 downto y_size_out_shift'left-2-y_vector_size)  <= to_signed(y_size_out_g,y_signed_vector_size);
			--y_size_out_shift(y_size_out_shift'left-2-y_vector_size-1 downto 0) 						<= ( others => '0') ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------			
----------------------							row_fraction_calc pipelined						-------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------
			a1 					<=	row_idx_in_shift - x_size_out_shift;
			a2					<=	a1 * zoom_factor;
			a3					<=	a2 * cos_teta;
			
			b1 					<=	col_idx_in_shift - y_size_out_shift;
			b2					<=	b1 * zoom_factor;
			b3					<=	b2*sin_teta;
			
			c1					<=	new_frame_x_size_shift;
			c2					<=	c1;
			c3					<=	c2;
			
			row_fraction_calc	<=	a3+b3+c3;
--------------------------------------------------------------------------------------------------------------------------------------------------------------			
------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------------------	
----------------------							col_fraction_calc pipelined						---------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------
			x1 					<=	col_idx_in_shift - y_size_out_shift;
			x2					<=	x1 * zoom_factor;
			x3					<=	x2 * cos_teta;
			
			y1 					<=	row_idx_in_shift - x_size_out_shift;
			y2					<=	y1 * zoom_factor;
			y3					<=	y2*sin_teta;
			
			z1					<=	new_frame_y_size_shift;
			z2					<=	z1;
			z3					<=	z2;
			
			col_fraction_calc	<=	x3-y3 + z3;
		end if;
		end if;	
--------------------------------------------------------------------------------------------------------------------------------------------------------------			
--------------------------------------------------------------------------------------------------------------------------------------------------------------		
	
----------------------------------------------before PIPE-----------------------------------------------------------------------------------------------------	
--	row_fraction_calc			<=	(	   
--											  (zoom_factor*( (row_idx_in_shift)- x_size_out_shift) *cos_teta) --temp row indx calc, before rounding
--											+ (zoom_factor*( (col_idx_in_shift)- y_size_out_shift) *sin_teta)    
--											+ new_frame_x_size_shift
--											);
--	col_fraction_calc			<= 	(
--											   (zoom_factor*( (col_idx_in_shift)- y_size_out_shift) *cos_teta)
--											  - (zoom_factor*( (row_idx_in_shift)- x_size_out_shift) *sin_teta) --temp col indx calc, before rounding
--											 + new_frame_y_size_shift
--											 );

	
end process calc_out_img_size_proc;			

--------------------------------------------------------------------------------------------------
	----------------------------		in_range_calcs Process			--------------------------
	----------------------------------------------------------------------------------------------
	-- The process calculates RAM address and fraction(for intepolation) when indexes are in range
	----------------------------------------------------------------------------------------------
	in_range_calcs: process (system_clk, system_rst)
	begin
		if (system_rst = reset_polarity_g) then
			out_of_range 					<= 	'0' ;
			tl_x					        <= (others =>'0');
			tl_y					        <= (others =>'0');
			tr_x					        <= (others =>'0');
			tr_y					        <= (others =>'0');
			bl_x					        <= (others =>'0');
			bl_y					        <= (others =>'0');
			br_x					        <= (others =>'0');
			br_y					        <= (others =>'0');             
			
			row_fraction_calc_after_crop    <= (others =>'0');
			col_fraction_calc_after_crop    <= (others =>'0');
			tl_out							<= (others =>'0');
			tr_out		                    <= (others =>'0');
			bl_out		                    <= (others =>'0');
			br_out		                    <= (others =>'0');
			delta_row_out                   <= (others =>'0');
		    delta_col_out                   <= (others =>'0');
			delta_row_out_pipe1             <= (others =>'0');
			delta_row_out_pipe2             <= (others =>'0');
			delta_col_out_pipe1             <= (others =>'0');
			delta_col_out_pipe2             <= (others =>'0');
			
			tl_out_phase_1                  <= (others =>'0');
			tr_out_phase_1                  <= (others =>'0');
			bl_out_phase_1                  <= (others =>'0');
			br_out_phase_1 	                <= (others =>'0');
			
			
			
			
			
		elsif (rising_edge (system_clk))   then	
			if (enable_unit='1') then
				if (in_range = true) then
					
					out_of_range 				<= '0' ; -- if is taken if in range (FLAG)  
					
					--Crop final calculation
					row_fraction_calc_after_crop( result_size - 5 downto shift_3_times)	<= row_fraction_calc( result_size - 5 downto shift_3_times) + x_crop_start(x_crop_start'left-1 downto 0);		
					
					--move [i,j] to ROI by [Xstart,Ystat].
					col_fraction_calc_after_crop( result_size - 5 downto shift_3_times)	<= col_fraction_calc( result_size - 5 downto shift_3_times) + y_crop_start(x_crop_start'left-1 downto 0);
					row_fraction_calc_after_crop( shift_3_times-1 downto 0)	<= row_fraction_calc( shift_3_times-1 downto 0) ;		--move [i,j] to ROI by [Xstart,Ystat].
					col_fraction_calc_after_crop( shift_3_times-1 downto 0)	<= col_fraction_calc( shift_3_times-1 downto 0) ;
				
					-- round up and down, take integer part of calculation
					tl_x	<=	std_logic_vector ( row_fraction_calc_after_crop (result_size - 5 downto shift_3_times)); 	--take the 10 relevant bits of the integer part of row_fraction_calc (30 downto shift_3_times)
					tl_y	<=	std_logic_vector ( col_fraction_calc_after_crop (result_size - 5 downto shift_3_times));		
					tr_x	<=	std_logic_vector ( row_fraction_calc_after_crop (result_size - 5 downto shift_3_times));	
					tr_y	<=	std_logic_vector ( col_fraction_calc_after_crop (result_size - 5 downto shift_3_times)) + '1';	
					bl_x	<=	std_logic_vector ( row_fraction_calc_after_crop (result_size - 5 downto shift_3_times)) + '1';	
					bl_y	<=	std_logic_vector ( col_fraction_calc_after_crop (result_size - 5 downto shift_3_times));	
					br_x	<=	std_logic_vector ( row_fraction_calc_after_crop (result_size - 5 downto shift_3_times)) + '1';	
					br_y	<=	std_logic_vector ( col_fraction_calc_after_crop (result_size - 5 downto shift_3_times)) + '1';		
		
					-- calculate delta row/col- necessary for bilinear interpolation	
					delta_row_out_pipe1	<=	std_logic_vector (row_fraction_calc_after_crop (shift_3_times-1 downto 14));		
					delta_row_out_pipe2 <=delta_row_out_pipe1;
					delta_row_out<=delta_row_out_pipe2;
					delta_col_out_pipe1	<=	std_logic_vector (col_fraction_calc_after_crop (shift_3_times-1 downto 14));
					delta_col_out_pipe2 <=delta_col_out_pipe1;
					delta_col_out<=delta_col_out_pipe2;
					
					-- convert [i,j] matrix form addreses to SDRAM address
			
					--without pipeline     +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					-- tl_out	<=	ram_start_add_in + (tl_x - '1') *std_logic_vector( to_signed(y_size_in_g,10)) + tl_y;
					-- tr_out	<=	ram_start_add_in + (tr_x - '1') *std_logic_vector( to_signed(y_size_in_g,10)) + tr_y;
					-- bl_out	<=	ram_start_add_in + (bl_x - '1') *std_logic_vector( to_signed(y_size_in_g,10)) + bl_y;
					-- br_out	<=	ram_start_add_in + (br_x - '1') *std_logic_vector( to_signed(y_size_in_g,10)) + br_y;
					--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++	
					--      with pipeline     +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					tl_out_phase_1 	<=(tl_x - "10") *std_logic_vector( to_signed(y_size_in_g,y_signed_vector_size+1));
					tl_out	<=tl_out_phase_1+ram_start_add_in+tl_y- "10";                                                       
					
					tr_out_phase_1 	<=(tr_x - "10") *std_logic_vector( to_signed(y_size_in_g,y_signed_vector_size+1));
					tr_out	<=tr_out_phase_1+ram_start_add_in+tr_y- "10";
					
					bl_out_phase_1 	<=(bl_x - "10") *std_logic_vector( to_signed(y_size_in_g,y_signed_vector_size+1));
					bl_out	<=bl_out_phase_1+ram_start_add_in+bl_y- "10";
					
					br_out_phase_1 	<=(br_x - "10") *std_logic_vector( to_signed(y_size_in_g,y_signed_vector_size+1));
					br_out	<=br_out_phase_1+ram_start_add_in+br_y- "10";
		
				else -- pixel is out of range
					tl_x	<=	 ( others => '0') ;		
					tl_y	<=	 ( others => '0') ;
					tr_x	<=	 ( others => '0') ;
					tr_y	<=	 ( others => '0') ;
					bl_x	<=	 ( others => '0') ;
					bl_y	<=	 ( others => '0') ;
					br_x	<=	 ( others => '0') ;
					br_y	<=	 ( others => '0') ;
					delta_row_out	<=( others => '0') ;
					delta_col_out	<=( others => '0') ;
					out_of_range	<= '1';
					tl_out 		 <=	 ( others => '0') ;
					tr_out  	 <=	 ( others => '0') ;
					bl_out   	 <=	 ( others => '0') ;
					br_out  	 <=	 ( others => '0') ;
					tl_out_phase_1 		 <=	 ( others => '0') ;
					tr_out_phase_1  	 <=	 ( others => '0') ;
					bl_out_phase_1   	 <=	 ( others => '0') ;
					br_out_phase_1  	 <=	 ( others => '0') ;
				end if	 ; 
			end if;
		end if;
	end process in_range_calcs;
		
end architecture arc_addr_calc;