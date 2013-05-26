------------------------------------------------------------------------------------------------
-- Model Name 	:	Pixel Manager
-- File Name	:	pixel_mng.vhd
-- Generated	:	18.5.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: The component initilize burst reads from SDRAM, according to VESA generator's 
--				demand.
--				Every VSync event will cause the Pixel Manager to flush the FIFO in the system.
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		18.5.2011	Beeri Schreiber					Creation			
--			1.01		11.12.2012	uri & ran						nivun mehudash
--			1.02		26.05.2013	uri								changes mainly in pix_req_add
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) 
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

entity pixel_mng is
   generic (
			reset_polarity_g	:	std_logic	:= '0';		--Reset active low
			vsync_polarity_g	:	std_logic	:= '1';		--VSync Polarity
			screen_hor_pix_g	:	positive	:= 800;		--800X600 = Actual screen resolution
			hor_pixels_g		:	positive	:= 640;		--640X480
			ver_lines_g			:	positive	:= 480;		--640X480
			req_lines_g			:	positive	:= 3		--Number of lines to request from image transmitter, to hold in its FIFO
	--		rep_size_g			:	positive	:= 7		--2^7=128 => Maximum of 128 repetitions for pixel / line
           );
   port
   	   (
   	    clk_i			:	in std_logic; 						--Wishbone Clock
   	    rst				:	in std_logic;						--Reset
		
		-- Wishbown Signals
		wbm_ack_i		:	in std_logic;						--Wishbone Acknowledge
		wbm_err_i		:	in std_logic;						--Wishbone Error
		wbm_stall_i		:	in std_logic;						--Wishbone Stall
		wbm_dat_i		:	in std_logic_vector (7 downto 0);	--Wishbone Input Data
		wbm_cyc_o		:	out std_logic;						--Wishbone Cycle
		wbm_stb_o		:	out std_logic;						--Wishbone Strobe
		wbm_adr_o		:	out std_logic_vector (9 downto 0);	--Wishbone Address
		wbm_tga_o		:	out std_logic_vector (9 downto 0);	--Burst Length
		wbm_tgc_o		:	out std_logic;						--'1': Restart from start of SDRAM
		
		--Signals to FIFO
		fifo_wr_en		:	out std_logic;						--Write Enable to FIFO
		fifo_flush		:	out std_logic;						--Flush FIFO
		
		--Signal to terminate cycle due to Debug Mode (Termination only before WBS_STALL_O negates)
		term_cyc		:	in std_logic;						--Terminate cycle
		
		--Signals from VESA Generator (Clock Domain: 40MHz)
		pixels_req		:	in std_logic_vector(integer(ceil(log(real(screen_hor_pix_g*req_lines_g)) / log(2.0))) - 1 downto 0); --Request for PIXELS*LINES pixels from VESA
		req_ln_trig		:	in std_logic;						--Trigger to image transmitter, to load its FIFO with new data
		vsync			:	in std_logic
		
   	   );
end entity pixel_mng;

architecture rtl_pixel_mng of pixel_mng is
	------------------------------	Constants	--------------------------------
	constant num_pixels_c	:	positive 	:= hor_pixels_g * ver_lines_g;	--Number of pixels
