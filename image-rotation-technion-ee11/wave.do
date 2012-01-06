onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_dat_i
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_dout
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_dout_val
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_wr_en
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_rd_req
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_empty
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_full
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_dout
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_rd_req
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_aclr
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/flush
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/clk_133
add wave -noupdate -radix hexadecimal /mds_top_tb/mds_top_inst/disp_ctrl_inst/clk_40
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {33326034567 ps} 0}
configure wave -namecolwidth 343
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {56700 us}
