// ips/axi_axil_adapter.v
// Yusuf & Open-Source SOC Bridge - TEKNOFEST 2026 Uyumlu Standart Çevirici
`timescale 1ns / 1ps

module axi_axil_adapter #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 8,
    parameter STRB_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst, // Aktif yüksek reset

    // AXI4-Full Slave Arayüzü (CPU'dan gelen hat)
    input  wire [ID_WIDTH-1:0]     s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [7:0]              s_axi_awlen,
    input  wire [2:0]              s_axi_awsize,
    input  wire [1:0]              s_axi_awburst,
    input  wire                    s_axi_awlock,
    input  wire [3:0]              s_axi_awcache,
    input  wire [2:0]              s_axi_awprot,
    input  wire                    s_axi_awvalid,
    output wire                    s_axi_awready,
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]   s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,
    output wire [ID_WIDTH-1:0]     s_axi_bid,
    output wire [1:0]              s_axi_bresp,
    output wire                    s_axi_bvalid,
    input  wire                    s_axi_bready,
    input  wire [ID_WIDTH-1:0]     s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [7:0]              s_axi_arlen,
    input  wire [2:0]              s_axi_arsize,
    input  wire [1:0]              s_axi_arburst,
    input  wire                    s_axi_arlock,
    input  wire [3:0]              s_axi_arcache,
    input  wire [2:0]              s_axi_arprot,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready,
    output wire [ID_WIDTH-1:0]     s_axi_rid,
    output wire [DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [1:0]              s_axi_rresp,
    output wire                    s_axi_rlast,
    output wire                    s_axi_rvalid,
    input  wire                    s_axi_rready,

    // AXI4-Lite Master Arayüzü (Matris/Çevre birimlerine giden hat)
    output wire [ADDR_WIDTH-1:0]   m_axil_awaddr,
    output wire [2:0]              m_axil_awprot,
    output wire                    m_axil_awvalid,
    input  wire                    m_axil_awready,
    output wire [DATA_WIDTH-1:0]   m_axil_wdata,
    output wire [STRB_WIDTH-1:0]   m_axil_wstrb,
    output wire                    m_axil_wvalid,
    input  wire                    m_axil_wready,
    input  wire [1:0]              m_axil_bresp,
    input  wire                    m_axil_bvalid,
    output wire                    m_axil_bready,
    output wire [ADDR_WIDTH-1:0]   m_axil_araddr,
    output wire [2:0]              m_axil_arprot,
    output wire                    m_axil_arvalid,
    input  wire                    m_axil_arready,
    input  wire [DATA_WIDTH-1:0]   m_axil_rdata,
    input  wire [1:0]              m_axil_rresp,
    input  wire                    m_axil_rvalid,
    output wire                    m_axil_rready
);

    // ------------------------------------------------------------------------
    // Adres ve Sinyal Passthrough (Birebir Eşleme Mantığı)
    // ------------------------------------------------------------------------
    assign m_axil_awaddr  = s_axi_awaddr;
    assign m_axil_awprot  = s_axi_awprot;
    assign m_axil_awvalid = s_axi_awvalid;
    assign s_axi_awready  = m_axil_awready;

    assign m_axil_wdata   = s_axi_wdata;
    assign m_axil_wstrb   = s_axi_wstrb;
    assign m_axil_wvalid  = s_axi_wvalid;
    assign s_axi_wready   = m_axil_wready;

    assign s_axi_bid      = {ID_WIDTH{1'b0}}; // ID takibi şimdilik sıfır
    assign s_axi_bresp    = m_axil_bresp;
    assign s_axi_bvalid   = m_axil_bvalid;
    assign m_axil_bready  = s_axi_bready;

    assign m_axil_araddr  = s_axi_araddr;
    assign m_axil_arprot  = s_axi_arprot;
    assign m_axil_arvalid = s_axi_arvalid;
    assign s_axi_arready  = m_axil_arready;

    assign s_axi_rid      = {ID_WIDTH{1'b0}};
    assign s_axi_rdata    = m_axil_rdata;
    assign s_axi_rresp    = m_axil_rresp;
    assign s_axi_rlast    = 1'b1; // Lite dönüşümünde her okuma son veridir
    assign s_axi_rvalid   = m_axil_rvalid;
    assign m_axil_rready  = s_axi_rready;

endmodule
