------------------------------------------------------------------------------------------------
-- Model Name 	:	Bilinear Interpolator
-- File Name	:	bilinear.vhd
-- Generated	:	28.08.2012
-- Author		:	Uri Tsipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   the block make a bilinear interpolation between 4 pixels
--					
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		28.08.2012	Uri					creation
--			
------------------------------------------------------------------------------------------------
-- TO DO:
--				
--		
--					
----------------------------------------------------------------------------------------------
--                       MATH Functionality- EXPLAINED
--		4  adjacent pixels: TL,TR,BL,BR 
--		requested pixel : $
--		weight : delta row - distance between top row to $ ,fraction ranged in[0,1]
--				 delta col - distance between left col to $ ,fraction ranged in[0,1]
--
--		result : 	I1=    (1-delta_col)*top_left    +   delta_col*top_right
--            		I2=    (1-delta_col)*bottom_left +   delta_col*bottom_right
--            		result=(1-delta_row)*I1          +   delta_row*I2;				
--
--						- - - - Col,y - - - - 
--				 		T.L.-------------T.R.
--				 |		|                   | 
--				 |		|                   | 
--				 |		|     $             | 
--			   Row,x	|     	   			| 
--				 |		|                   | 
--				 |		|                   | 
--				 |		|                   | 
--				 		B.L.-------------B.R.
--						
------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity bilinear is
	generic (
				reset_polarity_g		:	std_logic	:= '0';			--Reset active low
				pipeline_depth_g		:	positive := 4;
				trig_frac_size_g		:	positive := 7				-- number of digits after dot = resolution of fracture (binary)

			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;				-- clock
				sys_rst				:	in std_logic;				-- Reset
				req_trig			:	in std_logic;				-- Trigger for image manipulation to begin,
				--from SDRAM
				tl_pixel			:	in	std_logic_vector(trig_frac_size_g downto 0);		--top left pixel
				tr_pixel			:	in	std_logic_vector(trig_frac_size_g downto 0);		--top right pixel
				bl_pixel            :   in	std_logic_vector(trig_frac_size_g downto 0);		--bottom left pixel
				br_pixel            :   in	std_logic_vector(trig_frac_size_g downto 0);		--bottom right pixel
				--from Addr_Calc
				delta_row			:	in	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation
				delta_col			:	in	std_logic_vector(trig_frac_size_g-1 downto 0);				--	 needed for bilinear interpolation

				
				pixel_valid				:	out std_logic;				--valid signal for index
				pixel_res			:	out std_logic_vector (trig_frac_size_g downto 0) 	--current row index           --fix to generic
			
			);
end entity bilinear;

architecture rtl_bilinear of bilinear is

	------------------------------	Constants	------------------------------------
	constant	pipe_depth_const:	positive 	:= integer (ceil(log(real(pipeline_depth_g)) / log(2.0)))  ;
	------------------------------	Types	------------------------------------
				
	------------------------------	Signals	------------------------------------
	--delta calculation
	signal		delta_row_comp	:	std_logic_vector (trig_frac_size_g-1 downto 0); 
	signal		delta_col_comp  :	std_logic_vector (trig_frac_size_g-1 downto 0);
	--main calculation
	signal		a1  	:	std_logic_vector (trig_frac_size_g*2 downto 0);	
	signal		a2  	:	std_logic_vector (trig_frac_size_g*2 downto 0);	
	signal		b1  	:	std_logic_vector (trig_frac_size_g*2 downto 0);	
	signal		b2  	:	std_logic_vector (trig_frac_size_g*2 downto 0);
	signal		I1  	:	std_logic_vector (trig_frac_size_g*2 downto 0);	
	signal		I2  	:	std_logic_vector (trig_frac_size_g*2 downto 0);
	signal		c1  	:	std_logic_vector (trig_frac_size_g*3 downto 0);	
	signal		c2  	:	std_logic_vector (trig_frac_size_g*3 downto 0);	
	signal		res_sig :	std_logic_vector (trig_frac_size_g*3 downto 0);	
	--enable/trigger process
	signal      enable_unit			:	std_logic;	--enable unit signal, rises upon trigger	
	signal		valid_counter		:	std_logic_vector (pipe_depth_const downto 0);	
	
