#!/bin/bash
rm -f test_system mcu_top.vcd
iverilog -g2012 -D DATA_WIDTH=32 -D SEG_WIDTH=32 -D STRB_WIDTH=4 -I ../rtl -o test_system ../rtl/mcu_top.sv ../tb/mcu_tb.sv ../ips/verilog-axi/rtl/*.v
./test_system
