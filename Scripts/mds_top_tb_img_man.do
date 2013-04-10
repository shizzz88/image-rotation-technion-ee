

-- Compiling our units from lowest to highest level:
quit -sim
vcom VHDL/Design/Image_Maniplation/img_man_manager.vhd
vcom VHDL/Design/Image_Maniplation/addr_calc.vhd
vcom VHDL/Design/Image_Maniplation/img_man_top.vhd
vcom "VHDL/Design/Top Block/mds_top.vhd"
vcom VHDL/Simulation/TB/Top_Blocks/mds_top_tb.vhd


vsim -t ps -novopt work.mds_top_tb
add wave  -radix hexadecimal -group mem_mng -group top sim:/mds_top_tb/mds_top_inst/mem_mng_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_wr sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_wr -group wbm sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_wr -group wbs sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_inst/*

add wave  -radix hexadecimal -group mem_mng -group ctrl_rd sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_rd -group wbm sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_rd -group wbs sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_inst/*

add wave -radix hexadecimal  -group mds_top sim:/mds_top_tb/mds_top_inst/*
add wave  -radix hexadecimal  -group Image_Manipulation_Top -group Top sim:/mds_top_tb/mds_top_inst/img_man_top_inst/*
add wave  -radix hexadecimal  -group Image_Manipulation_Top -group Manager sim:/mds_top_tb/mds_top_inst/img_man_top_inst/img_man_manager_inst/*
add wave  -radix hexadecimal  -group Image_Manipulation_Top -group Address_Calculator sim:/mds_top_tb/mds_top_inst/img_man_top_inst/addr_calc_inst/*

run 75 ms

