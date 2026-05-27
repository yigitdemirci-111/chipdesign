// axil_dummy_slave.sv
`timescale 1ns / 1ps

module axil_dummy_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // AXI4-Lite Slave Arayüzü Wires
    input  logic [ADDR_WIDTH-1:0]   s_axil_awaddr,
    input  logic [2:0]              s_axil_awprot,
    input  logic                    s_axil_awvalid,
    output logic                    s_axil_awready,
    input  logic [DATA_WIDTH-1:0]   s_axil_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] s_axil_wstrb,
    input  logic                    s_axil_wvalid,
    output logic                    s_axil_wready,
    output logic [1:0]              s_axil_bresp,
    output logic                    s_axil_bvalid,
    input  logic                    s_axil_bready,
    input  logic [ADDR_WIDTH-1:0]   s_axil_araddr,
    input  logic [2:0]              s_axil_arprot,
    input  logic                    s_axil_arvalid,
    output logic                    s_axil_arready,
    output logic [DATA_WIDTH-1:0]   s_axil_rdata,
    output logic [1:0]              s_axil_rresp,
    output logic                    s_axil_rvalid,
    input  logic                    s_axil_rready
);

    // ------------------------------------------------------------------------
    // Yazma Kanalı Mantığı (Write Channel Handshake)
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_bvalid <= 1'b0;
        end else begin
            // Adres ve veri valid olduğunda ve henüz bvalid üretilmemişken el sıkış
            if (s_axil_awvalid && s_axil_wvalid && !s_axil_bvalid) begin
                s_axil_bvalid <= 1'b1; 
            end else if (s_axil_bready) begin
                s_axil_bvalid <= 1'b0; // Master yanıtı aldı, sıfırla
            end
        end
    end
    
    // Geçici olarak istek geldiği anda hazır olduğunu bildiriyoruz
    assign s_axil_awready = s_axil_awvalid && s_axil_wvalid && !s_axil_bvalid;
    assign s_axil_wready  = s_axil_awvalid && s_axil_wvalid && !s_axil_bvalid;
    assign s_axil_bresp   = 2'b00; // OKAY yanıtı

    // ------------------------------------------------------------------------
    // Okuma Kanalı Mantığı (Read Channel Handshake)
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata  <= 32'h0;
        end else begin
            if (s_axil_arvalid && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                // Simülasyonda okuma yapıldığını anlamak için anlamlı sahte bir veri dönüyoruz
                s_axil_rdata  <= 32'hDEADBEEF; 
            end else if (s_axil_rready) begin
                s_axil_rvalid <= 1'b0; // Master veriyi çekti
            end
        end
    end
    
    assign s_axil_arready = !s_axil_rvalid;
    assign s_axil_rresp   = 2'b00; // OKAY yanıtı

endmodule
