module dummy_slave (
    input  logic clk,
    input  logic rst_n,
    input  logic valid,
    output logic ready
);
    assign ready = valid; // Gelen her isteği anında kabul et
endmodule
