`timescale 1ns / 1ps

module special_timer #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // AXI4-Lite Arayüzü
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,

    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [3:0]             s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,

    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,

    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,

    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready
);

    // Register Adresleri
    localparam TIM_PRE = 5'h00; // Prescaler
    localparam TIM_ARE = 5'h04; // Auto-Reload
    localparam TIM_CLR = 5'h08; // Clear Register (Bit 0: Clear CNT)
    localparam TIM_ENA = 5'h0C; // Enable Register (Bit 0: Enable)
    localparam TIM_MOD = 5'h10; // Mode Register (Bit 0: 1->Up, 0->Down)
    localparam TIM_CNT = 5'h14; // Timer Counter (RO)
    localparam TIM_EVN = 5'h18; // Event Register (RO)
    localparam TIM_EVC = 5'h1C; // Event Clear (Bit 0: Clear EVN)

    // AXI-Lite Yazmaçları (Konfigürasyon)
    reg [31:0] reg_pre;
    reg [31:0] reg_are;
    reg        reg_ena;
    reg        reg_mod;

    // Sayaç ve Durum Yazmaçları
    reg [31:0] reg_cnt;
    reg [31:0] reg_evn;
    
    // İç Prescaler Sayacı
    reg [31:0] pre_cnt;

    // AXI-Lite Haberleşme Sinyalleri
    reg axi_awready_reg, axi_wready_reg, axi_bvalid_reg;
    reg axi_arready_reg, axi_rvalid_reg;
    reg [31:0] axi_rdata_reg;

    assign s_axil_awready = axi_awready_reg;
    assign s_axil_wready  = axi_wready_reg;
    assign s_axil_bresp   = 2'b00;
    assign s_axil_bvalid  = axi_bvalid_reg;
    assign s_axil_arready = axi_arready_reg;
    assign s_axil_rdata   = axi_rdata_reg;
    assign s_axil_rresp   = 2'b00;
    assign s_axil_rvalid  = axi_rvalid_reg;

    // Yazılım Tarafından Tetiklenen Sinyaller (Clear İşlemleri)
    wire trigger_clr = (axi_awready_reg && s_axil_awvalid && (s_axil_awaddr[4:0] == TIM_CLR) && s_axil_wdata[0]);
    wire trigger_evc = (axi_awready_reg && s_axil_awvalid && (s_axil_awaddr[4:0] == TIM_EVC) && s_axil_wdata[0]);

    // AXI YAZMA (WRITE) İŞLEMİ (Konfigürasyon Yazmaçları)
    always @(posedge clk) begin
        if (!rst_n) begin
            axi_awready_reg <= 0;
            axi_wready_reg  <= 0; 
            axi_bvalid_reg  <= 0;
            
            reg_pre <= 32'd0; 
            reg_are <= 32'hFFFFFFFF; 
            reg_ena <= 1'b0; 
            reg_mod <= 1'b1; // Default olarak yukarı sayma
        end else begin
            axi_awready_reg <= ~axi_awready_reg && s_axil_awvalid && s_axil_wvalid;
            axi_wready_reg  <= ~axi_wready_reg && s_axil_awvalid && s_axil_wvalid;
            
            if (axi_awready_reg && s_axil_awvalid) axi_bvalid_reg <= 1;
            else if (s_axil_bready) axi_bvalid_reg <= 0;

            if (axi_awready_reg) begin
                case (s_axil_awaddr[4:0])
                    TIM_PRE: reg_pre <= s_axil_wdata;
                    TIM_ARE: reg_are <= s_axil_wdata;
                    TIM_ENA: reg_ena <= s_axil_wdata[0];
                    TIM_MOD: reg_mod <= s_axil_wdata[0];
                endcase
            end
        end
    end

    // AXI OKUMA (READ) İŞLEMİ
    always @(posedge clk) begin
        if (!rst_n) begin
            axi_arready_reg <= 0;
            axi_rvalid_reg  <= 0; 
            axi_rdata_reg   <= 32'd0;
        end else begin
            axi_arready_reg <= ~axi_arready_reg && s_axil_arvalid;
            
            if (axi_arready_reg && s_axil_arvalid) axi_rvalid_reg <= 1;
            else if (s_axil_rready) axi_rvalid_reg <= 0;

            if (axi_arready_reg) begin
                case (s_axil_araddr[4:0])
                    TIM_PRE: axi_rdata_reg <= reg_pre;
                    TIM_ARE: axi_rdata_reg <= reg_are;
                    TIM_CLR: axi_rdata_reg <= 32'd0; // Tetikleyici yazmaç, her zaman 0 okunur
                    TIM_ENA: axi_rdata_reg <= {31'd0, reg_ena};
                    TIM_MOD: axi_rdata_reg <= {31'd0, reg_mod};
                    TIM_CNT: axi_rdata_reg <= reg_cnt;
                    TIM_EVN: axi_rdata_reg <= reg_evn;
                    TIM_EVC: axi_rdata_reg <= 32'd0; // Tetikleyici yazmaç, her zaman 0 okunur
                    default: axi_rdata_reg <= 32'd0;
                endcase
            end
        end
    end

    // DONANIMSAL SAYICI (TIMER CORE) ve EVENT YÖNETİMİ
    always @(posedge clk) begin
        if (!rst_n) begin
            reg_cnt <= 32'd0;
            pre_cnt <= 32'd0;
            reg_evn <= 32'd0;
        end else begin
            // 1. Sayaç Temizleme Önceliği (TIM_CLR)
            if (trigger_clr) begin
                reg_cnt <= 32'd0;
                pre_cnt <= 32'd0;
            end 
            // 2. Sayma İşlemi (TIM_ENA aktifse)
            else if (reg_ena) begin
                if (pre_cnt >= reg_pre) begin
                    pre_cnt <= 32'd0;
                    
                    // Yukarı Sayma Modu (TIM_MOD == 1)
                    if (reg_mod == 1'b1) begin
                        if (reg_cnt >= reg_are) begin
                            reg_cnt <= 32'd0; // Auto-reload
                            reg_evn <= reg_evn + 1; // Event artır
                        end else begin
                            reg_cnt <= reg_cnt + 1;
                        end
                    end 
                    // Aşağı Sayma Modu (TIM_MOD == 0)
                    else begin
                        if (reg_cnt == 32'd0) begin
                            reg_cnt <= reg_are; // Auto-reload
                            reg_evn <= reg_evn + 1; // Yeniden yükleme anında event artır
                        end else begin
                            reg_cnt <= reg_cnt - 1;
                        end
                    end
                end else begin
                    pre_cnt <= pre_cnt + 1;
                end
            end

            if (trigger_evc) begin
                reg_evn <= 32'd0;
            end
        end
    end

endmodule