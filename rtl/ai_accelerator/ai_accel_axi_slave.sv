`timescale 1ns / 1ps

//  AXI-Lite Protokol Haritası
module ai_accel_axi_slave #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4   // 4-bit adres = 16 Byte (4 adet 32-bit Yazmaç)
)(
    input  logic S_AXI_ACLK,
    input  logic S_AXI_ARESETN,

    // AXI-Lite Yazma Kanalları
    input  logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  logic S_AXI_AWVALID,
    output logic S_AXI_AWREADY,
    input  logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  logic S_AXI_WVALID,
    output logic S_AXI_WREADY,
    output logic [1:0] S_AXI_BRESP,
    output logic S_AXI_BVALID,
    input  logic S_AXI_BREADY,

    // AXI-Lite Okuma Kanalları
    input  logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  logic S_AXI_ARVALID,
    output logic S_AXI_ARREADY,
    output logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output logic [1:0] S_AXI_RRESP,
    output logic S_AXI_RVALID,
    input  logic S_AXI_RREADY,

    // --- YZ Çekirdeğine Giden Kontrol Sinyalleri ---
    output logic        start_mac_o,      // Yazmaç 0x0
    input  logic        mac_busy_i,       // Yazmaç 0x4
output logic [31:0] feature_addr_o,   // Yazmaç 0x8
    output logic [31:0] weight_addr_o,    // Yazmaç 0xC
    input  logic [31:0] mac_result_i      // YENİ: MAC'ten gelen sonuç);

    // --- YAZMAÇLAR (Registers) ---
    logic [31:0] slv_reg0; // CTRL: [0] = Start
    logic [31:0] slv_reg1; // STATUS: [0] = Busy
    logic [31:0] slv_reg2; // FEATURE_RAM_ADDR
    logic [31:0] slv_reg3; // WEIGHT_RAM_ADDR





    // --- AXI YAZMA MANTIĞI ---
    assign S_AXI_AWREADY = 1'b1; // Her zaman yazmaya hazır (Basitleştirilmiş)
    assign S_AXI_WREADY  = 1'b1;
    assign S_AXI_BRESP   = 2'b00; // OKAY yanıtı

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            slv_reg0 <= 0; slv_reg2 <= 0; slv_reg3 <= 0;
            S_AXI_BVALID <= 0;
        end else begin
            if (S_AXI_AWVALID && S_AXI_WVALID) begin
                case (S_AXI_AWADDR)
                    4'h0: slv_reg0 <= S_AXI_WDATA;
                    4'h8: slv_reg2 <= S_AXI_WDATA;
                    4'hC: slv_reg3 <= S_AXI_WDATA;
                endcase
                S_AXI_BVALID <= 1'b1;
            end else if (S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end
            
            // Start bit'i bir kez okunduktan sonra temizlensin (Auto-clear)
            if (start_mac_o) slv_reg0[0] <= 1'b0;
        end
    end

    // --- AXI OKUMA MANTIĞI ---
    assign S_AXI_ARREADY = 1'b1;
    assign S_AXI_RRESP   = 2'b00; // OKAY

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID <= 0;
            S_AXI_RDATA  <= 0;
        end else if (S_AXI_ARVALID && !S_AXI_RVALID) begin
            S_AXI_RVALID <= 1'b1;
            case (S_AXI_ARADDR)
                4'h0: S_AXI_RDATA <= slv_reg0;
                4'h4: S_AXI_RDATA <= {31'b0, mac_busy_i}; // Busy bilgisini oku
                4'h8: S_AXI_RDATA <= slv_reg2;
                4'hC: S_AXI_RDATA <= slv_reg3;
                4'h10: S_AXI_RDATA <= mac_result_i; // YENİ: CPU 0x10 adresinden sonucu okuyacak
                default: S_AXI_RDATA <= 32'hDEADBEEF;
            endcase
        end else if (S_AXI_RREADY) begin
            S_AXI_RVALID <= 1'b0;
        end
    end

    // Dışarıya Aktarılan Sinyaller
    assign start_mac_o    = slv_reg0[0];
    assign feature_addr_o = slv_reg2;
    assign weight_addr_o  = slv_reg3;

endmodule