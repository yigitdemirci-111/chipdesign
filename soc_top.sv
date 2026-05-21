`timescale 1ns / 1ps

module soc_top (
    input  logic        clk_i,
    input  logic        rst_ni,
    inout  wire  [7:0]  gpio_io,
    output logic        uart_tx_o,
    input  logic        uart_rx_i
);

    // AXI Master Hatları
    logic [31:0] m_axi_awaddr, m_axi_wdata, m_axi_araddr, m_axi_rdata_wire;
    logic        m_axi_awvalid, m_axi_awready, m_axi_wvalid, m_axi_wready;
    logic        m_axi_arvalid, m_axi_arready, m_axi_rvalid, m_axi_rready;

    // Interconnect Düz Vektör Tanımları
    localparam M_COUNT = 3;
    wire [M_COUNT*32-1:0] flat_m_awaddr;
    wire [M_COUNT-1:0]    flat_m_awvalid;
    wire [M_COUNT-1:0]    flat_m_awready;
    wire [M_COUNT*32-1:0] flat_m_wdata;
    wire [M_COUNT*4-1:0]  flat_m_wstrb;
    wire [M_COUNT-1:0]    flat_m_wlast;
    wire [M_COUNT-1:0]    flat_m_wvalid;
    wire [M_COUNT-1:0]    flat_m_wready;
    wire [M_COUNT*32-1:0] flat_m_araddr;
    wire [M_COUNT-1:0]    flat_m_arvalid;
    wire [M_COUNT-1:0]    flat_m_arready;
    wire [M_COUNT*32-1:0] flat_m_rdata;
    wire [M_COUNT-1:0]    flat_m_rvalid;
    wire [M_COUNT-1:0]    flat_m_rready;
    wire [M_COUNT*8-1:0]  flat_m_awlen,  flat_m_arlen;
    wire [M_COUNT*3-1:0]  flat_m_awsize, flat_m_arsize;
    wire [M_COUNT*2-1:0]  flat_m_awburst,flat_m_arburst;
    wire [M_COUNT*8-1:0]  flat_m_awid,   flat_m_arid, flat_m_bid, flat_m_rid;
    wire [M_COUNT-1:0]    flat_m_rlast;
    wire [M_COUNT*2-1:0]  flat_m_bresp,  flat_m_rresp;
    wire [M_COUNT-1:0]    flat_m_bvalid, flat_m_bready;

    // 1. İşlemci (Dummy CPU)
    dummy_cpu u_cpu (
        .clk(clk_i), .rst_n(rst_ni),
        .m_axi_awaddr, .m_axi_awvalid, .m_axi_awready,
        .m_axi_wdata, .m_axi_wvalid, .m_axi_wready,
        .m_axi_araddr, .m_axi_arvalid, .m_axi_arready,
        .m_axi_rdata(m_axi_rdata), .m_axi_rvalid, .m_axi_rready
    );

    // Testbench son rapor koruması
    logic [31:0] rdata_hold;
    logic [31:0] m_axi_rdata;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) rdata_hold <= 32'h0;
        else if (m_axi_rvalid && m_axi_rready) rdata_hold <= m_axi_rdata_wire;
    end
    assign m_axi_rdata = m_axi_rvalid ? m_axi_rdata_wire : rdata_hold;

    // 2. AXI Interconnect
    axi_interconnect #(
        .S_COUNT(1), .M_COUNT(3),
        .DATA_WIDTH(32), .ADDR_WIDTH(32),
        .M_ADDR_WIDTH({32'd16, 32'd16, 32'd16}),
        .M_BASE_ADDR({32'h4000_0000, 32'h0001_0000, 32'h0000_0000}) 
    ) u_interconnect (
        .clk(clk_i), .rst(!rst_ni),
        .s_axi_awid(8'h0), .s_axi_awaddr(m_axi_awaddr), .s_axi_awlen(8'h0), .s_axi_awsize(3'd2),
        .s_axi_awburst(2'h1), .s_axi_awlock(1'b0), .s_axi_awcache(4'h0), .s_axi_awprot(3'h0),
        .s_axi_awvalid(m_axi_awvalid), .s_axi_awready(m_axi_awready),
        .s_axi_wdata(m_axi_wdata), .s_axi_wstrb(4'hf), .s_axi_wlast(m_axi_wvalid),
        .s_axi_wvalid(m_axi_wvalid), .s_axi_wready(m_axi_wready),
        .s_axi_bid(), .s_axi_bresp(), .s_axi_bvalid(), .s_axi_bready(1'b1),
        .s_axi_arid(8'h0), .s_axi_araddr(m_axi_araddr), .s_axi_arlen(8'h0), .s_axi_arsize(3'd2),
        .s_axi_arburst(2'h1), .s_axi_arlock(1'b0), .s_axi_arcache(4'h0), .s_axi_arprot(3'h0),
        .s_axi_arvalid(m_axi_arvalid), .s_axi_arready(m_axi_arready),
        .s_axi_rid(), .s_axi_rdata(m_axi_rdata_wire), .s_axi_rresp(), .s_axi_rlast(),
        .s_axi_rvalid(m_axi_rvalid), .s_axi_rready(m_axi_rready),
        
        .m_axi_awid(flat_m_awid), .m_axi_awaddr(flat_m_awaddr), .m_axi_awlen(flat_m_awlen),
        .m_axi_awsize(flat_m_awsize), .m_axi_awburst(flat_m_awburst), .m_axi_awlock(), .m_axi_awcache(),
        .m_axi_awprot(), .m_axi_awvalid(flat_m_awvalid), .m_axi_awready(flat_m_awready),
        .m_axi_wdata(flat_m_wdata), .m_axi_wstrb(flat_m_wstrb), .m_axi_wlast(flat_m_wlast),
        .m_axi_wvalid(flat_m_wvalid), .m_axi_wready(flat_m_wready),
        .m_axi_bid(flat_m_bid), .m_axi_bresp(flat_m_bresp), .m_axi_bvalid(flat_m_bvalid), .m_axi_bready(flat_m_bready),
        .m_axi_arid(flat_m_arid), .m_axi_araddr(flat_m_araddr), .m_axi_arlen(flat_m_arlen),
        .m_axi_arsize(flat_m_arsize), .m_axi_arburst(flat_m_arburst), .m_axi_arlock(), .m_axi_arcache(),
        .m_axi_arprot(), .m_axi_arvalid(flat_m_arvalid), .m_axi_arready(flat_m_arready),
        .m_axi_rid(flat_m_rid), .m_axi_rdata(flat_m_rdata), .m_axi_rresp(flat_m_rresp),
        .m_axi_rlast(flat_m_rlast), .m_axi_rvalid(flat_m_rvalid), .m_axi_rready(flat_m_rready)
    );

    // YENİ DÜZENLEME: RAM artık Interconnect çıktısına göre Slot 0'da (00000000 Aralığı)
    axi_ram #(.ADDR_WIDTH(16), .DATA_WIDTH(32)) u_ram_main (
        .clk(clk_i), .rst(!rst_ni),
        .s_axi_awid(flat_m_awid[7:0]), .s_axi_awaddr(flat_m_awaddr[0 +: 16]), .s_axi_awlen(flat_m_awlen[7:0]),
        .s_axi_awsize(flat_m_awsize[2:0]), .s_axi_awburst(flat_m_awburst[1:0]), .s_axi_awlock(1'b0),
        .s_axi_awcache(4'h0), .s_axi_awprot(3'h0), .s_axi_awvalid(flat_m_awvalid[0]), .s_axi_awready(flat_m_awready[0]),
        .s_axi_wdata(flat_m_wdata[31:0]), .s_axi_wstrb(flat_m_wstrb[3:0]), .s_axi_wlast(flat_m_wlast[0]),
        .s_axi_wvalid(flat_m_wvalid[0]), .s_axi_wready(flat_m_wready[0]),
        .s_axi_bid(flat_m_bid[7:0]), .s_axi_bresp(flat_m_bresp[1:0]), .s_axi_bvalid(flat_m_bvalid[0]), .s_axi_bready(flat_m_bready[0]),
        .s_axi_arid(flat_m_arid[7:0]), .s_axi_araddr(flat_m_araddr[0 +: 16]), .s_axi_arlen(flat_m_arlen[7:0]),
        .s_axi_arsize(flat_m_arsize[2:0]), .s_axi_arburst(flat_m_arburst[1:0]), .s_axi_arlock(1'b0),
        .s_axi_arcache(4'h0), .s_axi_arprot(3'h0), .s_axi_arvalid(flat_m_arvalid[0]), .s_axi_arready(flat_m_arready[0]),
        .s_axi_rid(flat_m_rid[7:0]), .s_axi_rdata(flat_m_rdata[31:0]), .s_axi_rresp(flat_m_rresp[1:0]),
        .s_axi_rlast(flat_m_rlast[0]), .s_axi_rvalid(flat_m_rvalid[0]), .s_axi_rready(flat_m_rready[0])
    );

    // Boşta kalan Slot 1 kapatıldı
    assign flat_m_awready[1] = 1'b0; assign flat_m_wready[1] = 1'b0; assign flat_m_arready[1] = 1'b0;
    assign flat_m_rdata[63:32] = 32'h0; assign flat_m_rvalid[1] = 1'b0; assign flat_m_rlast[1] = 1'b0;
    assign flat_m_rresp[3:2] = 2'b00; assign flat_m_bresp[3:2] = 2'b00; assign flat_m_bvalid[1] = 1'b0;
    assign flat_m_bid[15:8] = 8'h0; assign flat_m_rid[15:8] = 8'h0;

    // YENİ DÜZENLEME: GPIO Bridge artık Interconnect çıktısına göre Slot 2'de (40000000 Aralığı)
    logic axil_wvalid;
    logic [31:0] axil_wdata;
    logic [7:0]  gpio_reg;

    axi_axil_adapter u_bridge (
        .clk(clk_i), .rst(!rst_ni),
        .s_axi_awid(flat_m_awid[23:16]), .s_axi_awaddr(flat_m_awaddr[64:33]), .s_axi_awlen(flat_m_awlen[23:16]),
        .s_axi_awsize(flat_m_awsize[8:6]), .s_axi_awburst(flat_m_awburst[5:4]), .s_axi_awlock(1'b0),
        .s_axi_awcache(4'h0), .s_axi_awprot(3'h0), .s_axi_awvalid(flat_m_awvalid[2]), .s_axi_awready(flat_m_awready[2]),
        .s_axi_wdata(flat_m_wdata[95:64]), .s_axi_wstrb(flat_m_wstrb[11:8]), .s_axi_wlast(flat_m_wlast[2]),
        .s_axi_wvalid(flat_m_wvalid[2]), .s_axi_wready(flat_m_wready[2]),
        .s_axi_bid(flat_m_bid[23:16]), .s_axi_bresp(flat_m_bresp[5:4]), .s_axi_bvalid(flat_m_bvalid[2]), .s_axi_bready(flat_m_bready[2]),
        .s_axi_arid(flat_m_arid[23:16]), .s_axi_araddr(flat_m_araddr[64:33]), .s_axi_arlen(flat_m_arlen[23:16]),
        .s_axi_arsize(flat_m_arsize[8:6]), .s_axi_arburst(flat_m_arburst[5:4]), .s_axi_arlock(1'b0),
        .s_axi_arcache(4'h0), .s_axi_arprot(3'h0), .s_axi_arvalid(flat_m_arvalid[2]), .s_axi_arready(flat_m_arready[2]),
        .s_axi_rid(flat_m_rid[23:16]), .s_axi_rdata(flat_m_rdata[95:64]), .s_axi_rresp(flat_m_rresp[5:4]),
        .s_axi_rlast(flat_m_rlast[2]), .s_axi_rvalid(flat_m_rvalid[2]), .s_axi_rready(flat_m_rready[2]),
        
        .m_axil_awaddr(), .m_axil_awprot(), .m_axil_awvalid(), .m_axil_awready(1'b1),
        .m_axil_wdata(axil_wdata), .m_axil_wstrb(), .m_axil_wvalid(axil_wvalid), .m_axil_wready(1'b1),
        .m_axil_bresp(2'b00), .m_axil_bvalid(axil_wvalid), .m_axil_bready(),
        .m_axil_araddr(), .m_axil_arprot(), .m_axil_arvalid(), .m_axil_arready(1'b1),
        .m_axil_rdata(32'h0), .m_axil_rresp(2'b00), .m_axil_rvalid(1'b0), .m_axil_rready()
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) gpio_reg <= 8'h0;
        else if (axil_wvalid) gpio_reg <= axil_wdata[7:0];
    end
    assign gpio_io = gpio_reg;

endmodule