--	constant rep_kind_pos_c	: 	natural 	:= 8 - rep_size_g;				--MSB bit of repetition kind
	
	------------------------------	Types	------------------------------------
	type wbm_states is (
							wbm_idle_st,	--Idle - wait for line trigger from VESA generator
							wbm_init_rx_st,	--Initilize read burst from SDRAM
							wbm_rx_st,		--Receive data from SDRAM and count pixels
							end_cyc_st,		--Wait for end of cycle, to negate CYC_O
							restart_rd_st,	--Restart from start of SDRAM
							restart_wack_st	--Wait for first ACK 
						);
	
	------------------------------	Signals	------------------------------------
	--FSM
	signal cur_st			:	wbm_states;							--FSM

	--Pixels
	signal pix_cnt			:	natural range 0 to num_pixels_c + 256;	--Total received pixels for specific frame
	signal tot_req_pix		:	natural range 0 to num_pixels_c + req_lines_g*hor_pixels_g;	--Total number of requested pixels from VESA generator
	signal pix_req_add		:	std_logic_vector(9 downto 0); --uri 26.05
	--signal pix_req_add		:	std_logic_vector(integer(ceil(log(real(screen_hor_pix_g*req_lines_g)) / log(2.0))) - 1 downto 0); --Request for PIXELS*LINES pixels from VESA + 480 

	--	alias  reps_in			: 	std_logic_vector (rep_size_g - 1 downto 0) is wbm_dat_i (7 downto rep_kind_pos_c);--Repetitions
	
	--General
	signal rd_adr			:	std_logic_vector (9 downto 0);		--Read address from Wishbone Slave
	signal ack_err_cnt		:	std_logic_vector (10 downto 0);		--Number of received ACK / ERR (0 to 1024)
	signal cyc_internal		:	std_logic;							--Internal wishbone cycle;
	signal end_burst_b		:	boolean;							--End of burst (One clock after rd_adr = x"3FF")
	signal req_trig_b		:	boolean;							--FALSE to acknowledge number of pixels from VESA
	signal pix_max_b		:	boolean;							--TRUE - Maybe end of burst
	
	--From 40MHz to 133MHz signals
	signal req_trig_sig		:	std_logic;							--133MHz Clock Domain req_ln_trig
	signal req_trig_d1		:	std_logic;							--133MHz Clock Domain req_ln_trig Filter
	signal req_trig_d2		:	std_logic;							--133MHz Clock Domain req_ln_trig Filter
	signal req_trig_d3		:	std_logic;							--133MHz Clock Domain req_ln_trig Filter
	
	signal vsync_sig		:	std_logic;							--133MHz Clock Domain VSync
	signal vsync_d1			:	std_logic;							--133MHz Clock Domain VSync Filter
	signal vsync_d2			:	std_logic;							--133MHz Clock Domain VSync Filter
	
