module dummy_axi_slave (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Arayüzü
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,
    output logic [31:0] s_axi_rdata
);

    // 1. Kombinasyonel READY: İşlemci ARVALID bastığı an, slave ARREADY 1 olur.
    // Bu, el sıkışmanın anında gerçekleşmesini sağlar.
    assign s_axi_arready = (state == IDLE);
    assign s_axi_awready = 1'b1;
    assign s_axi_wready  = 1'b1;

    typedef enum logic [1:0] {IDLE, READ_BUSY, READ_DONE} state_t;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'h0;
            s_axi_bvalid <= 1'b0;
        end else begin
            // Yazma Yanıtı
            if (s_axi_awvalid && s_axi_wvalid) s_axi_bvalid <= 1'b1;
            else if (s_axi_bready) s_axi_bvalid <= 1'b0;

            // Okuma FSM
            case (state)
                IDLE: begin
                    s_axi_rvalid <= 1'b0;
                    // Eğer işlemci geçerli bir adres ile gelirse
                    if (s_axi_arvalid) begin
                        state <= READ_BUSY;
                    end
                end
                
                READ_BUSY: begin
                    s_axi_rdata  <= 32'h00000013; // RISC-V NOP komutu
                    s_axi_rvalid <= 1'b1;
                    if (s_axi_rready) begin
                        state <= READ_DONE;
                    end
                end
                
                READ_DONE: begin
                    s_axi_rvalid <= 1'b0;
                    state        <= IDLE;
                end
            endcase
        end
    end
endmodule
