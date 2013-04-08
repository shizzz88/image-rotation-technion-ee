
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.
echo "START OF MACRO" 	; # Print this massage on screen. 

-- Compiling our units from lowest to highest level:
quit -sim
vcom VHDL/Design/Image_Maniplation/img_man_manager.vhd
vcom VHDL/Design/Image_Maniplation/img_man_top.vhd
vcom VHDL/Design/Image_Maniplation/addr_calc.vhd
vcom VHDL/Simulation/TB/Image_Manipulation/img_man_top_tb.vhd


vsim -t ps -novopt work.img_man_top_tb
add wave -r sim:/img_man_top_tb/img_man_top_inst/*


run 10 ns
# write 80 to type reg 

run 20 ns

#write zoom factor to zoom reg register

run 10 ns

run 500 ns