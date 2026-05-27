`timescale 1ns / 1ps

/*
 * TEKNOFEST 2026 - Dummy AXI-Lite Slave
 * Amacı: İşlemciden (CV32E40P) veya Matristen gelen okuma/yazma isteklerini (Valid) alıp,
 * sistemi sonsuz döngüye (deadlock) sokmadan anında onaylamak (Ready) ve 
 * sahte veri dönmektir. Çevre birimleri (UART, Timer vs.) hazır olana kadar 
 * interconnect testlerinde kullanılacaktır.
 */
module dummy_axil_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // AXI-Lite Yazma Adres Kanalı
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,

    // AXI-Lite Yazma Veri Kanalı
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [DATA_WIDTH/8-1:0]s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,

    // AXI-Lite Yazma Yanıt Kanalı (B Channel)
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,

    // AXI-Lite Okuma Adres Kanalı
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,

    // AXI-Lite Okuma Veri Kanalı
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready
);

    // Deadlock'ı önlemek için hazır sinyallerini sürekli 1'de (Aktif) tutuyoruz.
    // Gerçek bir modülde bunlar FSM (State Machine) ile kontrol edilir.
    assign s_axil_awready = 1'b1;
    assign s_axil_wready  = 1'b1;
    assign s_axil_arready = 1'b1;

    // --- Yazma Onayı (Write Response) ---
    // AWVALID ve WVALID geldiğinde OKAY (00) durumu dönüyoruz.
    reg bvalid_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_reg <= 1'b0;
        end else begin
            if (s_axil_awvalid && s_axil_wvalid)
                bvalid_reg <= 1'b1;
            else if (s_axil_bready)
                bvalid_reg <= 1'b0;
        end
    end
    assign s_axil_bvalid = bvalid_reg;
    assign s_axil_bresp  = 2'b00; // OKAY yanıtı

    // --- Okuma Onayı (Read Response) ---
    // ARVALID geldiğinde sahte veri ile onay dönüyoruz.
    reg rvalid_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
        end else begin
            if (s_axil_arvalid)
                rvalid_reg <= 1'b1;
            else if (s_axil_rready)
                rvalid_reg <= 1'b0;
        end
    end
    
    assign s_axil_rvalid = rvalid_reg;
    // Sahte okuma verisi: Hexadecimal "DEADBEEF" döner. 
    // İşlemci UART'ı veya Timer'ı okumaya çalıştığında bu veriyi görecektir.
    assign s_axil_rdata  = 32'hDEADBEEF; 
    assign s_axil_rresp  = 2'b00; // OKAY yanıtı

endmodule
