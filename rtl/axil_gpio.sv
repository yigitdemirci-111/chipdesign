module axil_gpio (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    inout  wire  [7:0]  gpio_io
);
    assign s_axi_awready = 1'b1;
    assign s_axi_wready  = 1'b1;
endmodule
