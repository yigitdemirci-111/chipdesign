// INT8 Tabanlı YZ Hesaplama Birimi
module mac_unit (
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0]  weight_i,  // 8-bit INT8 Ağırlık
    input  logic [7:0]  feature_i, // 8-bit INT8 Ses Verisi
    input  logic        enable_i,  // Hesaplamayı akt
    input  logic        clear_i,   // Akümülatörü sıfırlama
    output logic [31:0] result_o   // 32-bit Sonuç
);

    logic [31:0] accum_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg <= 32'd0;
        end else if (clear_i) begin
            accum_reg <= 32'd0;
        end else if (enable_i) begin
            // Çarp ve Topla (Multiply-Accumulate)
            accum_reg <= accum_reg + (weight_i * feature_i);
        end
    end

    assign result_o = accum_reg;

endmodule