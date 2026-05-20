module dummy_cpu (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite Yazma (Write) Kanalları
    output logic [31:0] m_axi_awaddr,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,

    output logic [31:0] m_axi_wdata,
    output logic        m_axi_wvalid,
    input  logic        m_axi_wready,

    // AXI4-Lite Okuma (Read) Kanalları
    output logic [31:0] m_axi_araddr,
    output logic        m_axi_arvalid,
    input  logic        m_axi_arready,

    input  logic [31:0] m_axi_rdata,
    input  logic        m_axi_rvalid,
    output logic        m_axi_rready
);

    // Durum Makinesi (State Machine) Tanımları
    typedef enum logic [2:0] {
        IDLE   = 3'b000,
        WRITE  = 3'b001,
        WAIT_W = 3'b010,
        READ   = 3'b011,
        WAIT_R = 3'b100,
        DONE   = 3'b101
    } state_t;

    state_t state, next_state;

    // Ardışıl Mantık (Saat Vuruşlarında Durum Güncelleme)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Kombinasyonel Mantık (Sonraki Durum ve Sinyal Çıkışları)
    always_comb begin
        // Varsayılan Değerler (Latch oluşmasını engeller)
        next_state    = state;
        m_axi_awvalid = 0;
        m_axi_wvalid  = 0;
        m_axi_arvalid = 0;
        m_axi_rready  = 0;

        // Sabit Adres ve Veri (0x1000 adresine DEADBEEF yazıp okuyacağız)
        m_axi_awaddr  = 32'h0000_1000;
        m_axi_wdata   = 32'hDEAD_BEEF;
        m_axi_araddr  = 32'h0000_1000;

        case (state)
            IDLE: begin
                next_state = WRITE; // Resetten çıkınca yazmaya başla
            end

            WRITE: begin
                m_axi_awvalid = 1;
                m_axi_wvalid  = 1;
                // RAM hem adresi hem veriyi aldığını onayladığında geç
                if (m_axi_awready && m_axi_wready) begin
                    next_state = WAIT_W;
                end
            end
            
            WAIT_W: begin
                // Yazma sonrası bir cycle nefes al ve okumaya geç
                next_state = READ;
            end

            READ: begin
                m_axi_arvalid = 1; // Okuma adresi geçerli
                if (m_axi_arready) begin
                    next_state = WAIT_R; // RAM adresi aldı, veriyi bekle
                end
            end
            
            WAIT_R: begin
                m_axi_rready = 1; // İşlemci veriyi almaya hazır
                if (m_axi_rvalid) begin
                    next_state = DONE; // Veri geldi, işlemi bitir
                end
            end

            DONE: begin
                // Tüm işlemler başarıyla bitti, burada uyu
                next_state = DONE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
