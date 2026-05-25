`timescale 1ns / 1ps

module tb_uart_unit();

    // 1. Sistem Sinyalleri
    reg aclk;
    reg aresetn;

    // 2. AXI-Lite Master Sinyalleri (İşlemciyi Taklit Edecek)
    reg [4:0]  s_axi_awaddr;
    reg [2:0]  s_axi_awprot;
    reg        s_axi_awvalid;
    wire       s_axi_awready;
    reg [31:0] s_axi_wdata;
    reg [3:0]  s_axi_wstrb;
    reg        s_axi_wvalid;
    wire       s_axi_wready;
    wire [1:0] s_axi_bresp;
    wire       s_axi_bvalid;
    reg        s_axi_bready;
    
    reg [4:0]  s_axi_araddr;
    reg [2:0]  s_axi_arprot;
    reg        s_axi_arvalid;
    wire       s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire       s_axi_rvalid;
    reg        s_axi_rready;

    // 3. UART Dış Dünya Pinleri
    wire uart_txd; // Çipten çıkan
    reg  uart_rxd; // Çipe giren

    wire interrupt; // Kesme sinyali

    // 4. Saat (Clock) Üretimi (50 MHz)
    initial begin
        aclk = 0;
        forever #10 aclk = ~aclk;
    end

    // 5. Test Edilecek UART Modülünün (DUT) Çağrılması
    axi_lite_uart #(
        .ADDR_WIDTH(5),
        .CLK_FREQ(50_000_000), // 50 MHz
        .DEFAULT_BAUD(115200)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        
        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd),
        .interrupt(interrupt)
    );

    // YARDIMCI GÖREVLER (TASKS)

    // AXI-Lite Yazma (Write) İşlemi
    task axi_write;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(posedge aclk);
            s_axi_awaddr  = addr;
            s_axi_awvalid = 1;
            s_axi_wdata   = data;
            s_axi_wstrb   = 4'hF;
            s_axi_wvalid  = 1;
            
            // Ready gelene kadar bekle
            wait(s_axi_awready && s_axi_wready);
            @(posedge aclk);
            #1; // Hold time
            
            s_axi_awaddr  = 0;
            s_axi_awvalid = 0;
            s_axi_wdata   = 0;
            s_axi_wstrb   = 0;
            s_axi_wvalid  = 0;
            
            // Yanıt (B Channel) bekle
            s_axi_bready = 1;
            wait(s_axi_bvalid);
            @(posedge aclk);
            #1;
            s_axi_bready = 0;
        end
    endtask

    // AXI-Lite Okuma (Read) İşlemi
    task axi_read;
        input  [4:0] addr;
        output [31:0] read_data;
        begin
            @(posedge aclk);
            s_axi_araddr  = addr;
            s_axi_arvalid = 1;
            s_axi_rready  = 1;
            
            wait(s_axi_arready);
            @(posedge aclk);
            #1;
            s_axi_araddr  = 0;
            s_axi_arvalid = 0;
            
            wait(s_axi_rvalid);
            read_data = s_axi_rdata; // Veriyi değişkene kaydet
            @(posedge aclk);
            #1;
            s_axi_rready = 0;
        end
    endtask

    // Dış Dünyadan (Sensör/PC) UART Verisi Gönderme (115200 baud)
    task send_uart_rx;
        input [7:0] tx_byte;
        integer i;
        begin
            uart_rxd = 0; // START BIT
            #8680;
            
            for (i = 0; i < 8; i = i + 1) begin
                uart_rxd = tx_byte[i]; // DATA BITS (LSB First)
                #8680;
            end
            
            uart_rxd = 1; // STOP BIT
            #8680;
        end
    endtask

    // KASITLI OLARAK HATALI ÇERÇEVE (FRAME ERROR) GÖNDEREN GÖREV
    task send_uart_error_frame;
        input [7:0] tx_byte;
        integer i;
        begin
            uart_rxd = 0; // START BIT
            #8680;
            for (i = 0; i < 8; i = i + 1) begin
                uart_rxd = tx_byte[i];
                #8680;
            end
            uart_rxd = 0; // INTENTIONALLY BAD STOP BIT
            #8680;
            uart_rxd = 1; // IDLE konumuna dön
        end
    endtask

    // ANA TEST SENARYOSU
    reg [31:0] read_val; // AXI okuma sonuçlarını tutacağımız değişken

    initial begin
        // Başlangıç Değerleri
        aclk = 0;
        aresetn = 0;
        uart_rxd = 1; // UART hattı boşta
        
        s_axi_awaddr = 0; s_axi_awvalid = 0;
        s_axi_wdata = 0; s_axi_wstrb = 0; s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0; s_axi_arvalid = 0; s_axi_rready = 0;
        
        // Sistemi Resetten Çıkar
        #100 aresetn = 1;
        #100;

        $display("---------------------------------------------------");
        $display("  1. TEST: UART TX (VERI GONDERIMI) ");
        $display("---------------------------------------------------");
        
        // 0x0C (TDR) Adresine 'T' (0x54) verisini yaz
        axi_write(5'h0C, 32'h0000_0054);
        
        // 0x10 (CFG) Adresine TX Enable (Bit 0 = 1) gönder
        axi_write(5'h10, 32'h0000_0001);
        
        // Donanımın veriyi göndermesini bekle (1 karakter ~ 86 us sürer)
        #100_000;
        
        $display("---------------------------------------------------");
        $display("  2. TEST: DONANIM BIT SIFIRLAMASI (AUTO-CLEAR) ");
        $display("---------------------------------------------------");
        axi_read(5'h10, read_val);
        if (read_val[0] == 1'b0)
            $display("BASARILI: CFG[0] donanim tarafindan 0'a cekilmis.");
        else
            $display("HATA: CFG[0] hala 1! State Machine duzeltilmeli.");

        #10_000;
        
        $display("---------------------------------------------------");
        $display("  3. TEST: UART RX (VERI ALIMI - YZ HIZLANDIRICI) ");
        $display("---------------------------------------------------");
        
        // Testbench'ten modülün RX pinine 'R' (0x52) karakteri gönderiyoruz
        send_uart_rx(8'h52);
        
        // Modülün veriyi işleyip içeri almasını bekle
        #10_000;
        
        // 0x08 (RDR) Adresinden gelen veriyi oku
        axi_read(5'h08, read_val);
        if (read_val[7:0] == 8'h52)
            $display("BASARILI: Gelen veri dogru sekilde okundu (0x%h).", read_val[7:0]);
        else
            $display("HATA: Gelen veri yanlis! Beklenen: 0x52, Okunan: 0x%h", read_val[7:0]);
        
        $display("---------------------------------------------------");
        $display("  4. TEST: CTRL_REG PARITY VE AYAR KONTROLU ");
        $display("---------------------------------------------------");
        // Parity Enable (Bit 3) = 1, Odd Parity (Bit 4) = 1
        axi_write(5'h10, 32'h0000_0018); 
        axi_read(5'h10, read_val);
        if (read_val[4:3] == 2'b11) 
            $display("BASARILI: CTRL_REG ayarlari (Parity vb.) basariyla donanima kaydedildi.");
        else 
            $display("HATA: CTRL_REG ayarlari okunamadi! Okunan: %h", read_val);

        $display("---------------------------------------------------");
        $display("  5. TEST: FRAME ERROR (CERCEVE HATASI) KORUMASI ");
        $display("---------------------------------------------------");
        
        // 4. testten kalan Parity ayarlarını sıfırla (8N1 formatına dön)
        axi_write(5'h10, 32'h0000_0000); 

        // Eksik Stop biti olan bir veri gönderiyoruz
        send_uart_error_frame(8'hAA);
        #10_000;
        
        // STAT_REG (0x1C) okunarak Frame Error (Bit 4) bayrağı kontrol ediliyor
        axi_read(5'h1C, read_val);
        if (read_val[4] == 1'b1)
            $display("BASARILI: Donanim Frame Error (Cerceve Hatasi) durumunu yakaladi (STAT_REG[4]=1)!");
        else
            $display("HATA: Frame Error yakalanamadi! STAT_REG: %h", read_val);
        
        $display("---------------------------------------------------");
        $display("  6. TEST: RX FIFO OVERRUN KORUMASI (TASMA) ");
        $display("---------------------------------------------------");
        $display("RX FIFO'ya tasirma verileri (17 byte) gonderiliyor. Bu biraz surebilir...");
        begin : overrun_test
            integer j;
            // FIFO derinliği 16, biz 17 veri basıyoruz.
            for (j = 0; j < 17; j = j + 1) begin
                send_uart_rx(8'hBB);
            end
        end
        #10_000;
        
        // STAT_REG okunarak Overrun Error (Bit 6) kontrol ediliyor
        axi_read(5'h1C, read_val);
        if (read_val[6] == 1'b1)
            $display("BASARILI: Donanim FIFO Overrun (Tasma) hatasini yakaladi (STAT_REG[6]=1)!");
        else
            $display("HATA: Overrun algilanamadi! STAT_REG: %h", read_val);

        $display("---------------------------------------------------");
        $display(" TESTLER TAMAMLANDI.");
        $display("---------------------------------------------------");
        $finish;
    end

    // VCD (Waveform) Kaydı
    initial begin
        $dumpfile("uart_unit_sim.vcd");
        $dumpvars(0, tb_uart_unit);
    end

endmodule