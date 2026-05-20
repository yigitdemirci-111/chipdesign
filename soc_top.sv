`timescale 1ns / 1ps

module soc_top (
    input  logic clk_i,        // Çipin ana saat sinyali
    input  logic rst_ni,       // Çipi sıfırlama sinyali (0 aktif)
    
    // Dış dünya ile haberleşme pinleri
    input  logic uart_rx_i,    // Bilgisayardan çipe veri girişi
    output logic uart_tx_o     // Çipten bilgisayara veri çıkışı
);

    // ----------------------------------------------------
    // 1. İŞLEMCİ (OBI) İÇ KABLOLARI
    // ----------------------------------------------------
    logic        instr_req;
    logic        instr_gnt;
    logic [31:0] instr_addr;
    logic        instr_rvalid;
    logic [31:0] instr_rdata;

    logic        data_req;
    logic        data_gnt;
    logic [31:0] data_addr;
    logic        data_we;
    logic [3:0]  data_be;
    logic [31:0] data_wdata;
    logic        data_rvalid;
    logic [31:0] data_rdata;

    // ----------------------------------------------------
    // 2. CV32E40P İŞLEMCİ ENTEGRASYONU
    // ----------------------------------------------------
    cv32e40p_core #(
        .PULP_XPULP      ( 1'b0 ),
        .FPU             ( 1'b0 ),
        .PULP_CLUSTER    ( 1'b0 )
    ) u_cpu_core (
        .clk_i           ( clk_i   ), 
        .rst_ni          ( rst_ni  ), 
        
        .boot_addr_i     ( 32'h0000_0000 ),
        .mtvec_addr_i    ( 32'h0000_0000 ),
        
        .instr_req_o     ( instr_req    ),
        .instr_gnt_i     ( instr_gnt    ),
        .instr_addr_o    ( instr_addr   ),
        .instr_rvalid_i  ( instr_rvalid ),
        .instr_rdata_i   ( instr_rdata  ),
        
        .data_req_o      ( data_req     ),
        .data_gnt_i      ( data_gnt     ),
        .data_addr_o     ( data_addr    ),
        .data_we_o       ( data_we      ),
        .data_be_o       ( data_be      ),
        .data_wdata_o    ( data_wdata   ),
        .data_rvalid_i   ( data_rvalid ),
        .data_rdata_i    ( data_rdata  ),

        .irq_i           ( 32'b0        ),
        .irq_ack_o       (              ),
        .irq_id_o        (              ),
        .debug_req_i     ( 1'b0         )
    );

    // ----------------------------------------------------
    // 3. AXI4 ARAYÜZ KABLOLARI (Otoyol Şeritleri)
    // ----------------------------------------------------
    // Master 0: Kod Kanalı AXI Sinyalleri
    logic [31:0] m0_axi_awaddr;   logic [2:0]  m0_axi_awprot;  logic        m0_axi_awvalid; logic        m0_axi_awready;
    logic [31:0] m0_axi_wdata;    logic [3:0]  m0_axi_wstrb;   logic        m0_axi_wvalid;  logic        m0_axi_wready;
    logic [1:0]  m0_axi_bresp;    logic        m0_axi_bvalid;  logic        m0_axi_bready;
    logic [31:0] m0_axi_araddr;   logic [2:0]  m0_axi_arprot;  logic        m0_axi_arvalid; logic        m0_axi_arready;
    logic [31:0] m0_axi_rdata;    logic [1:0]  m0_axi_rresp;   logic        m0_axi_rvalid;  logic        m0_axi_rready;

    // Master 1: Veri Kanalı AXI Sinyalleri
    logic [31:0] m1_axi_awaddr;   logic [2:0]  m1_axi_awprot;  logic        m1_axi_awvalid; logic        m1_axi_awready;
    logic [31:0] m1_axi_wdata;    logic [3:0]  m1_axi_wstrb;   logic        m1_axi_wvalid;  logic        m1_axi_wready;
    logic [1:0]  m1_axi_bresp;    logic        m1_axi_bvalid;  logic        m1_axi_bready;
    logic [31:0] m1_axi_araddr;   logic [2:0]  m1_axi_arprot;  logic        m1_axi_arvalid; logic        m1_axi_arready;
    logic [31:0] m1_axi_rdata;    logic [1:0]  m1_axi_rresp;   logic        m1_axi_rvalid;  logic        m1_axi_rready;

    // ----------------------------------------------------
    // 4. OBI-to-AXI KÖPRÜLERİ (Tercümanlar)
    // ----------------------------------------------------
    obi_to_axi u_obi_to_axi_instr (
        .clk_i           ( clk_i           ),
        .rst_ni          ( rst_ni          ),
        
        .obi_req_i       ( instr_req       ),
        .obi_gnt_o       ( instr_gnt       ),
        .obi_addr_i      ( instr_addr      ),
        .obi_we_i        ( 1'b0            ), 
        .obi_be_i        ( 4'hF            ),
        .obi_wdata_i     ( 32'b0           ),
        .obi_rvalid_o    ( instr_rvalid    ),
        .obi_rdata_o     ( instr_rdata     ),
        
        .axi_awaddr_o    ( m0_axi_awaddr   ), .axi_awprot_o   ( m0_axi_awprot   ), .axi_awvalid_o  ( m0_axi_awvalid  ), .axi_awready_i  ( m0_axi_awready  ),
        .axi_wdata_o     ( m0_axi_wdata    ), .axi_wstrb_o    ( m0_axi_wstrb    ), .axi_wvalid_o   ( m0_axi_wvalid   ), .axi_wready_i   ( m0_axi_wready   ),
        .axi_bresp_i     ( m0_axi_bresp    ), .axi_bvalid_i   ( m0_axi_bvalid   ), .axi_bready_o   ( m0_axi_bready   ),
        .axi_araddr_o    ( m0_axi_araddr   ), .axi_arprot_o   ( m0_axi_arprot   ), .axi_arvalid_o  ( m0_axi_arvalid  ), .axi_arready_i  ( m0_axi_arready  ),
        .axi_rdata_i     ( m0_axi_rdata    ), .axi_rresp_i    ( m0_axi_rresp    ), .axi_rvalid_i   ( m0_axi_rvalid   ), .axi_rready_o   ( m0_axi_rready   )
    );

    obi_to_axi u_obi_to_axi_data (
        .clk_i           ( clk_i           ),
        .rst_ni          ( rst_ni          ),
        
        .obi_req_i       ( data_req        ),
        .obi_gnt_o       ( data_gnt        ),
        .obi_addr_i      ( data_addr       ),
        .obi_we_i        ( data_we         ), 
        .obi_be_i        ( data_be         ),
        .obi_wdata_i     ( data_wdata      ),
        .obi_rvalid_o    ( data_rvalid     ),
        .obi_rdata_o     ( data_rdata      ),
        
        .axi_awaddr_o    ( m1_axi_awaddr   ), .axi_awprot_o   ( m1_axi_awprot   ), .axi_awvalid_o  ( m1_axi_awvalid  ), .axi_awready_i  ( m1_axi_awready  ),
        .axi_wdata_o     ( m1_axi_wdata    ), .axi_wstrb_o    ( m1_axi_wstrb    ), .axi_wvalid_o   ( m1_axi_wvalid   ), .axi_wready_i   ( m1_axi_wready   ),
        .axi_bresp_i     ( m1_axi_bresp    ), .axi_bvalid_i   ( m1_axi_bvalid   ), .axi_bready_o   ( m1_axi_bready   ),
        .axi_araddr_o    ( m1_axi_araddr   ), .axi_arprot_o   ( m1_axi_arprot   ), .axi_arvalid_o  ( m1_axi_arvalid  ), .axi_arready_i  ( m1_axi_arready  ),
        .axi_rdata_i     ( m1_axi_rdata    ), .axi_rresp_i    ( m1_axi_rresp    ), .axi_rvalid_i   ( m1_axi_rvalid   ), .axi_rready_o   ( m1_axi_rready   )
    );




// ----------------------------------------------------
    // 5. HEDEF (SLAVE) BİRİMLER İÇİN AXI KABLOLARI
    // ----------------------------------------------------
    // Slave 0: Instruction RAM
    logic [31:0] s0_axi_awaddr;  logic s0_axi_awvalid; logic s0_axi_awready;
    logic [31:0] s0_axi_wdata;   logic s0_axi_wvalid;  logic s0_axi_wready;
    logic [31:0] s0_axi_araddr;  logic s0_axi_arvalid; logic s0_axi_arready;
    logic [31:0] s0_axi_rdata;   logic s0_axi_rvalid;  logic s0_axi_rready;

    // Slave 1: Data RAM
    logic [31:0] s1_axi_awaddr;  logic s1_axi_awvalid; logic s1_axi_awready;
    logic [31:0] s1_axi_wdata;   logic s1_axi_wvalid;  logic s1_axi_wready;
    logic [31:0] s1_axi_araddr;  logic s1_axi_arvalid; logic s1_axi_arready;
    logic [31:0] s1_axi_rdata;   logic s1_axi_rvalid;  logic s1_axi_rready;

    // Slave 2: Edge-AI Registers (Yusuf'un modülü için)
    logic [31:0] s2_axi_awaddr;  logic s2_axi_awvalid; logic s2_axi_awready;
    logic [31:0] s2_axi_wdata;   logic s2_axi_wvalid;  logic s2_axi_wready;
    logic [31:0] s2_axi_araddr;  logic s2_axi_arvalid; logic s2_axi_arready;
    logic [31:0] s2_axi_rdata;   logic s2_axi_rvalid;  logic s2_axi_rready;

    // 6. ADRES ÇÖZÜCÜ (POSTACI) ENTEGRASYONU
    logic sel_i_ram, sel_d_ram, sel_ai_reg, sel_ai_mem, sel_uart, dec_error;

    addr_decode #(
        .ADDR_WIDTH   ( 32 )
    ) u_address_decoder (
        .addr_i       ( m1_axi_awvalid ? m1_axi_awaddr : m1_axi_araddr ), // Yazma veya okuma adresi
        .req_i        ( m1_axi_awvalid | m1_axi_arvalid ), // Herhangi bir istek var mı?
        
        .sel_i_ram_o  ( sel_i_ram  ),
        .sel_d_ram_o  ( sel_d_ram  ),
        .sel_ai_reg_o ( sel_ai_reg ),
        .sel_ai_mem_o ( sel_ai_mem ),
        .sel_uart_o   ( sel_uart   ),
        .dec_error_o  ( dec_error  )
    );

    // 7. INTERCONNECT YÖNLENDİRME MANTIĞI (Makas Sistemi)
    always_comb begin
        // İlk başta tüm yolları güvenli olması için sıfırlıyoruz (Kısa devre önleme)
        s1_axi_awaddr  = 32'b0; s1_axi_awvalid = 1'b0; s1_axi_wdata = 32'b0; s1_axi_wvalid = 1'b0; s1_axi_araddr = 32'b0; s1_axi_arvalid = 1'b0;
        s2_axi_awaddr  = 32'b0; s2_axi_awvalid = 1'b0; s2_axi_wdata = 32'b0; s2_axi_wvalid = 1'b0; s2_axi_araddr = 32'b0; s2_axi_arvalid = 1'b0;
        
        m1_axi_awready = 1'b0;  m1_axi_wready  = 1'b0; m1_axi_arready = 1'b0; m1_axi_rdata  = 32'b0; m1_axi_rvalid  = 1'b0; m1_axi_bvalid  = 1'b0; m1_axi_bresp = 2'b0;

        if (sel_d_ram) begin
            s1_axi_awaddr  = m1_axi_awaddr;  s1_axi_awvalid = m1_axi_awvalid;
            s1_axi_wdata   = m1_axi_wdata;   s1_axi_wvalid  = m1_axi_wvalid;
            s1_axi_araddr  = m1_axi_araddr;  s1_axi_arvalid = m1_axi_arvalid;
            
            m1_axi_awready = s1_axi_awready; m1_axi_wready  = s1_axi_wready;
            m1_axi_arready = s1_axi_arready; m1_axi_rdata   = s1_axi_rdata;
            m1_axi_rvalid  = s1_axi_rvalid;  m1_axi_bvalid  = s1_axi_bvalid;
            m1_axi_bresp   = s1_axi_bresp;
        end
        
        else if (sel_ai_reg) begin
            s2_axi_awaddr  = m1_axi_awaddr;  s2_axi_awvalid = m1_axi_awvalid;
            s2_axi_wdata   = m1_axi_wdata;   s2_axi_wvalid  = m1_axi_wvalid;
            s2_axi_araddr  = m1_axi_araddr;  s2_axi_arvalid = m1_axi_arvalid;
            
            m1_axi_awready = s2_axi_awready; m1_axi_wready  = s2_axi_wready;
            m1_axi_arready = s2_axi_arready; m1_axi_rdata   = s2_axi_rdata;
            m1_axi_rvalid  = s2_axi_rvalid;  m1_axi_bvalid  = s2_axi_bvalid;
            m1_axi_bresp   = s2_axi_bresp;
        end
    end

    // 8. HAFIZA BLOKLARININ (RAM) YERLEŞTİRİLMESİ
    
    // KOD BELLEĞİ (Instruction RAM - 32 KB)
    axi_ram #(
        .DATA_WIDTH ( 32 ),
        .ADDR_WIDTH ( 15 ) // 2^15 byte = 32 KB
    ) u_instruction_ram (
        .clk_i      ( clk_i          ),
        .rst_ni     ( rst_ni         ),
        
        // AXI4 Slave Arayüzü Bağlantıları
        .axi_awaddr  ( s0_axi_awaddr  ), .axi_awvalid ( s0_axi_awvalid ), .axi_awready ( s0_axi_awready ),
        .axi_wdata   ( s0_axi_wdata   ), .axi_wvalid  ( s0_axi_wvalid  ), .axi_wready  ( s0_axi_wready  ),
        .axi_araddr  ( s0_axi_araddr  ), .axi_arvalid ( s0_axi_arvalid ), .axi_arready ( s0_axi_arready ),
        .axi_rdata   ( s0_axi_rdata   ), .axi_rvalid  ( s0_axi_rvalid  ), .axi_rready  ( s0_axi_rready  )
    );

    // VERİ BELLEĞİ (Data RAM - 32 KB)
    axi_ram #(
        .DATA_WIDTH ( 32 ),
        .ADDR_WIDTH ( 15 ) // 2^15 byte = 32 KB
    ) u_data_ram (
        .clk_i      ( clk_i          ),
        .rst_ni     ( rst_ni         ),
        
        .axi_awaddr  ( s1_axi_awaddr  ), .axi_awvalid ( s1_axi_awvalid ), .axi_awready ( s1_axi_awready ),
        .axi_wdata   ( s1_axi_wdata   ), .axi_wvalid  ( s1_axi_wvalid  ), .axi_wready  ( s1_axi_wready  ),
        .axi_araddr  ( s1_axi_araddr  ), .axi_arvalid ( s1_axi_arvalid ), .axi_arready ( s1_axi_arready ),
        .axi_rdata   ( s1_axi_rdata   ), .axi_rvalid  ( s1_axi_rvalid  ), .axi_rready  ( s1_axi_rready  )
    );

endmodule
