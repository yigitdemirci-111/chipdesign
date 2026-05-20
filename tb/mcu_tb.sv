`timescale 1ns / 1ps

module mcu_tb;

    // 1. Sinyal Tanımları
    logic clk;
    logic rst_n;

    // 2. Saat Üretimi (100 MHz için 5ns periyot = 10ns cycle)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 3. Reset Üretimi
    initial begin
        rst_n = 0;
        #20 rst_n = 1;
    end

    // 4. DUT (Design Under Test) Bağlantısı
    // Burada soc_top modülüne saat ve reset'i bağlıyoruz
    soc_top u_dut (
        .clk_i(clk),
        .rst_ni(rst_n)
    );

    // 5. Simülasyon Kontrolü
    initial begin
        // Dalga formu kayıt dosyası
        $dumpfile("mcu_top.vcd");
        $dumpvars(0, mcu_tb);

        // İşlemciye çalışması için süre tanı (10 mikrosaniye)
        #10000;
        
        $display("Simülasyon süresi doldu, bitiriliyor...");
        $finish;
    end

endmodule
