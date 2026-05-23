module axi_ram #(
    parameter int ADDR_WIDTH = 16,
    parameter int DATA_WIDTH = 32
) (
    input  logic clk,
    input  logic rst,
    
    // Sinyalleri soc_top ile uyumlu hale getiriyoruz
    input  logic [7:0]  s_axi_awid,
    input  logic [31:0] s_axi_awaddr,
    input  logic [7:0]  s_axi_awlen,
    input  logic [2:0]  s_axi_awsize,
    input  logic [1:0]  s_axi_awburst,
    input  logic        s_axi_awlock,
    input  logic [3:0]  s_axi_awcache,
    input  logic [2:0]  s_axi_awprot,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wlast,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    
    output logic [7:0]  s_axi_bid,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    
    input  logic [7:0]  s_axi_arid,
    input  logic [31:0] s_axi_araddr,
    input  logic [7:0]  s_axi_arlen,
    input  logic [2:0]  s_axi_arsize,
    input  logic [1:0]  s_axi_arburst,
    input  logic        s_axi_arlock,
    input  logic [3:0]  s_axi_arcache,
    input  logic [2:0]  s_axi_arprot,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    
    output logic [7:0]  s_axi_rid,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rlast,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);

    // Bellek
    logic [31:0] mem [0:1023];

    // Basit AXI4-Lite mantığı (Gelişmiş özellikleri görmezden geliyoruz)
    assign s_axi_awready = 1'b1;
    assign s_axi_wready  = 1'b1;
    assign s_axi_arready = 1'b1;
    assign s_axi_rvalid  = s_axi_arvalid;
    assign s_axi_bvalid  = s_axi_wvalid;
    assign s_axi_rlast   = 1'b1;
    assign s_axi_rdata   = mem[s_axi_araddr[11:2]];
    
    // Boşta kalan sinyaller
    assign s_axi_bid   = 8'd0;
    assign s_axi_rid   = 8'd0;
    assign s_axi_bresp = 2'd0;
    assign s_axi_rresp = 2'd0;

    always_ff @(posedge clk) begin
        if (s_axi_wvalid) mem[s_axi_awaddr[11:2]] <= s_axi_wdata;
    end
endmodule
