`timescale 1ns / 1ps
`include "memory_map.svh"
`include "cv32e40p_apu_core_pkg.sv"
`include "cv32e40p_pkg.sv"
`include "cv32e40p_fpu_pkg.sv"

module soc_top (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        fetch_enable_i,
    inout  wire  [7:0]  gpio_io,
    output logic        uart_tx_o,
    input  logic        uart_rx_i,
    output logic        debug_instr_req,
    output logic        debug_instr_gnt,
    output logic [31:0] debug_instr_addr
);

    localparam S_COUNT = 2; 
    localparam M_COUNT = 1; // DÜZELTME 1: Boşta pin kalmasın diye sadece RAM'i bıraktık

    logic [31:0] inst_axi_awaddr, inst_axi_wdata, inst_axi_araddr, inst_axi_rdata;
    logic        inst_axi_awvalid, inst_axi_awready, inst_axi_wvalid, inst_axi_wready;
    logic        inst_axi_arvalid, inst_axi_arready, inst_axi_rready;
    logic        inst_axi_rvalid_int;

    logic [31:0] data_axi_awaddr, data_axi_wdata, data_axi_araddr, data_axi_rdata;
    logic        data_axi_awvalid, data_axi_awready, data_axi_wvalid, data_axi_wready;
    logic        data_axi_arvalid, data_axi_arready, data_axi_rvalid, data_axi_rready;

    wire [S_COUNT*32-1:0] flat_s_awaddr; wire [S_COUNT-1:0] flat_s_awvalid; wire [S_COUNT-1:0] flat_s_awready;
    wire [S_COUNT*32-1:0] flat_s_wdata;  wire [S_COUNT-1:0] flat_s_wvalid;  wire [S_COUNT-1:0] flat_s_wready;
    wire [S_COUNT*32-1:0] flat_s_araddr; wire [S_COUNT-1:0] flat_s_arvalid; wire [S_COUNT-1:0] flat_s_arready;
    wire [S_COUNT*32-1:0] flat_s_rdata;  wire [S_COUNT-1:0] flat_s_rvalid;  wire [S_COUNT-1:0] flat_s_rready;

    wire [M_COUNT*32-1:0] flat_m_awaddr; wire [M_COUNT-1:0] flat_m_awvalid; wire [M_COUNT-1:0] flat_m_awready;
    wire [M_COUNT*32-1:0] flat_m_wdata;  wire [M_COUNT-1:0] flat_m_wvalid;  wire [M_COUNT-1:0] flat_m_wready;
    wire [M_COUNT*32-1:0] flat_m_araddr; wire [M_COUNT-1:0] flat_m_arvalid; wire [M_COUNT-1:0] flat_m_arready;
    wire [M_COUNT*32-1:0] flat_m_rdata;  wire [M_COUNT-1:0] flat_m_rvalid;  wire [M_COUNT-1:0] flat_m_rready;

    // DÜZELTME 2: RAM ile Crossbar arasındaki eksik sinyaller
    wire [M_COUNT-1:0] flat_m_bvalid;
    wire [M_COUNT-1:0] flat_m_bready;
    wire [M_COUNT-1:0] flat_m_rlast;

    assign flat_s_awaddr  = {data_axi_awaddr, inst_axi_awaddr};
    assign flat_s_awvalid = {data_axi_awvalid, inst_axi_awvalid};
    assign {data_axi_awready, inst_axi_awready} = flat_s_awready;

    assign flat_s_wdata   = {data_axi_wdata, inst_axi_wdata};
    assign flat_s_wvalid  = {data_axi_wvalid, inst_axi_wvalid};
    assign {data_axi_wready, inst_axi_wready} = flat_s_wready;

    assign flat_s_araddr  = {data_axi_araddr, inst_axi_araddr};
    assign flat_s_arvalid = {data_axi_arvalid, inst_axi_arvalid};
    assign {data_axi_arready, inst_axi_arready} = flat_s_arready;

    assign {data_axi_rdata, inst_axi_rdata} = flat_s_rdata;
    assign {data_axi_rvalid, inst_axi_rvalid_int} = flat_s_rvalid;
    assign flat_s_rready  = {data_axi_rready, inst_axi_rready};

    logic instr_req, instr_gnt, instr_rvalid;
    logic [31:0] instr_addr, instr_rdata;
    logic data_req, data_gnt, data_rvalid, data_we;
    logic [3:0] data_be;
    logic [31:0] data_addr, data_wdata, data_rdata;

    obi_to_axil_bridge u_bridge_instr (
        .clk(clk_i), .rst_n(rst_ni),
        .obi_req_i(instr_req), .obi_gnt_o(instr_gnt), .obi_addr_i(instr_addr),
        .obi_we_i(1'b0), .obi_be_i(4'hF), .obi_wdata_i(32'h0),
        .obi_rvalid_o(instr_rvalid), .obi_rdata_o(instr_rdata),
        .axil_awaddr(inst_axi_awaddr), .axil_awvalid(inst_axi_awvalid), .axil_awready(inst_axi_awready),
        .axil_wdata(inst_axi_wdata), .axil_wstrb(), .axil_wvalid(inst_axi_wvalid), .axil_wready(inst_axi_wready),
        .axil_bresp(2'b0), .axil_bvalid(1'b0), .axil_bready(),
        .axil_araddr(inst_axi_araddr), .axil_arvalid(inst_axi_arvalid), .axil_arready(inst_axi_arready),
        .axil_rdata(inst_axi_rdata), .axil_rresp(2'b0), .axil_rvalid(inst_axi_rvalid_int), .axil_rready(inst_axi_rready)
    );

    obi_to_axil_bridge u_bridge_data (
        .clk(clk_i), .rst_n(rst_ni),
        .obi_req_i(data_req), .obi_gnt_o(data_gnt), .obi_addr_i(data_addr),
        .obi_we_i(data_we), .obi_be_i(data_be), .obi_wdata_i(data_wdata),
        .obi_rvalid_o(data_rvalid), .obi_rdata_o(data_rdata),
        .axil_awaddr(data_axi_awaddr), .axil_awvalid(data_axi_awvalid), .axil_awready(data_axi_awready),
        .axil_wdata(data_axi_wdata), .axil_wstrb(), .axil_wvalid(data_axi_wvalid), .axil_wready(data_axi_wready),
        .axil_bresp(2'b0), .axil_bvalid(1'b1), .axil_bready(),
        .axil_araddr(data_axi_araddr), .axil_arvalid(data_axi_arvalid), .axil_arready(data_axi_arready),
        .axil_rdata(data_axi_rdata), .axil_rresp(2'b0), .axil_rvalid(data_rvalid), .axil_rready(data_axi_rready)
    );

cv32e40p_core u_riscv_core (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .pulp_clock_en_i  (1'b1),
        .scan_cg_en_i     (1'b0),
        
        // Boot adresi: İşlemcinin kod çekmeye başlayacağı yer
        .boot_addr_i      (32'h0000_0000), 
        .mtvec_addr_i     (32'h0000_0020),
        .dm_halt_addr_i   (32'h0000_0000),
        .dm_exception_addr_i (32'h0000_0000),
        
        // Fetch (Komut) Arayüzü
        .instr_req_o      (instr_req),
        .instr_gnt_i      (instr_gnt),
        .instr_addr_o     (instr_addr),
        .instr_rvalid_i   (instr_rvalid),
        .instr_rdata_i    (instr_rdata),
        
        // Data (Veri) Arayüzü
        .data_req_o       (data_req),
        .data_gnt_i       (data_gnt),
        .data_addr_o      (data_addr),
        .data_we_o        (data_we),
        .data_be_o        (data_be),
        .data_wdata_o     (data_wdata),
        .data_rvalid_i    (data_rvalid),
        .data_rdata_i     (data_rdata),
        
        // ÖNEMLİ: İşlemcinin uyanmasını engelleyen sinyaller
.irq_i(33'h0),
        .debug_req_i      (1'b0), 
        .fetch_enable_i   (fetch_enable_i)
    );
// Kendi modülünü değil, standart bir AXI Interconnect modülünü çağırıyoruz
    // Port isimleri senin flat_ sinyallerinle uyumlu hale getirildi
    axi_interconnect_custom u_axi_crossbar (
        .clk(clk_i), 
        .rst(!rst_ni),

        // Slave (CPU/Bridge tarafları)
        .s_axi_awaddr(flat_s_awaddr), 
        .s_axi_awvalid(flat_s_awvalid), 
        .s_axi_awready(flat_s_awready),
        .s_axi_wdata(flat_s_wdata), 
        .s_axi_wvalid(flat_s_wvalid), 
        .s_axi_wready(flat_s_wready),
        .s_axi_araddr(flat_s_araddr), 
        .s_axi_arvalid(flat_s_arvalid), 
        .s_axi_arready(flat_s_arready),
        .s_axi_rdata(flat_s_rdata), 
        .s_axi_rvalid(flat_s_rvalid), 
        .s_axi_rready(flat_s_rready),

        // Master (RAM tarafı)
        .m_axi_awaddr(flat_m_awaddr),
        .m_axi_awvalid(flat_m_awvalid),
        .m_axi_awready(flat_m_awready),
        .m_axi_wdata(flat_m_wdata),
        .m_axi_wvalid(flat_m_wvalid),
        .m_axi_wready(flat_m_wready),
        .m_axi_araddr(flat_m_araddr),
        .m_axi_arvalid(flat_m_arvalid),
        .m_axi_arready(flat_m_arready),
        .m_axi_rdata(flat_m_rdata),
        .m_axi_rvalid(flat_m_rvalid),
        .m_axi_rready(flat_m_rready)
    );
    axi_ram #(.ADDR_WIDTH(16), .DATA_WIDTH(32)) u_ram_main (
        .clk(clk_i), .rst(!rst_ni),
        .s_axi_awid(8'h0), .s_axi_awaddr(flat_m_awaddr[15:0]), // DÜZELTME 4: Adres bitleri hizalandı
        .s_axi_awlen(8'h0), .s_axi_awsize(3'd2), .s_axi_awburst(2'h1), 
        .s_axi_awlock(1'b0), .s_axi_awcache(4'h0), .s_axi_awprot(3'h0),
        .s_axi_awvalid(flat_m_awvalid), .s_axi_awready(flat_m_awready),
        .s_axi_wdata(flat_m_wdata), .s_axi_wstrb(4'hf), .s_axi_wlast(1'b1),
        .s_axi_wvalid(flat_m_wvalid), .s_axi_wready(flat_m_wready),
        .s_axi_bid(), .s_axi_bresp(), 
        .s_axi_bvalid(flat_m_bvalid), .s_axi_bready(flat_m_bready),
        .s_axi_arid(8'h0), .s_axi_araddr(flat_m_araddr[15:0]), // DÜZELTME 4
        .s_axi_arlen(8'h0), .s_axi_arsize(3'd2), .s_axi_arburst(2'h1), 
        .s_axi_arlock(1'b0), .s_axi_arcache(4'h0), .s_axi_arprot(3'h0),
        .s_axi_arvalid(flat_m_arvalid), .s_axi_arready(flat_m_arready),
        .s_axi_rid(), .s_axi_rdata(flat_m_rdata), .s_axi_rresp(), 
        .s_axi_rlast(flat_m_rlast), .s_axi_rvalid(flat_m_rvalid), .s_axi_rready(flat_m_rready)
    );

    assign debug_instr_req  = instr_req;
    assign debug_instr_gnt  = instr_gnt;
    assign debug_instr_addr = instr_addr;


initial begin
        $monitor("Zaman: %0t | Fetch_Enable: %b | Instr_Req: %b | Instr_Addr: %h", $time, fetch_enable_i, instr_req, instr_addr);
    end
endmodule
