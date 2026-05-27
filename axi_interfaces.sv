// axi_interfaces.sv
`timescale 1ns / 1ps

// ============================================================================
// 1. AXI4-FULL INTERFACE (Ana Bellekler ve YZ Hızlandırıcı İçin)
// ============================================================================
interface axi4_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 8
);
    // Write Address Channel
    logic [ID_WIDTH-1:0]     awid;
    logic [ADDR_WIDTH-1:0]   awaddr;
    logic [7:0]              awlen;
    logic [2:0]              awsize;
    logic [1:0]              awburst;
    logic                    awlock;
    logic [3:0]              awcache;
    logic [2:0]              awprot;
    logic                    awvalid;
    logic                    awready;

    // Write Data Channel
    logic [DATA_WIDTH-1:0]   wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                    wlast;
    logic                    wvalid;
    logic                    wready;

    // Write Response Channel
    logic [ID_WIDTH-1:0]     bid;
    logic [1:0]              bresp;
    logic                    bvalid;
    logic                    bready;

    // Read Address Channel
    logic [ID_WIDTH-1:0]     arid;
    logic [ADDR_WIDTH-1:0]   araddr;
    logic [7:0]              arlen;
    logic [2:0]              arsize;
    logic [1:0]              arburst;
    logic                    arlock;
    logic [3:0]              arcache;
    logic [2:0]              arprot;
    logic                    arvalid;
    logic                    arready;

    // Read Data Channel
    logic [ID_WIDTH-1:0]     rid;
    logic [DATA_WIDTH-1:0]   rdata;
    logic [1:0]              rresp;
    logic                    rlast;
    logic                    rvalid;
    logic                    rready;

    // Master Modport (İşlemci / Köprü Çıkışı)
    modport master (
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid,
        output wdata, wstrb, wlast, wvalid,
        output bready,
        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid,
        output rready,
        input  awready, wready, bid, bresp, bvalid, arready, rid, rdata, rresp, rlast, rvalid
    );

    // Slave Modport (SRAM'ler / YZ Hızlandırıcı Girişi)
    modport slave (
        input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid,
        input  wdata, wstrb, wlast, wvalid,
        input  bready,
        input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid,
        input  rready,
        output awready, wready, bid, bresp, bvalid, arready, rid, rdata, rresp, rlast, rvalid
    );
endinterface


// ============================================================================
// 2. AXI4-LITE INTERFACE (UART, GPIO, I2C, Timer ve YZ Konfigürasyon İçin)
// ============================================================================
interface axil_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
);
    // Write Address Channel
    logic [ADDR_WIDTH-1:0]   awaddr;
    logic [2:0]              awprot;
    logic                    awvalid;
    logic                    awready;

    // Write Data Channel
    logic [DATA_WIDTH-1:0]   wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                    wvalid;
    logic                    wready;

    // Write Response Channel
    logic [1:0]              bresp;
    logic                    bvalid;
    logic                    bready;

    // Read Address Channel
    logic [ADDR_WIDTH-1:0]   araddr;
    logic [2:0]              arprot;
    logic                    arvalid;
    logic                    arready;

    // Read Data Channel
    logic [DATA_WIDTH-1:0]   rdata;
    logic [1:0]              rresp;
    logic                    rvalid;
    logic                    rready;

    // Master Modport (Köprü Çıkışı / Matris Girişi)
    modport master (
        output awaddr, awprot, awvalid,
        output wdata, wstrb, wvalid,
        output bready,
        output araddr, arprot, arvalid,
        output rready,
        input  awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid
    );

    // Slave Modport (Çevre Birimleri Girişi)
    modport slave (
        input  awaddr, awprot, awvalid,
        input  wdata, wstrb, wvalid,
        input  bready,
        input  araddr, arprot, arvalid,
        input  rready,
        output awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid
    );
endinterface