begin
	
	--##############################	Hidden Processes	###############################--
	--Wishbone Address
	wbm_adr_proc:
	wbm_adr_o	<=	rd_adr;
	
	--Wishbone Burst Length
	wbm_tga_proc:
	wbm_tga_o	<=	(others => '1');	--1023 ==> 1024 bytes = 512 words
	
	--Wishbone Cycle
	wbm_cyc_proc:
	wbm_cyc_o	<=	cyc_internal;
	
	--FIFO Write Enable
	fifo_wr_en_proc:
	fifo_wr_en	<=	cyc_internal and wbm_ack_i;
	
	--FIFO Flush
	--Two processes are implemented, one for each VSync polarity
	fifo_flush_gen1:
	if (vsync_polarity_g = '1') generate
		fifo_flush_proc:
		fifo_flush	<=	vsync_sig;
	end generate fifo_flush_gen1;
	
	fifo_flush_gen2:
	if (vsync_polarity_g = '0') generate
		fifo_flush_proc:
		fifo_flush	<=	not vsync_sig;
	end generate fifo_flush_gen2;
	
	--##############################	40MHz Clock Domain	###############################--
	----------------------------------------------------------------------------------------
	---------------------		req_ln_trig_domain_proc Process			--------------------
	----------------------------------------------------------------------------------------
	-- The process receives trigger from VESA generator, at 40MHz clock domain , and 
	-- converts the signal to 133MHz clock domain.
	-- 2 FF are for preventing Metastability to enter the system. The 3rd FF is the 
	-- converted signal itself.
	----------------------------------------------------------------------------------------
	req_ln_trig_domain_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			req_trig_sig<=	'0';
			req_trig_d1	<=	'0';
			req_trig_d2	<=	'0';
			req_trig_d3	<=	'0';
		elsif rising_edge (clk_i) then
			req_trig_d1	<=	req_ln_trig;
			req_trig_d2	<=	req_trig_d1;
			req_trig_d3	<=	req_trig_d2;
			req_trig_sig<=	req_trig_d3;
		end if;
	end process req_ln_trig_domain_proc;	
	
	----------------------------------------------------------------------------------------
	---------------------		vsync_domain_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- The process receives VSync from VESA generator, at 40MHz clock domain , and 
	-- converts the signal to 133MHz clock domain.
	-- 2 FF are for preventing Metastability to enter the system. The 3rd FF is the 
	-- converted signal itself.
	----------------------------------------------------------------------------------------
	vsync_domain_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			vsync_sig	<=	'0';
			vsync_d1	<=	'0';
			vsync_d2	<=	'0';
		elsif rising_edge (clk_i) then
			vsync_d1	<=	vsync;
			vsync_d2	<=	vsync_d1;
			vsync_sig	<=	vsync_d2;
		end if;
	end process vsync_domain_proc;

	--##############################	General Processes	###############################--
	
	----------------------------------------------------------------------------------------
	----------------------------		req_trig_b_proc Process			--------------------
	----------------------------------------------------------------------------------------
	-- The req_trig_b together with the req_trig_sig indicates that req_pixels from VESA
	-- should be read.
	----------------------------------------------------------------------------------------
	req_trig_b_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			req_trig_b	<=	true;
		elsif rising_edge (clk_i) then
			req_trig_b	<=	(req_trig_sig = '0');
		end if;
	end process req_trig_b_proc;
	
	----------------------------------------------------------------------------------------
	----------------------------		fsm_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- This is the main FSM Process
	----------------------------------------------------------------------------------------
	fsm_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			cyc_internal<=	'0';
			wbm_stb_o	<=	'0';
			wbm_tgc_o	<=	'0';
			cur_st		<=	wbm_idle_st;
		elsif rising_edge (clk_i) then
			case cur_st is
				when wbm_idle_st =>
					if (term_cyc = '1') then	--Terminate transaction due to debug mode
						cur_st 	<=	cur_st;
					
					elsif (req_trig_sig = '1') 
					and (pix_cnt /= num_pixels_c) 
					and (pix_cnt < tot_req_pix + conv_integer(pix_req_add)) then	--Request for data, and not end of picture
					--NOTE: req_trig_sig may be active for more than 1 clock, which is OK
						cur_st		<=	wbm_init_rx_st;
					elsif (vsync_sig = vsync_polarity_g) then
						cur_st		<=	restart_rd_st;
					else
						cur_st		<=	cur_st;
					end if;
					cyc_internal<=	'0';
					wbm_stb_o	<=	'0';
					wbm_tgc_o	<=	'0';
					
				when wbm_init_rx_st =>
					cyc_internal<=	'1';
					wbm_stb_o	<=	'1';
					if (vsync_sig = '1') then
						cur_st	<= wbm_idle_st;
					else					
						cur_st	<=	wbm_rx_st;
					end if;
					
				when wbm_rx_st	=>
					cyc_internal<=	'1';
					if (vsync_sig = '1') then
						cur_st	<= wbm_idle_st;
					elsif (wbm_ack_i = '1') then
						if (rd_adr = x"3FF") --End of Burst / All pixels have been received
						or pix_max_b then
						 --((rd_adr(0) = '0') then--and (pix_cnt + (conv_integer(reps_in) + 1)*(2**rep_kind_pos_c) = num_pixels_c)) then
							wbm_stb_o	<=	'0';	
							cur_st		<=	end_cyc_st;
						else
							wbm_stb_o	<=	'1';
							cur_st		<=	cur_st;
						end if;
					
					elsif (wbm_err_i = '1') then	--Error
						wbm_stb_o	<= '0';
						cyc_internal<= '0';
						cur_st		<=	wbm_idle_st;
					
					elsif (wbm_stall_i = '1') and (term_cyc = '1') then	--Terminate transaction and debug mode
						cyc_internal<=	'0';
						wbm_stb_o	<=	'0';
						cur_st		<=	wbm_idle_st;
					
					else	--Happens when (wbm_stall_i = '1') or wbm_ack_i has not been received yet
						wbm_stb_o	<=	'1';
						cur_st		<=	cur_st;
					end if;
					
				when end_cyc_st =>
					if (vsync_sig = '1') then
						cur_st		<= wbm_idle_st;
						cyc_internal<= '0';
					elsif (rd_adr - '1' = ack_err_cnt - '1') then			--Number of WBM_STB_O = WBM_ACK_I + WBM_ERR_I
						--NOTE: rd_adr 		= 0 ==> 1st data
						--		ack_err_cnt = 1	==> 1st data acknowledged
						--		i.e: When rd_adr = x"3FF" and ack_err_cnt = x"3FF", it means that 1023 ACK / ERR have been received, and 1024 bytes have been requested
						if (pix_cnt >= tot_req_pix) then	--All requested pixels have been received
							cur_st		<=	wbm_idle_st;	--Go to idle state, and wait for request event
						else
							cur_st		<=	wbm_init_rx_st;	--Execute another burst from SDRAM
						end if;
						cyc_internal<= '0';
					else
						cur_st		<=	cur_st;
						cyc_internal<= '1';
					end if;

				when restart_rd_st	=>
					cyc_internal	<= 	'1';
					wbm_stb_o		<=	'1';
					wbm_tgc_o		<=	'1';
					cur_st			<=	restart_wack_st;
					
				when restart_wack_st	=>	
					if (wbm_ack_i = '1') then		--End of restart
						cyc_internal	<= 	'0';
						wbm_stb_o		<=	'0';
						wbm_tgc_o		<=	'0';
						cur_st			<=	wbm_idle_st;
					else
						cyc_internal	<= 	'1';
						wbm_stb_o		<=	'1';
						wbm_tgc_o		<=	'1';
						cur_st			<=	cur_st;
					end if;
				
				when others =>
					cur_st	<=	wbm_idle_st;
					report "Time: " & time'image(now) & "Pixel Manager : Unimplemented state has been detected" severity error;
				end case;
		end if;
	end process fsm_proc;
	
	----------------------------------------------------------------------------------------
	----------------------------		ack_err_cnt_proc Process			----------------
	----------------------------------------------------------------------------------------
	-- WBM_ACK_I and WBM_ERR_I counter
	----------------------------------------------------------------------------------------
	ack_err_cnt_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			ack_err_cnt	<=	(others => '0');
		elsif rising_edge (clk_i) then
			if (cur_st = wbm_init_rx_st) then
				ack_err_cnt	<= (others => '0');

			elsif (cur_st = wbm_rx_st) or (cur_st = end_cyc_st) then
				if (wbm_ack_i = '1') or (wbm_err_i = '1') then
					ack_err_cnt	<=	ack_err_cnt + '1';
				else
					ack_err_cnt	<= ack_err_cnt;
				end if;

				else
				ack_err_cnt	<=	ack_err_cnt;
			end if;
		end if;
	end process ack_err_cnt_proc;
	
	----------------------------------------------------------------------------------------
	----------------------------		pixel_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- The process handles pixels counters
	----------------------------------------------------------------------------------------
	pixel_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			tot_req_pix			<=	0;--hor_pixels_g * req_lines_g; uri 26.05
			pix_cnt				<=	0;
		elsif rising_edge (clk_i) then
			if (vsync_sig = '1') then
				tot_req_pix		<=	0;--hor_pixels_g  * req_lines_g;uri 26.05
				pix_cnt			<=	0;

			elsif (cur_st = wbm_idle_st) then
				pix_cnt	<=	pix_cnt;
				if (req_trig_sig = '1') and req_trig_b
				and (pix_cnt /= num_pixels_c)  then	--Request for data
					tot_req_pix	<=	tot_req_pix + conv_integer(pix_req_add);
				else
					tot_req_pix	<=	tot_req_pix;
				end if;

			elsif (cur_st = wbm_rx_st)
			and (wbm_ack_i = '1') then
				tot_req_pix		<=	tot_req_pix;
				-- if (pix_cnt < num_pixels_c) then
				if (rd_adr(0) = '0') and (pix_cnt < num_pixels_c) then	--Repetition data
				--	pix_cnt		<=	pix_cnt + (conv_integer(reps_in) + 1)*(2**rep_kind_pos_c); --uri ran 
					pix_cnt		<=	pix_cnt + 1;-- uri ran promote counter by 1
				else							--Color data
					pix_cnt		<=	pix_cnt;
				end if;	
				
			elsif (cur_st = end_cyc_st)
			and (wbm_ack_i = '1') then
				tot_req_pix		<=	tot_req_pix;
				--if (pix_cnt < num_pixels_c) then
				if (rd_adr(0) = '0') and (pix_cnt < num_pixels_c) then	--Repetition data
					--pix_cnt		<=	pix_cnt + (conv_integer(reps_in) + 1)*(2**rep_kind_pos_c); --uri ran
					pix_cnt		<=	pix_cnt +  1; --uri ran promote counter by 1
				else							--Color data
					pix_cnt		<=	pix_cnt;
				end if;	
										
			else	
				pix_cnt			<=	pix_cnt;
				tot_req_pix		<=	tot_req_pix;
			end if;
		end if;
	end process pixel_proc;

	----------------------------------------------------------------------------------------
	----------------------------		rd_adr_proc Process			------------------------
	----------------------------------------------------------------------------------------
	-- The process manages the read address from Wishbone Slave
	----------------------------------------------------------------------------------------
	rd_adr_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			rd_adr			<=	(others => '0');
		elsif rising_edge (clk_i) then
			if (cur_st = wbm_init_rx_st) then
				rd_adr		<=	(others => '0');
			
			elsif (cur_st = wbm_rx_st) and (wbm_stall_i = '0') then
				if (end_burst_b) then --End of Burst / All pixels have been received
				--TODO: Removed for timing improvment : or ((rd_adr(0) = '0') and (pix_cnt + (conv_integer(reps_in) + 1)*(2**rep_kind_pos_c) = num_pixels_c)) then
					rd_adr	<=	rd_adr;
				else
					rd_adr	<=	rd_adr + '1';
				end if;

			else
				rd_adr		<=	rd_adr;
			end if;
		end if;
	end process rd_adr_proc;
	
	----------------------------------------------------------------------------------------
	----------------------------		end_burst_proc Process			--------------------
	----------------------------------------------------------------------------------------
	-- The process manages the end of burst (maximum address range) signal
	----------------------------------------------------------------------------------------
	end_burst_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			end_burst_b	<=	false;
		elsif rising_edge (clk_i) then
			end_burst_b	<= (rd_adr = x"3FF");
		end if;
	end process end_burst_proc;
	
	----------------------------------------------------------------------------------------
	----------------------------		pix_max_proc Process			--------------------
	----------------------------------------------------------------------------------------
	-- The process manages the overflow pixels signal
	----------------------------------------------------------------------------------------
	pix_max_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			pix_max_b	<=	false;
		elsif rising_edge (clk_i) then
			pix_max_b <= (pix_cnt + 256 >= num_pixels_c);
		end if;
	end process pix_max_proc;
	
	----------------------------------------------------------------------------------------
	----------------------------		pix_req_add Process				--------------------
	----------------------------------------------------------------------------------------
	-- The process manages the pix_req_add signal, which is pixels_req + 480
	----------------------------------------------------------------------------------------
	pix_req_add_proc: process (clk_i, rst)
	begin
		if (rst = reset_polarity_g) then
			pix_req_add	<=	(others => '0');
		elsif rising_edge (clk_i) then
			if (req_trig_d2 = '1') then
				pix_req_add	<=	"1000000000";--pixels_req + hor_pixels_g;uri 26.05
			else
				pix_req_add	<=	"1000000000";--pix_req_add;uri 26.05
			end if;
		end if;
	end process pix_req_add_proc;
	
end architecture rtl_pixel_mng;