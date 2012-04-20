transcript off 
onerror abort 
echo "------- START OF SCRIPT -------" 
# signed

vsim -t ps -voptargs=+acc work.addr_calc
add wave -r /*

##########################		start RESET
force -freeze sim:/addr_calc/clk_133 1 0, 0 {3759 ps} -r 7518
force -freeze sim:/addr_calc/rst_133 1 0
run 7518 ps
force -freeze sim:/addr_calc/rst_133 0 0
run 7518 ps


###############################			end RESET
force -freeze sim:/addr_calc/rst_133 1 0

############################################################################################     zoom=0.25

force -freeze sim:/addr_calc/zoom_factor 0010 0

force -freeze sim:/addr_calc/row_idx_in 0100101101 0
force -freeze sim:/addr_calc/col_idx_in 0100101101 0

#######################################################   teta=0
force -freeze sim:/addr_calc/sin_teta 000000000 0
force -freeze sim:/addr_calc/cos_teta 010000000 0

force -freeze sim:/addr_calc/ram_start_add_in 00000000000000000000000 0

force -freeze sim:/addr_calc/x_crop_start 0000011110 0
force -freeze sim:/addr_calc/y_crop_start 0000011101 0
run 7518 ps
run 7518 ps
run 7518 ps
run 7518 ps
run 7518 ps
run 7518 ps
run 7518 ps
run 7518 ps

#######################################################   teta=60deg
force -freeze sim:/addr_calc/sin_teta 001101110 0
force -freeze sim:/addr_calc/cos_teta 001000000 0
run 7518 ps
run 7518 ps
run 7518 ps
run 7518 ps
run 7518 ps
;# ======= end of stimulus section ======= 
echo "------- END OF SCRIPT -------" 
echo "The time now is $now [string trim $resolution 01]" 


