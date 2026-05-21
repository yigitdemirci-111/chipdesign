`timescale 1ns / 1ps

module obi_to_axil_bridge (
    input  logic        clk,
    input  logic        rst_n,

    // OBI Slave Arayüzü (İşlemciye Bakan Taraf)
    input  logic        obi_req_i,
    output logic        obi_gnt_o,
    input  logic [31:0] obi_addr_i,
    input  logic        obi_we_i,
    input  logic [3:0]  obi_be_i,
    input  logic [31:0] obi_wdata_i,
    output logic        obi_rvalid_o,
    output logic [31:0] obi_rdata_o,

    // AXI4-Lite Master Arayüzü (Matrise Bakan Taraf)
    output logic [31:0] axil_awaddr,
    output logic        axil_awvalid,
    input  logic        axil_awready,
    output logic [31:0] axil_wdata,
    output logic [3:0]  axil_wstrb,
    output logic        axil_wvalid,
    input  logic        axil_wready,
    input  logic [1:0]  axil_bresp,
    input  logic        axil_bvalid,
    output logic        axil_bready,
    output logic [31:0] axil_araddr,
    output logic        axil_arvalid,
    input  logic        axil_arready,
    input  logic [31:0] axil_rdata,
    input  logic [1:0]  axil_rresp,
    input  logic        axil_rvalid,
    output logic        axil_rready
);

    // Durum Makinesi
    typedef enum logic [1:0] {IDLE, WRITE_DATA, READ_DATA, BRESP} state_t;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            obi_gnt_o    <= 1'b0;
            obi_rvalid_o <= 1'b0;
            obi_rdata_o  <= 32'h0;
            axil_awaddr  <= 32'h0;
            axil_awvalid <= 1'b0;
            axil_wdata   <= 32'h0;
            axil_wstrb   <= 4'h0;
            axil_wvalid  <= 1'b0;
            axil_bready  <= 1'b0;
            axil_araddr  <= 32'h0;
            axil_arvalid <= 1'b0;
            axil_rready  <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    obi_rvalid_o <= 1'b0;
                    if (obi_req_i) begin
                        obi_gnt_o <= 1'b1; // İsteği kabul et (Grant)
                        if (obi_we_i) begin
                            axil_awaddr  <= obi_addr_i;
                            axil_awvalid <= 1'b1;
                            axil_wdata   <= obi_wdata_i;
                            axil_wstrb   <= obi_be_i;
                            axil_wvalid  <= 1'b1;
                            state        <= WRITE_DATA;
                        end else begin
                            axil_araddr  <= obi_addr_i;
                            axil_arvalid <= 1'b1;
                            state        <= READ_DATA;
                        end
                    end else begin
                        obi_gnt_o <= 1'b0;
                    end
                end

                WRITE_DATA: begin
                    obi_gnt_o <= 1'b0;
                    if (axil_awready) axil_awvalid <= 1'b0;
                    if (axil_wready)  axil_wvalid  <= 1'b0;

                    if ((axil_awready || !axil_awvalid) && (axil_wready || !axil_wvalid)) begin
                        axil_bready <= 1'b1;
                        state       <= BRESP;
                    end
                end

                BRESP: begin
                    if (axil_bvalid) begin
                        axil_bready  <= 1'b0;
                        obi_rvalid_o <= 1'b1; // İşlem bitti sinyali
                        state        <= IDLE;
                    end
                end

                READ_DATA: begin
                    obi_gnt_o <= 1'b0;
                    if (axil_arready) axil_arvalid <= 1'b0;
                    axil_rready <= 1'b1;

                    if (axil_rvalid) begin
                        axil_rready  <= 1'b0;
                        obi_rdata_o  <= axil_rdata;
                        obi_rvalid_o <= 1'b1;
                        state        <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
