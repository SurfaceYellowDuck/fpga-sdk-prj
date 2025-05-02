//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.03 Education 
//Created Time: 2025-04-29 19:45:10
create_clock -name clk_mem_out -period 37.037 -waveform {0 18.518} [get_nets {ddr3/ddr3_mem/gw3_top/clk_mem_out}] -add
create_clock -name clk_mem -period 9.259 -waveform {0 4.63} [get_nets {ddr3/clk_mem}] -add
create_clock -name CLK -period 37.037 -waveform {0 18.518} [get_ports {CLK}] -add
create_clock -name JTAG_TCK -period 1000 -waveform {0 125} [get_ports {JTAG_TCK}] -add
set_clock_groups -asynchronous -group [get_clocks {clk_mem_out}] -group [get_clocks {clk_mem}] -group [get_clocks {CLK}]
set_input_delay -clock JTAG_TCK 6.6 -add_delay [get_ports {JTAG_TMS JTAG_TDI}]
set_output_delay -clock JTAG_TCK 3.3 -add_delay [get_ports {JTAG_TDO}]
