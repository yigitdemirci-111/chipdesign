`timescale 1ns / 1ps

module mcu_tb;
    logic clk, rst_n;
    wire [7:0] gpio_io;

    // CPU sinyallerini testbench içinde tanımlıyoruz
    logic [31:0] m_axi_awaddr, m_axi_wdata;
    logic        m_axi_awvalid, m_axi_awready, m_axi_wvalid;

    // SoC'yi testbench'e bağlıyoruz
    soc_top u_dut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .gpio_io(gpio_io),
        .uart_rx_i(1'b0),
        .uart_tx_o(),
        .i2c_sda_io(),
        .i2c_scl_o()
    );

    // Saat Üretimi
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Senaryosu
    initial begin
        $dumpfile("soc_test.vcd");
        $dumpvars(0, mcu_tb);
        
        rst_n = 0; #20 rst_n = 1;

        // 1. Test: RAM'e Yaz (Adres 0x0000)
        #20;
        u_dut.u_cpu.m_axi_awaddr  = 32'h0000; 
        u_dut.u_cpu.m_axi_wdata   = 32'hAAAA;
        u_dut.u_cpu.m_axi_awvalid = 1;
        u_dut.u_cpu.m_axi_wvalid  = 1;
        #10;
        u_dut.u_cpu.m_axi_awvalid = 0;
        u_dut.u_cpu.m_axi_wvalid  = 0;

        // 2. Test: GPIO'ya Yaz (Adres 0x1000)
        #50;
        u_dut.u_cpu.m_axi_awaddr  = 32'h1000;
        u_dut.u_cpu.m_axi_wdata   = 32'h55;
        u_dut.u_cpu.m_axi_awvalid = 1;
        u_dut.u_cpu.m_axi_wvalid  = 1;
        #10;
        u_dut.u_cpu.m_axi_awvalid = 0;
        u_dut.u_cpu.m_axi_wvalid  = 0;

        #100 $finish;
    end
endmodule
