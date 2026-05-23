`timescale 1ns / 1ps

module mcu_tb;
    logic clk, rst_n;
    wire [7:0] gpio_io;
    logic fetch_en; // reg yerine logic daha günceldir

    logic debug_req, debug_gnt;
    logic [31:0] debug_addr;

    // SoC Bağlantısı
    soc_top u_dut (
        .clk_i            (clk),
        .rst_ni           (rst_n),
        .fetch_enable_i   (fetch_en),
        .gpio_io          (gpio_io),
        .uart_rx_i        (1'b0),
        .uart_tx_o        (),
        .debug_instr_req  (debug_req),
        .debug_instr_gnt  (debug_gnt),
        .debug_instr_addr (debug_addr)
    );

    // Saat Üretici (100 MHz - 10ns periyot)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // İşlemci İç Durum İzleme (Hiyerarşik erişimi düzelttik)
    always @(posedge clk) begin
        if (u_dut.u_riscv_core.instr_req_o) begin
            $display("Zaman: %0t | İŞLEMCİ KOD İSTİYOR! Adres: %h | GNT: %b", $time, u_dut.u_riscv_core.instr_addr_o, u_dut.u_riscv_core.instr_gnt_i);
        end
    end

    // Reset ve Simülasyon Akışı
    initial begin
        $dumpfile("soc_test.vcd");
        $dumpvars(0, mcu_tb);

        // Başlangıç değerleri
        rst_n = 0;
        fetch_en = 0;
        $display("Zaman: %0t | RESET AKTİF", $time);

        #500; 
        rst_n = 1;
        $display("Zaman: %0t | RESET PASİF", $time);

        #100;
        fetch_en = 1;
        $display("Zaman: %0t | FETCH ENABLE 1 YAPILDI", $time);

        #100000;
        $display("Zaman: %0t | Simülasyon sonu.", $time);
        $finish;
    end
endmodule
