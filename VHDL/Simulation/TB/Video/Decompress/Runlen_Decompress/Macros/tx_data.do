transcript off
onerror abort
echo "------- START OF SCRIPT -------"
vcom -93 tx_data.vhd
vsim tx_data
restart -force
noview *
add wave *
;# ====== start of stimulus section ======
force clk 0 , 1 10 ns -r 20 ns
run 2400 us
;# ======= end of stimulus section =======
echo "------- END OF SCRIPT -------"
echo "The time now is $now [string trim $resolution 01]"