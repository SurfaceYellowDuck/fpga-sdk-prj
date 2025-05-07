//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.03 Education 
//Created Time: 2025-05-07 18:34:34
create_clock -name JTAG_TCK -period 1000 -waveform {0 125} [get_ports {JTAG_TCK}] -add
create_clock -name CLK_27MHz -period 37.037 -waveform {0 18.518} [get_ports {CLK_27MHz}] -add
create_generated_clock -name CLK -source [get_ports {CLK_27MHz}] -divide_by 9 -multiply_by 10 -duty_cycle 50 -add [get_nets {CLK}]
set_input_delay -clock JTAG_TCK 6.6 -add_delay [get_ports {JTAG_TMS JTAG_TDI}]
set_output_delay -clock JTAG_TCK 3.3 -add_delay [get_ports {JTAG_TDO}]
