

-- Compiling our units from lowest to highest level:
quit -sim
vcom VHDL/Design/Image_Maniplation/img_man_manager.vhd
vcom VHDL/Design/Image_Maniplation/addr_calc.vhd
vcom VHDL/Design/Image_Maniplation/img_man_top.vhd
vcom "VHDL/Design/Top Block/mds_top.vhd"
vcom VHDL/Simulation/TB/Top_Blocks/mds_top_tb.vhd


vsim -t ps -novopt work.mds_top_tb
add wave  -radix hexadecimal -group mem_mng -group top sim:/mds_top_tb/mds_top_inst/mem_mng_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_wr -group top sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_wr -group wbm sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_wr -group wbs sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_inst/*

add wave  -radix hexadecimal -group mem_mng -group ctrl_rd -group top sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_rd -group wbm sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_inst/*
add wave  -radix hexadecimal -group mem_mng -group ctrl_rd -group wbs sim:/mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_inst/*

add wave -radix hexadecimal  -group mds_top -group TOP sim:/mds_top_tb/mds_top_inst/*

add wave  -radix hexadecimal  -group Image_Manipulation_Top -group Top sim:/mds_top_tb/mds_top_inst/img_man_top_inst/*
add wave  -radix hexadecimal  -group Image_Manipulation_Top -group Manager sim:/mds_top_tb/mds_top_inst/img_man_top_inst/img_man_manager_inst/*
add wave  -radix hexadecimal  -group Image_Manipulation_Top -group Address_Calculator sim:/mds_top_tb/mds_top_inst/img_man_top_inst/addr_calc_inst/*
add wave  -radix hexadecimal  -group Image_Manipulation_Top -group Bilinear sim:/mds_top_tb/mds_top_inst/img_man_top_inst/bilinear_inst/*

quietly wave cursor active 0
configure wave -namecolwidth 500
configure wave -valuecolwidth 80
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {5250 us}

run 63 ms


