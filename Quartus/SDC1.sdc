set_time_format -unit ns -decimal_places 3

create_clock -name fpga_clk -period 20 [get_ports {fpga_clk} ]

derive_pll_clocks
derive_clock_uncertainty
