// soc_top.sv
`timescale 1ns / 1ps

module soc_top (
    input  logic clk,
    input  logic rst_ni
);

    // ============================================================================
    // 1. OBI Sinyal Tanımlamaları (İşlemci ile Köprü Arası)
    // ============================================================================
    logic        obi_req;
    logic        obi_gnt;
    logic [31:0] obi_addr;
    logic        obi_we;
    logic [3:0]  obi_be;
    logic [31:0] obi_wdata;
    logic        obi_rvalid;
    logic [31:0] obi_rdata;

    // ============================================================================
    // 2. AXI Interface Tanımlamaları
    // ============================================================================
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32), .ID_WIDTH(8)) cpu_axi4_m();
    axil_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) periph_axil_s();

    // ============================================================================
    // 3. CV32E40P İşlemci Çekirdeği
    // ============================================================================
// soc_top.sv içinde:
cv32e40p_core #(
    .COREV_PULP(0) // COREV_DM yerine COREV_PULP kullanılıyor
) u_cv32e40p_core (
    .clk_i(clk),           // clk yerine clk_i
    .rst_ni(rst_ni),       // rst_n yerine rst_ni
    
    // Data OBI portları (OBI_ ön eki kaldırılmış)
    .data_req_o(obi_req),
    .data_gnt_i(obi_gnt),
    .data_addr_o(obi_addr),
    .data_we_o(obi_we),
    .data_be_o(obi_be),
    .data_wdata_o(obi_wdata),
    .data_rvalid_i(obi_rvalid),
    .data_rdata_i(obi_rdata),

    // Instruction OBI portları
    .instr_req_o(),
    .instr_gnt_i(1'b1),
    .instr_addr_o(),
    .instr_rvalid_i(1'b0),
    .instr_rdata_i(32'h0),
    
    .core_sleep_o() // sleep_o yerine core_sleep_o
    
    // Diğer kullanılmayan pinleri şimdilik boş bırakabilirsin
);
    // ============================================================================
    // 4. OBI-to-AXI4-Lite Köprüsü
    // ============================================================================
    obi_to_axil_bridge u_obi_bridge (
        .clk(clk),
        .rst_n(rst_ni),
        
        .obi_req_i(obi_req),
        .obi_gnt_o(obi_gnt),
        .obi_addr_i(obi_addr),
        .obi_we_i(obi_we),
        .obi_be_i(obi_be),
        .obi_wdata_i(obi_wdata),
        .obi_rvalid_o(obi_rvalid),
        .obi_rdata_o(obi_rdata),

        .axil_awaddr (periph_axil_s.awaddr),
        .axil_awvalid(periph_axil_s.awvalid),
        .axil_awready(periph_axil_s.awready),
        .axil_wdata  (periph_axil_s.wdata),
        .axil_wstrb  (periph_axil_s.wstrb),
        .axil_wvalid (periph_axil_s.wvalid),
        .axil_wready (periph_axil_s.wready),
        .axil_bresp  (periph_axil_s.bresp),
        .axil_bvalid (periph_axil_s.bvalid),
        .axil_bready (periph_axil_s.bready),
        .axil_araddr (periph_axil_s.araddr),
        .axil_arvalid(periph_axil_s.arvalid),
        .axil_arready(periph_axil_s.arready),
        .axil_rdata  (periph_axil_s.rdata),
        .axil_rresp  (periph_axil_s.rresp),
        .axil_rvalid (periph_axil_s.rvalid),
        .axil_rready (periph_axil_s.rready)
    );

    // ============================================================================
    // 5. Dummy Slave Bağlantısı
    // ============================================================================
    dummy_axil_slave u_dummy_uart0 (
        .clk(clk),
        .rst_n(rst_ni),
        .s_axil_awaddr (periph_axil_s.awaddr),
        .s_axil_awvalid(periph_axil_s.awvalid),
        .s_axil_awready(periph_axil_s.awready),
        .s_axil_wdata  (periph_axil_s.wdata),
        .s_axil_wstrb  (periph_axil_s.wstrb),
        .s_axil_wvalid (periph_axil_s.wvalid),
        .s_axil_wready (periph_axil_s.wready),
        .s_axil_bresp  (periph_axil_s.bresp),
        .s_axil_bvalid (periph_axil_s.bvalid),
        .s_axil_bready (periph_axil_s.bready),
        .s_axil_araddr (periph_axil_s.araddr),
        .s_axil_arvalid(periph_axil_s.arvalid),
        .s_axil_arready(periph_axil_s.arready),
        .s_axil_rdata  (periph_axil_s.rdata),
        .s_axil_rresp  (periph_axil_s.rresp),
        .s_axil_rvalid (periph_axil_s.rvalid),
        .s_axil_rready (periph_axil_s.rready)
    );

endmodule
