onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /sdram_tb/clk_133
add wave -noupdate -format Logic /sdram_tb/rst
add wave -noupdate -format Literal -radix unsigned /sdram_tb/dram_addr
add wave -noupdate -format Literal -radix unsigned /sdram_tb/addr
add wave -noupdate -format Literal /sdram_tb/dram_bank
add wave -noupdate -format Logic /sdram_tb/dram_ras_n
add wave -noupdate -format Logic /sdram_tb/dram_cas_n
add wave -noupdate -format Logic /sdram_tb/dram_we_n
add wave -noupdate -format Logic /sdram_tb/we_i
add wave -noupdate -format Literal -radix unsigned /sdram_tb/dram_dq
add wave -noupdate -format Literal -radix unsigned /sdram_tb/dat_o
add wave -noupdate -format Literal -radix unsigned /sdram_tb/dat_i
add wave -noupdate -format Literal -radix unsigned /sdram_tb/sdr_rw/mem_value
add wave -noupdate -format Logic /sdram_tb/dram_ldqm
add wave -noupdate -format Logic /sdram_tb/dram_udqm
add wave -noupdate -format Logic /sdram_tb/cmd
add wave -noupdate -format Logic /sdram_tb/cmd_ack
add wave -noupdate -format Logic /sdram_tb/cmd_done
add wave -noupdate -format Logic /sdram_tb/data_req
add wave -noupdate -format Logic /sdram_tb/data_valid
add wave -noupdate -format Literal -radix unsigned /sdram_tb/burst_len
add wave -noupdate -format Logic /sdram_tb/green_led
add wave -noupdate -format Logic /sdram_tb/red_led
add wave -noupdate -format Logic /sdram_tb/writing
add wave -noupdate -format Literal /sdram_tb/sdr_ctrl/current_state
add wave -noupdate -format Literal /sdram_tb/sdr_ctrl/current_init_state
add wave -noupdate -format Literal /sdram_tb/sdr_rw/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
configure wave -namecolwidth 240
configure wave -valuecolwidth 296
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1392 ns}
