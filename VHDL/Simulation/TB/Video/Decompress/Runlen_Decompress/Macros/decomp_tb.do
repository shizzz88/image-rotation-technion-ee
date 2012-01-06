transcript off
onerror abort
echo "------- START OF SCRIPT -------"
vcom -93 tx_data.vhd
vcom -93 decomp.vhd
vcom decomp_tb.vhd
vsim decomp_tb
restart -force
noview *
add wave -noupdate -format Logic /decomp_tb/clk
add wave -noupdate -format Logic /decomp_tb/data_rdy
add wave -noupdate -format Logic /decomp_tb/rx_rdy
add wave -noupdate -format Logic /decomp_tb/end_pic
add wave -noupdate -format Logic /decomp_tb/col_en
add wave -noupdate -format Literal -radix unsigned /decomp_tb/color
add wave -noupdate -format Literal -radix unsigned /decomp_tb/repetition
add wave -noupdate -format Literal -radix unsigned /decomp_tb/col_out
;# ====== start of stimulus section ======
echo "------- Start of Simulation -------"
;#force clk 0 , 1 10 ns -r 20 ns
run 8567760 ns
;# ======= end of stimulus section =======
echo "------- END OF SCRIPT -------"
echo "The time now is $now [string trim $resolution 01]"