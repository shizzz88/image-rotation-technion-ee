
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.
echo "START OF MACRO" 	; # Print this massage on screen. 

-- Compiling our units from lowest to highest level:
quit -sim
vcom img_man_manager.vhd
vcom img_man_manager_tb.vhd
vsim -gui -t ps work.img_man_manager_tb

add wave -r -radix decimal /*
run 91 us


#;# ======= end of stimulus section ======= 
echo "------- END OF SCRIPT -------" 
echo "The time now is $now [string trim $resolution 01]" 


