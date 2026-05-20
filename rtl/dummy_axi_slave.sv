module dummy_axi_slave (
    input  logic        clk,
    input  logic        rst_n,
    
    // AXI4-Lite Arayüzü Sinyalleri
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);
    // Gelen her isteğe anında "Hazırım" cevabı ver (Yusuf'un istediği deadlock-free yapı)
    assign s_axi_awready = 1'b1;
    assign s_axi_wready  = 1'b1;
    assign s_axi_arready = 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_rvalid <= 1'b0;
        end else begin
            if (s_axi_awvalid && s_axi_wvalid) s_axi_bvalid <= 1'b1;
            else if (s_axi_bready)             s_axi_bvalid <= 1'b0;

            if (s_axi_arvalid)                 s_axi_rvalid <= 1'b1;
            else if (s_axi_rready)             s_axi_rvalid <= 1'b0;
        end
    end
endmodule
