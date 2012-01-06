onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock & Reset}
add wave -noupdate -format Logic /vesa_tb/clk
add wave -noupdate -format Logic /vesa_tb/reset
add wave -noupdate -divider {I/O RGB}
add wave -noupdate -format Literal -radix unsigned /vesa_tb/r_in
add wave -noupdate -format Literal -radix unsigned /vesa_tb/g_in
add wave -noupdate -format Literal -radix unsigned /vesa_tb/b_in
add wave -noupdate -format Literal -radix unsigned /vesa_tb/r_out
add wave -noupdate -format Literal -radix unsigned /vesa_tb/g_out
add wave -noupdate -format Literal -radix unsigned /vesa_tb/b_out
add wave -noupdate -divider {Sync & Blank}
add wave -noupdate -format Logic /vesa_tb/hsync
add wave -noupdate -format Logic /vesa_tb/vsync
add wave -noupdate -format Logic /vesa_tb/blank
add wave -noupdate -divider Counters
add wave -noupdate -format Literal /vesa_tb/vesa_gen_ctrl_inst/hcnt
add wave -noupdate -format Literal /vesa_tb/vesa_gen_ctrl_inst/vcnt
add wave -noupdate -format Literal /vesa_tb/vesa_gen_ctrl_inst/req_lines_cnt
add wave -noupdate -divider {Collector Signals}
add wave -noupdate -format Literal /vesa_tb/vesa_pic_col_inst/hcnt
add wave -noupdate -format Literal /vesa_tb/vesa_pic_col_inst/vcnt
add wave -noupdate -format Logic /vesa_tb/vesa_pic_col_inst/blank
add wave -noupdate -format Logic /vesa_tb/vesa_pic_col_inst/collect_active
add wave -noupdate -format Literal -radix unsigned /vesa_tb/vesa_pic_col_inst/r_in
add wave -noupdate -format Literal -radix unsigned /vesa_tb/vesa_pic_col_inst/g_in
add wave -noupdate -format Literal -radix unsigned /vesa_tb/vesa_pic_col_inst/b_in
add wave -noupdate -divider {Data Handshake}
add wave -noupdate -format Logic /vesa_tb/req_data
add wave -noupdate -format Logic /vesa_tb/data_valid
add wave -noupdate -format Literal -radix hexadecimal /vesa_tb/pixels_req
add wave -noupdate -format Logic /vesa_tb/req_ln_trig
add wave -noupdate -divider {Frame Size}
add wave -noupdate -format Literal -radix hexadecimal /vesa_tb/left_frame
add wave -noupdate -format Literal -radix hexadecimal /vesa_tb/upper_frame
add wave -noupdate -format Literal -radix hexadecimal /vesa_tb/right_frame
add wave -noupdate -format Literal -radix hexadecimal /vesa_tb/lower_frame
add wave -noupdate -format Literal /vesa_tb/vesa_gen_ctrl_inst/left_frame_i
add wave -noupdate -format Literal /vesa_tb/vesa_gen_ctrl_inst/right_frame_i
add wave -noupdate -format Literal /vesa_tb/vesa_gen_ctrl_inst/upper_frame_i
add wave -noupdate -format Literal /vesa_tb/vesa_gen_ctrl_inst/lower_frame_i
add wave -noupdate -divider {Image Enable}
add wave -noupdate -format Logic /vesa_tb/vesa_en
add wave -noupdate -format Logic /vesa_tb/image_tx_en
add wave -noupdate -format Logic /vesa_tb/vesa_gen_ctrl_inst/pic_enable_i
add wave -noupdate -format Logic /vesa_tb/vesa_gen_ctrl_inst/req_data_hor_cond1
add wave -noupdate -format Logic /vesa_tb/vesa_gen_ctrl_inst/req_data_hor_cond2
add wave -noupdate -format Logic /vesa_tb/vesa_gen_ctrl_inst/req_data_ver_cond1
add wave -noupdate -format Logic /vesa_tb/vesa_gen_ctrl_inst/blanking_hor_cond
add wave -noupdate -format Logic /vesa_tb/vesa_gen_ctrl_inst/blanking_ver_cond
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {774444 ns} 0}
configure wave -namecolwidth 378
configure wave -valuecolwidth 100
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
update
WaveRestoreZoom {765591 ns} {784087 ns}
