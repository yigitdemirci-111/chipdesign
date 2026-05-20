`timescale 1ns / 1ps
module mcu_tb;
    logic clk; logic rst_n;
    initial begin clk=0; forever #5 clk=~clk; end
    initial begin rst_n=0; #20 rst_n=1; end
    mcu_top u_dut (.clk_i(clk), .rst_ni(rst_n));
    initial begin
        $dumpfile("mcu_top.vcd");
        $dumpvars(0, mcu_tb);
        #300; // 300ns bekle
        $stop;
    end
endmodule
