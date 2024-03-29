transcript off
onerror abort
echo "-------------- Executing Test 16 -------------"
echo "------------ TX Baudrate : 109440 ------------"
echo "------------ RX Baudrate : 115200 ------------"
echo "------------ System Clock : 33MHz ------------"
echo "-------------  Parity Bit Enabled ------------"
echo "----------------  Odd Parity  ----------------"
echo "--------- Clock Resolution Error : 5% --------"

;# ====== start of stimulus section ======
vsim -t 1ps -Gtx_baudrate_g=109440 -Grx_baudrate_g=115200 -Gtest_number_g=16 -Gparity_en_g=1 -Gparity_odd_g=true -Gclkrate_g=33333333 uart_tx_tb
run 240 ms
force end_test 1
run 1 ps
echo "Simulation time: $now [string trim $resolution 01]"
quit -sim
;# ======= end of stimulus section =======
echo "------- End of Test 16 -------"