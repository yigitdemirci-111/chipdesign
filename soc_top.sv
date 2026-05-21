`timescale 1ns / 1ps
`include "memory_map.svh"

module soc_top (
    input  logic        clk_i,
    input  logic        rst_ni,
    inout  wire  [7:0]  gpio_io,
    output logic        uart_tx_o,
    input  logic        uart_rx_i
);

    // =========================================================================
    // SİNYAL TANIMLAMALARI (2 MASTER [RISC-V] -> 3 SLAVE OTOBAN HATLARI)
    // =========================================================================
    localparam S_COUNT = 2; // Master Sayısı (0: Instruction Fetch, 1: Data Access)
    localparam M_COUNT = 3; // Slave Sayısı (0: RAM, 1: UART, 2: GPIO)

    // Master 0 (Instruction Port) AXI Hatları
    logic [31:0] inst_axi_awaddr,  inst_axi_wdata,  inst_axi_araddr,  inst_axi_rdata;
    logic        inst_axi_awvalid, inst_axi_awready, inst_axi_wvalid,  inst_axi_wready;
    logic        inst_axi_arvalid, inst_axi_arready, inst_axi_rvalid,  inst_axi_rready;

    // Master 1 (Data Port) AXI Hatları
    logic [31:0] data_axi_awaddr,  data_axi_wdata,  data_axi_araddr,  data_axi_rdata;
    logic        data_axi_awvalid, data_axi_awready, data_axi_wvalid,  data_axi_wready;
    logic        data_axi_arvalid, data_axi_arready, data_axi_rvalid,  data_axi_rready;

    // Interconnect Vektör Bağlantıları
    wire [S_COUNT*32-1:0] flat_s_awaddr;  wire [S_COUNT-1:0]    flat_s_awvalid; wire [S_COUNT-1:0]    flat_s_awready;
    wire [S_COUNT*32-1:0] flat_s_wdata;   wire [S_COUNT-1:0]    flat_s_wvalid;  wire [S_COUNT-1:0]    flat_s_wready;
    wire [S_COUNT*32-1:0] flat_s_araddr;  wire [S_COUNT-1:0]    flat_s_arvalid; wire [S_COUNT-1:0]    flat_s_arready;
    wire [S_COUNT*32-1:0] flat_s_rdata;   wire [S_COUNT-1:0]    flat_s_rvalid;  wire [S_COUNT-1:0]    flat_s_rready;
    
    wire [M_COUNT*32-1:0] flat_m_awaddr;  wire [M_COUNT-1:0]    flat_m_awvalid; wire [M_COUNT-1:0]    flat_m_awready;
    wire [M_COUNT*32-1:0] flat_m_wdata;   wire [M_COUNT-1:0]    flat_m_wvalid;  wire [M_COUNT-1:0]    flat_m_wready;
    wire [M_COUNT*32-1:0] flat_m_araddr;  wire [M_COUNT-1:0]    flat_m_arvalid; wire [M_COUNT-1:0]    flat_m_arready;
    wire [M_COUNT*32-1:0] flat_m_rdata;   wire [M_COUNT-1:0]    flat_m_rvalid;  wire [M_COUNT-1:0]    flat_m_rready;

    // Vektör Eşlemeleri (Flattening)
    assign flat_s_awaddr  = {data_axi_awaddr,  inst_axi_awaddr};
    assign flat_s_awvalid = {data_axi_awvalid, inst_axi_awvalid};
    assign inst_axi_awready = flat_s_awready[0];
    assign data_axi_awready = flat_s_awready[1];

    assign flat_s_wdata   = {data_axi_wdata,   inst_axi_wdata};
    assign flat_s_wvalid  = {data_axi_wvalid,  inst_axi_wvalid};
    assign inst_axi_wready  = flat_s_wready[0];
    assign data_axi_wready  = flat_s_wready[1];

    assign flat_s_araddr  = {data_axi_araddr,  inst_axi_araddr};
    assign flat_s_arvalid = {data_axi_arvalid, inst_axi_arvalid};
    assign inst_axi_arready = flat_s_arready[0];
    assign data_axi_arready = flat_s_arready[1];

    assign inst_axi_rdata   = flat_s_rdata[31:0];
    assign data_axi_rdata   = flat_s_rdata[63:32];
    assign inst_axi_rvalid  = flat_s_rvalid[0];
    assign data_axi_rvalid  = flat_s_rvalid[1];
    assign flat_s_rready  = {data_axi_rready,  inst_axi_rready};

