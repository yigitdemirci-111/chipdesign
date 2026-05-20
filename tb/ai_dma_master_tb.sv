`timescale 1ns / 1ps

module ai_dma_master_tb();

    logic clk;
    logic rst_n;
    logic [31:0] start_addr_i;
    logic        start_fsm_i;
    logic        dma_busy_o;
    logic [31:0] M_AXI_ARADDR;
    logic        M_AXI_ARVALID;
    logic        M_AXI_ARREADY;
    logic [31:0] M_AXI_RDATA;
    logic        M_AXI_RVALID;
    logic        M_AXI_RREADY;
    logic [7:0]  data_to_mac_o;
    logic        data_valid_o;

    ai_dma_master dut (.*);

    // 100 MHz Clock
    always #5 clk = ~clk;

    initial begin
        $display("=== DMA TESTI BASLIYOR ===");
        clk = 0; rst_n = 0;
        start_addr_i = 0; start_fsm_i = 0;
        M_AXI_ARREADY = 0; M_AXI_RVALID = 0; M_AXI_RDATA = 0;
        
        #20 rst_n = 1; 
        
        #10 start_addr_i = 32'h4000_0000; start_fsm_i = 1;
        #10 start_fsm_i = 0;
        
        // ÖNEMLİ: Döngüyü 16'ya kadar tam döndürüyoruz
        for (int i = 0; i < 16; i++) begin
            // Adres isteğini bekle
            wait(M_AXI_ARVALID == 1);
            #2; // Sinyal kararlılığı için küçük bir gecikme
            M_AXI_ARREADY = 1;
            @(posedge clk);
            M_AXI_ARREADY = 0;
            
            // Veriyi gönder
            #2;
            M_AXI_RDATA = 32'h0000_0000 + i + 8; 
            M_AXI_RVALID = 1;
            // DMA veriyi alana (READY verene) kadar bekle
            wait(M_AXI_RREADY == 1);
            @(posedge clk);
            M_AXI_RVALID = 0;
            
            $display("RAM'den %0d. veri DMA'ya iletildi. Giden: %0d", i+1, M_AXI_RDATA[7:0]);
        end
        
        #100;
        $display("=== DMA TESTI TAMAMLANDI ===");
        $finish;
    end

    initial begin
        $dumpfile("dma_wave.vcd");
        $dumpvars(0, ai_dma_master_tb);
    end

endmodule