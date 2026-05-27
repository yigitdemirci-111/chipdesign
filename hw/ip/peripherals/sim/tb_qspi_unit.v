`timescale 1ns / 1ps

module tb_qspi_unit();

    // 1. Sistem Sinyalleri
    reg clk;
    reg resetn;

    // 2. AXI-Lite Control (CSR) Sinyalleri
    reg  [4:0]  s_axil_awaddr;
    reg         s_axil_awvalid;
    wire        s_axil_awready;
    reg  [31:0] s_axil_wdata;
    reg  [3:0]  s_axil_wstrb;
    reg         s_axil_wvalid;
    wire        s_axil_wready;
    wire [1:0]  s_axil_bresp;
    wire        s_axil_bvalid;
    reg         s_axil_bready;
    
    reg  [4:0]  s_axil_araddr;
    reg         s_axil_arvalid;
    wire        s_axil_arready;
    wire [31:0] s_axil_rdata;
    wire [1:0]  s_axil_rresp;
    wire        s_axil_rvalid;
    reg         s_axil_rready;

    // 3. QSPI Dış Dünya Pinleri
    wire sclk;
    wire cs_n;
    wire [3:0] io;

    // --- FİZİKSEL FLASH SÜRÜCÜ ---
    reg flash_drive;
    reg [3:0] flash_data;
    assign io = flash_drive ? flash_data : 4'bz;

    // 4. Saat Üretimi (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // 5. DUT (Device Under Test)
    qspi_controller #(
        .ADDR_WIDTH(32),
        .FIFO_DEPTH(16)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        
        // AXI-Lite Control
        .s_axil_awaddr(s_axil_awaddr), .s_axil_awvalid(s_axil_awvalid), .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata), .s_axil_wstrb(s_axil_wstrb), .s_axil_wvalid(s_axil_wvalid), .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp), .s_axil_bvalid(s_axil_bvalid), .s_axil_bready(s_axil_bready),
        .s_axil_araddr(s_axil_araddr), .s_axil_arvalid(s_axil_arvalid), .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata), .s_axil_rresp(s_axil_rresp), .s_axil_rvalid(s_axil_rvalid), .s_axil_rready(s_axil_rready),
        
        // AXI-Lite DMA (Kullanılmıyor, Tie-off)
        .m_axi_awready(1'b0), .m_axi_wready(1'b0), .m_axi_bvalid(1'b0), .m_axi_bresp(2'b00),
        .m_axi_arready(1'b0), .m_axi_rdata(32'd0), .m_axi_rvalid(1'b0), .m_axi_rresp(2'b00),
        
        // AXI-Lite XIP (Kullanılmıyor, Tie-off)
        .s_axi_awaddr(32'd0), .s_axi_awvalid(1'b0), .s_axi_wdata(32'd0), .s_axi_wstrb(4'd0), .s_axi_wvalid(1'b0), .s_axi_bready(1'b0),
        .s_axi_araddr(32'd0), .s_axi_arvalid(1'b0), .s_axi_rready(1'b0),
        
        // QSPI Pads
        .sclk(sclk),
        .cs_n(cs_n),
        .io(io),
        .irq()
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
            @(posedge clk); #1;
            s_axil_awaddr = 0; s_axil_awvalid = 0; s_axil_wdata = 0; s_axil_wstrb = 0; s_axil_wvalid = 0;
            s_axil_bready = 1;
            wait(s_axil_bvalid);
            @(posedge clk); #1;
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
            @(posedge clk); #1;
            s_axil_araddr = 0; s_axil_arvalid = 0;
            wait(s_axil_rvalid);
            read_data = s_axil_rdata;
            @(posedge clk); #1;
            s_axil_rready = 0;
        end
    endtask

    // ANA TEST SENARYOSU
    reg [31:0] read_val;

    initial begin
        resetn = 0;
        s_axil_awaddr = 0; s_axil_awvalid = 0; s_axil_wdata = 0; s_axil_wstrb = 0; s_axil_wvalid = 0; s_axil_bready = 0;
        s_axil_araddr = 0; s_axil_arvalid = 0; s_axil_rready = 0;
        
        flash_drive = 0;
        flash_data = 4'h0;

        #100 resetn = 1;
        #100;

        $display("---------------------------------------------------");
        $display("  1. TEST: QSPI TX (PAGE PROGRAM - 0x02) ");
        $display("---------------------------------------------------");
        axi_write(5'h08, 32'hDDCCBBAA);
        axi_write(5'h04, 32'h00123456);
        axi_write(5'h00, 32'h0003_0402);
        
        #25000; 

        $display("---------------------------------------------------");
        $display("  2. TEST: QSPI RX (FAST READ QUAD OUT - 0x6B) ");
        $display("---------------------------------------------------");
        
        flash_drive = 0;
        flash_data = 4'hA; // Hatta basacağımız veri (1010)

        // 1. Adresi Belirle
        axi_write(5'h04, 32'h00ABCDEF);
        
        // 2. CCR_REG'i ayarla
        fork
            begin
                // FSM'yi tetikleyen AXI yazması (QOR - 0x6B)
                axi_write(5'h00, 32'h0003_336B);
            end
            begin
                // --- FİZİKSEL SENKRONİZASYON ---
                wait(cs_n == 0); // İşlem başlangıcı

                repeat(38) @(negedge sclk);
                flash_drive = 1;              
                wait(cs_n == 1'b1);
                flash_drive = 0;
            end
        join
        
        // FSM'nin toparlanması ve FIFO'ya yazması için ek delay
        #100;

        $display("---------------------------------------------------");
        $display("  3. TEST: FIFO OVERFLOW HATASI VE TEMİZLENMESİ (W1C) ");
        $display("---------------------------------------------------");
        // FIFO Derinliği 16. Kasıtlı olarak 17 veri yazıp taşıracağız.
        $display("TX FIFO'ya 17 adet veri basiliyor...");
        begin : fifo_overflow_test
            integer i;
            for (i = 0; i < 17; i = i + 1) begin
                axi_write(5'h08, 32'hDEAD_BEEF); // QSPI_DR
            end
        end
        
        #50;
        // STA_REG (0x0C) okunarak hata bayrakları (Bit 11:8) kontrol ediliyor
        axi_read(5'h0C, read_val);
        if (read_val[11:8] == 4'b0010) begin
            $display("BASARILI: Donanim TX FIFO tasmasini (0010) basariyla yakaladi!");
        end else begin
            $display("HATA: Donanim tasmayi yakalayamadi. STA_REG: %h", read_val);
        end
        
        // Hata bayrağını temizlemek için STA_REG[9]. bitine (TX Hata Temizleme) 1 yaz (Write-1-to-Clear)
        axi_write(5'h0C, 32'h0000_0200); 
        #50;
        axi_read(5'h0C, read_val);
        if (read_val[11:8] == 4'b0000) 
            $display("BASARILI: Hata bayragi yazilim (W1C) ile basariyla temizlendi.");
        else 
            $display("HATA: Bayrak temizlenemedi!");


        $display("---------------------------------------------------");
        $display("  4. TEST: DONANIMSAL FIFO FLUSH (TEMIZLEME) ");
        $display("---------------------------------------------------");
        // Şu an FIFO ağzına kadar dolu (16 veri var). STA_REG[7] (TX Empty) 0 olmalı.
        axi_read(5'h0C, read_val);
        if (read_val[7] == 1'b0) $display("TX FIFO su an dolu, Flush komutu gonderiliyor...");
        
        // FCR_REG (0x10) yazmacının 1. bitine (TX Flush) 1 yaz
        axi_write(5'h10, 32'h0000_0002);
        #50;
        
        // Tekrar STA_REG kontrolü: TX Empty (Bit 7) 1 olmuş mu?
        axi_read(5'h0C, read_val);
        if (read_val[7] == 1'b1) 
            $display("BASARILI: TX FIFO donanimsal olarak basariyla bosaltildi!");
        else 
            $display("HATA: Flush islemi basarisiz oldu!");


        // 3. Gelen veriyi RX FIFO'dan (DR_REG) oku
        axi_read(5'h08, read_val);
        $display("RX FIFO'dan okunan deger: %h (Beklenen: aaaaaaaa)", read_val);

        $display("---------------------------------------------------");
        $display(" TESTLER TAMAMLANDI.");
        $display("---------------------------------------------------");
        $finish;
    end

    // VCD Kaydı
    initial begin
        $dumpfile("qspi_unit_sim.vcd");
        $dumpvars(0, tb_qspi_unit);
    end

endmodule