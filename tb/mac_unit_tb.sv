`timescale 1ns / 1ps

module mac_unit_tb();

    // Sinyal Tanımlamaları
    logic clk;
    logic rst_n;
    logic [7:0] weight_i;
    logic [7:0] feature_i;
    logic enable_i;
    logic clear_i;
    logic [31:0] result_o;

    // Test Edilecek Modülün (DUT) Bağlanması
    mac_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .weight_i(weight_i),
        .feature_i(feature_i),
        .enable_i(enable_i),
        .clear_i(clear_i),
        .result_o(result_o)
    );

    // 100 MHz Saat Sinyali Üretimi
    always #5 clk = ~clk;

    initial begin
        // 1. Başlangıç Değerleri ve Reset 
        $display("=== TEST BASLIYOR ===");
        clk = 0; rst_n = 0;
        weight_i = 0; feature_i = 0;
        enable_i = 0; clear_i = 0;
        
        #20 rst_n = 1; // Sistemi uyandır
        
        // 2. Senaryo 1: Basit Çarpma (10 * 5 = 50)
        @(posedge clk);
        clear_i = 1; #10; clear_i = 0; // Akümülatörü sıfırla
        weight_i = 8'd10; feature_i = 8'd5; enable_i = 1;
        #10;
        enable_i = 0;
        
        if (result_o == 32'd50) $display("TEST 1 BASARILI: %d", result_o);
        else $error("TEST 1 HATALI! Beklenen: 50, Gelen: %d", result_o);

        // 3. Senaryo 2: Akümülasyon (Önceki 50 + (4 * 20) = 130)
        #10;
        weight_i = 8'd4; feature_i = 8'd20; enable_i = 1;
        #10;
        enable_i = 0;
        
        if (result_o == 32'd130) $display("TEST 2 BASARILI: %d", result_o);
        else $error("TEST 2 HATALI! Beklenen: 130, Gelen: %d", result_o);

        // Testi Bitir
        #50 $display("=== TESTLER TAMAMLANDI ===");
        $finish;
    end

    // Dalga formu (Waveform) dökümü için VCD ayarı
    initial begin
        $dumpfile("mac_unit_wave.vcd");
        $dumpvars(0, mac_unit_tb);
    end

endmodule