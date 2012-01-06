onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /decomp_tb/clk
add wave -noupdate -format Logic /decomp_tb/data_rdy
add wave -noupdate -format Logic /decomp_tb/rx_rdy
add wave -noupdate -format Logic /decomp_tb/end_pic
add wave -noupdate -format Logic /decomp_tb/col_en
add wave -noupdate -format Literal -radix unsigned /decomp_tb/color
add wave -noupdate -format Literal -radix unsigned /decomp_tb/repetition
add wave -noupdate -format Literal -radix unsigned /decomp_tb/col_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
WaveRestoreZoom {6050 ns} {7050 ns}
configure wave -namecolwidth 150
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
