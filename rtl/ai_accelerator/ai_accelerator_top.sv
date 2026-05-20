`timescale 1ns / 1ps

// TEKNOFEST ÖTR Referansı: Entegre Uç YZ Donanım Hızlandırıcısı (Top Level)
module ai_accelerator_top #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    // --- AXI-LITE SLAVE ARAYÜZÜ (İşlemci Bağlantısı) ---
    input  logic [3:0]  S_AXI_AWADDR,
    input  logic        S_AXI_AWVALID,
    output logic        S_AXI_AWREADY,
    input  logic [31:0] S_AXI_WDATA,
    input  logic        S_AXI_WVALID,
    output logic        S_AXI_WREADY,
    output logic [1:0]  S_AXI_BRESP,
    output logic        S_AXI_BVALID,
    input  logic        S_AXI_BREADY,
    input  logic [3:0]  S_AXI_ARADDR,
    input  logic        S_AXI_ARVALID,
    output logic        S_AXI_ARREADY,
    output logic [31:0] S_AXI_RDATA,
    output logic [1:0]  S_AXI_RRESP,
    output logic        S_AXI_RVALID,
    input  logic        S_AXI_RREADY,

    // --- AXI MASTER ARAYÜZÜ (SRAM Bağlantısı - DMA) ---
    output logic [31:0] M_AXI_ARADDR,
    output logic        M_AXI_ARVALID,
    input  logic        M_AXI_ARREADY,
    input  logic [31:0] M_AXI_RDATA,
    input  logic        M_AXI_RVALID,
    output logic        M_AXI_RREADY
);

    // --- ARA SİNYALLER (Modülleri birbirine bağlayan kablolar) ---
    logic [31:0] feature_addr_from_cpu;
    logic [31:0] weight_addr_from_cpu; // YENİ: İşlemciden gelen ağırlık adresi
    logic [7:0]  data_from_dma;
    logic        data_valid_from_dma;
    logic [31:0] mac_result;

    // 1. MODÜL: AXI-Lite Slave (Sekreter - Emirleri Alır)
    ai_accel_axi_slave slave_inst (
        .S_AXI_ACLK(clk),
        .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        // İç bağlantılar
        .start_mac_o(start_sig),
        .mac_busy_i(dma_busy),
        .feature_addr_o(feature_addr_from_cpu),
        .weight_addr_o(weight_addr_from_cpu), 
        .mac_result_i(mac_result) // YENİ: MAC sonucu
    );

    // 2. MODÜL: Dahili DMA (Kamyon - Veriyi Getirir)
    ai_dma_master dma_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_addr_i(feature_addr_from_cpu),
        .start_fsm_i(start_sig),
        .dma_busy_o(dma_busy),
        // AXI Master portları
        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY),
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RREADY(M_AXI_RREADY),
        // MAC Ünitesine giden veri
        .data_to_mac_o(data_from_dma),
        .data_valid_o(data_valid_from_dma)
    );

// 3. MODÜL: MAC Unit (İşçi - Hesaplar)
    mac_unit mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .weight_i(data_from_dma), // GEÇİCİ ÇÖZÜM: Gerçek veriyi ağırlık kabul et (DMA güncellenene kadar)
        .feature_i(data_from_dma),
        .enable_i(data_valid_from_dma),
        .clear_i(start_sig),
        .result_o(mac_result)
    );

endmodule