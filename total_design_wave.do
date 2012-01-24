onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/addr
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/addr_bits
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/ba
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/bank0
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/bank1
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/bank2
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/bank3
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/bank_index
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/cas
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/cke
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/clk
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/col_bits
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/col_index
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/cs
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/curr_sd_val
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/curr_sd_val1
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/curr_sd_val2
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/data_bits
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/do_en
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/do_en1
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/do_en2
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/dq
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/dqm
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/latency_pipe
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/ras
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/row_index
add wave -noupdate -group SDRAM-MODEL -radix hexadecimal /mds_top_tb/sdram_model_inst/we
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/rst
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/uart_serial_in
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/clk_i
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_ack_i
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_stall_i
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_err_i
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_dat_i
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_adr_o
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_cyc_o
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_stb_o
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_tga_o
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_tgc_o
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_dat_o
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_we_o
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/data_rx2dec
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/valid
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/sbit_err
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/sbit_err_status
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ram_ready
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ack_i_cnt
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/err_i_status
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/dat_1st_bool
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/neg_cyc_bool
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_cyc_internal
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_stb_internal
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_adr_internal
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ram_addr_out
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ram_aout_val
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ram_dout
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ram_full_addr
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ram_1st_data
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ram_bytes_left
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/eof_err_status
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/crc_err_status
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/eof_err
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/crc_err
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/mp_done
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/type_reg
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/addr_reg
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/len_reg
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/write_en
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/dec2ram
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/dec2crc_valid
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/dec2crc_data
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/dec2crc_rst
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/dec2crc_req
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/crc2dec_data
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/crc2dec_valid
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/wbm_cur_st
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/datalen
add wave -noupdate -group RX-Path -radix hexadecimal /mds_top_tb/mds_top_inst/rx_path_inst/ram_expect_adr
add wave -noupdate /mds_top_tb/clk_133
add wave -noupdate /mds_top_tb/rst_133
add wave -noupdate /mds_top_tb/clk_40
add wave -noupdate /mds_top_tb/uart_serial_in
add wave -noupdate /mds_top_tb/uart_serial_out
add wave -noupdate /mds_top_tb/dram_addr
add wave -noupdate /mds_top_tb/dram_bank
add wave -noupdate /mds_top_tb/dram_cas_n
add wave -noupdate /mds_top_tb/dram_cke
add wave -noupdate /mds_top_tb/dram_cs_n
add wave -noupdate /mds_top_tb/dram_dq
add wave -noupdate /mds_top_tb/dram_ldqm
add wave -noupdate /mds_top_tb/dram_udqm
add wave -noupdate /mds_top_tb/dram_ras_n
add wave -noupdate /mds_top_tb/dram_we_n
add wave -noupdate /mds_top_tb/r_out
add wave -noupdate /mds_top_tb/g_out
add wave -noupdate /mds_top_tb/b_out
add wave -noupdate /mds_top_tb/blank
add wave -noupdate /mds_top_tb/hsync
add wave -noupdate /mds_top_tb/vsync
add wave -noupdate /mds_top_tb/rst_40
add wave -noupdate /mds_top_tb/uart_gen_inst/uart_out
add wave -noupdate /mds_top_tb/uart_gen_inst/value
add wave -noupdate /mds_top_tb/uart_gen_inst/valid
add wave -noupdate /mds_top_tb/uart_gen_inst/clk_i
add wave -noupdate /mds_top_tb/uart_gen_inst/clk_unmasked
add wave -noupdate /mds_top_tb/uart_gen_inst/reopen_file
add wave -noupdate /mds_top_tb/uart_gen_inst/reopen_file_delay
add wave -noupdate /mds_top_tb/uart_gen_inst/valid_i
add wave -noupdate /mds_top_tb/uart_gen_inst/clk_en
add wave -noupdate /mds_top_tb/mds_top_inst/clk_133
add wave -noupdate /mds_top_tb/mds_top_inst/clk_40
add wave -noupdate /mds_top_tb/mds_top_inst/rst_133
add wave -noupdate /mds_top_tb/mds_top_inst/rst_40
add wave -noupdate /mds_top_tb/mds_top_inst/uart_serial_in
add wave -noupdate /mds_top_tb/mds_top_inst/uart_serial_out
add wave -noupdate /mds_top_tb/mds_top_inst/dram_addr
add wave -noupdate /mds_top_tb/mds_top_inst/dram_bank
add wave -noupdate /mds_top_tb/mds_top_inst/dram_cas_n
add wave -noupdate /mds_top_tb/mds_top_inst/dram_cke
add wave -noupdate /mds_top_tb/mds_top_inst/dram_cs_n
add wave -noupdate /mds_top_tb/mds_top_inst/dram_dq
add wave -noupdate /mds_top_tb/mds_top_inst/dram_ldqm
add wave -noupdate /mds_top_tb/mds_top_inst/dram_udqm
add wave -noupdate /mds_top_tb/mds_top_inst/dram_ras_n
add wave -noupdate /mds_top_tb/mds_top_inst/dram_we_n
add wave -noupdate /mds_top_tb/mds_top_inst/r_out
add wave -noupdate /mds_top_tb/mds_top_inst/g_out
add wave -noupdate /mds_top_tb/mds_top_inst/b_out
add wave -noupdate /mds_top_tb/mds_top_inst/blank
add wave -noupdate /mds_top_tb/mds_top_inst/hsync
add wave -noupdate /mds_top_tb/mds_top_inst/vsync
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_dat_i
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_stall_i
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_ack_i
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_err_i
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_adr_o
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_tga_o
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_dat_o
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_cyc_o
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_stb_o
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_we_o
add wave -noupdate /mds_top_tb/mds_top_inst/icx_wbm_tgc_o
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_adr_i
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_tga_i
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_dat_i
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_cyc_i
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_stb_i
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_we_i
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_tgc_i
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_dat_o
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_stall_o
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_ack_o
add wave -noupdate /mds_top_tb/mds_top_inst/ic_wbs_err_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_adr_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_tga_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_cyc_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_stb_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_we_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_tgc_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_dat_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_dat_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_stall_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_ack_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_wbm_err_i
add wave -noupdate /mds_top_tb/mds_top_inst/mem_rx_wbm_dat_i
add wave -noupdate /mds_top_tb/mds_top_inst/mem_rx_wbm_stall_i
add wave -noupdate /mds_top_tb/mds_top_inst/mem_rx_wbm_ack_i
add wave -noupdate /mds_top_tb/mds_top_inst/mem_rx_wbm_err_i
add wave -noupdate /mds_top_tb/mds_top_inst/disp_rx_wbm_dat_i
add wave -noupdate /mds_top_tb/mds_top_inst/disp_rx_wbm_stall_i
add wave -noupdate /mds_top_tb/mds_top_inst/disp_rx_wbm_ack_i
add wave -noupdate /mds_top_tb/mds_top_inst/disp_rx_wbm_err_i
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_adr_i
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_tga_i
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_cyc_i
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_tgc_i
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_stb_i
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_dat_o
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_stall_o
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_ack_o
add wave -noupdate /mds_top_tb/mds_top_inst/rd_wbs_err_o
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_dat_i
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_stall_i
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_err_i
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_ack_i
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_adr_o
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_dat_o
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_we_o
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_tga_o
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_cyc_o
add wave -noupdate /mds_top_tb/mds_top_inst/wbm_stb_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/clk_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/rst
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_adr_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_tga_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_dat_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_cyc_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_stb_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_we_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_tgc_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_dat_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_stall_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_ack_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_err_i
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_adr_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_tga_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_dat_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_cyc_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_stb_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_we_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbm_tgc_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_dat_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_stall_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_ack_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/ic_wbs_err_o
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/cur_st
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/wbm_gnt
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/wbs_gnt
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/wbs_taken
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/wbm_adr_arr
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/wbm_dat_arr
add wave -noupdate -group {Intercon Z} /mds_top_tb/mds_top_inst/intercon_z_inst/wbm_tga_arr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/clk_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rst
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_adr_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_tga_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_dat_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_cyc_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_stb_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_we_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_tgc_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_stall_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_ack_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_err_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_adr_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_tga_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_cyc_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_tgc_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_stb_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_stall_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_ack_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbs_err_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_dat_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_stall_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_err_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_ack_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_adr_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_we_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_tga_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_cyc_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbm_stb_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_reg_cyc
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_cmp_cyc
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_din_ack
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_cmp_ack_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_ack_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_cmp_stall_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_stall_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_cmp_stb
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbs_reg_stb
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_adr_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_we_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_tga_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_cyc_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_stb_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_stall_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_err_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_wbm_ack_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_adr_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_dat_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_we_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_tga_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_cyc_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_stb_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_stall_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_err_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_wbm_ack_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arb_wr_gnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arb_wr_req
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arb_rd_gnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arb_rd_req
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_bank_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/rd_bank_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/bank_switch
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_cnt_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wr_cnt_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/reg_addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/reg_din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/reg_wr_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/reg_rd_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/type_reg_din_ack
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/type_reg_rd_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/type_reg_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/type_reg_dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_din_ack
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_rd_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_din_ack
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_rd_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_din_ack
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_rd_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_din_ack
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_rd_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_din_ack
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_rd_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/clk_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/rst
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_adr_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_tga_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_dat_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_cyc_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_stb_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_stall_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_ack_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_err_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_adr_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_we_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_tga_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_cyc_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_stb_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_stall_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_err_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_ack_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/arbiter_gnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/arbiter_req
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/bank_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/bank_switch
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/type_reg
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wr_addr_reg
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wr_cnt_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wr_cnt_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_ready
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ack_i_cnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/err_i_status
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/dat_1st_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/neg_cyc_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_cyc_internal
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_stb_internal
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/cur_wr_addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wr_cnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/sum_wr_cnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/addr_pipe
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/sum_pipe_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_cnt_zero_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/type_reg_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/addr_reg_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_addr_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_aout_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_din_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_expect_adr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_1st_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_words_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_words_left
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram_words_cnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbs_cur_st
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/wbm_cur_st
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/addr_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/addr_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/data_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/data_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/dout_valid_s
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/aout_valid_s
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/bank_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/ram2mux
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/dec_gen1/dec_inst/sel
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(0)/ram_inst/addr_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(0)/ram_inst/addr_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(0)/ram_inst/data_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(0)/ram_inst/data_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(0)/ram_inst/ram_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(1)/ram_inst/addr_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(1)/ram_inst/addr_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(1)/ram_inst/data_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(1)/ram_inst/data_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_wr_inst/ram1_inst/power_sign_dec/ram_gen(1)/ram_inst/ram_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/wr_wbm_adr_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/wr_wbm_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/wr_wbm_tga_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/rd_wbm_adr_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/rd_wbm_tga_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/rd_wbm_dat_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/wbm_adr_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/wbm_tga_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/wbm_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/wbm_dat_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/arbiter_inst/wr_gnt_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/clk_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/rst
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_adr_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_tga_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_cyc_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_tgc_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_stb_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_stall_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_ack_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_err_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_adr_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_we_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_tga_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_cyc_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_stb_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_dat_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_stall_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_err_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_ack_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/arbiter_gnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/arbiter_req
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/bank_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/type_reg
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/rd_addr_reg
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wr_cnt_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wr_cnt_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_ready
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ack_i_cnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/err_i_status
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/neg_cyc_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/dat_1st_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_cyc_internal
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_stb_internal
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/cur_rd_addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/rd_cnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/rd_cnt_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/init_sdram_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ack_o_sr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/first_rx_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/update_rdcnt_bool
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/addr_pipe
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/type_reg_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/addr_reg_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_addr_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_aout_val
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_expect_adr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_words_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_words_left
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_words_cnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram_delay_cnt
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbs_cur_st
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/wbm_cur_st
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/addr_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/addr_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/data_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/data_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/dout_valid_s
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/aout_valid_s
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/bank_en
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/ram2mux
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/mux_inst_data/sel
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/mux_inst_data/input
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/mux_inst_data/output
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/mux_inst_data/in_arr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/dec_inst_aout/sel
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/clk
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/rst
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/addr_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/addr_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/aout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/data_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/din_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/data_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(0)/ram_inst/ram_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/clk
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/rst
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/addr_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/addr_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/aout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/data_in
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/din_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/data_out
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/dout_valid
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/mem_ctrl_rd_inst/ram1_inst/power_sign_mux/ram_gen(1)/ram_inst/ram_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/gen_reg_type_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/gen_reg_type_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/gen_reg_type_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/gen_reg_type_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_generate(1)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_generate(1)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_generate(1)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_generate(1)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_generate(0)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_generate(0)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_generate(0)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/angle_reg_generate(0)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_generate(1)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_generate(1)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_generate(1)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_generate(1)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_generate(0)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_generate(0)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_generate(0)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/x_start_reg_generate(0)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_generate(1)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_generate(1)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_generate(1)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_generate(1)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_generate(0)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_generate(0)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_generate(0)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/y_start_reg_generate(0)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_generate(1)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_generate(1)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_generate(1)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_generate(1)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_generate(0)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_generate(0)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_generate(0)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/zoom_reg_generate(0)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(2)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(2)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(2)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(2)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(1)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(1)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(1)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(1)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(0)/gen_reg_dbg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(0)/gen_reg_dbg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(0)/gen_reg_dbg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/dbg_reg_generate(0)/gen_reg_dbg_inst/reg_data
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_inst/wbs_adr_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_inst/wbs_dat_i
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_inst/wbs_dat_o
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_inst/dout
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_inst/addr
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_inst/din
add wave -noupdate -group {Mem Mng Top} /mds_top_tb/mds_top_inst/mem_mng_inst/wbs_reg_inst/cyc_active
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/clk_133
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/clk_40
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/rst_133
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/rst_40
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_adr_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_tga_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_dat_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_cyc_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_stb_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_we_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_tgc_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_dat_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_stall_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_ack_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_err_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_dat_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_stall_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_ack_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_err_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_adr_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_tga_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_cyc_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_stb_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbm_tgc_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/r_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/g_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/b_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/blank
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/hsync
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vsync
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixels_req
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/req_ln_trig
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vsync_int
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/hsync_int
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_full
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_req_data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_empty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_rd_req
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_data_valid
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_data_valid_sy
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/r_in_sy
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/g_in_sy
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/b_in_sy
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/r_in
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/g_in
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/b_in
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_empty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_dout_val
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_wr_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/flush
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_rd_req
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/left_frame_rg
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/upper_frame_rg
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/lower_frame_rg
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_din_ack
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_dout_valid
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_cyc
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/reg_addr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/reg_din
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/reg_wr_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/reg_rd_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/type_reg_din_ack
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/type_reg_rd_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/type_reg_dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/type_reg_dout_valid
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/left_frame_reg_din_ack
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/left_frame_reg_rd_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/left_frame_reg_dout_valid
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/right_frame_reg_din_ack
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/right_frame_reg_rd_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/right_frame_reg_dout_valid
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/upper_frame_reg_din_ack
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/upper_frame_reg_rd_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/upper_frame_reg_dout_valid
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/lower_frame_reg_din_ack
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/lower_frame_reg_rd_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/lower_frame_reg_dout_valid
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/left_frame_sy
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/upper_frame_sy
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/right_frame_sy
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/lower_frame_sy
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/left_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/upper_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/right_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/lower_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/right_frame_rg
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/wbm_adr_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/wbm_tga_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/pixels_req
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/cur_st
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/pix_cnt
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/tot_req_pix
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/rd_adr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/ack_err_cnt
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/cyc_internal
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/end_burst_b
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/req_trig_b
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/pix_max_b
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/req_trig_sig
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/req_trig_d1
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/req_trig_d2
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/vsync_sig
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/vsync_d1
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/pixel_mng_inst/vsync_d2
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/rdclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/rdreq
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/wrclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/wrreq
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/sub_wire0
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/sub_wire1
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/sub_wire2
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/sub_wire3
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/rdfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/wrempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/i_rdfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/i_wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/i_rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/i_wrempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/i_rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/i_wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/i_q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/rdclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/wrclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/rdreq
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/wrreq
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/rdfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/wrempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdfull_a
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrfull_a
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdempty_a
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrempty_a
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdfull_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrfull_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdempty_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrempty_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdfull_l
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrfull_l
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdempty_l
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrempty_l
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdusedw_a
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrusedw_a
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdusedw_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrusedw_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_rdusedw_l
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_wrusedw_l
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_q_a
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_q_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/i_q_l
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rdclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wrclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rdreq
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wrreq
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wrempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rdfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_data_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rdptr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wrptr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wrptr_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rdptrrg
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wrdelaycycle
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rden
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wren
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rdenclock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wren_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wrempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rdfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_ws_nbrp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rs_nbwp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_ws_dbrp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rs_dbwp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wr_udwn
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rd_udwn
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_wr_dbuw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_rd_dbuw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_q_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_showahead_flag
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_showahead_flag1
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_showahead_flag2
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_showahead_flag3
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_data_ready
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_data_delay_count
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/i_zero
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rdptr_d/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rdptr_d/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rdptr_d/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wrptr_d/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wrptr_d/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wrptr_d/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_ws_nbrp/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_ws_nbrp/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_ws_nbrp/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_ws_nbrp/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rs_nbwp/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rs_nbwp/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rs_nbwp/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rs_nbwp/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_ws_dbrp/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_ws_dbrp/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_ws_dbrp/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rs_dbwp/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rs_dbwp/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rs_dbwp/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wr_usedw/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wr_usedw/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wr_usedw/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rd_usedw/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rd_usedw/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rd_usedw/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wr_dbuw/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wr_dbuw/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_wr_dbuw/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rd_dbuw/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rd_dbuw/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/dp_rd_dbuw/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wr_fe/usedw_in
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wr_fe/empty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wr_fe/full
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wr_fe/i_empty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wr_fe/i_full
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wr_fe/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/wr_fe/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rd_fe/usedw_in
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rd_fe/empty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rd_fe/full
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rd_fe/i_empty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rd_fe/i_full
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rd_fe/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/async/rd_fe/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/rdfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_data_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_rdptr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wrptr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wrptr_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_rdptr_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wrptr_r
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wrptr_s
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wrempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_rdfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_rden
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wren
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wren_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_q_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_cnt_mod
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/i_max_widthu
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/rdclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/rdptr_d/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/rdptr_d/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/rdptr_d/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrptr_d/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrptr_d/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrptr_d/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrptr_e/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrptr_e/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/sync/wrptr_e/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/rdclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/wrclk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/rdreq
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/wrreq
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/rdfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/wrempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rdptr_g
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rdptr_g1p
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wrptr_g
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wrptr_g1
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_delayed_wrptr_g
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rden
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wren
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rdempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wrempty_area
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wrempty_speed
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rdempty_rreg
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rdfull_area
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rdfull_speed
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wrfull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wrfull_wreg
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rdusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wrusedw
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rdusedw_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_wrusedw_tmp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_rs_dgwp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_ws_dgrp
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/i_q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/sync_aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/sync_aclr_pre
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/write_aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/is_overflow
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/is_underflow
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_ws_dgrp/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_ws_dgrp/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_ws_dgrp/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_ws_dgrp/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_rs_dgwp/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_rs_dgwp/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_rs_dgwp/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_rs_dgwp/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_rdusedw/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_rdusedw/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_rdusedw/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_rdusedw/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_wrusedw/d
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_wrusedw/clock
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_wrusedw/aclr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/dc_fifo_inst/dcfifo_component/dcfifo_mw/lowlatency_fifo/lowlatency/dp_wrusedw/q
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/din
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/afull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/aempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/used
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/mem
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/write_addr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/read_addr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/read_addr_dup
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/count
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/ifull
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/sc_fifo_inst/iempty
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/clk
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/reset
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/r_in
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/g_in
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/b_in
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/left_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/upper_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/right_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/lower_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/vesa_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/image_tx_en
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/data_valid
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/req_data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/pixels_req
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/req_ln_trig
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/r_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/g_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/b_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/blank
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/hsync
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/vsync
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/hcnt
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/vcnt
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/req_lines_cnt
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/vesa_en_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/image_tx_en_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/left_frame_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/right_frame_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/upper_frame_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/lower_frame_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/pic_enable_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/req_data_hor_cond1
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/req_data_hor_cond2
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/req_data_ver_cond1
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/blanking_hor_cond
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/blanking_ver_cond
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/vesa_gen_ctrl_inst/vsync_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/r_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/g_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/b_out
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/left_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/upper_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/right_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/lower_frame
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/hcnt
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/vcnt
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/frame_cnt
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/frame_flag
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/synth_pic_gen_inst/frame_state
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_type_inst/addr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_type_inst/din
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_type_inst/dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_type_inst/reg_data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_upper_frame_inst/addr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_upper_frame_inst/din
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_upper_frame_inst/dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_upper_frame_inst/reg_data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_lower_frame_inst/addr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_lower_frame_inst/din
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_lower_frame_inst/dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/gen_reg_lower_frame_inst/reg_data
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_inst/wbs_adr_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_inst/wbs_dat_i
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_inst/wbs_dat_o
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_inst/dout
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_inst/addr
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_inst/din
add wave -noupdate -group {Display Top} /mds_top_tb/mds_top_inst/disp_ctrl_inst/wbs_reg_inst/cyc_active
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_addr
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_bank
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_dq
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/wbs_adr_i
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/wbs_dat_i
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/wbs_tga_i
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/wbs_dat_o
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/address_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_addr_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_bank_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_dq_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_cas_n_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_ras_n_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dram_we_n_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/dat_o_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/cmd_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/we_i_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/oe_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/oor_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/stb_err_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/oor_err_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/stall_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/rx_data_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/data_valid_r
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/current_state
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/next_state
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/current_init_state
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/next_init_state
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/init_done
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/init_pre_cntr
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/trc_cntr
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/rfsh_int_cntr
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/trcd_trp_trsc_cntr
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/wait_200us_cntr
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/do_refresh
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/blen_cnt
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/new_blen_n
add wave -noupdate -group {SDR Ctrl} /mds_top_tb/mds_top_inst/sdr_ctrl/cyc_i_internal
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/rst
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_serial_in
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/clk_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_ack_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_stall_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_err_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_dat_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_adr_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_cyc_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_stb_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_tga_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_tgc_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_dat_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_we_o
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/data_rx2dec
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/valid
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/sbit_err
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/sbit_err_status
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_ready
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ack_i_cnt
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/err_i_status
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/dat_1st_bool
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/neg_cyc_bool
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_cyc_internal
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_stb_internal
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_adr_internal
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_addr_out
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_aout_val
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_dout
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_full_addr
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_1st_data
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_bytes_left
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/eof_err_status
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/crc_err_status
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/eof_err
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/crc_err
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_done
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/type_reg
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/addr_reg
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/len_reg
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/write_en
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/dec2ram
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/dec2crc_valid
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/dec2crc_data
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/dec2crc_rst
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/dec2crc_req
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/crc2dec_data
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/crc2dec_valid
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/wbm_cur_st
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/datalen
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_expect_adr
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/dout
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/parity_err
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/cur_st
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/dout_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/din_d1
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/din_d2
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/sample_cnt
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/pos_cnt
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/one_cnt
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/parity_bit
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/uart_rx_c/parity_err_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/din
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/type_reg
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/addr_reg
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/data_crc
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/crc_in
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/dout
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/type_blk
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/addr_blk
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/len_blk
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/crc_blk
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/eof_blk
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/w_addr
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/blk_pos
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/sof_sr
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/sof_sr_cnt
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/cur_st
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/tx_regs
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/mp_dec1/crc_err_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_inst1/addr_out
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_inst1/data_in
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_inst1/data_out
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/ram_inst1/ram_data
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/checksum_inst_dec/data
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/checksum_inst_dec/checksum_out
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/checksum_inst_dec/checksum_i
add wave -noupdate /mds_top_tb/mds_top_inst/rx_path_inst/checksum_inst_dec/checksum_init_val
add wave -noupdate /mds_top_tb/vesa_pic_col_inst/r_in
add wave -noupdate /mds_top_tb/vesa_pic_col_inst/g_in
add wave -noupdate /mds_top_tb/vesa_pic_col_inst/b_in
add wave -noupdate /mds_top_tb/vesa_pic_col_inst/hcnt
add wave -noupdate /mds_top_tb/vesa_pic_col_inst/vcnt
add wave -noupdate /mds_top_tb/vesa_pic_col_inst/vsync
add wave -noupdate /mds_top_tb/sdram_model_inst/dq
add wave -noupdate /mds_top_tb/sdram_model_inst/addr
add wave -noupdate /mds_top_tb/sdram_model_inst/ba
add wave -noupdate /mds_top_tb/sdram_model_inst/clk
add wave -noupdate /mds_top_tb/sdram_model_inst/cke
add wave -noupdate /mds_top_tb/sdram_model_inst/cs
add wave -noupdate /mds_top_tb/sdram_model_inst/ras
add wave -noupdate /mds_top_tb/sdram_model_inst/cas
add wave -noupdate /mds_top_tb/sdram_model_inst/we
add wave -noupdate /mds_top_tb/sdram_model_inst/dqm
add wave -noupdate /mds_top_tb/sdram_model_inst/curr_sd_val
add wave -noupdate /mds_top_tb/sdram_model_inst/curr_sd_val1
add wave -noupdate /mds_top_tb/sdram_model_inst/curr_sd_val2
add wave -noupdate /mds_top_tb/sdram_model_inst/do_en
add wave -noupdate /mds_top_tb/sdram_model_inst/do_en1
add wave -noupdate /mds_top_tb/sdram_model_inst/do_en2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 472
configure wave -valuecolwidth 103
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
WaveRestoreZoom {0 ps} {81697 us}
