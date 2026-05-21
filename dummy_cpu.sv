`timescale 1ns / 1ps

module dummy_cpu (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] m_axi_awaddr,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,
    output logic [31:0] m_axi_wdata,
    output logic        m_axi_wvalid,
    input  logic        m_axi_wready,
    output logic [31:0] m_axi_araddr,
    output logic        m_axi_arvalid,
    input  logic        m_axi_arready,
    input  logic [31:0] m_axi_rdata,
    input  logic        m_axi_rvalid,
    output logic        m_axi_rready
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
    logic aw_done, w_done;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            aw_done       <= 1'b0;
            w_done        <= 1'b0;
        end else begin
            current_state <= next_state;
            if ((current_state == WRITE_RAM || current_state == WRITE_GPIO) && m_axi_awvalid && m_axi_awready) 
                aw_done <= 1'b1;
            if ((current_state == WRITE_RAM || current_state == WRITE_GPIO) && m_axi_wvalid && m_axi_wready)   
                w_done  <= 1'b1;
            if (next_state != WRITE_RAM && next_state != WRITE_GPIO) begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
            end
        end
    end

    always_comb begin
        next_state    = current_state;
        m_axi_awaddr  = 32'h0;
        m_axi_awvalid = 1'b0;
        m_axi_wdata   = 32'h0;
        m_axi_wvalid  = 1'b0;
        m_axi_araddr  = 32'h0;
        m_axi_arvalid = 1'b0;
        m_axi_rready  = 1'b0;

        case (current_state)
            IDLE: next_state = WRITE_RAM;
            WRITE_RAM: begin
                m_axi_awaddr  = 32'h0000_0100;
                m_axi_wdata   = 32'hDEADBEEF;
                m_axi_awvalid = !aw_done;
                m_axi_wvalid  = !w_done;
                if ((aw_done || m_axi_awready) && (w_done || m_axi_wready))
                    next_state = READ_RAM;
            end
            READ_RAM: begin
                m_axi_araddr  = 32'h0000_0100;
                m_axi_arvalid = 1'b1;
                if (m_axi_arready)
                    next_state = WAIT_RAM_R;
            end
            WAIT_RAM_R: begin
                m_axi_rready = 1'b1;
                if (m_axi_rvalid)
                    next_state = WRITE_GPIO;
            end
            WRITE_GPIO: begin
                m_axi_awaddr  = 32'h4000_0300;
                m_axi_wdata   = 32'h0000_0055;
                m_axi_awvalid = !aw_done;
                m_axi_wvalid  = !w_done;
                if ((aw_done || m_axi_awready) && (w_done || m_axi_wready))
                    next_state = DONE;
            end
            DONE: next_state = DONE;
        endcase
    end
endmodule
