
transcript off  		; # We don't want that do file commands 
						; # will appear on the command window.
echo "START OF ADDR_CALC_SIM" 	; # Print this massage on screen. 
quit -sim

-- Compiling our units from lowest to highest level:
vcom VHDL/Design/Image_Maniplation/addr_calc.vhd
vcom VHDL/Simulation/TB/Image_Manipulation/addr_calc_tb.vhd

-- start simulation
vsim -t ps -voptargs=+acc work.addr_calc_tb

------------------------------ wave format---------------------------------------------------------------------------------------------------------------------------------------------
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/system_clk
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/system_rst
add wave -noupdate -group Ports -radix unsigned -childformat {{/addr_calc_tb/zoom_factor_sig(8) -radix unsigned} {/addr_calc_tb/zoom_factor_sig(7) -radix unsigned} {/addr_calc_tb/zoom_factor_sig(6) -radix unsigned} {/addr_calc_tb/zoom_factor_sig(5) -radix unsigned} {/addr_calc_tb/zoom_factor_sig(4) -radix unsigned} {/addr_calc_tb/zoom_factor_sig(3) -radix unsigned} {/addr_calc_tb/zoom_factor_sig(2) -radix unsigned} {/addr_calc_tb/zoom_factor_sig(1) -radix unsigned} {/addr_calc_tb/zoom_factor_sig(0) -radix unsigned}} -subitemconfig {/addr_calc_tb/zoom_factor_sig(8) {-radix unsigned} /addr_calc_tb/zoom_factor_sig(7) {-radix unsigned} /addr_calc_tb/zoom_factor_sig(6) {-radix unsigned} /addr_calc_tb/zoom_factor_sig(5) {-radix unsigned} /addr_calc_tb/zoom_factor_sig(4) {-radix unsigned} /addr_calc_tb/zoom_factor_sig(3) {-radix unsigned} /addr_calc_tb/zoom_factor_sig(2) {-radix unsigned} /addr_calc_tb/zoom_factor_sig(1) {-radix unsigned} /addr_calc_tb/zoom_factor_sig(0) {-radix unsigned}} /addr_calc_tb/zoom_factor_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/sin_teta_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/cos_teta_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/row_idx_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/col_idx_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/x_crop_start_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/y_crop_start_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/ram_start_add_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/tl_out_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/tr_out_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/bl_out_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/br_out_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/out_of_range_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/data_valid_out_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/delta_row_out_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/delta_col_out_sig
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/trigger
add wave -noupdate -group Ports -radix unsigned /addr_calc_tb/en_unit
add wave -noupdate -radix unsigned /addr_calc_tb/start_tb
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/a1
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/b1
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/c1
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/a2
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/b2
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/c2
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/a3
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/b3
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/c3
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/x1
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/y1
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/z1
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/x2
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/y2
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/z2
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/x3
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/y3
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/z3
add wave -noupdate -group calc_out_img_size_proc -radix unsigned -childformat {{/addr_calc_tb/addr_calc_inst/row_fraction_calc(35) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(34) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(33) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(32) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(31) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(30) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(29) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(28) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(27) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(26) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(25) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(24) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(23) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(22) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(21) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(20) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(19) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(18) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(17) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(16) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(15) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(14) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(13) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(12) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(11) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(10) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(9) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(8) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(7) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(6) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(5) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(4) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(3) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(2) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(1) -radix unsigned} {/addr_calc_tb/addr_calc_inst/row_fraction_calc(0) -radix unsigned}} -subitemconfig {/addr_calc_tb/addr_calc_inst/row_fraction_calc(35) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(34) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(33) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(32) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(31) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(30) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(29) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(28) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(27) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(26) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(25) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(24) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(23) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(22) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(21) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(20) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(19) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(18) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(17) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(16) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(15) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(14) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(13) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(12) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(11) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(10) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(9) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(8) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(7) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(6) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(5) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(4) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(3) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(2) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(1) {-radix unsigned} /addr_calc_tb/addr_calc_inst/row_fraction_calc(0) {-radix unsigned}} /addr_calc_tb/addr_calc_inst/row_fraction_calc
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/col_fraction_calc
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/new_frame_x_size
add wave -noupdate -group calc_out_img_size_proc -radix unsigned /addr_calc_tb/addr_calc_inst/new_frame_y_size
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/delta_row_out_pipe1
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/delta_row_out_pipe2
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/delta_col_out_pipe1
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/delta_col_out_pipe2
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/x_size_out_shift
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/y_size_out_shift
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/new_frame_x_size_shift
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/new_frame_y_size_shift
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/tl_x
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/tl_y
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/tr_x
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/tr_y
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/bl_x
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/bl_y
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/br_x
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/br_y
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/row_idx_in_shift
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/col_idx_in_shift
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/row_fraction_calc_after_crop
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/col_fraction_calc_after_crop
add wave -noupdate -group in_range_calc_proc -radix unsigned -childformat {{/addr_calc_tb/addr_calc_inst/tl_out(22) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(21) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(20) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(19) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(18) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(17) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(16) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(15) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(14) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(13) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(12) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(11) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(10) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(9) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(8) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(7) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(6) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(5) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(4) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(3) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(2) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(1) -radix unsigned} {/addr_calc_tb/addr_calc_inst/tl_out(0) -radix unsigned}} -subitemconfig {/addr_calc_tb/addr_calc_inst/tl_out(22) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(21) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(20) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(19) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(18) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(17) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(16) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(15) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(14) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(13) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(12) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(11) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(10) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(9) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(8) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(7) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(6) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(5) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(4) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(3) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(2) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(1) {-radix unsigned} /addr_calc_tb/addr_calc_inst/tl_out(0) {-radix unsigned}} /addr_calc_tb/addr_calc_inst/tl_out
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/tr_out
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/bl_out
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/br_out
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/delta_row_out
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/delta_col_out
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/tl_out_phase_1
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/tr_out_phase_1
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/bl_out_phase_1
add wave -noupdate -group in_range_calc_proc -radix unsigned /addr_calc_tb/addr_calc_inst/br_out_phase_1
add wave -noupdate -group {out of range process} -radix unsigned /addr_calc_tb/addr_calc_inst/a_if_1
add wave -noupdate -group {out of range process} -radix unsigned /addr_calc_tb/addr_calc_inst/a_if_2
add wave -noupdate -group {out of range process} -radix unsigned /addr_calc_tb/addr_calc_inst/a_if_3
add wave -noupdate -group {out of range process} -radix unsigned /addr_calc_tb/addr_calc_inst/a_if_4
add wave -noupdate -group {out of range process} -radix unsigned /addr_calc_tb/addr_calc_inst/a_if_5
add wave -noupdate -group {out of range process} -radix unsigned /addr_calc_tb/addr_calc_inst/a_if_6
add wave -noupdate -group {out of range process} -radix unsigned /addr_calc_tb/addr_calc_inst/in_range
add wave -noupdate -group {control signals} -radix unsigned /addr_calc_tb/addr_calc_inst/en_valid_count
add wave -noupdate -group {control signals} -radix unsigned /addr_calc_tb/addr_calc_inst/valid_counter
add wave -noupdate -group {control signals} -radix unsigned /addr_calc_tb/addr_calc_inst/data_valid_out_sig
add wave -noupdate -group {control signals} -radix unsigned /addr_calc_tb/addr_calc_inst/total_counter
add wave -noupdate -group {control signals} -radix unsigned /addr_calc_tb/addr_calc_inst/unit_finish_sig
add wave -noupdate -group {control signals} -radix unsigned /addr_calc_tb/addr_calc_inst/enable_unit
add wave -noupdate -radix unsigned /addr_calc_tb/curr_st
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {12992759 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 440
configure wave -valuecolwidth 177
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
WaveRestoreZoom {0 ps} {12863286 ps}
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
run 5 ms


