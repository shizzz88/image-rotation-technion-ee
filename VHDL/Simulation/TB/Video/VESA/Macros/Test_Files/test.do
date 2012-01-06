transcript off
onerror abort

;# ====== start of stimulus section ======
;# Test 1: 800X600 Picture
vsim -t 1ns -Gtest_number_g=1 -Gfile_prefix_in_g=800X600 -Gfile_prefix_out_g=800x600 vesa_tb
run 18 ms
quit -sim

;# Test 2: 800X600 Picture - Different VESA Parameters
vsim -t 1ns -Gtest_number_g=2 -Gfile_prefix_in_g=800X600 -Gfile_prefix_out_g=800x600 -Ghor_left_border_g=7 -Ghor_right_border_g=6 -Gver_top_border_g=5 -Gver_buttom_border_g=4 -Ghor_back_porch_g=9 -Ghor_front_porch_g=8 -Gver_back_porch_g=7 -Gver_front_porch_g=6 vesa_tb
run 18 ms
quit -sim

;# Test 3: 640X480 Picture - Different VESA Parameters
vsim -t 1ns -Gtest_number_g=3 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Ghor_left_border_g=7 -Ghor_right_border_g=6 -Gver_top_border_g=5 -Gver_buttom_border_g=4 -Ghor_back_porch_g=9 -Ghor_front_porch_g=8 -Gver_back_porch_g=7 -Gver_front_porch_g=6 -Gleft_frame_g=130 -Gright_frame_g=130 -Gupper_frame_g=60 -Glower_frame_g=60 vesa_tb
run 58 ms
quit -sim

;# Test 4: 640X480 Picture - Different VESA Parameters, Frame's size diminished image's size
vsim -t 1ns -Gtest_number_g=4 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=130 -Gright_frame_g=130 -Gupper_frame_g=110 -Glower_frame_g=110 vesa_tb
run 18 ms
quit -sim

;# Test 5: 640X480 Picture - Different VESA Parameters, Frame's size diminished image's size, Different frame color
vsim -t 1ns -Gtest_number_g=5 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=130 -Gright_frame_g=130 -Gupper_frame_g=110 -Glower_frame_g=110 -Gred_default_color_g=255 -Ggreen_default_color_g=0 -Gblue_default_color_g=0 vesa_tb
run 18 ms
quit -sim

;# Test 6: 640X480 Picture - Different VESA Parameters, Frame's size diminished image's size, Different frame color
vsim -t 1ns -Gtest_number_g=6 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=0 -Gright_frame_g=260 -Gupper_frame_g=0 -Glower_frame_g=220 -Gred_default_color_g=0 -Ggreen_default_color_g=255 -Gblue_default_color_g=0 vesa_tb
run 18 ms
quit -sim

;# Test 7: 640X480 Picture - Different VESA Parameters,  Different frame place, Different frame color
vsim -t 1ns -Gtest_number_g=7 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=260 -Gright_frame_g=0 -Gupper_frame_g=120 -Glower_frame_g=0 -Gred_default_color_g=0 -Ggreen_default_color_g=0 -Gblue_default_color_g=255 vesa_tb
run 18 ms
quit -sim

;# Test 8: 640X480 Picture - Different VESA Parameters, Different frame place, Different frame color
vsim -t 1ns -Gtest_number_g=8 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=260 -Gright_frame_g=0 -Gupper_frame_g=120 -Glower_frame_g=0 -Gred_default_color_g=0 -Ggreen_default_color_g=0 -Gblue_default_color_g=255 vesa_tb
run 18 ms
quit -sim

;# Test 9: 640X480 Picture - Different VESA Parameters, Different frame place, Different frame color
vsim -t 1ns -Gtest_number_g=9 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=100 -Gright_frame_g=160 -Gupper_frame_g=100 -Glower_frame_g=20 -Gred_default_color_g=100 -Ggreen_default_color_g=100 -Gblue_default_color_g=100 -Ghor_sync_time_g=1 -Gver_sync_time_g=1 vesa_tb
run 18 ms
quit -sim

;# Test 10: 640X480 Picture - Different VESA Parameters, Frame's size diminished image's size, Different frame color
vsim -t 1ns -Gtest_number_g=10 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=320 -Gright_frame_g=320 -Gupper_frame_g=100 -Glower_frame_g=20 -Gred_default_color_g=100 -Ggreen_default_color_g=100 -Gblue_default_color_g=100 -Ghor_sync_time_g=1 -Gver_sync_time_g=1 vesa_tb
run 18 ms
quit -sim

;# Test 11: 640X480 Picture - Different VESA Parameters, Frame's size diminished image's size, Different frame color
vsim -t 1ns -Gtest_number_g=11 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=400 -Gright_frame_g=400 -Gupper_frame_g=100 -Glower_frame_g=20 -Gred_default_color_g=100 -Ggreen_default_color_g=100 -Gblue_default_color_g=100 -Ghor_sync_time_g=1 -Gver_sync_time_g=1 vesa_tb
run 18 ms
quit -sim

;# Test 12: 640X480 Picture - Different VESA Parameters, Frame's size diminished image's size, Different frame color
vsim -t 1ns -Gtest_number_g=12 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=130 -Gright_frame_g=130 -Gupper_frame_g=400 -Glower_frame_g=500 -Gred_default_color_g=100 -Ggreen_default_color_g=100 -Gblue_default_color_g=100 -Ghor_sync_time_g=1 -Gver_sync_time_g=1 vesa_tb
run 18 ms
quit -sim

;# Test 13: 640X480 Picture - Different VESA Parameters, Stimulus of image_tx_en before receiving image
vsim -t 1ns -Gtest_number_g=13 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=130 -Gright_frame_g=130 -Gupper_frame_g=60 -Glower_frame_g=60 vesa_tb
force image_tx_en 0
run 6 ms
force image_tx_en 1
run 12 ms
quit -sim

;# Test 14: 640X480 Picture - Different VESA Parameters, Stimulus of vesa_tx_en before receiving image
vsim -t 1ns -Gtest_number_g=14 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=130 -Gright_frame_g=130 -Gupper_frame_g=60 -Glower_frame_g=60 vesa_tb
force vesa_en 0
run 6 ms
force vesa_en 1
run 12 ms
quit -sim

;# Test 15: 640X480 Picture - Different VESA Parameters, Stimulus of image_tx_en, vesa_en while receiving image
vsim -t 1ns -Gtest_number_g=15 -Gfile_prefix_in_g=640X480 -Gfile_prefix_out_g=640X480 -Gleft_frame_g=130 -Gright_frame_g=130 -Gupper_frame_g=60 -Glower_frame_g=60 vesa_tb
force vesa_en 1
force image_tx_en 1
run 6 ms
force vesa_en 0
force image_tx_en 0
run 30 ms
quit -sim

;# ======= end of stimulus section =======
echo "------- End of VESA Tests -------"