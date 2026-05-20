`include "memory_map.svh"

module mcu_top (
    input logic clk_i,
    input logic rst_ni
);

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam AXI_DATA_WIDTH = 32;
    localparam AXIL_DATA_WIDTH = 32;

    // Sinyal tanımları (Dummy Master)
    logic [7:0] m_axi_awid;
    logic [ADDR_WIDTH-1:0] m_axi_awaddr;
    logic m_axi_awvalid;
    logic m_axi_awready;
    logic [DATA_WIDTH-1:0] m_axi_wdata;
    logic m_axi_wvalid;
    logic m_axi_wready;
    logic m_axi_bready;

    // Sinyal tanımları (Bridge Çıkışı)
    logic [ADDR_WIDTH-1:0] axil_bridge_awaddr;
    logic axil_bridge_awvalid;
    logic axil_bridge_awready;
    logic [DATA_WIDTH-1:0] axil_bridge_wdata;
    logic axil_bridge_wvalid;
    logic axil_bridge_wready;
    logic axil_bridge_bready;

    axi_axil_adapter #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH)
    ) u_axi_to_axil_bridge (
        .clk(clk_i),
        .rst(rst_ni),
        .s_axi_awid(m_axi_awid),
        .s_axi_awaddr(m_axi_awaddr),
        .s_axi_awvalid(m_axi_awvalid),
        .s_axi_awready(m_axi_awready),
        .s_axi_wdata(m_axi_wdata),
        .s_axi_wvalid(m_axi_wvalid),
        .s_axi_wready(m_axi_wready),
        .s_axi_bready(m_axi_bready),
        .m_axil_awaddr(axil_bridge_awaddr),
        .m_axil_awvalid(axil_bridge_awvalid),
        .m_axil_awready(axil_bridge_awready),
        .m_axil_wdata(axil_bridge_wdata),
        .m_axil_wvalid(axil_bridge_wvalid),
        .m_axil_wready(axil_bridge_wready),
        .m_axil_bready(axil_bridge_bready)
    );

    // Dummy Sürücüler
    assign m_axi_awid    = '0;
    assign m_axi_awaddr  = '0;
    assign m_axi_awvalid = '0;
    assign m_axi_wdata   = '0;
    assign m_axi_wvalid  = '0;
    assign m_axi_bready  = '1;
    assign axil_bridge_awready = '1;
    assign axil_bridge_wready  = '1;
// ... diğer kodlarının altına ...
my_fifo #(
    .DATA_WIDTH(32),
    .DEPTH(16)
) u_vfifo (
    .clk(clk_i),
    .rst_n(rst_ni),
    .din(m_axi_wdata), // FIFO girişini bağla
    .wr_en(m_axi_wvalid),
    .dout(),
    .full(),
    .empty()
);
endmodule
