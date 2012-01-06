transcript off
onerror abort
echo "-------------- Executing Test 14 --------------"
echo "------------ TX Baudrate : 108288 ------------"
echo "------------ RX Baudrate : 115200 ------------"
echo "------------ System Clock : 33MHz ------------"
echo "--------- Clock Resolution Error : 6% --------"

;# ====== start of stimulus section ======
vsim -t 1ps -Gtx_baudrate_g=108288 -Grx_baudrate_g=115200 -Gtest_number_g=14 -Gclkrate_g=33333333 uart_tx_tb
run 240 ms
force end_test 1
run 1 ps
echo "Simulation time: $now [string trim $resolution 01]"
quit -sim
;# ======= end of stimulus section =======
echo "------- End of Test 14 -------"