--	###########################		Implementation		##############################	--
begin	


----------------------------------------------------------------------------------------
	----------------------------		valid and trigger Process			------------------------
	----------------------------------------------------------------------------------------
	-- a process indicating when the unit is finished calculating all the pixels addresses
    -- the unit counts upto pipeline_depth_g 
	----------------------------------------------------------------------------------------
	
valid_proc: process (sys_clk, sys_rst)
begin
	
	if (sys_rst = reset_polarity_g) then                 --RESET
		pixel_valid<= '0';
		enable_unit<='0';		
		valid_counter<=(others =>'0');
	elsif (rising_edge (sys_clk))   then  				--rising edge+notRESET
		--request trigger
		if (req_trig='1') then
			enable_unit<='1';
			valid_counter<=(others =>'0');-----TEST-########################################
		--unit enable
		elsif (enable_unit='1')  then
			if (valid_counter /= pipeline_depth_g) then        --calc is not finish: increment counter
				valid_counter <= valid_counter+1;
				pixel_valid<='0';
			else											--calc is finish: disable unit, assert valid
				pixel_valid<='1';
				enable_unit<='0';
			end if;
		-- unit disabled
		elsif (enable_unit='0')  then
			pixel_valid<='0';						--unit disabled,assert data not valid
			
		end if;
	end if;	
end process valid_proc;			


----------------------------------------------------------------------------------------
----------------------------		main calc Processes			------------------------
----------------------------------------------------------------------------------------
------   the process calculates (1-delta_col),(1-delta_row)  when trigger comes in  ----
----------------------------------------------------------------------------------------
	delta_comp_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			delta_row_comp	<= (others =>'0');
		    delta_col_comp	<= (others =>'0');
		elsif rising_edge (sys_clk) then
			if 	(req_trig='1') then
				delta_row_comp <= not (delta_row);
				delta_col_comp <= not (delta_col);
			end if;
		end if;
	end process delta_comp_proc;	
----------------------------------------------------------------------------------------

							
----------------------------------------------------------------------------------------
----------------------------		calc Processes		------------------------
----------------------------------------------------------------------------------------
------   the process calculates  													----
----------------------------------------------------------------------------------------
	calc_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			a1		        <= (others => '0');
			a2		        <= (others => '0');
			I1		        <= (others => '0');
			b1		        <= (others => '0');
			b2		        <= (others => '0');
			I2		        <= (others => '0');
			c1		        <= (others => '0');
			c2		        <= (others => '0');
			res_sig         <= (others => '0');
		    pixel_res		<= (others =>'0');
		elsif rising_edge (sys_clk) then	
			if (enable_unit='1') then
				-- I1=    (1-delta_col)*top_left    +   delta_col*top_right
				a1			<=	delta_col_comp*tl_pixel;
				a2			<=	delta_col*tr_pixel;
				I1			<=	a1 + a2;
				
				-- I2=    (1-delta_col)*bottom_left +   delta_col*bottom_right
				b1			<=	delta_col_comp*bl_pixel;
				b2			<=	delta_col*br_pixel;
				I2			<=	b1 + b2;
				
				-- pixel_res=(1-delta_row)*I1          +   delta_row*I2;		
				c1			<=	delta_row_comp*I1;
				c2			<=	delta_row*I2;
				res_sig	<=	(c1 + c2);			
			
				pixel_res	<=	res_sig(res_sig'left downto 14);---------------NEED to CALC REAL LENGTH
			end if;	
		end if;
	end process calc_proc;	
	
end architecture rtl_bilinear;