------------------------------------------------------------------------------------------------
-- Model Name 	:	Wishbone INTERCON
-- File Name	:	intercon.vhd
-- Generated	:	7.8.2011
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: Generic Wishbone INTERCON. The generic INTERCON can connect between Wishbone
--				Masters and Wishbone Slaves.
--
--				The first master, which grants control on the bus - will grant the bus until
--				end of the transaction (ic_wbm_cyc_o Negation).
--				Request for grant by asserting ic_wbm_cyc_o.
--
--				The first slave, which grants control on the bus - will grant the bus until
--				end of the transaction (ic_wbm_cyc_o Negation).
--				Request for grant by negating WBS_STALL_O.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name					Description			
--			1.00		10.5.2011	Beeri Schreiber			Creation
------------------------------------------------------------------------------------------------
--	Todo:
--			(1)
------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.intercon_pkg.all;

entity intercon is
		generic 	
			(
				reset_polarity_g	:	std_logic 	:=	'0';		--Reset polarity: '0' is active low, '1' is active high
				num_of_wbm_g		:	positive	:=	1;			--Number of Wishbone Masters
				num_of_wbs_g		:	positive	:=	3;			--Number of Wishbone Slaves
				id					:	string		:=	"icz";		--INTERCON identification (icz = INTERCON Z)
				adr_width_g			:	positive	:=	10;			--Address width
				blen_width_g		:	positive	:=	10;			--Maximum Burst length
				data_width_g		:	positive	:=	8			--Data Width
			);
		
		port
			(
				--Clock and Reset
				clk_i				:	in std_logic;
				rst					:	in std_logic;
				
				--'ic_' = INTERCON.
				--WBM/WBS ports should be connected to the same port.
				--i.e: wbm_dat_o of the WBM should be connected to ic_wbm_dat_o of the INTERCON
				
				--Signals from INTERCON to WBS
				ic_wbs_adr_i		:	out std_logic_vector (num_of_wbs_g * adr_width_g - 1 downto 0);		--Address in internal RAM
				ic_wbs_tga_i		:	out std_logic_vector (num_of_wbs_g * blen_width_g - 1 downto 0);	--Burst Length
				ic_wbs_dat_i		:	out std_logic_vector (num_of_wbs_g * data_width_g - 1 downto 0);	--Data In (8 bits)
				ic_wbs_cyc_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Cycle command from WBM
				ic_wbs_stb_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Strobe command from WBM
				ic_wbs_we_i			:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Write Enable
				ic_wbs_tgc_i		:	out std_logic_vector (num_of_wbs_g - 1 downto 0);					--Cycle tag: '0' = Write to components, '1' = Write to registers
				
				--Signals from INTERCON to WBM 
				ic_wbm_dat_i		:	out std_logic_vector (num_of_wbm_g * data_width_g - 1 downto 0);	--Data Out for reading registers (8 bits)
				ic_wbm_stall_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				ic_wbm_ack_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Input data has been successfuly acknowledged
				ic_wbm_err_i		:	out std_logic_vector (num_of_wbm_g - 1 downto 0);					--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				--Signals from WBM to INTERCON
				ic_wbm_adr_o		:	in std_logic_vector (num_of_wbm_g * adr_width_g - 1 downto 0);		--Address in internal RAM
				ic_wbm_tga_o		:	in std_logic_vector (num_of_wbm_g * blen_width_g - 1 downto 0);		--Burst Length
				ic_wbm_dat_o		:	in std_logic_vector (num_of_wbm_g * data_width_g - 1 downto 0);		--Data In (8 bits)
				ic_wbm_cyc_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Cycle command from WBM
				ic_wbm_stb_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Strobe command from WBM
				ic_wbm_we_o			:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Write Enable
				ic_wbm_tgc_o		:	in std_logic_vector (num_of_wbm_g - 1 downto 0);					--Cycle tag: '0' = Write to components, '1' = Write to registers
				
				--Signals from WBS to INTERCON
				ic_wbs_dat_o		:	in std_logic_vector (num_of_wbs_g * data_width_g - 1 downto 0);		--Data Out for reading registers (8 bits)
				ic_wbs_stall_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0);					--Slave is not ready to receive new data (Internal RAM has not been written YET to SDRAM)
				ic_wbs_ack_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0);					--Input data has been successfuly acknowledged
				ic_wbs_err_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0);						--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
				
				--Debug signals
				dbg_bus_taken		:	out std_logic														--'1' when bus is taken, '0' otherwise
			);
