`timescale 1ns / 1ps

module soc_top (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        uart_rx_i,
    output logic        uart_tx_o,
    inout  wire         i2c_sda_io,
    output logic        i2c_scl_o,
    inout  wire  [7:0]  gpio_io
);
// Sinyal Tanımları
    
    logic [31:0] m_axi_araddr, m_axi_rdata;
    logic        m_axi_arvalid, m_axi_arready, m_axi_rvalid, m_axi_rready;

    logic [31:0] m_axi_awaddr, m_axi_wdata;
    logic        m_axi_awvalid, m_axi_awready, m_axi_wvalid, m_axi_wready;
    
    logic [31:0] s0_axi_awaddr;
    logic        s0_axi_awvalid, s0_axi_awready;
    // CPU Bağlantısı
// CPU Bağlantısı (Düzeltilmiş)
    dummy_cpu u_cpu (
        .clk(clk_i),
        .rst_n(rst_ni),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        // CPU'dan çıkan isimlerle aynı tutalım:
        .m_axi_araddr(m_axi_araddr), 
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready)


    );

    assign s0_axi_awaddr = m_axi_awaddr;
    assign s0_axi_awvalid = m_axi_awvalid;
    assign m_axi_awready = s0_axi_awready;

axi_ram #(.ADDR_WIDTH(16), .DATA_WIDTH(32)) u_ram_0 (
        .clk(clk_i),
        .rst(!rst_ni),

        // Yazma Kanalı
        .s_axi_awaddr  (s0_axi_awaddr[15:0]),
        .s_axi_awvalid (s0_axi_awvalid),
        .s_axi_awready (s0_axi_awready), 
        .s_axi_wdata   (m_axi_wdata),
        .s_axi_wvalid  (m_axi_wvalid),
        .s_axi_wready  (m_axi_wready),   

        // Okuma Kanalı
        .s_axi_araddr  (m_axi_araddr[15:0]),
        .s_axi_arvalid (m_axi_arvalid),
        .s_axi_arready (m_axi_arready),
        .s_axi_rdata   (m_axi_rdata),
        .s_axi_rvalid  (m_axi_rvalid),
        .s_axi_rready  (m_axi_rready)
    ); 

endmodule
