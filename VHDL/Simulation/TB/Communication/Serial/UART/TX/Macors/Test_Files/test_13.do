transcript off
onerror abort
echo "-------------- Executing Test 13 -------------"
echo "------------ TX Baudrate : 120960 ------------"
echo "------------ RX Baudrate : 115200 ------------"
echo "------------ System Clock : 33MHz ------------"
echo "--------- Clock Resolution Error : 5% --------"

;# ====== start of stimulus section ======
vsim -t 1ps -Gtx_baudrate_g=120960 -Grx_baudrate_g=115200 -Gtest_number_g=13 -Gclkrate_g=33333333 uart_tx_tb
run 240 ms
force end_test 1
run 1 ps
echo "Simulation time: $now [string trim $resolution 01]"
quit -sim
;# ======= end of stimulus section =======
echo "------- End of Test 13 -------"