end entity intercon;

architecture intercon_rtl of intercon is

	---------------------------------		Constants		--------------------------------

	---------------------------------		Types			--------------------------------
	--States for Wishbone Master Grant on the BUS
	type intercon_states is
							(	wait_wbm_st,	--Wait until one WBM will request for grant on the bus
								bus_taken_st	--Bus is taken by one WBM
							);
							
	--Arrays for WBM
	type slv_adr_t is array (natural range <>) of std_logic_vector (adr_width_g - 1 downto 0);
	type slv_dat_t is array (natural range <>) of std_logic_vector (data_width_g - 1 downto 0);
	type slv_tga_t is array (natural range <>) of std_logic_vector (blen_width_g - 1 downto 0);

	---------------------------------		Signals			--------------------------------
	signal cur_st		:	intercon_states;						--WBM FSM
	signal wbm_gnt		:	natural range 0 to num_of_wbm_g - 1;	--Current WBM, which grants the bus. num_of_wbm_g represent that no WBM grant control on the bus
	signal wbs_gnt		:	natural range 0 to num_of_wbs_g - 1;	--Current WBS, which grants the bus. num_of_wbs_g represent that no WBS grant control on the bus
	
	--Array signals for WBM, WBS
	signal wbm_adr_arr	:	slv_adr_t (num_of_wbm_g - 1 downto 0);
	signal wbm_dat_arr	:	slv_dat_t (num_of_wbm_g - 1 downto 0);
	signal wbm_tga_arr	:	slv_tga_t (num_of_wbm_g - 1 downto 0);
	signal wbs_dat_arr	:	slv_dat_t (num_of_wbs_g - 1 downto 0);
	
	---------------------------------		Functions		--------------------------------
	
	--The function returns the next wishbone master/slave to search grant from.
	--	*	wb_search	-	Search from
	--	*	wb_range	-	Search maximum range (i.e: 4 ==> range is 0 --> 4)
	function get_next_wb (wb_search : in natural ; wb_range : in natural) return natural is
	begin
		return (wb_search + 1) mod wb_range;
	end function get_next_wb;

