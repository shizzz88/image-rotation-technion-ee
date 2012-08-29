
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.
echo "START OF MACRO" 	; # Print this massage on screen. 

-- Compiling our units from lowest to highest level:
quit -sim
#vcom VHDL/Design/Image_Maniplation/bilinear.vhd
vcom -work work c:/image-rotation-technion-ee/VHDL/Design/Image_Maniplation/bilinear.vhd
#vcom VHDL/Simulation/TB/Image_Manipulation/bilinear_tb.vhd
vcom -work work c:/image-rotation-technion-ee/VHDL//Simulation/TB/Image_Manipulation/bilinear_tb.vhd
vsim -t ps -voptargs=+acc work.bilinear_tb

add wave -r -radix unsigned /*
force -freeze sim:/bilinear_tb/bilinear_inst/tl_pixel 01100000 0
force -freeze sim:/bilinear_tb/bilinear_inst/tr_pixel 01100101 0
force -freeze sim:/bilinear_tb/bilinear_inst/bl_pixel 11111000 0
force -freeze sim:/bilinear_tb/bilinear_inst/br_pixel 10111001 0
force -freeze sim:/bilinear_tb/bilinear_inst/delta_row 1111001 0
force -freeze sim:/bilinear_tb/bilinear_inst/delta_col 1000001 0
run 150 ns

force -freeze sim:/bilinear_tb/trigger 1 1
force -freeze sim:/bilinear_tb/bilinear_inst/tl_pixel 01000000 0
force -freeze sim:/bilinear_tb/bilinear_inst/tr_pixel 01010001 0
force -freeze sim:/bilinear_tb/bilinear_inst/bl_pixel 00001000 0
force -freeze sim:/bilinear_tb/bilinear_inst/br_pixel 01001001 0
force -freeze sim:/bilinear_tb/bilinear_inst/delta_row 1111001 0
force -freeze sim:/bilinear_tb/bilinear_inst/delta_col 1100001 0
run 7.5 ns
force -freeze sim:/bilinear_tb/trigger 0 0
run 37.5 ns
force -freeze sim:/bilinear_tb/trigger 1 1
force -freeze sim:/bilinear_tb/bilinear_inst/tl_pixel 11010000 0
force -freeze sim:/bilinear_tb/bilinear_inst/tr_pixel 11000001 0
force -freeze sim:/bilinear_tb/bilinear_inst/bl_pixel 01001000 0
force -freeze sim:/bilinear_tb/bilinear_inst/br_pixel 01011001 0
force -freeze sim:/bilinear_tb/bilinear_inst/delta_row 0111001 0
force -freeze sim:/bilinear_tb/bilinear_inst/delta_col 0100101 0
run 7.5 ns
force -freeze sim:/bilinear_tb/trigger 0 0
run 37.5 ns
force -freeze sim:/bilinear_tb/trigger 1 1
force -freeze sim:/bilinear_tb/bilinear_inst/tl_pixel 11010000 0
force -freeze sim:/bilinear_tb/bilinear_inst/tr_pixel 01010001 0
force -freeze sim:/bilinear_tb/bilinear_inst/bl_pixel 01001100 0
force -freeze sim:/bilinear_tb/bilinear_inst/br_pixel 00000001 0
force -freeze sim:/bilinear_tb/bilinear_inst/delta_row 0101001 0
force -freeze sim:/bilinear_tb/bilinear_inst/delta_col 1100101 0
run 7.5 ns
force -freeze sim:/bilinear_tb/trigger 0 0
run 37.5 ns
#;# ======= end of stimulus section ======= 
echo "------- END OF SCRIPT -------" 
echo "The time now is $now [string trim $resolution 01]" 


