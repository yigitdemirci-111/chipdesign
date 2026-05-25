`timescale 1ns / 1ps

module special_i2c_wrapper #(
    parameter CLK_FREQ = 50000000 // Sistem saat frekansı
)(
    input wire clk,
    input wire rst_n,

    // AXI4-LITE KAVŞAK ARAYÜZÜ (CROSSBAR'DAN GELEN)
    input  wire [4:0]  s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,

    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,

    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,

    input  wire [4:0]  s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,

    // DIŞ DÜNYA I2C PİNLERİ
    input  wire i2c_scl_i,
    output wire i2c_scl_o,
    output wire i2c_scl_t,
    input  wire i2c_sda_i,
    output wire i2c_sda_o,
    output wire i2c_sda_t
);

    // I2C Register Adresleri
    localparam NBY_REG = 5'h00; // I2C_NBY
    localparam ADR_REG = 5'h04; // I2C_ADR
    localparam RDR_REG = 5'h08; // I2C_RDR
    localparam TDR_REG = 5'h0C; // I2C_TDR
    localparam CFG_REG = 5'h10; // I2C_CFG

    // Register Tanımlamaları
    reg [2:0]  i2c_nby;    // 1-4 arası bayt sayısı
    reg [6:0]  i2c_adr;    // 7-bit slave adresi
    reg [31:0] i2c_tdr;    // Gönderilecek veri
    reg [31:0] i2c_rdr;    // Okunan veri
    
    reg cfg_tx_en;         // CFG[0]
    reg cfg_tx_done;       // CFG[1]
    reg cfg_rx_en;         // CFG[2]
    reg cfg_rx_done;       // CFG[3]

    // ALEX'İN ÇEKİRDEĞİNE GİDEN KABLOLAR
    reg  [6:0] cmd_address;
    reg        cmd_start;
    reg        cmd_read;
    reg        cmd_write;
    reg        cmd_stop;
    reg        cmd_valid;
    wire       cmd_ready;

    reg  [7:0] data_in;
    reg        data_in_valid;
    wire       data_in_ready;
    reg        data_in_last;

    wire [7:0] data_out;
    wire       data_out_valid;
    reg        data_out_ready;
    wire       data_out_last;
    
    wire busy, bus_control, bus_active, missed_ack;

    // Prescaler değeri
    localparam PRESCALE_VAL = CLK_FREQ / (400000 * 4);

    i2c_master u_i2c_core (
        .clk(clk),
        .rst(~rst_n),
        
        // Komut Arayüzü
        .s_axis_cmd_address(cmd_address),
        .s_axis_cmd_start(cmd_start),
        .s_axis_cmd_read(cmd_read),
        .s_axis_cmd_write(cmd_write),
        .s_axis_cmd_write_multiple(1'b0), // Kullanılmıyor
        .s_axis_cmd_stop(cmd_stop),
        .s_axis_cmd_valid(cmd_valid),
        .s_axis_cmd_ready(cmd_ready),
        
        // TX Veri Arayüzü
        .s_axis_data_tdata(data_in),
        .s_axis_data_tvalid(data_in_valid),
        .s_axis_data_tready(data_in_ready),
        .s_axis_data_tlast(data_in_last),
        
        // RX Veri Arayüzü
        .m_axis_data_tdata(data_out),
        .m_axis_data_tvalid(data_out_valid),
        .m_axis_data_tready(data_out_ready),
        .m_axis_data_tlast(data_out_last),
        
        // Fiziksel Pinler
        .scl_i(i2c_scl_i), .scl_o(i2c_scl_o), .scl_t(i2c_scl_t),
        .sda_i(i2c_sda_i), .sda_o(i2c_sda_o), .sda_t(i2c_sda_t),
        
        // Durum
        .busy(busy), .bus_control(bus_control), .bus_active(bus_active), .missed_ack(missed_ack),
        .prescale(PRESCALE_VAL[15:0]),
        .stop_on_idle(1'b0)
    );

    // AXI-LITE HABERLEŞME
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

    // AXI Yazma ve Okuma Sinyalleri
    always @(posedge clk) begin
        if (!rst_n) begin
            axi_awready_reg <= 0; axi_wready_reg <= 0; axi_bvalid_reg <= 0;
            axi_arready_reg <= 0; axi_rvalid_reg <= 0;
        end else begin
            // Write
            axi_awready_reg <= ~axi_awready_reg && s_axil_awvalid && s_axil_wvalid;
            axi_wready_reg  <= ~axi_wready_reg && s_axil_awvalid && s_axil_wvalid;
            if (axi_awready_reg && s_axil_awvalid) axi_bvalid_reg <= 1;
            else if (s_axil_bready) axi_bvalid_reg <= 0;
            
            // Read
            axi_arready_reg <= ~axi_arready_reg && s_axil_arvalid;
            if (axi_arready_reg && s_axil_arvalid) axi_rvalid_reg <= 1;
            else if (s_axil_rready) axi_rvalid_reg <= 0;
        end
    end

    // Yazmaçlara (Register) Veri Yazma
    always @(posedge clk) begin
        if (!rst_n) begin
            i2c_nby <= 3'd1; i2c_adr <= 7'd0; i2c_tdr <= 32'd0;
            cfg_tx_en <= 0; cfg_rx_en <= 0;
            cfg_tx_done <= 0; cfg_rx_done <= 0;
        end else begin
            // Yazılım 0 yazarsa bayrakları temizle
            if (s_axil_wvalid && s_axil_awvalid && s_axil_awaddr == CFG_REG) begin
                if (s_axil_wdata[1] == 1'b0) cfg_tx_done <= 0;
                if (s_axil_wdata[3] == 1'b0) cfg_rx_done <= 0;
            end
        
            if (axi_awready_reg) begin
                case(s_axil_awaddr)
                    NBY_REG: begin
                    if (s_axil_wdata == 32'd0) begin
                        i2c_nby <= 3'd1;
                    end else if (s_axil_wdata > 32'd4) begin
                        i2c_nby <= 3'd4;
                    end else begin
                        i2c_nby <= s_axil_wdata[2:0];
                    end
                end
                    ADR_REG: i2c_adr <= s_axil_wdata[6:0];
                    TDR_REG: i2c_tdr <= s_axil_wdata;
                    CFG_REG: begin
                        // Donanımsal Koruma: İkisi birden 1 ise reddet
                        if (s_axil_wdata[0] && s_axil_wdata[2]) begin
                            cfg_tx_en <= 0; cfg_rx_en <= 0;
                        end else begin
                            cfg_tx_en <= s_axil_wdata[0];
                            cfg_rx_en <= s_axil_wdata[2];
                        end
                    end
                endcase
            end
            
            // State Machine işlemi bitirdiğinde En'leri kapat, Done'ları yak
            if (state == TX_DONE) begin cfg_tx_en <= 0; cfg_tx_done <= 1; end
            if (state == RX_DONE) begin cfg_rx_en <= 0; cfg_rx_done <= 1; end
        end
    end

    // Yazmaçlardan (Register) Veri Okuma
    always @(posedge clk) begin
        if (axi_arready_reg) begin
            case(s_axil_araddr)
                NBY_REG: axi_rdata_reg <= {29'd0, i2c_nby};
                ADR_REG: axi_rdata_reg <= {25'd0, i2c_adr};
                RDR_REG: axi_rdata_reg <= i2c_rdr;
                CFG_REG: axi_rdata_reg <= {28'd0, cfg_rx_done, cfg_rx_en, cfg_tx_done, cfg_tx_en};
                default: axi_rdata_reg <= 32'd0;
            endcase
        end
    end

    // FINITE STATE MACHINE
    localparam IDLE = 0, TX_CMD = 1, TX_DATA = 2, TX_DONE = 3;
    localparam RX_CMD = 4, RX_WAIT = 5, RX_DONE = 6;
    
    reg [2:0] state;
    reg [2:0] byte_cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            byte_cnt <= 0;
            cmd_valid <= 0; data_in_valid <= 0; data_out_ready <= 0;
            i2c_rdr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    byte_cnt <= 0;
                    cmd_valid <= 0; data_in_valid <= 0; data_out_ready <= 0;
                    if (cfg_tx_en) state <= TX_CMD;
                    else if (cfg_rx_en) state <= RX_CMD;
                end
                
                // Transmit
                TX_CMD: begin
                    cmd_address <= i2c_adr;
                    cmd_start <= (byte_cnt == 0); // Sadece ilk baytta Start
                    cmd_stop <= (byte_cnt == i2c_nby - 1); // Sadece son baytta Stop
                    cmd_write <= 1; cmd_read <= 0;
                    cmd_valid <= 1;
                    if (cmd_ready && cmd_valid) begin
                        cmd_valid <= 0;
                        state <= TX_DATA;
                    end
                end
                TX_DATA: begin
                    // Byte sayacına göre 32-bit TDR'nin ilgili 8-bitini yolla
                    case(byte_cnt)
                        0: data_in <= i2c_tdr[7:0];
                        1: data_in <= i2c_tdr[15:8];
                        2: data_in <= i2c_tdr[23:16];
                        3: data_in <= i2c_tdr[31:24];
                    endcase
                    data_in_last <= (byte_cnt == i2c_nby - 1);
                    data_in_valid <= 1;
                    if (data_in_ready && data_in_valid) begin
                        data_in_valid <= 0;
                        byte_cnt <= byte_cnt + 1;
                        if (byte_cnt == i2c_nby - 1) state <= TX_DONE;
                        else state <= TX_CMD; // Sıradaki bayt için tekrar CMD yolla
                    end
                end
                TX_DONE: begin
                    if (!cfg_tx_en) state <= IDLE; // İşlemci cfg'yi 0'layana kadar bekle
                end

                // RECEIVE
                RX_CMD: begin
                    cmd_address <= i2c_adr;
                    cmd_start <= (byte_cnt == 0);
                    cmd_stop <= (byte_cnt == i2c_nby - 1);
                    cmd_write <= 0; cmd_read <= 1;
                    cmd_valid <= 1;
                    if (cmd_ready && cmd_valid) begin
                        cmd_valid <= 0;
                        state <= RX_WAIT;
                    end
                end
                RX_WAIT: begin
                    data_out_ready <= 1;
                    if (data_out_valid && data_out_ready) begin
                        data_out_ready <= 0;
                        // Gelen 8-bit veriyi RDR'nin doğru yerine yerleştir
                        case(byte_cnt)
                            0: i2c_rdr[7:0]   <= data_out;
                            1: i2c_rdr[15:8]  <= data_out;
                            2: i2c_rdr[23:16] <= data_out;
                            3: i2c_rdr[31:24] <= data_out;
                        endcase
                        byte_cnt <= byte_cnt + 1;
                        if (byte_cnt == i2c_nby - 1) state <= RX_DONE;
                        else state <= RX_CMD;
                    end
                end
                RX_DONE: begin
                    if (!cfg_rx_en) state <= IDLE;
                end
            endcase
        end
    end

endmodule