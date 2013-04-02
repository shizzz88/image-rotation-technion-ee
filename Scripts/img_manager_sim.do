
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.
echo "START OF MACRO" 	; # Print this massage on screen. 

-- Compiling our units from lowest to highest level:
quit -sim
vcom VHDL/Design/Image_Maniplation/img_man_manager.vhd
vcom VHDL/Simulation/TB/Image_Manipulation/img_man_manager_tb.vhd
vsim -t ps -novopt work.img_man_manager_tb

#add wave -noupdate -radix hexadecimal /img_man_manager_tb/system_clk
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/system_rst
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/trigger
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/row_idx_out_sig
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/col_idx_out_sig
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/idx_valid_sig
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_adr_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_tga_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_dat_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_cyc_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_stb_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_we_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_tgc_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_dat_i
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_stall_i
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_ack_i
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_wr_wbm_err_i
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_adr_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_tga_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_cyc_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_tgc_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_stb_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_dat_i
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_stall_i
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_ack_i
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_err_i
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_dat_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_rd_wbm_we_o
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_man_manager_inst/cur_st
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_man_manager_inst/finish_image
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_man_manager_inst/row_idx_sig
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_man_manager_inst/col_idx_sig
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_man_manager_inst/finish_read_pxl
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_man_manager_inst/en_read_proc
#add wave -noupdate -radix hexadecimal /img_man_manager_tb/img_man_manager_inst/phase_number
add wave  -radix hexadecimal sim:/img_man_manager_tb/img_man_manager_inst/*

run 250 ns
# ack number 1
force -freeze sim:/img_man_manager_tb/img_man_manager_inst/rd_wbm_ack_i 1 0
run 10 ns
force -freeze sim:/img_man_manager_tb/img_man_manager_inst/rd_wbm_ack_i 0 0
run 100 ns
# ack number 2
force -freeze sim:/img_man_manager_tb/img_man_manager_inst/rd_wbm_ack_i 1 0
run 10 ns
force -freeze sim:/img_man_manager_tb/img_man_manager_inst/rd_wbm_ack_i 0 0
run 100 ns
#;# ======= end of stimulus section ======= 
echo "------- END OF SCRIPT -------" 
echo "The time now is $now [string trim $resolution 01]" 


