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
logic awready_q;
logic wready_q;

assign s_axi_awready = awready_q;
assign s_axi_wready  = wready_q;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awready_q <= 1'b0;
        wready_q  <= 1'b0;
    end else begin
        awready_q <= s_axi_awvalid && s_axi_wvalid;
        wready_q  <= s_axi_awvalid && s_axi_wvalid;
    end
end
endmodule
