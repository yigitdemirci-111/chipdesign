`timescale 1ns / 1ps

module dummy_cpu (
    input  logic        clk,
    input  logic        rst_n,

    // OBI Arayüzü (Bridge ile haberleşecek kısım)
    output logic        obi_req,
    input  logic        obi_gnt,
    output logic [31:0] obi_addr,
    output logic        obi_we,
    output logic [3:0]  obi_be,
    output logic [31:0] obi_wdata,
    input  logic        obi_rvalid,
    input  logic [31:0] obi_rdata
);

    typedef enum logic [2:0] {
        IDLE        = 3'b000,
        WRITE_RAM   = 3'b001,
        READ_RAM    = 3'b010,
        WAIT_RAM_R  = 3'b011,
        WRITE_GPIO  = 3'b100,
        DONE        = 3'b101
    } state_t;

    state_t current_state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        obi_req    = 1'b0;
        obi_addr   = 32'h0;
        obi_we     = 1'b0;
        obi_be     = 4'hF;
        obi_wdata  = 32'h0;

        case (current_state)
            IDLE: next_state = WRITE_RAM;

            WRITE_RAM: begin
                obi_addr  = 32'h0000_0100;
                obi_wdata = 32'hDEADBEEF;
                obi_we    = 1'b1;
                obi_req   = 1'b1;
                if (obi_gnt) next_state = READ_RAM;
            end

            READ_RAM: begin
                obi_addr  = 32'h0000_0100;
                obi_we    = 1'b0;
                obi_req   = 1'b1;
                if (obi_gnt) next_state = WAIT_RAM_R;
            end

            WAIT_RAM_R: begin
                if (obi_rvalid) next_state = WRITE_GPIO;
            end

            WRITE_GPIO: begin
                obi_addr  = 32'h4000_0300;
                obi_wdata = 32'h0000_0055;
                obi_we    = 1'b1;
                obi_req   = 1'b1;
                if (obi_gnt) next_state = DONE;

            end

DONE: next_state = DONE;
            
            default: next_state = IDLE;
        endcase
    end
endmodule
