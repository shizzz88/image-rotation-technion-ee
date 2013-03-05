###################################################################	do read0xA.do	###################################################################
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.

vsim -t ps -novopt work.mds_top_tb
add wave sim:/mds_top_tb/mds_top_inst/mem_mng_inst/*
add wave -noupdate -divider {TX Path Registers}
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/rd_burst_reg_din_ack 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/rd_burst_reg_rd_en 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/rd_burst_reg_dout 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/rd_burst_reg_dout_valid 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/dbg_cmd_reg_din_ack 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/dbg_cmd_reg_rd_en 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/dbg_cmd_reg_dout 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/dbg_cmd_reg_dout_valid 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/clear_dbg_reg 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/reg_addr_reg_din_ack 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/reg_addr_reg_rd_en 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/reg_addr_reg_dout 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/reg_addr_reg_dout_valid 
add wave sim:/mds_top_tb/mds_top_inst/tx_path_inst/reg_addr_reg_dout_extended
add wave -noupdate -divider {SDRAM Controller}
add wave sim:/mds_top_tb/mds_top_inst/sdr_ctrl/*
add wave -noupdate -divider {SDRAM Model}
add wave sim:/mds_top_tb/sdram_model_inst/*
run 58 ms


######################################	1	#########################################################
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_adr_i 0000000000 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_tga_i 0000000000 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_cyc_i 0 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_stb_i 0 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_tgc_i 0 0
## write 01 to type reg 
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_adr_i 0000001101 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_cyc_i 1 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_dat_i 00000001 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_stb_i 1 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_we_i 1 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_tgc_i 1 0
#run 7.5 ns
##write addres to dbg register
#
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_adr_i 0000000010 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_dat_i 00001010 0
#run 7.5 ns
##disable wr_ctrl
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_cyc_i 0 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_stb_i 0 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_we_i 0 0
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_tgc_i 0 0
#
#force -freeze sim:/mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_tga_i 0000000000 0
#run 7.5 ns
#
#######################################	3	#######################################################
#