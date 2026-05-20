module my_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] din,
    input wire wr_en,
    output reg [DATA_WIDTH-1:0] dout,
    output wire full,
    output wire empty
);
    // Basit bir FIFO mantığı
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] head, tail;
    
    assign full = (tail + 1 == head);
    assign empty = (head == tail);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin head <= 0; tail <= 0; end
        else begin
            if (wr_en && !full) begin mem[tail] <= din; tail <= tail + 1; end
        end
    end
endmodule
