module simple_ram (
    input clk,
    input [31:0] addr,
    input [31:0] wdata,
    input wen,
    output logic [31:0] rdata
);
    reg [31:0] mem [0:1023]; // 4KB RAM

    initial $readmemh("test.hex", mem);

    always @(posedge clk) begin
        if (wen) mem[addr[11:2]] <= wdata;
        rdata <= mem[addr[11:2]];
    end
endmodule
