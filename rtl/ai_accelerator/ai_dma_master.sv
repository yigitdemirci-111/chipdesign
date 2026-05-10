// Darboğaz için dahili veri taşıma birimi (DMA) - DİZİ OKUMA GÜNCELLEMESİ
module ai_dma_master #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    // Kontrol 
    input  logic [ADDR_WIDTH-1:0] start_addr_i,
    input  logic                  start_fsm_i,
    output logic                  dma_busy_o,

    // AXI Master Okuma Kanalları
    output logic [ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output logic                  M_AXI_ARVALID,
    input  logic                  M_AXI_ARREADY,

    input  logic [DATA_WIDTH-1:0] M_AXI_RDATA,
    input  logic                  M_AXI_RVALID,
    output logic                  M_AXI_RREADY,

    // MAC Ünitesine Veri 
    output logic [7:0]            data_to_mac_o,
    output logic                  data_valid_o
);

    // FSM ve Sayaçlar
    typedef enum logic [1:0] {IDLE, SEND_ADDR, WAIT_DATA, DONE} state_t;
    state_t current_state, next_state;
    
    logic [ADDR_WIDTH-1:0] current_addr;
    logic [3:0] read_counter; // 16 adet INT8 veri okuyacak sayaç

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            current_addr <= 0;
            read_counter <= 0;
        end else begin
            current_state <= next_state;
            
            // Adres Sayacı Mantığı (Her başarılı okumada adresi 4 byte artır)
            if (current_state == IDLE && start_fsm_i) begin
                current_addr <= start_addr_i;
                read_counter <= 0;
            end else if (current_state == WAIT_DATA && M_AXI_RVALID) begin
                current_addr <= current_addr + 4; 
                read_counter <= read_counter + 1;
            end
        end
    end

    always_comb begin
        next_state = current_state;
        M_AXI_ARVALID = 0;
        M_AXI_RREADY  = 0;
        dma_busy_o    = 0;

        case (current_state)
            IDLE: begin
                if (start_fsm_i) next_state = SEND_ADDR;
            end
            SEND_ADDR: begin
                dma_busy_o = 1;
                M_AXI_ARVALID = 1;
                if (M_AXI_ARREADY) next_state = WAIT_DATA;
            end
            WAIT_DATA: begin
                dma_busy_o = 1;
                M_AXI_RREADY = 1;
                if (M_AXI_RVALID) begin
                    if (read_counter == 4'd15) next_state = DONE; // 16 veri okunduysa bitir
                    else next_state = SEND_ADDR; // Devam et
                end
            end
            DONE: begin
                next_state = IDLE; // İşlem bitti, beklemeye dön
            end
        endcase
    end

    assign M_AXI_ARADDR  = current_addr;
    assign data_to_mac_o = M_AXI_RDATA[7:0]; 
    assign data_valid_o  = (current_state == WAIT_DATA && M_AXI_RVALID);

endmodule