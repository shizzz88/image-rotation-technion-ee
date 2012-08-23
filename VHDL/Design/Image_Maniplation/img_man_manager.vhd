------------------------------------------------------------------------------------------------
-- Model Name 	:	Image Manipulation Manager (FSM)
-- File Name	:	img_man_manager.vhd
-- Generated	:	21.08.2012
-- Author		:	Uri Tzipin
-- Project		:	Im_rotate Project
------------------------------------------------------------------------------------------------
-- Description  :   Manager for Image manipulation Block
--					FSM for the image manipulation procces
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		21.08.2012	Uri					creation
--					

------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work ;

entity img_man_manager is
	generic (
				reset_polarity_g 	: 	std_logic 					:= '0';
				img_hor_pixels_g	:	positive					:= 640;	--640 pixel in a coloum
				img_ver_pixels_g		:	positive					:= 480	--480 pixels in a row
			);
	port	(
				--Clock and Reset 
				sys_clk				:	in std_logic;				-- clock
				sys_rst				:	in std_logic;				-- Reset
				
				req_trig			:	in std_logic;				-- Trigger for image manipulation to begin,
				
				row_idx_out			:	out signed (10 downto 0); 	--current row index
				col_idx_out			:	out signed (10 downto 0) 	--corrent coloumn index
				
			);
end entity img_man_manager;

architecture rtl_img_man_manager of img_man_manager is

	------------------------------	Constants	------------------------------------
	constant num_pixels_c		:	positive 	:= img_hor_pixels_g * img_ver_pixels_g;	--Number of pixels
	constant col_bits_c			:	positive 	:= 11;--integer(ceil(log(real(img_hor_pixels_g)) / log(2.0))) ; --Width of registers for coloum index
	constant row_bits_c			:	positive 	:= 11;--integer(ceil(log(real(img_ver_pixels_g)) / log(2.0))) ; --Width of registers for row index

	------------------------------	Types	------------------------------------
	type fsm_states is (
							fsm_idle_st,			-- Idle - wait to start 
							fsm_init_coord_st, 		-- initialize coordinate registers to (0,0) or (1,1)??
							fsm_increment_coord_st,	-- increment coordinate by 1, if line is over move to next line
							fsm_address_calc_st,	-- send coordinates to Address Calc, if out of range WB BLACK_PIXEL(0) else continue
							fsm_READ_from_SDRAM_st, -- read 4 pixels from SDRAM according to result of addr_calc
							fsm_bilinear_st,		-- do a bilinear interpolation between the 4 pixels
							fsm_WB_to_SDRAM_st		-- Write Back result to SDRAM
						);
						
	------------------------------	Signals	------------------------------------
	-------------------------FSM
	signal cur_st			:	fsm_states;			-- Current State
	
	-------------------------Coordinate Procces
	signal finish_init_coord	: std_logic;				-- flag indicating when initilze coordinate is complete
	signal img_complete 		: std_logic;				-- flag indicating when image is complete botom left corner
	signal one_inc_compelte 	: std_logic;				-- flag indicating when one incrament was done

	signal row_idx_sig		 :  signed (10 downto 0);	
	signal col_idx_sig       :  signed (10 downto 0);
--	###########################		Implementation		##############################	--
begin	