begin
	
	-----------------------		Input WBM, WBS to ARRAY		--------------------------
	--WBM Address array
	wbm_adr_arr_comb_proc: process (ic_wbm_adr_o)
	begin
		for idx in num_of_wbm_g - 1 downto 0 loop
			wbm_adr_arr (idx)	<=	ic_wbm_adr_o	((idx + 1) * adr_width_g - 1 downto idx * adr_width_g);	
		end loop;
	end process wbm_adr_arr_comb_proc;
	
	--WBM Data array
	wbm_dat_arr_comb_proc: process (ic_wbm_dat_o)
	begin
		for idx in num_of_wbm_g - 1 downto 0 loop
			wbm_dat_arr (idx)	<=	ic_wbm_dat_o	((idx + 1) * data_width_g - 1 downto idx * data_width_g);	
		end loop;
	end process wbm_dat_arr_comb_proc;
	
	--WBM Tag Address array
	wbm_tga_arr_comb_proc: process (ic_wbm_tga_o)
	begin
		for idx in num_of_wbm_g - 1 downto 0 loop
			wbm_tga_arr (idx)	<=	ic_wbm_tga_o	((idx + 1) * blen_width_g - 1 downto idx * blen_width_g);	
		end loop;
	end process wbm_tga_arr_comb_proc;
	
	--WBS Data array
	wbs_dat_arr_comb_proc: process (ic_wbs_dat_o)
	begin
		for idx in num_of_wbs_g - 1 downto 0 loop
			wbs_dat_arr (idx)	<=	ic_wbs_dat_o	((idx + 1) * data_width_g - 1 downto idx * data_width_g);	
		end loop;
	end process wbs_dat_arr_comb_proc;
	
	-----------------------		Wishbone Master Select	--------------------------
	fsm_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			cur_st		<=	wait_wbm_st;
			wbm_gnt		<=	num_of_wbm_g - 1;
			wbs_gnt		<=	num_of_wbs_g - 1;
		elsif rising_edge(clk_i) then
			case cur_st is
				when wait_wbm_st	=>
					if (ic_wbm_cyc_o (wbm_gnt) = '1') then		--Request for grant on bus
						wbm_gnt		<=	wbm_gnt;
						wbs_gnt		<=	get_wbs (	id	=>	id,						--Aquire relevant WBS for this specific address
													tgc	=>	ic_wbm_tgc_o (wbm_gnt),
													adr	=>	wbm_adr_arr (wbm_gnt)
												);
						cur_st		<=	bus_taken_st;
					else
						wbm_gnt		<=	get_next_wb (wb_search => wbm_gnt, wb_range => num_of_wbm_g);
						wbs_gnt		<=	0;
						cur_st		<=	cur_st;
					end if;
					
				when bus_taken_st	=>
					if (ic_wbm_cyc_o (wbm_gnt) = '0') then			--End of WBM cycle
						cur_st		<=	wait_wbm_st;
					end if;
					wbm_gnt			<=	wbm_gnt;
					wbs_gnt			<=	wbs_gnt;
					
				when others			=>								--Should not happen. All states are covered
					cur_st		<=	wait_wbm_st;
			end case;
		end if;
	end process fsm_proc;
	
	---------------------------		MUX Processes, WBM to INTERCON	-----------------------
	--Address - Connects all WBS to the selected WBM
	wbs_adr_comb_proc: process (wbm_adr_arr, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				if (idx = wbs_gnt) then
					ic_wbs_adr_i ((idx + 1) * adr_width_g - 1 downto idx * adr_width_g)	<=	wbm_adr_arr (wbm_gnt);
				else
					ic_wbs_adr_i ((idx + 1) * adr_width_g - 1 downto idx * adr_width_g)	<=	(others => '0');
				end if;
			end loop;
		else
			ic_wbs_adr_i	<=	(others => '0');
		end if;
	end process wbs_adr_comb_proc;
	
	--Address Tag - Connects all WBS to the selected WBM
	wbs_tga_comb_proc: process (wbm_tga_arr, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				if (idx = wbs_gnt) then
					ic_wbs_tga_i ((idx + 1) * blen_width_g - 1 downto idx * blen_width_g)	<=	wbm_tga_arr (wbm_gnt);
				else
					ic_wbs_tga_i ((idx + 1) * blen_width_g - 1 downto idx * blen_width_g)	<=	(others => '0');
				end if;
			end loop;
		else
			ic_wbs_tga_i	<=	(others => '0');
		end if;
	end process wbs_tga_comb_proc;
	
	--Data - Connects all WBS to the selected WBM
	wbs_dat_comb_proc: process (wbm_dat_arr, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				if (idx = wbs_gnt) then
					ic_wbs_dat_i ((idx + 1) * data_width_g - 1 downto idx * data_width_g)	<=	wbm_dat_arr (wbm_gnt);
				else
					ic_wbs_dat_i ((idx + 1) * data_width_g - 1 downto idx * data_width_g)	<=	(others => '0');
				end if;
			end loop;
		else
			ic_wbs_dat_i	<=	(others => '0');
		end if;
	end process wbs_dat_comb_proc;
	
	--Cycle - Connects all WBS to the selected WBM
	wbs_cyc_comb_proc: process (ic_wbm_cyc_o, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				if (idx = wbs_gnt) then
					ic_wbs_cyc_i (idx)	<=	ic_wbm_cyc_o (wbm_gnt);
				else
					ic_wbs_cyc_i (idx)	<=	'0';
				end if;
			end loop;
		else
			ic_wbs_cyc_i	<=	(others => '0');
		end if;
	end process wbs_cyc_comb_proc;
	
	--Strobe - Connects all WBS to the selected WBM
	wbs_stb_comb_proc: process (ic_wbm_stb_o, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				if (idx = wbs_gnt) then
					ic_wbs_stb_i (idx)	<=	ic_wbm_stb_o (wbm_gnt);
				else
					ic_wbs_stb_i (idx)	<=	'0';
				end if;
			end loop;
		else
			ic_wbs_stb_i	<=	(others => '0');
		end if;
	end process wbs_stb_comb_proc;
	
	--Write Enable - Connects all WBS to the selected WBM
	wbs_we_comb_proc: process (ic_wbm_we_o, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				if (idx = wbs_gnt) then
					ic_wbs_we_i (idx)	<=	ic_wbm_we_o (wbm_gnt);
				else
					ic_wbs_we_i (idx)	<=	'0';
				end if;
			end loop;
		else
			ic_wbs_we_i	<=	(others => '0');
		end if;
	end process wbs_we_comb_proc;

	--Cycle Tag - Connects all WBS to the selected WBM
	wbs_tgc_comb_proc: process (ic_wbm_tgc_o, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				if (idx = wbs_gnt) then
					ic_wbs_tgc_i (idx)	<=	ic_wbm_tgc_o (wbm_gnt);
				else
					ic_wbs_tgc_i (idx)	<=	'0';
				end if;
			end loop;
		else
			ic_wbs_tgc_i	<=	(others => '0');
		end if;
	end process wbs_tgc_comb_proc;

	---------------------------		MUX Processes, WBS to INTERCON	-----------------------
	--Data - Connect selected WBS to INTERCON
	wbm_dat_comb_proc: process (wbs_dat_arr, cur_st, wbs_gnt, wbm_gnt)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbm_g - 1 loop
				if (idx = wbm_gnt) then
					ic_wbm_dat_i ((idx + 1) * data_width_g - 1 downto idx * data_width_g) 	<= wbs_dat_arr (wbs_gnt);
				else
					ic_wbm_dat_i ((idx + 1) * data_width_g - 1 downto idx * data_width_g)	<=	(others => '0');
				end if;
			end loop;
		else
			ic_wbm_dat_i	<=	(others => '0');
		end if;
	end process wbm_dat_comb_proc;
	
	--Stall - Connect selected WBS to INTERCON
	wbm_stall_comb_proc: process (ic_wbs_stall_o, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then
			for idx in 0 to num_of_wbm_g - 1 loop
				if (idx = wbm_gnt) then
					ic_wbm_stall_i (idx) 	<= ic_wbs_stall_o (wbs_gnt);
				else
					ic_wbm_stall_i (idx)	<=	'1';
				end if;
			end loop;

		else
			ic_wbm_stall_i	<=	(others => '1');
		end if;
	end process wbm_stall_comb_proc;
	
	--Acknowledge - Connect selected WBS to INTERCON
	wbm_ack_comb_proc: process (ic_wbs_ack_o, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then
			for idx in 0 to num_of_wbm_g - 1 loop
				if (idx = wbm_gnt) then
					ic_wbm_ack_i (idx) 	<= ic_wbs_ack_o (wbs_gnt);
				else
					ic_wbm_ack_i (idx)	<=	'0';
				end if;
			end loop;
		else
			ic_wbm_ack_i	<=	(others => '0');	--WBS Not Acknowledge (since no one is connected)
		end if;
	end process wbm_ack_comb_proc;
	
	--Error - Connect selected WBS to INTERCON
	wbm_err_comb_proc: process (ic_wbs_err_o, cur_st, wbm_gnt, wbs_gnt)
	begin
		if (cur_st = bus_taken_st) then
			for idx in 0 to num_of_wbm_g - 1 loop
				if (idx = wbm_gnt) then
					ic_wbm_err_i (idx) 	<= ic_wbs_err_o (wbs_gnt);
				else
					ic_wbm_err_i (idx)	<=	'0';
				end if;
			end loop;
		else
			ic_wbm_err_i	<=	(others => '0');	--WBS - No Error (since no one is connected)
		end if;
	end process wbm_err_comb_proc;

	--------------------------	Debug Processes	---------------------------
	--'1' when bus is taken, '0' otherwise (one clock delay)
	dbg_bus_taken_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			dbg_bus_taken	<=	'0';
		elsif rising_edge (clk_i) then
			if (cur_st = bus_taken_st) then
				dbg_bus_taken	<=	'1';
			else
				dbg_bus_taken	<=	'0';
			end if;
		end if;
	end process dbg_bus_taken_proc;
	
end architecture intercon_rtl;