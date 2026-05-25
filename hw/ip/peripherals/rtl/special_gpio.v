`timescale 1ns / 1ps

module special_gpio #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // AXI4-Lite Slave Arayüzü
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
    input  wire                   s_axil_rready,

    // Dış Dünya GPIO Pinleri (16 Giriş, 16 Çıkış)
    input  wire [15:0]            gpio_in,
    output wire [15:0]            gpio_out
);

    // Register Adresleri
    localparam GPIO_IDR = 5'h00; // Okuma (Read-Only)
    localparam GPIO_ODR = 5'h04; // Yazma (Read/Write)

    // Çıkış (ODR) değerini tutacak hafıza
    reg [15:0] gpio_odr_reg;
    assign gpio_out = gpio_odr_reg;

    // AXI-Lite Durum Sinyalleri
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

    // YAZMA İŞLEMİ (Sadece GPIO_ODR Adresine)
    always @(posedge clk) begin
        if (!rst_n) begin
            axi_awready_reg <= 0; axi_wready_reg <= 0; axi_bvalid_reg <= 0;
            gpio_odr_reg <= 16'd0;
        end else begin
            axi_awready_reg <= ~axi_awready_reg && s_axil_awvalid && s_axil_wvalid;
            axi_wready_reg  <= ~axi_wready_reg && s_axil_awvalid && s_axil_wvalid;
            
            if (axi_awready_reg && s_axil_awvalid) axi_bvalid_reg <= 1;
            else if (s_axil_bready) axi_bvalid_reg <= 0;

            if (axi_awready_reg && s_axil_awaddr[4:0] == GPIO_ODR) begin
                // Sadece alt 16 bit (2 byte) çıkışa yönlendirilir
                if (s_axil_wstrb[0]) gpio_odr_reg[7:0]  <= s_axil_wdata[7:0];
                if (s_axil_wstrb[1]) gpio_odr_reg[15:8] <= s_axil_wdata[15:8];
            end
        end
    end

    // OKUMA İŞLEMİ (GPIO_IDR ve GPIO_ODR)
    always @(posedge clk) begin
        if (!rst_n) begin
            axi_arready_reg <= 0; axi_rvalid_reg <= 0; axi_rdata_reg <= 32'd0;
        end else begin
            axi_arready_reg <= ~axi_arready_reg && s_axil_arvalid;
            
            if (axi_arready_reg && s_axil_arvalid) axi_rvalid_reg <= 1;
            else if (s_axil_rready) axi_rvalid_reg <= 0;

            if (axi_arready_reg) begin
                case (s_axil_araddr[4:0])
                    GPIO_IDR: axi_rdata_reg <= {16'd0, gpio_in};      // Dışarıdan gelen veriyi oku
                    GPIO_ODR: axi_rdata_reg <= {16'd0, gpio_odr_reg}; // Yazdığımız çıkış verisini geri oku
                    default:  axi_rdata_reg <= 32'd0;
                endcase
            end
        end
    end
endmodule