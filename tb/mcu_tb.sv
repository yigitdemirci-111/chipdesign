`timescale 1ns / 1ps

module mcu_tb;
    logic clk, rst_n;
    wire [7:0] gpio_io;

    // SoC Bağlantısı
    soc_top u_dut (
        .clk_i     (clk),
        .rst_ni    (rst_n),
        .gpio_io   (gpio_io),
        .uart_rx_i (1'b0),
        .uart_tx_o ()
    );

    // Saat Üretici (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("soc_test.vcd");
        $dumpvars(0, mcu_tb);

        rst_n = 0; 
        #20;
        @(negedge clk);
        rst_n = 1;

        // FSM'in tüm aşamaları (RAM Yazma -> Okuma -> GPIO Yazma) bitirmesi için süre
        #250; 

        $display("==================================================");
        $display("TEKNOFEST SoC ENTEGRASYON TEST RAPORU:");
        $display("--------------------------------------------------");
        $display("1) RAM Durumu  (m_axi_rdata) : %h", u_dut.u_cpu.m_axi_rdata);
        $display("2) GPIO Çıkışı (gpio_io)     : %b (Hex: %h)", gpio_io, gpio_io);
        $display("==================================================");

        $finish;
    end

endmodule
