
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.
echo "START OF MACRO" 	; # Print this massage on screen. 

-- Compiling our units from lowest to highest level:
quit -sim
vcom VHDL/Design/Image_Maniplation/img_man_manager.vhd
vcom VHDL/Simulation/TB/Image_Manipulation/img_man_manager_tb.vhd
vsim -t ps -voptargs=+acc work.img_man_manager_tb

add wave -r -radix decimal /*
run 90200000 ps


#;# ======= end of stimulus section ======= 
echo "------- END OF SCRIPT -------" 
echo "The time now is $now [string trim $resolution 01]" 


