`timescale 1ns / 1ps

module tb_soc_top();

    // 1. Sistem Sinyalleri
    reg clk;
    reg resetn;

    // 2. Çevre Birimi Pinleri (DUT Bağlantıları)
    wire uart1_txd;
    reg  uart1_rxd;
    wire uart2_txd;
    reg  uart2_rxd;
    wire uart1_irq;
    wire uart2_irq;

    // Diğer dummy bağlantılar
    wire i2c_scl_o, i2c_scl_t, i2c_sda_o, i2c_sda_t;
    reg  i2c_scl_i, i2c_sda_i;
    wire qspi_sclk, qspi_cs_n;
    wire [3:0] qspi_io;
    reg  [15:0] gpio_in;
    wire [15:0] gpio_out;

    // 3. Saat (Clock) Üretimi (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // 4. Test Edilecek Tasarımın (DUT) Çağrılması
    soc_top dut (
        .soc_clk(clk),
        .soc_resetn(resetn),
        
        .soc_uart1_txd(uart1_txd),
        .soc_uart1_rxd(uart1_rxd),
        .soc_uart2_txd(uart2_txd),
        .soc_uart2_rxd(uart2_rxd),
        .soc_uart1_interrupt(uart1_irq), 
        .soc_uart2_interrupt(uart2_irq),
        
        .soc_i2c_scl_i(i2c_scl_i), .soc_i2c_scl_o(i2c_scl_o), .soc_i2c_scl_t(i2c_scl_t),
        .soc_i2c_sda_i(i2c_sda_i), .soc_i2c_sda_o(i2c_sda_o), .soc_i2c_sda_t(i2c_sda_t),
        
        .soc_qspi_sclk(qspi_sclk), .soc_qspi_cs_n(qspi_cs_n), .soc_qspi_io(qspi_io),
        
        .soc_gpio_in(gpio_in), .soc_gpio_out(gpio_out)
    );

    // 5. İşlemciyi Taklit Eden AXI-Lite Yazma Görevi (Task)
    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            force dut.soc_main_m_axil_awaddr  = addr;
            force dut.soc_main_m_axil_awvalid = 1;
            force dut.soc_main_m_axil_wdata   = data;
            force dut.soc_main_m_axil_wstrb   = 4'hF; // Tüm byte'lar geçerli
            force dut.soc_main_m_axil_wvalid  = 1;
            
            // Slave'den Ready gelene kadar bekle
            wait(dut.soc_main_m_axil_awready && dut.soc_main_m_axil_wready);
            @(posedge clk);
            
            #1; 
            
            // Sinyalleri bırak
            release dut.soc_main_m_axil_awaddr;
            release dut.soc_main_m_axil_awvalid;
            release dut.soc_main_m_axil_wdata;
            release dut.soc_main_m_axil_wstrb;
            release dut.soc_main_m_axil_wvalid;
            
            // Yanıt kanalını (B Channel) bekle
            force dut.soc_main_m_axil_bready = 1;
            wait(dut.soc_main_m_axil_bvalid);
            @(posedge clk);
            
            #1;
            release dut.soc_main_m_axil_bready;
        end
    endtask

// 6. Ana Test Senaryosu
    initial begin
        // Başlangıç Durumları
        resetn = 0;
        uart1_rxd = 1; // UART hattı boşta 1'dir (Idle)
        uart2_rxd = 1;
        i2c_scl_i = 1;
        i2c_sda_i = 1;
        gpio_in   = 16'h0000;
        
        #100 resetn = 1; // Sistemi resetten çıkar
        #100;

        $display("--- TEST BASLIYOR: UART1 TX (Log Ekrani) ---");
        // UART-1 Base: 0x0100_0000
        axi_write(32'h0100_0010, 32'h0000_0001); 
        
        axi_write(32'h0100_000C, 32'h0000_0041); // 'A' (0x41)
        
        #500000; 

        $display("--- TEST BASLIYOR: UART2 TX (YZ Ses Akisi) ---");
        // UART-2 Base: 0x0000_0000
        
        axi_write(32'h0000_0010, 32'h0000_0001); // TX Enable
        axi_write(32'h0000_000C, 32'h0000_0042); // 'B' (0x42)
        
        #500000;
        
        $display("--- TEST TAMAMLANDI ---");
        $finish;
    end

    // VCD (Waveform) Kaydı İçin
    initial begin
        $dumpfile("soc_sim.vcd");
        $dumpvars(0, tb_soc_top);
    end

endmodule