// =========================================================================
    // GERÇEK DURUM MAKİNELİ OBI - AXI4-LITE KÖPRÜLERİ ENTEGRASYONU
    // =========================================================================
    // Çekirdek ile Matris arasındaki ara bağlantı telleri
    logic        instr_req,    instr_gnt,    instr_rvalid;
    logic [31:0] instr_addr,   instr_rdata;

    logic        data_req,     data_gnt,     data_rvalid, data_we;
    logic [3:0]  data_be;
    logic [31:0] data_addr,    data_wdata,   data_rdata;

    // --- Instruction Fetch Kanalı Köprüsü (Master 0) ---
    obi_to_axil_bridge u_bridge_instr (
        .clk          (clk_i),
        .rst_n        (rst_ni),
        // OBI (İşlemciye giden hatlar)
        .obi_req_i    (instr_req),
        .obi_gnt_o    (instr_gnt),
        .obi_addr_i   (instr_addr),
        .obi_we_i     (1'b0), // Fetch her zaman okumadır
        .obi_be_i     (4'hF),
        .obi_wdata_i  (32'h0),
        .obi_rvalid_o (instr_rvalid),
        .obi_rdata_o  (instr_rdata),
        // AXI4-Lite (Matrise giden hatlar)
        .axil_awaddr  (inst_axi_awaddr),  .axil_awvalid (inst_axi_awvalid), .axil_awready (inst_axi_awready),
        .axil_wdata   (inst_axi_wdata),   .axil_wstrb   (),                 .axil_wvalid  (inst_axi_wvalid),  .axil_wready (inst_axi_wready),
        .axil_bresp   (2'b0),             .axil_bvalid  (1'b0),             .axil_bready  (),
        .axil_araddr  (inst_axi_araddr),  .axil_arvalid (inst_axi_arvalid), .axil_arready (inst_axi_arready),
        .axil_rdata   (inst_axi_rdata),   .axil_rresp   (2'b0),             .axil_rvalid  (inst_axi_rvalid),  .axil_rready (inst_axi_rready)
    );

    // --- Data Access Kanalı Köprüsü (Master 1) ---
    obi_to_axil_bridge u_bridge_data (
        .clk          (clk_i),
        .rst_n        (rst_ni),
        // OBI (İşlemciye giden hatlar)
        .obi_req_i    (data_req),
        .obi_gnt_o    (data_gnt),
        .obi_addr_i   (data_addr),
        .obi_we_i     (data_we),
        .obi_be_i     (data_be),
        .obi_wdata_i  (data_wdata),
        .obi_rvalid_o (data_rvalid),
        .obi_rdata_o  (data_rdata),
        // AXI4-Lite (Matrise giden hatlar)
        .axil_awaddr  (data_axi_awaddr),  .axil_awvalid (data_axi_awvalid), .axil_awready (data_axi_awready),
        .axil_wdata   (data_axi_wdata),   .axil_wstrb   (),                 .axil_wvalid  (data_axi_wvalid),  .axil_wready (data_axi_wready),
        .axil_bresp   (2'b0),             .axil_bvalid  (1'b1),             .axil_bready  (), // Hazır matris için bvalid simüle ediliyor
        .axil_araddr  (data_axi_araddr),  .axil_arvalid (data_axi_arvalid), .axil_arready (data_axi_arready),
        .axil_rdata   (data_axi_rdata),   .axil_rresp   (2'b0),             .axil_rvalid  (data_axi_rvalid),  .axil_rready (data_axi_rready)
    );
    // =========================================================================
    // GERÇEK RISC-V CORE ENTEGRASYONU (CV32E40P)

// =========================================================================
    // GERÇEK RISC-V CORE ENTEGRASYONU (CV32E40P / HARVARD DUMMY)
    // =========================================================================
    cv32e40p_core #(
        .COREV_PULP      (0),
        .FPU             (0)
    ) u_riscv_core (
        .clk_i           (clk_i),
        .rst_ni          (rst_ni),

        .pulp_clock_en_i (1'b1),
        .scan_cg_en_i    (1'b0),

        // Core Konfigürasyon Girişleri
        .boot_addr_i     (32'h0000_0000),
        .mtvec_addr_i    (32'h0000_0020),
        .dm_halt_addr_i  (32'h0000_0000),
        .dm_exception_addr_i(32'h0000_0000),

        // Instruction (Komut Okuma) OBI Arayüzü
        .instr_req_o     (instr_req),
        .instr_gnt_i     (instr_gnt),
        .instr_addr_o    (instr_addr),
        .instr_rvalid_i  (instr_rvalid),
        .instr_rdata_i   (instr_rdata),

        // Data (Veri Okuma/Yazma) OBI Arayüzü
        .data_req_o      (data_req),
        .data_gnt_i      (data_gnt),
        .data_addr_o     (data_addr),
        .data_we_o       (data_we),
        .data_be_o       (data_be),
        .data_wdata_o    (data_wdata),
        .data_rvalid_i   (data_rvalid),
        .data_rdata_i    (data_rdata),

        // Kesme ve Debug Hatları
        .irq_i           (32'h0),
        .debug_req_i     (1'b0),
        .fetch_enable_i  (1'b1)
    );
    // =========================================================================
    // AXI MATRİS VE SLAVE BİRİMLERİ (DEĞİŞMEDİ - GÜVENLİ BÖLGE)
    // =========================================================================
    axi_interconnect #(
        .S_COUNT(S_COUNT), .M_COUNT(M_COUNT),
        .DATA_WIDTH(32), .ADDR_WIDTH(32),
        .M_ADDR_WIDTH({32'd16, 32'd16, 32'd16}),
        .M_BASE_ADDR({32'h4000_0000, 32'h0001_0000, 32'h0000_0000}) 
    ) u_axi_crossbar (
        .clk(clk_i), .rst(!rst_ni),
        .s_axi_awid({8'h1, 8'h0}), .s_axi_awaddr(flat_s_awaddr), .s_axi_awlen({8'h0, 8'h0}), .s_axi_awsize({3'd2, 3'd2}),
        .s_axi_awburst({2'h1, 2'h1}), .s_axi_awlock({1'b0, 1'b0}), .s_axi_awcache({4'h0, 4'h0}), .s_axi_awprot({3'h0, 3'h0}),
        .s_axi_awvalid(flat_s_awvalid), .s_axi_awready(flat_s_awready),
        .s_axi_wdata(flat_s_wdata), .s_axi_wstrb({4'hf, 4'hf}), .s_axi_wlast(flat_s_wvalid),
        .s_axi_wvalid(flat_s_wvalid), .s_axi_wready(flat_s_wready),
        .s_axi_bid(), .s_axi_bresp(), .s_axi_bvalid(), .s_axi_bready({1'b1, 1'b1}),
        .s_axi_arid({8'h1, 8'h0}), .s_axi_araddr(flat_s_araddr), .s_axi_arlen({8'h0, 8'h0}), .s_axi_arsize({3'd2, 3'd2}),
        .s_axi_arburst({2'h1, 2'h1}), .s_axi_arlock({1'b0, 1'b0}), .s_axi_arcache({4'h0, 4'h0}), .s_axi_arprot({3'h0, 3'h0}),
        .s_axi_arvalid(flat_s_arvalid), .s_axi_arready(flat_s_arready),
        .s_axi_rid(), .s_axi_rdata(flat_s_rdata), .s_axi_rresp(), .s_axi_rlast(),
        .s_axi_rvalid(flat_s_rvalid), .s_axi_rready(flat_s_rready),
        
        .m_axi_awid(), .m_axi_awaddr(flat_m_awaddr), .m_axi_awlen(), .m_axi_awsize(), .m_axi_awburst(),
        .m_axi_awlock(), .m_axi_awcache(), .m_axi_awprot(), .m_axi_awvalid(flat_m_awvalid), .m_axi_awready(flat_m_awready),
        .m_axi_wdata(flat_m_wdata), .m_axi_wstrb(), .m_axi_wlast(), .m_axi_wvalid(flat_m_wvalid), .m_axi_wready(flat_m_wready),
        .m_axi_bid(24'h0), .m_axi_bresp(6'h0), .m_axi_bvalid(flat_m_wvalid), .m_axi_bready(),
        .m_axi_arid(), .m_axi_araddr(flat_m_araddr), .m_axi_arlen(), .m_axi_arsize(), .m_axi_arburst(),
        .m_axi_arlock(), .m_axi_arcache(), .m_axi_arprot(), .m_axi_arvalid(flat_m_arvalid), .m_axi_arready(flat_m_arready),
        .m_axi_rid(24'h0), .m_axi_rdata(flat_m_rdata), .m_axi_rresp(6'h0), .m_axi_rlast(flat_m_rvalid),
        .m_axi_rvalid(flat_m_rvalid), .m_axi_rready(flat_m_rready)
    );

    // --- SLOT 0: RAM ---
    axi_ram #(.ADDR_WIDTH(16), .DATA_WIDTH(32)) u_ram_main (
        .clk(clk_i), .rst(!rst_ni),
        .s_axi_awid(8'h0), .s_axi_awaddr({16'h0, flat_m_awaddr[0 +: 16]}), .s_axi_awlen(8'h0), .s_axi_awsize(3'd2),
        .s_axi_awburst(2'h1), .s_axi_awlock(1'b0), .s_axi_awcache(4'h0), .s_axi_awprot(3'h0),
        .s_axi_awvalid(flat_m_awvalid[0]), .s_axi_awready(flat_m_awready[0]),
        .s_axi_wdata(flat_m_wdata[31:0]), .s_axi_wstrb(4'hf), .s_axi_wlast(1'b1),
        .s_axi_wvalid(flat_m_wvalid[0]), .s_axi_wready(flat_m_wready[0]),
        .s_axi_bid(), .s_axi_bresp(), .s_axi_bvalid(), .s_axi_bready(1'b1),
        .s_axi_arid(8'h0), .s_axi_araddr({16'h0, flat_m_araddr[0 +: 16]}), .s_axi_arlen(8'h0), .s_axi_arsize(3'd2),
        .s_axi_arburst(2'h1), .s_axi_arlock(1'b0), .s_axi_arcache(4'h0), .s_axi_arprot(3'h0),
        .s_axi_arvalid(flat_m_arvalid[0]), .s_axi_arready(flat_m_arready[0]),
        .s_axi_rid(), .s_axi_rdata(flat_m_rdata[31:0]), .s_axi_rresp(), .s_axi_rlast(),
        .s_axi_rvalid(flat_m_rvalid[0]), .s_axi_rready(flat_m_rready[0])
    );

    // --- SLOT 1: UART ---
    assign flat_m_awready[1] = flat_m_awvalid[1];
    assign flat_m_wready[1]  = flat_m_wvalid[1];
    assign flat_m_arready[1] = flat_m_arvalid[1];
    assign flat_m_rdata[63:32] = 32'h0;
    assign flat_m_rvalid[1]  = flat_m_arvalid[1];

    // --- SLOT 2: GPIO ---
    logic axil_wvalid; logic [31:0] axil_wdata; logic [7:0] gpio_reg;
    wire unused_m_axil_bready, unused_m_axil_rready;

    axi_axil_adapter u_gpio_bridge (
        .clk(clk_i), .rst(!rst_ni),
        .s_axi_awid(8'h0), .s_axi_awaddr({16'h0, flat_m_awaddr[64 +: 16]}), .s_axi_awlen(8'h0), .s_axi_awsize(3'd2),
        .s_axi_awburst(2'h1), .s_axi_awlock(1'b0), .s_axi_awcache(4'h0), .s_axi_awprot(3'h0),
        .s_axi_awvalid(flat_m_awvalid[2]), .s_axi_awready(flat_m_awready[2]),
        .s_axi_wdata(flat_m_wdata[95:64]), .s_axi_wstrb(4'hf), .s_axi_wlast(1'b1),
        .s_axi_wvalid(flat_m_wvalid[2]), .s_axi_wready(flat_m_wready[2]),
        .s_axi_bid(), .s_axi_bresp(), .s_axi_bvalid(), .s_axi_bready(1'b1),
        .s_axi_arid(8'h0), .s_axi_araddr({16'h0, flat_m_araddr[64 +: 16]}), .s_axi_arlen(8'h0), .s_axi_arsize(3'd2),
        .s_axi_arburst(2'h1), .s_axi_arlock(1'b0), .s_axi_arcache(4'h0), .s_axi_arprot(3'h0),
        .s_axi_arvalid(flat_m_arvalid[2]), .s_axi_arready(flat_m_arready[2]),
        .s_axi_rid(), .s_axi_rdata(flat_m_rdata[95:64]), .s_axi_rresp(), .s_axi_rlast(),
        .s_axi_rvalid(flat_m_rvalid[2]), .s_axi_rready(flat_m_rready[2]),
        
        .m_axil_awaddr(), .m_axil_awprot(), .m_axil_awvalid(), .m_axil_awready(1'b1),
        .m_axil_wdata(axil_wdata), .m_axil_wstrb(), .m_axil_wvalid(axil_wvalid), .m_axil_wready(1'b1),
        .m_axil_bresp(), .m_axil_bvalid(axil_wvalid), .m_axil_bready(unused_m_axil_bready),
        .m_axil_araddr(), .m_axil_arprot(), .m_axil_arvalid(), .m_axil_arready(1'b1),
        .m_axil_rdata(32'h0), .m_axil_rresp(), .m_axil_rvalid(1'b0), .m_axil_rready(unused_m_axil_rready)
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) gpio_reg <= 8'h0;
        else if (axil_wvalid) gpio_reg <= axil_wdata[7:0];
    end
    assign gpio_io = gpio_reg;

endmodule
