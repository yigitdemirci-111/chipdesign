`timescale 1ns / 1ps

module tb_gpio_timer();

    // 1. SİSTEM SİNYALLERİ
    reg clk;
    reg resetn;

    // 2. GPIO AXI-LITE SİNYALLERİ
    reg  [4:0]  g_awaddr;   reg         g_awvalid;  wire        g_awready;
    reg  [31:0] g_wdata;    reg  [3:0]  g_wstrb;    reg         g_wvalid;   wire        g_wready;
    wire [1:0]  g_bresp;    wire        g_bvalid;   reg         g_bready;
    reg  [4:0]  g_araddr;   reg         g_arvalid;  wire        g_arready;
    wire [31:0] g_rdata;    wire [1:0]  g_rresp;    wire        g_rvalid;   reg         g_rready;

    // GPIO Dış Dünya Pinleri
    reg  [15:0] gpio_in_pins;
    wire [15:0] gpio_out_pins;

    // 3. TIMER AXI-LITE SİNYALLERİ
    reg  [4:0]  t_awaddr;   reg         t_awvalid;  wire        t_awready;
    reg  [31:0] t_wdata;    reg  [3:0]  t_wstrb;    reg         t_wvalid;   wire        t_wready;
    wire [1:0]  t_bresp;    wire        t_bvalid;   reg         t_bready;
    reg  [4:0]  t_araddr;   reg         t_arvalid;  wire        t_arready;
    wire [31:0] t_rdata;    wire [1:0]  t_rresp;    wire        t_rvalid;   reg         t_rready;

    // 4. SAAT ÜRETİMİ (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // 5. DUT: SPECIAL GPIO
    special_gpio #(
        .ADDR_WIDTH(5),
        .DATA_WIDTH(32)
    ) dut_gpio (
        .clk(clk),              .rst_n(resetn),
        .s_axil_awaddr(g_awaddr), .s_axil_awvalid(g_awvalid), .s_axil_awready(g_awready),
        .s_axil_wdata(g_wdata),   .s_axil_wstrb(g_wstrb),     .s_axil_wvalid(g_wvalid),   .s_axil_wready(g_wready),
        .s_axil_bresp(g_bresp),   .s_axil_bvalid(g_bvalid),   .s_axil_bready(g_bready),
        .s_axil_araddr(g_araddr), .s_axil_arvalid(g_arvalid), .s_axil_arready(g_arready),
        .s_axil_rdata(g_rdata),   .s_axil_rresp(g_rresp),     .s_axil_rvalid(g_rvalid),   .s_axil_rready(g_rready),
        .gpio_in(gpio_in_pins),   .gpio_out(gpio_out_pins)
    );

    // 6. DUT: SPECIAL TIMER
    special_timer #(
        .ADDR_WIDTH(5),
        .DATA_WIDTH(32)
    ) dut_timer (
        .clk(clk),                .rst_n(resetn),
        .s_axil_awaddr(t_awaddr), .s_axil_awvalid(t_awvalid), .s_axil_awready(t_awready),
        .s_axil_wdata(t_wdata),   .s_axil_wstrb(t_wstrb),     .s_axil_wvalid(t_wvalid),   .s_axil_wready(t_wready),
        .s_axil_bresp(t_bresp),   .s_axil_bvalid(t_bvalid),   .s_axil_bready(t_bready),
        .s_axil_araddr(t_araddr), .s_axil_arvalid(t_arvalid), .s_axil_arready(t_arready),
        .s_axil_rdata(t_rdata),   .s_axil_rresp(t_rresp),     .s_axil_rvalid(t_rvalid),   .s_axil_rready(t_rready)
    );

    // AXI-LITE GÖREVLERİ
    task axi_write_gpio(input [4:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            g_awaddr = addr; g_awvalid = 1; g_wdata = data; g_wstrb = 4'hF; g_wvalid = 1;
            wait(g_awready && g_wready);
            @(posedge clk); #1;
            g_awaddr = 0; g_awvalid = 0; g_wdata = 0; g_wstrb = 0; g_wvalid = 0; g_bready = 1;
            wait(g_bvalid);
            @(posedge clk); #1; g_bready = 0;
        end
    endtask

    task axi_read_gpio(input [4:0] addr, output [31:0] read_data);
        begin
            @(posedge clk);
            g_araddr = addr; g_arvalid = 1; g_rready = 1;
            wait(g_arready);
            @(posedge clk); #1;
            g_araddr = 0; g_arvalid = 0;
            wait(g_rvalid);
            read_data = g_rdata;
            @(posedge clk); #1; g_rready = 0;
        end
    endtask

    task axi_write_timer(input [4:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            t_awaddr = addr; t_awvalid = 1; t_wdata = data; t_wstrb = 4'hF; t_wvalid = 1;
            wait(t_awready && t_wready);
            @(posedge clk); #1;
            t_awaddr = 0; t_awvalid = 0; t_wdata = 0; t_wstrb = 0; t_wvalid = 0; t_bready = 1;
            wait(t_bvalid);
            @(posedge clk); #1; t_bready = 0;
        end
    endtask

    task axi_read_timer(input [4:0] addr, output [31:0] read_data);
        begin
            @(posedge clk);
            t_araddr = addr; t_arvalid = 1; t_rready = 1;
            wait(t_arready);
            @(posedge clk); #1;
            t_araddr = 0; t_arvalid = 0;
            wait(t_rvalid);
            read_data = t_rdata;
            @(posedge clk); #1; t_rready = 0;
        end
    endtask

    // ANA TEST SENARYOSU
    reg [31:0] rdata;
    reg [31:0] hold_val;

    initial begin
        // Başlangıç Durumları
        resetn = 0;
        g_awaddr=0; g_awvalid=0; g_wdata=0; g_wstrb=0; g_wvalid=0; g_bready=0; g_araddr=0; g_arvalid=0; g_rready=0;
        t_awaddr=0; t_awvalid=0; t_wdata=0; t_wstrb=0; t_wvalid=0; t_bready=0; t_araddr=0; t_arvalid=0; t_rready=0;
        gpio_in_pins = 16'h0000;

        #100 resetn = 1;
        #100;
        
        // 1. Çıkış Testi: ODR_REG (0x04) yazmacına değer yaz ve pinleri kontrol et
        $display("[GPIO] ODR (0x04) yazmacina 0xABCD yaziliyor...");
        axi_write_gpio(5'h04, 32'h0000ABCD);
        #20;
        if (gpio_out_pins === 16'hABCD) $display("[GPIO] BASARILI: gpio_out pini 0xABCD oldu.");
        else $display("[GPIO] HATA: gpio_out degeri %h (Beklenen: abcd)", gpio_out_pins);

        // 2. Giriş Testi: Fiziksel pinlere değer bas ve IDR_REG (0x00) üzerinden oku
        $display("[GPIO] Fiziksel giris pinlerine 0x5555 veriliyor ve AXI uzerinden okunuyor...");
        gpio_in_pins = 16'h5555;
        #20;
        axi_read_gpio(5'h00, rdata);
        if (rdata[15:0] === 16'h5555) $display("[GPIO] BASARILI: IDR (0x00) uzerinden 0x5555 okundu.");
        else $display("[GPIO] HATA: IDR degeri %h (Beklenen: 00005555)", rdata);

        // 1. Timer Konfigürasyonu
        $display("[TIMER] Prescaler 0 (SysClk), Auto-Reload 5, Mode 1 (Up-count) olarak ayarlaniyor...");
        axi_write_timer(5'h00, 32'h0); // TIM_PRE = 0
        axi_write_timer(5'h04, 32'h5); // TIM_ARE = 5
        axi_write_timer(5'h10, 32'h1); // TIM_MOD = 1
        
        // 2. Timer'ı Temizle ve Başlat
        $display("[TIMER] Sayac sifirlaniyor ve baslatiliyor...");
        axi_write_timer(5'h08, 32'h1); // TIM_CLR = 1
        axi_write_timer(5'h0C, 32'h1); // TIM_ENA = 1
        
        // 3. 7 Saat Vuruşu Bekle (Counter'ın 5'i geçip sıfırlanmasını ve Event üretmesini istiyoruz)
        repeat(7) @(posedge clk);
        
        // 4. Değerleri Oku
        axi_read_timer(5'h14, rdata);
        $display("[TIMER] Guncel Sayac Degeri (TIM_CNT): %d", rdata);
        
        axi_read_timer(5'h18, rdata);
        if (rdata > 0) $display("[TIMER] BASARILI: Sayac 5'i gectigi icin Event (TIM_EVN) uretildi! (%d)", rdata);
        else $display("[TIMER] HATA: Event uretilmedi.");

        $display("GPIO ve Timer için Corner-Case Testleri");

        // --- GPIO CORNER CASES ---
        $display("[GPIO CORNER] ODR uzerine 32-bit (0xFFFFFFFF) yaziliyor, sadece alt 16 bitin degismesi bekleniyor...");
        axi_write_gpio(5'h04, 32'hFFFFFFFF);
        
        #20;    
        
        if (gpio_out_pins === 16'hFFFF) $display("[GPIO CORNER] BASARILI: Sadece 16 bit yansidi.");
        else $display("[GPIO CORNER] HATA: Maskeleme calismadi! Gelen: %h", gpio_out_pins);

        $display("[GPIO CORNER] Fiziksel pinlere 16-bit 0xFFFF verip, IDR uzerinden 32-bit okuma kontrolu...");
        gpio_in_pins = 16'hFFFF;
        
        #20;
        
        axi_read_gpio(5'h00, rdata);
        if (rdata === 32'h0000FFFF) $display("[GPIO CORNER] BASARILI: Ust 16 bit 0 olarak okundu.");
        else $display("[GPIO CORNER] HATA: IDR ust bitleri sifirlanmamis! Okunan: %h", rdata);

            // --- TIMER CORNER CASES ---
        $display("[TIMER CORNER] Timer durduruluyor (TIM_ENA = 0) ve degerin sabit kaldigi kontrol ediliyor...");
        
        axi_write_timer(5'h0C, 32'h0); // TIM_ENA = 0
        axi_read_timer(5'h14, rdata);
        hold_val = rdata;
        repeat(5) @(posedge clk);
        axi_read_timer(5'h14, rdata);
        if (rdata == hold_val) $display("[TIMER CORNER] BASARILI: Timer durdu.");
        else $display("[TIMER CORNER] HATA: Timer calismaya devam ediyor!");

        $display("[TIMER CORNER] Event Bayragi (TIM_EVN) temizleniyor (TIM_EVC=1)...");
        axi_write_timer(5'h1C, 32'h1); // TIM_EVC = 1
        #10;
        axi_read_timer(5'h18, rdata);
        if (rdata == 0) $display("[TIMER CORNER] BASARILI: TIM_EVN temizlendi.");
        else $display("[TIMER CORNER] HATA: TIM_EVN temizlenemedi!");

        $display("[TIMER CORNER] Asagi sayma modu (TIM_MOD=0) test ediliyor...");
        axi_write_timer(5'h10, 32'h0); // TIM_MOD = 0
        axi_write_timer(5'h08, 32'h1); // TIM_CLR = 1
        axi_write_timer(5'h0C, 32'h1); // TIM_ENA = 1
        repeat(3) @(posedge clk);
        axi_read_timer(5'h14, rdata);
        $display("[TIMER CORNER] Asagi Sayma Degeri: %d (Beklenen: auto-reload'dan asagi inmesi)", rdata);

        

        $display("===================================================");
        $display(" TESTLER TAMAMLANDI.");
        $display("===================================================");
        $finish;
    end

    // VCD Kaydı
    initial begin
        $dumpfile("gpio_timer_sim.vcd");
        $dumpvars(0, tb_gpio_timer);
    end

endmodule