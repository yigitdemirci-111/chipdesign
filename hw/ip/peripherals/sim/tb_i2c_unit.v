`timescale 1ns / 1ps

module tb_i2c_unit();

    // 1. Sistem Sinyalleri
    reg clk;
    reg rst_n;
    
    // 2. AXI-Lite Master Sinyalleri (İşlemci Taklidi Yapılıyor)
    reg [4:0]  s_axil_awaddr;
    reg        s_axil_awvalid;
    wire       s_axil_awready;
    reg [31:0] s_axil_wdata;
    reg [3:0]  s_axil_wstrb;
    reg        s_axil_wvalid;
    wire       s_axil_wready;
    wire [1:0] s_axil_bresp;
    wire       s_axil_bvalid;
    reg        s_axil_bready;
    
    reg [4:0]  s_axil_araddr;
    reg        s_axil_arvalid;
    wire       s_axil_arready;
    wire [31:0] s_axil_rdata;
    wire [1:0] s_axil_rresp;
    wire       s_axil_rvalid;
    reg        s_axil_rready;
    
    // 3. I2C Dış Dünya Pinleri
    wire i2c_scl_i, i2c_scl_o, i2c_scl_t;
    wire i2c_sda_i, i2c_sda_o, i2c_sda_t;
    
    assign i2c_scl_i = i2c_scl_t ? 1'b1 : i2c_scl_o;
    assign i2c_sda_i = i2c_sda_t ? 1'b0 : i2c_sda_o; // SDA bırakıldığında her zaman 0 (ACK) ver

    // 4. Saat Üretimi (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // 5. DUT 
    special_i2c_wrapper #(
        .CLK_FREQ(50_000_000)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        
        .s_axil_awaddr(s_axil_awaddr), .s_axil_awvalid(s_axil_awvalid), .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata), .s_axil_wstrb(s_axil_wstrb), .s_axil_wvalid(s_axil_wvalid), .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp), .s_axil_bvalid(s_axil_bvalid), .s_axil_bready(s_axil_bready),
        .s_axil_araddr(s_axil_araddr), .s_axil_arvalid(s_axil_arvalid), .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata), .s_axil_rresp(s_axil_rresp), .s_axil_rvalid(s_axil_rvalid), .s_axil_rready(s_axil_rready),
        
        .i2c_scl_i(i2c_scl_i), .i2c_scl_o(i2c_scl_o), .i2c_scl_t(i2c_scl_t),
        .i2c_sda_i(i2c_sda_i), .i2c_sda_o(i2c_sda_o), .i2c_sda_t(i2c_sda_t)
    );

    // AXI-LITE GÖREVLERİ
    task axi_write;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            s_axil_awaddr  = addr;
            s_axil_awvalid = 1;
            s_axil_wdata   = data;
            s_axil_wstrb   = 4'hF;
            s_axil_wvalid  = 1;
            
            wait(s_axil_awready && s_axil_wready);
            @(posedge clk);
            #1;
            
            s_axil_awaddr  = 0; s_axil_awvalid = 0;
            s_axil_wdata   = 0; s_axil_wstrb   = 0;
            s_axil_wvalid  = 0;
            
            s_axil_bready = 1;
            wait(s_axil_bvalid);
            @(posedge clk);
            #1;
            s_axil_bready = 0;
        end
    endtask

    task axi_read;
        input  [4:0] addr;
        output [31:0] read_data;
        begin
            @(posedge clk);
            s_axil_araddr  = addr;
            s_axil_arvalid = 1;
            s_axil_rready  = 1;
            
            wait(s_axil_arready);
            @(posedge clk);
            #1;
            s_axil_araddr  = 0; s_axil_arvalid = 0;
            
            wait(s_axil_rvalid);
            read_data = s_axil_rdata;
            @(posedge clk);
            #1;
            s_axil_rready = 0;
        end
    endtask

    // ANA TEST SENARYOSU
    reg [31:0] read_val;
    
    initial begin
        rst_n = 0;
        s_axil_awaddr = 0; s_axil_awvalid = 0;
        s_axil_wdata = 0; s_axil_wstrb = 0; s_axil_wvalid = 0; s_axil_bready = 0;
        s_axil_araddr = 0; s_axil_arvalid = 0;
        s_axil_rready = 0;
        
        #100 rst_n = 1;
        #100;

        $display("---------------------------------------------------");
        $display("  1. TEST: I2C TX (VERI GONDERIMI) ");
        $display("---------------------------------------------------");
        axi_write(5'h00, 32'h0000_0002);
        axi_write(5'h04, 32'h0000_005A);
        axi_write(5'h0C, 32'h0000_BBAA);
        axi_write(5'h10, 32'h0000_0001);
        #100_000; 
        axi_read(5'h10, read_val);
        if (read_val[1] == 1'b1) $display("BASARILI: TX islemi tamamlandi (TX_DONE=1)");
        else $display("HATA: TX islemi bitmedi!");
        axi_write(5'h10, 32'h0000_0000);
        #5_000;

        $display("---------------------------------------------------");
        $display("  2. TEST: I2C RX (VERI ALIMI) ");
        $display("---------------------------------------------------");
        axi_write(5'h00, 32'h0000_0001);
        axi_write(5'h04, 32'h0000_005A);
        axi_write(5'h10, 32'h0000_0004);
        #50_000;
        axi_read(5'h10, read_val);
        if (read_val[3] == 1'b1) $display("BASARILI: RX islemi tamamlandi (RX_DONE=1)");
        else $display("HATA: RX islemi bitmedi!");
        axi_write(5'h10, 32'h0000_0000);

        $display("---------------------------------------------------");
        $display("  3. TEST: DONANIMSAL KORUMA (TX VE RX AYNI ANDA) ");
        $display("---------------------------------------------------");
        axi_write(5'h10, 32'h0000_0005);
        axi_read(5'h10, read_val);
        if (read_val[0] == 1'b0 && read_val[2] == 1'b0) 
            $display("BASARILI: Donanim korumasi devreye girdi. Istek reddedildi");
        else 
            $display("HATA: Donanim korumasi calismadi, yazmac degeri: %h", read_val);

        $display("---------------------------------------------------");
        $display("  4. CORNER CASE: NBY YAZMACININ YUVARLANMASI ");
        $display("---------------------------------------------------");
        // 0 yazılması durumu (1'e yuvarlanmalı)
        axi_write(5'h00, 32'h0000_0000);
        axi_read(5'h00, read_val);
        if (read_val == 32'h0000_0001) $display("BASARILI: NBY'ye 0 yazildi, 1 olarak yuvarlandi.");
        else $display("HATA: NBY'ye 0 yazildi, okunan deger: %h", read_val);

        // 4'ten büyük değer yazılması durumu (Örn: 25 -> 4'e yuvarlanmalı)
        axi_write(5'h00, 32'h0000_0019); // 25
        axi_read(5'h00, read_val);
        if (read_val == 32'h0000_0004) $display("BASARILI: NBY'ye 25 yazildi, 4 olarak yuvarlandi.");
        else $display("HATA: NBY'ye 25 yazildi, okunan deger: %h", read_val);

        $display("---------------------------------------------------");
        $display("  5. CORNER CASE: ADRES (ADR) YAZMACININ MASKELEMESI ");
        $display("---------------------------------------------------");
        // 7-bit dışındaki bitlerin donanım tarafından maskelenmesi test ediliyor.
        axi_write(5'h04, 32'hFFFF_FFFF);
        axi_read(5'h04, read_val);
        if (read_val == 32'h0000_007F) $display("BASARILI: Adres yazmaci yalnizca alt 7 biti (0x7F) kabul etti.");
        else $display("UYARI: Adres yazmaci ust bitleri maskelemiyor. Okunan deger: %h", read_val);

        $display("---------------------------------------------------");
        $display("  6. CORNER CASE: FLAG (DONE) BITLERININ YAZILIMLA TEMIZLENMESI ");
        $display("---------------------------------------------------");
        // Kısa bir TX işlemi başlatıp bayrağın temizlenebildiğini kontrol ediyoruz.
        axi_write(5'h00, 32'h0000_0001); // NBY = 1
        axi_write(5'h10, 32'h0000_0001); // TX_EN = 1
        #50_000;
        axi_read(5'h10, read_val);
        if (read_val[1] == 1'b1) begin
            $display("TX_DONE bayragi donanim tarafindan 1 yapildi. Yazilim ile 0'a cekiliyor...");
            axi_write(5'h10, 32'h0000_0000); // Tüm konfigürasyonu sıfırla
            axi_read(5'h10, read_val);
            if (read_val[1] == 1'b0) $display("BASARILI: TX_DONE basariyla temizlendi.");
            else $display("HATA: TX_DONE temizlenemedi! Okunan deger: %h", read_val);
        end else begin
            $display("HATA: TX islemi tamamlanamadi, bayrak 0.");
        end

        $display("---------------------------------------------------");
        $display(" TESTLER TAMAMLANDI.");
        $display("---------------------------------------------------");
        $finish;
    end

    // VCD Kaydı
    initial begin
        $dumpfile("i2c_unit_sim.vcd");
        $dumpvars(0, tb_i2c_unit);
    end

endmodule