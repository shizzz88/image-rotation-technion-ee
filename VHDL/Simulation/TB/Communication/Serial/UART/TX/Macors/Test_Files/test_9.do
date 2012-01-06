transcript off
onerror abort
echo "-------------- Executing Test 9 --------------"
echo "------------ TX Baudrate : 110592 ------------"
echo "------------ RX Baudrate : 115200 ------------"
echo "-------------  Parity Bit Enabled ------------"
echo "----------------  Even Parity  ---------------"
echo "--------- Clock Resolution Error : 4% --------"

;# ====== start of stimulus section ======
vsim -t 1ps -Gtx_baudrate_g=110592 -Grx_baudrate_g=115200 -Gtest_number_g=9 -Gparity_en_g=1 -Gparity_odd_g=false uart_tx_tb
run 60 ms
force end_test 1
run 1 ps
echo "Simulation time: $now [string trim $resolution 01]"
quit -sim
;# ======= end of stimulus section =======
echo "------- End of Test 9 -------"