vsim -t ps work.addr_calc 
add wave -r /*
force -freeze sim:/addr_calc/clk_133 1 0, 0 {3759 ps} -r 7518
force -freeze sim:/addr_calc/rst_133 1 0
run 7518 ps
force -freeze sim:/addr_calc/rst_133 0 0
run 7518 ps
force -freeze sim:/addr_calc/rst_133 1 0
force -freeze sim:/addr_calc/zoom_factor 0010 0