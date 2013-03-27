###################################################################	do read0xA.do	###################################################################
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.

vsim -t ps -novopt work.mds_top_tb
add wave sim:/mds_top_tb/mds_top_inst/mem_mng_inst/*
add wave sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/*
add wave sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_inst/*
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
