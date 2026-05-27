module axi_ram #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst,
    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);

    // Hafıza dizisi
    logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemh("program.hex", mem);
    end

    // RAM her zaman hazır (s_axi_arready = 1)
    assign s_axi_arready = 1'b1;

    always_ff @(posedge clk) begin
        if (rst) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'b0;
        end else if (s_axi_arvalid) begin
            // Adres istendiği an veriyi RAM'den çekiyoruz
            s_axi_rvalid <= 1'b1;
s_axi_rdata <= mem[16'(s_axi_araddr[ADDR_WIDTH-1:2])];
        end else begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'b0;
        end
    end

endmodule
