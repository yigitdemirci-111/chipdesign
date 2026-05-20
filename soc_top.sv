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

    // --- CPU - Interconnect Sinyalleri ---
    logic [31:0] m_axi_awaddr, m_axi_wdata, m_axi_araddr, m_axi_rdata;
    logic        m_axi_awvalid, m_axi_awready, m_axi_wvalid, m_axi_wready;
    logic        m_axi_arvalid, m_axi_arready, m_axi_rvalid, m_axi_rready;

    // --- Seçici Sinyaller (Bus Interconnect) ---
    logic ram_sel, gpio_sel;
    logic ram_awready, gpio_awready;

    // 1. CPU Modülü
    dummy_cpu u_cpu (
        .clk           (clk_i),
        .rst_n         (rst_ni),
        .m_axi_awaddr  (m_axi_awaddr),
        .m_axi_awvalid (m_axi_awvalid),
        .m_axi_awready (m_axi_awready),
        .m_axi_wdata   (m_axi_wdata),
        .m_axi_wvalid  (m_axi_wvalid),
        .m_axi_wready  (m_axi_wready),
        .m_axi_araddr  (m_axi_araddr),
        .m_axi_arvalid (m_axi_arvalid),
        .m_axi_arready (m_axi_arready),
        .m_axi_rdata   (m_axi_rdata),
        .m_axi_rvalid  (m_axi_rvalid),
        .m_axi_rready  (m_axi_rready)
    );

    // 2. Interconnect (Adres Çözücü)
    axi_interconnect_custom u_interconnect (
        .s_axi_awaddr  (m_axi_awaddr),
        .ram_sel       (ram_sel),
        .gpio_sel      (gpio_sel)
    );

    // 3. RAM Modülü
    axi_ram #(.ADDR_WIDTH(16), .DATA_WIDTH(32)) u_ram_0 (
        .clk           (clk_i),
        .rst           (!rst_ni),
        .s_axi_awaddr  (m_axi_awaddr[15:0]),
        .s_axi_awvalid (m_axi_awvalid && ram_sel),
        .s_axi_awready (ram_awready),
        .s_axi_wdata   (m_axi_wdata),
        .s_axi_wvalid  (m_axi_wvalid && ram_sel),
        .s_axi_wready  (),
        .s_axi_araddr  (m_axi_araddr[15:0]),
        .s_axi_arvalid (m_axi_arvalid && ram_sel),
        .s_axi_arready (),
        .s_axi_rdata   (m_axi_rdata),
        .s_axi_rvalid  (m_axi_rvalid),
        .s_axi_rready  (m_axi_rready)
    );

    // 4. GPIO Modülü
    axil_gpio u_gpio_0 (
        .clk           (clk_i),
        .rst_n         (rst_ni),
        .s_axi_awaddr  (m_axi_awaddr),
        .s_axi_awvalid (m_axi_awvalid && gpio_sel),
        .s_axi_awready (gpio_awready),
        .s_axi_wdata   (m_axi_wdata),
        .s_axi_wvalid  (m_axi_wvalid && gpio_sel),
        .s_axi_wready  (),
        .gpio_io       (gpio_io)
    );

    // 5. Bus Yönetimi (Ready Sinyallerini Birleştirme)
    assign m_axi_awready = (ram_sel  ? ram_awready  : 1'b0) | 
                           (gpio_sel ? gpio_awready : 1'b0);

endmodule
