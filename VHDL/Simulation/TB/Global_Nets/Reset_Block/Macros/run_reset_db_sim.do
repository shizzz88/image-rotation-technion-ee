transcript off
onerror abort

echo "----------- Reset Debouncer Test -------"
;# ====== start of stimulus section ======
vsim -t 1ps -Gsys_clk_freq_g=50000000 -Gvesa_clk_freq_g=40000000 -Gsdram_clk_freq_g=133333333 -Greset_polarity_g=0 reset_db_tb

quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Clocks
add wave -noupdate -format Logic /reset_db_tb/sys_clk
add wave -noupdate -format Logic /reset_db_tb/vesa_clk
add wave -noupdate -format Logic /reset_db_tb/sdram_clk
add wave -noupdate -divider {Input Reset & PLL}
add wave -noupdate -format Logic /reset_db_tb/sys_rst
add wave -noupdate -format Logic /reset_db_tb/pll_locked
add wave -noupdate -divider {Debounced Reset}
add wave -noupdate -format Logic /reset_db_tb/deb_rst
add wave -noupdate -divider {Output Reset}
add wave -noupdate -format Logic /reset_db_tb/vesa_rst_out
add wave -noupdate -format Logic /reset_db_tb/sdram_rst_out
run 1150 ns
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 246
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
WaveRestoreZoom {0 ps} {1150 ns}

;# ======= end of stimulus section =======
echo "------- End of Reset Debouncer Test -------"
echo "------- Execute 'quit -sim' to end simulation and close wave !!! -------"