
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.
echo "START OF MACRO" 	; # Print this massage on screen. 

-- Compiling our units from lowest to highest level:
quit -sim
vcom VHDL/Design/Image_Maniplation/img_man_manager.vhd
vcom VHDL/Simulation/TB/Image_Manipulation/img_man_manager_tb.vhd
vsim -t ps -novopt work.img_man_manager_tb
add wave sim:/img_man_manager_tb/img_man_manager_inst/*
run 150 ns
##read test
#run 250 ns
## ack number 1
#force -freeze sim:/img_man_manager_tb/img_man_manager_inst/rd_wbm_ack_i 1 0
#run 10 ns
#force -freeze sim:/img_man_manager_tb/img_man_manager_inst/rd_wbm_ack_i 0 0
#run 100 ns
## ack number 2
#force -freeze sim:/img_man_manager_tb/img_man_manager_inst/rd_wbm_ack_i 1 0
#run 10 ns
#force -freeze sim:/img_man_manager_tb/img_man_manager_inst/rd_wbm_ack_i 0 0
#run 100 ns
#;# ======= end of stimulus section ======= 
echo "------- END OF SCRIPT -------" 
echo "The time now is $now [string trim $resolution 01]" 


