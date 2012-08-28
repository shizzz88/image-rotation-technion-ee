
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.
echo "START OF MACRO" 	; # Print this massage on screen. 

-- Compiling our units from lowest to highest level:
quit -sim
vcom VHDL/Design/Image_Maniplation/addr_calc.vhd
vcom VHDL/Simulation/TB/Image_Manipulation/addr_calc_tb.vhd

vsim -t ps -voptargs=+acc work.addr_calc_tb
add wave -r /*
run 31 us

###########################		start RESET
#force -freeze sim:/addr_calc/clk_133 1 0, 0 {3759 ps} -r 7518
#force -freeze sim:/addr_calc/rst_133 1 0
#run 7518 ps
#force -freeze sim:/addr_calc/rst_133 0 0
#run 7518 ps
#
#
################################			end RESET
#force -freeze sim:/addr_calc/rst_133 1 0
#
#############################################################################################     zoom=0.25
#
#force -freeze sim:/addr_calc/zoom_factor 000100000 0	
#force -freeze sim:/addr_calc/row_idx_in 00100101101 0
#force -freeze sim:/addr_calc/col_idx_in 00100101101 0
#force -freeze sim:/addr_calc/ram_start_add_in 00000000000000000000000 0
#force -freeze sim:/addr_calc/x_crop_start 00000011110 0
#force -freeze sim:/addr_calc/y_crop_start 00000011101 0
#
########################################################   teta=0
#force -freeze sim:/addr_calc/sin_teta 000000000 0
#force -freeze sim:/addr_calc/cos_teta 010000000 0
#
#
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#
########################################################   teta=60deg
#force -freeze sim:/addr_calc/sin_teta 001101110 0
#force -freeze sim:/addr_calc/cos_teta 001000000 0
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#
########################################################   teta=90deg
#force -freeze sim:/addr_calc/sin_teta 010000000 0
#force -freeze sim:/addr_calc/cos_teta 000000000 0
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#run 7518 ps
#
#;# ======= end of stimulus section ======= 
#echo "------- END OF SCRIPT -------" 
#echo "The time now is $now [string trim $resolution 01]" 


