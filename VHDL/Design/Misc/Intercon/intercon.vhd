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

entity intercon is
		generic 	
			(
				reset_polarity_g	:	std_logic 	:=	'0';		--Reset polarity: '0' is active low, '1' is active high
				num_of_wbm_g		:	positive	:=	1;			--Number of Wishbone Masters
				num_of_wbs_g		:	positive	:=	3;			--Number of Wishbone Slaves
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
				ic_wbs_err_o		:	in std_logic_vector (num_of_wbs_g - 1 downto 0)						--Error: Address should be incremental, but receives address was not as expected (0 --> 1023)
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
	signal wbm_gnt		:	natural range 0 to num_of_wbm_g - 1;		--Current WBM, which grants the bus. num_of_wbm_g represent that no WBM grant control on the bus
	signal wbs_gnt		:	natural range 0 to num_of_wbs_g;		--Current WBS, which grants the bus. num_of_wbs_g represent that no WBS grant control on the bus
	signal wbs_taken	:	boolean;								--TRUE - BUS is taken by WBS, False otherwise
	
	--Array signals for WBM
	signal wbm_adr_arr	:	slv_adr_t (num_of_wbm_g - 1 downto 0);
	signal wbm_dat_arr	:	slv_dat_t (num_of_wbm_g - 1 downto 0);
	signal wbm_tga_arr	:	slv_tga_t (num_of_wbm_g - 1 downto 0);
	
begin
	
	-----------------------		Input WBM to ARRAY		--------------------------
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
	
	
	-----------------------		Wishbone Master Select	--------------------------
	--More than one master is connected
	wbm_grant_few_wbm_gen:
	if (num_of_wbm_g > 1) generate	
	begin
		fsm_proc: process (clk_i, rst)
		variable wbm_req_v	:	natural range 0 to num_of_wbm_g - 1;	--num_of_wbm_g represent that no WBM grant control on the bus
		begin
			if (rst = reset_polarity_g) then
				cur_st		<=	wait_wbm_st;
				wbm_gnt		<=	0;
				wbm_req_v	:=	0;
			elsif rising_edge(clk_i) then
				case cur_st is
					when wait_wbm_st	=>
						wbm_req_v_loop:
						for idx in 0 to num_of_wbm_g - 1 loop
							if (ic_wbm_cyc_o (idx) = '1') then		--Request for grant on bus
								wbm_req_v	:=	idx;
								cur_st		<=	bus_taken_st;
								exit wbm_req_v_loop;
							end if;
						end loop wbm_req_v_loop;
						
					when bus_taken_st	=>
						if (ic_wbm_cyc_o (wbm_req_v) = '0') then	--End of WBM cycle
							wbm_req_v	:= wbm_req_v;
							cur_st		<=	wait_wbm_st;
						end if;
						
					when others			=>						--Should not happen. All states are covered
						cur_st		<=	wait_wbm_st;
						wbm_req_v	:=	wbm_req_v;
				end case;
			wbm_gnt <= wbm_req_v;
			end if;
		end process fsm_proc;
	end generate wbm_grant_few_wbm_gen;
	
	--Only one master is connected
	wbm_grant_1_wbm_gen:
	if (num_of_wbm_g = 1) generate
	begin
		fsm_proc:
		cur_st	<=	bus_taken_st;
		
		wbm_gnt_proc:
		wbm_gnt	<=	0;
	end generate wbm_grant_1_wbm_gen;
	
	-----------------------		Wishbone Slave Select	--------------------------
	--More than one master is connected
	wbs_grant_few_wbs_gen:
	if (num_of_wbs_g > 1) generate
	begin
		wbs_gnt_proc : process (clk_i, rst)
		variable wbs_req_v	:	natural range 0 to num_of_wbs_g; --num_of_wbs_g represent that no WBS grant control on the bus
		begin
			if (rst = reset_polarity_g) then
				wbs_req_v	:=	num_of_wbs_g;
				wbs_gnt		<=	num_of_wbs_g;
				wbs_taken	<=	false;
			elsif rising_edge (clk_i) then
				if (cur_st = wait_wbm_st) then	--No WBM has grant the bus, therefor no WBS should grant the bus
					wbs_req_v	:=	num_of_wbs_g;
					wbs_taken	<=	false;
				
				elsif (not wbs_taken) then		--WBM grants the bus, but no WBS has grant the bus
					wbs_req_v_loop:
					for idx in 0 to num_of_wbs_g - 1 loop
						if (ic_wbs_stall_o (idx) = '0') then	--Request for grant on bus
							wbs_req_v	:=	idx;
							wbs_taken	<=	true;
							exit wbs_req_v_loop;
						end if;
					end loop wbs_req_v_loop;
				
				else							--WBS bus is taken
					wbs_req_v	:=	wbs_req_v;
					if (ic_wbs_stall_o (wbs_gnt) = '1') then	--Done with WBS transaction
						wbs_taken	<=	false;
					else
						wbs_taken	<=	wbs_taken;
					end if;
				end if;

				wbs_gnt <= wbs_req_v;			--Signal assignment from variable
			end if;
		end process wbs_gnt_proc;
	end generate wbs_grant_few_wbs_gen;
	
	--Only one slave is connected
	wbs_grant_1_wbs_gen:
	if (num_of_wbs_g = 1) generate
		wbs_gnt_proc:
		wbs_gnt		<=	0;
		
		wbs_taken_proc:
		wbs_taken	<=	true;
	end generate wbs_grant_1_wbs_gen;
	
	---------------------------		MUX Processes, WBM to INTERCON	-----------------------
	--Address - Connects all WBS to the selected WBM
	wbs_adr_comb_proc: process (wbm_adr_arr, cur_st)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				ic_wbs_adr_i ((idx + 1) * adr_width_g - 1 downto idx * adr_width_g)	<=	wbm_adr_arr (wbm_gnt);
			end loop;
		else
			ic_wbs_adr_i	<=	(others => '0');
		end if;
	end process wbs_adr_comb_proc;
	
	--Address Tag - Connects all WBS to the selected WBM
	wbs_tga_comb_proc: process (wbm_tga_arr, cur_st)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				ic_wbs_tga_i ((idx + 1) * blen_width_g - 1 downto idx * blen_width_g)	<=	wbm_tga_arr (wbm_gnt);
			end loop;
		else
			ic_wbs_tga_i	<=	(others => '0');
		end if;
	end process wbs_tga_comb_proc;
	
	--Data - Connects all WBS to the selected WBM
	wbs_dat_comb_proc: process (wbm_dat_arr, cur_st)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				ic_wbs_dat_i ((idx + 1) * data_width_g - 1 downto idx * data_width_g)	<=	wbm_dat_arr (wbm_gnt);
			end loop;
		else
			ic_wbs_dat_i	<=	(others => '0');
		end if;
	end process wbs_dat_comb_proc;
	
	--Cycle - Connects all WBS to the selected WBM
	wbs_cyc_comb_proc: process (ic_wbm_cyc_o, cur_st)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				ic_wbs_cyc_i (idx)	<=	ic_wbm_cyc_o (wbm_gnt);
			end loop;
		else
			ic_wbs_cyc_i	<=	(others => '0');
		end if;
	end process wbs_cyc_comb_proc;
	
	--Strobe - Connects all WBS to the selected WBM
	wbs_stb_comb_proc: process (ic_wbm_stb_o, cur_st)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				ic_wbs_stb_i (idx)	<=	ic_wbm_stb_o (wbm_gnt);
			end loop;
		else
			ic_wbs_stb_i	<=	(others => '0');
		end if;
	end process wbs_stb_comb_proc;
	
	--Write Enable - Connects all WBS to the selected WBM
	wbs_we_comb_proc: process (ic_wbm_we_o, cur_st)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				ic_wbs_we_i (idx)	<=	ic_wbm_we_o (wbm_gnt);
			end loop;
		else
			ic_wbs_we_i	<=	(others => '0');
		end if;
	end process wbs_we_comb_proc;

	--Cycle Tag - Connects all WBS to the selected WBM
	wbs_tgc_comb_proc: process (ic_wbm_tgc_o, cur_st)
	begin
		if (cur_st = bus_taken_st) then	--WBM grants the bus
			for idx in 0 to num_of_wbs_g - 1 loop
				ic_wbs_tgc_i (idx)	<=	ic_wbm_tgc_o (wbm_gnt);
			end loop;
		else
			ic_wbs_tgc_i	<=	(others => '0');
		end if;
	end process wbs_tgc_comb_proc;

	---------------------------		MUX Processes, WBS to INTERCON	-----------------------
	--Data - Connect selected WBS to INTERCON
	wbm_dat_comb_proc: process (ic_wbs_dat_o, cur_st)
	begin
		if (cur_st = bus_taken_st) and (wbs_taken) then	--WBM, WBS grants the bus
			ic_wbm_dat_i ((wbm_gnt + 1) * data_width_g - 1 downto wbm_gnt * data_width_g) <= ic_wbs_dat_o((wbs_gnt + 1) * data_width_g - 1 downto wbs_gnt * data_width_g);
		else
			ic_wbm_dat_i	<=	(others => '0');
		end if;
	end process wbm_dat_comb_proc;
	
	--Stall - Connect selected WBS to INTERCON
	wbm_stall_comb_proc: process (ic_wbs_stall_o, cur_st)
	variable cur_stall_v	:	std_logic;
	begin
		cur_stall_v	:= '1';		--Default state: STALL active
		if (cur_st = bus_taken_st) then
			ic_wbm_stall_i	<=	(others => '1');
			and_loop:
			for idx in 0 to num_of_wbs_g - 1 loop
				if (ic_wbs_stall_o (idx) = '0') then
					cur_stall_v := '0';						--If one WBS's STALL is negated, then all outputs will be negated
					ic_wbm_stall_i (wbm_gnt)	<=	'0';	--WBS BUSY (only one is connected)
					exit and_loop;
				end if;
			end loop and_loop;
		else
			cur_stall_v		:= cur_stall_v;
			ic_wbm_stall_i	<=	(others => '1');
		end if;
		ic_wbm_stall_i		<=	(others => cur_stall_v);	--WBM is not connected
	end process wbm_stall_comb_proc;
	
	--Acknowledge - Connect selected WBS to INTERCON
	wbm_ack_comb_proc: process (ic_wbs_ack_o, cur_st)
	begin
		if (cur_st = bus_taken_st) then
			if  (wbs_taken) then	--WBM, WBS grants the bus
				ic_wbm_ack_i				<=	(others => '0');	--WBS Not Acknowledge (only one is connected)
				ic_wbm_ack_i (wbm_gnt) 	<= ic_wbs_ack_o(wbs_gnt);
			else
				ic_wbm_ack_i (wbm_gnt) 	<= '0';	--WBS Not Acknowledge (since no one is connected)
			end if;
		else
			ic_wbm_ack_i	<=	(others => '0');	--WBS Not Acknowledge (since no one is connected)
		end if;
	end process wbm_ack_comb_proc;
	
	--Error - Connect selected WBS to INTERCON
	wbm_err_comb_proc: process (ic_wbs_err_o, cur_st)
	begin
		if (cur_st = bus_taken_st) then
			if  (wbs_taken) then	--WBM, WBS grants the bus
				ic_wbm_err_i				<=	(others => '0');	--WBS - No Error (only one is connected)
				ic_wbm_err_i (wbm_gnt) 	<= ic_wbs_err_o(wbs_gnt);
			else
				ic_wbm_err_i (wbm_gnt) 	<= '0';	--WBS - No Error (since no one is connected)
			end if;
		else
			ic_wbm_err_i	<=	(others => '0');	--WBS - No Error (since no one is connected)
		end if;
	end process wbm_err_comb_proc;
	
end architecture intercon_rtl;