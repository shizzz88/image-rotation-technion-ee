onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock and Reset}
add wave -noupdate -format Logic /uart_mp_tb/clk
add wave -noupdate -format Logic /uart_mp_tb/rst
add wave -noupdate -divider {Data from UART Generator}
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/din
add wave -noupdate -format Logic /uart_mp_tb/uart_serial
add wave -noupdate -format Logic /uart_mp_tb/valid
add wave -noupdate -divider {MP Decoder Errors}
add wave -noupdate -format Logic /uart_mp_tb/parity_err
add wave -noupdate -format Logic /uart_mp_tb/sbit_err
add wave -noupdate -format Logic /uart_mp_tb/eof_err
add wave -noupdate -format Logic /uart_mp_tb/crc_err
add wave -noupdate -divider {DONE Signals}
add wave -noupdate -format Logic /uart_mp_tb/mp_dec_done
add wave -noupdate -format Logic /uart_mp_tb/mp_enc_done
add wave -noupdate -divider Registers
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/type_reg
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/addr_reg
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/len_reg
add wave -noupdate -divider {MP Decoder <--> RAM}
add wave -noupdate -format Logic /uart_mp_tb/write_en
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/write_addr
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/dec2ram
add wave -noupdate -divider {MP Encoder <--> FIFO}
add wave -noupdate -format Logic /uart_mp_tb/fifo_full
add wave -noupdate -format Logic /uart_mp_tb/fifo_empty
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/mp2fifo
add wave -noupdate -format Logic /uart_mp_tb/enc_dout_val
add wave -noupdate -divider {FIFO <--> UART TX}
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/fifo2tx_data
add wave -noupdate -format Logic /uart_mp_tb/fifo2tx_val
add wave -noupdate -format Logic /uart_mp_tb/uart_tx_out
add wave -noupdate -format Logic /uart_mp_tb/fifo_rd_en
add wave -noupdate -divider {MP Decoder <--> CRC}
add wave -noupdate -format Logic /uart_mp_tb/dec2crc_valid
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/dec2crc_data
add wave -noupdate -format Logic /uart_mp_tb/dec2crc_rst
add wave -noupdate -format Logic /uart_mp_tb/dec2crc_req
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/crc2dec_data
add wave -noupdate -format Logic /uart_mp_tb/crc2dec_valid
add wave -noupdate -divider {MP Encoder <--> CRC}
add wave -noupdate -format Logic /uart_mp_tb/enc2crc_valid
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/enc2crc_data
add wave -noupdate -format Logic /uart_mp_tb/enc2crc_rst
add wave -noupdate -format Logic /uart_mp_tb/enc2crc_req
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/crc2enc_data
add wave -noupdate -format Logic /uart_mp_tb/crc2enc_valid
add wave -noupdate -divider {MP Encoder <--> RAM}
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/ram_read_addr
add wave -noupdate -format Literal -radix hexadecimal /uart_mp_tb/ram_dout
add wave -noupdate -format Logic /uart_mp_tb/ram_dout_valid
add wave -noupdate -format Logic /uart_mp_tb/enc2ram_rd_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 303
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
WaveRestoreZoom {0 ps} {2129 ps}