----------------------------------------------------------------------------------------
	----------------------------		fsm_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- This is the main FSM Process
	----------------------------------------------------------------------------------------
	fsm_proc: process (sys_clk, sys_rst)
	begin
		if (sys_rst = reset_polarity_g) then
			cur_st		<=	fsm_idle_st;
		elsif rising_edge (sys_clk) then
			case cur_st is
				when fsm_idle_st =>
					if (req_trig='1') then
						cur_st	<= 	fsm_init_coord_st;
					else
						cur_st 	<= 	cur_st;	
					end if;				
				
				when fsm_init_coord_st =>
					if (finish_init_coord='1') then
						cur_st	<=	fsm_increment_coord_st;
					else
						cur_st 	<= 	cur_st;
					end if;	
				
				when fsm_increment_coord_st	=>				
					if (img_complete = '1') then  			-- image is complete, back to idle
						cur_st		<=	fsm_idle_st;
					elsif  (one_inc_compelte='1') then 		-- continue incrementing/building picture 
						cur_st 	<= 	fsm_address_calc_st;			
					end if;
				when fsm_address_calc_st =>
						cur_st 	<= 	fsm_READ_from_SDRAM_st;		--for tb of coordinate process
				when fsm_READ_from_SDRAM_st =>		
						cur_st 	<= 	fsm_bilinear_st;			--for tb of coordinate process
				when fsm_bilinear_st =>		
						cur_st 	<= 	fsm_WB_to_SDRAM_st;			--for tb of coordinate process
				when fsm_WB_to_SDRAM_st =>							
						cur_st 	<= 	fsm_increment_coord_st;		--for tb of coordinate process
				when others =>
					cur_st	<=	fsm_idle_st;
					report "Time: " & time'image(now) & "Image Man Manager : Unimplemented state has been detected" severity error;
				end case;
		end if;
	end process fsm_proc;

	---------------------------------------------------------------------------------------
	----------------------------	coordinate process	-----------------------------------
	---------------------------------------------------------------------------------------
	-- THE process will advance the row/col indexes until end of image
	-- when image is over a flag will rise - img_complete
	-- reset will set the coordinates at (0,0)
	-- init will set the coordinates at (1,1)
	---------------------------------------------------------------------------------------	
coord_proc : process (sys_clk,sys_rst)			
	variable row_cnt : integer range 0 to img_ver_pixels_g	:=0;
	variable col_cnt : integer range 0 to img_hor_pixels_g	:=0;
	
	begin
		if (sys_rst =reset_polarity_g) then	
			row_cnt:=0;
			col_cnt:=0;
			finish_init_coord <= '0';
			img_complete <='0';
			one_inc_compelte <='0';
			row_idx_sig <=(others => '0');
			col_idx_sig <=(others => '0');
		elsif rising_edge(sys_clk) then
			if (cur_st=fsm_init_coord_st) then 			--initialize row and col counter
				row_cnt:=1;	
				col_cnt:=1;
				finish_init_coord <= '1';
			elsif (cur_st=fsm_increment_coord_st) then	--increment col if possible, else move to new row
				if (row_cnt< img_ver_pixels_g) then
					row_cnt:=row_cnt+1;
					one_inc_compelte<='1';
				else  --(row_cnt == img_ver_pixels_g)
					if (col_cnt<img_hor_pixels_g) then
						row_cnt:=1;
						col_cnt:=col_cnt+1;
						one_inc_compelte<='1';
					else --(col_cnt == img_hor_pixels_g)
						img_complete <='1';
						one_inc_compelte<='0';
					end if;
				end if;	
				
			row_idx_sig <= to_signed(row_cnt,row_bits_c);
			col_idx_sig <= to_signed(col_cnt,col_bits_c);
			end if;
		end if;	
	end process coord_proc;
	-------------------Wire coordinates to out ports
	row_idx_out<=row_idx_sig;
	col_idx_out<=col_idx_sig;
							
--	---------------------------------------------------------------------------------------
--	----------------------------	Bank value process	-----------------------------------
--	---------------------------------------------------------------------------------------
--	-- The process switches between the two double banks when fine image has been received.
--	---------------------------------------------------------------------------------------
--	bank_val_proc: process (sys_clk, sys_rst)
--	begin
--		if (sys_rst = reset_polarity_g) then
--			bank_val <= '0';
--			rd_bank_val <= '1';
--		elsif rising_edge (sys_clk) then
--			if (bank_switch = '1') then
--				bank_val <= not bank_val;
--				rd_bank_val <= not rd_bank_val;
--			else
--				bank_val <= bank_val;
--				rd_bank_val <= rd_bank_val;
--			end if;
--		end if;
--	end process bank_val_proc;
	
--	###########################		Instances		##############################	--


end architecture rtl_img_man_manager;