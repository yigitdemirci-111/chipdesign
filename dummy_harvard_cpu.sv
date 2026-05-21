`timescale 1ns / 1ps

module cv32e40p_core #(
    parameter COREV_PULP = 0,
    parameter FPU = 0
) (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        pulp_clock_en_i,
    input  logic        scan_cg_en_i,
    input  logic [31:0] boot_addr_i,
    input  logic [31:0] mtvec_addr_i,
    input  logic [31:0] dm_halt_addr_i,
    input  logic [31:0] dm_exception_addr_i,

    // Instruction Port (OBI)
    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    output logic [31:0] instr_addr_o,
    input  logic        instr_rvalid_i,
    input  logic [31:0] instr_rdata_i,

    // Data Port (OBI)
    output logic        data_req_o,
    input  logic        data_gnt_i,
    output logic [31:0] data_addr_o,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    output logic [31:0] data_wdata_o,
    input  logic        data_rvalid_i,
    input  logic [31:0] data_rdata_i,

    input  logic [32:0] irq_i,
    input  logic        debug_req_i,
    input  logic        fetch_enable_i
);

    enum logic [1:0] { IDLE, WRITE_DATA, DONE } state;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state        <= IDLE;
            instr_req_o  <= 1'b0;
            instr_addr_o <= 32'h0;
            data_req_o   <= 1'b0;
            data_addr_o  <= 32'h0;
            data_we_o    <= 1'b0;
            data_be_o    <= 4'hF;
            data_wdata_o <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    // Simülasyon başlar başlamaz data portundan GPIO'ya yazma isteği gönderelim
                    data_req_o   <= 1'b1;
                    data_we_o    <= 1'b1;
                    data_addr_o  <= 32'h4000_0000; // GPIO Base adresi
                    data_wdata_o <= 32'h0000_0055; // Göndermek istediğimiz 0x55 verisi
                    state        <= WRITE_DATA;
                end

                WRITE_DATA: begin
                    // OBI protokolüne göre, grant (gnt) geldiği an adres kabul edilmiştir.
                    // İstek (req) sinyalini sıfırlayabiliriz.
                    if (data_gnt_i) begin
                        data_req_o <= 1'b0;
                    end
                    
                    // İşlem (okuma/yazma) rvalid geldiği an tamamen tamamlanmış olur.
                    if (data_rvalid_i || (data_req_o == 1'b0 && data_gnt_i)) begin
                        data_we_o <= 1'b0;
                        state     <= DONE;
                    end
                end

                DONE: begin
                    data_req_o <= 1'b0;
                    data_we_o  <= 1'b0;
                end
            endcase
        end
    end

endmodule
