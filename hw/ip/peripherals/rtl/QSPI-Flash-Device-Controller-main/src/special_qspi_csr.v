`timescale 1ns / 1ps

module special_qspi_csr (
  input  wire        pclk,
  input  wire        presetn,

  // AXI-LITE ARAYÜZÜ
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
  output reg  [31:0] s_axil_rdata,
  output wire [1:0]  s_axil_rresp,
  output reg         s_axil_rvalid,
  input  wire        s_axil_rready,

  // IP'NIN ALT MOTORLARINA GİDEN SİNYALLER
  output wire enable_o, xip_en_o, quad_en_o, cpol_o, cpha_o, lsb_first_o, cmd_start_o, dma_en_o, hold_en_o, wp_en_o,
  output wire [2:0] clk_div_o,
  output wire cs_auto_o,
  output wire [1:0] cs_level_o, cs_delay_o,
  output wire [1:0] xip_addr_bytes_o, xip_data_lanes_o,
  output wire [3:0] xip_dummy_cycles_o,
  output wire xip_cont_read_o, xip_mode_en_o, xip_write_en_o,
  output wire [7:0] xip_read_op_o, xip_mode_bits_o, xip_write_op_o,
  output wire [1:0] cmd_lanes_o, addr_lanes_o, data_lanes_o, addr_bytes_o,
  output wire mode_en_cfg_o,
  output wire [3:0] dummy_cycles_o,
  output wire is_write_o,
  output wire [7:0] opcode_o, mode_bits_o,
  output wire [31:0] cmd_addr_o, cmd_len_o,
  output wire [7:0] extra_dummy_o,
  output wire [3:0] burst_size_o,
  output wire dma_dir_o, incr_addr_o,
  output wire [31:0] dma_addr_o, dma_len_o,
  output wire [31:0] fifo_tx_data_o,
  output wire fifo_tx_we_o,
  input  wire [31:0] fifo_rx_data_i,
  output wire fifo_rx_re_o,
  output wire [4:0] int_en_o,
  output reg flush_tx_o,
  output reg flush_rx_o,

  // Durum Girdileri
  input  wire cmd_done_set_i, dma_done_set_i, err_set_i, fifo_tx_empty_set_i, fifo_rx_full_set_i,
  input  wire busy_i, xip_active_i, cmd_done_i, dma_done_i,
  input  wire [3:0] tx_level_i, rx_level_i,
  input  wire tx_empty_i, rx_full_i, timeout_i, overrun_i, underrun_i, axi_err_i,
  
  // Ekstra durumlar
  input  wire tx_full_i, rx_empty_i,
  output wire irq
);

  // QSPI Adresleri
  localparam CCR_REG = 5'h00;
  localparam ADR_REG = 5'h04;
  localparam DR_REG  = 5'h08;
  localparam STA_REG = 5'h0C;
  localparam FCR_REG = 5'h10;

  reg [31:0] qspi_ccr;
  reg [23:0] qspi_adr;
  reg        qspi_done_flag;
  reg [3:0]  fifo_error_flag;

  reg axi_awready_reg, axi_wready_reg, axi_bvalid_reg;
  reg axi_arready_reg;

  assign s_axil_awready = axi_awready_reg;
  assign s_axil_wready  = axi_wready_reg;
  assign s_axil_bresp   = 2'b00;
  assign s_axil_bvalid  = axi_bvalid_reg;
  assign s_axil_arready = axi_arready_reg;
  assign s_axil_rresp   = 2'b00;

// -------------------------------------------------------------------------
  // BLOK 1: AXI YAZMA EL SIKIŞMA (HANDSHAKE) - EKSİK OLAN KISIM
  // -------------------------------------------------------------------------
  always @(posedge pclk) begin
      if (!presetn) begin
          axi_awready_reg <= 0;
          axi_wready_reg <= 0; 
          axi_bvalid_reg <= 0;
      end else begin
          axi_awready_reg <= ~axi_awready_reg && s_axil_awvalid && s_axil_wvalid;
          axi_wready_reg  <= ~axi_wready_reg && s_axil_awvalid && s_axil_wvalid;
          
          if (axi_awready_reg && s_axil_awvalid) 
              axi_bvalid_reg <= 1;
          else if (s_axil_bready) 
              axi_bvalid_reg <= 0;
      end
  end

  reg cmd_start_pulse;

  // -------------------------------------------------------------------------
  // BLOK 2: YAZMAÇ (REGISTER) GÜNCELLEME BLOĞU - TEKE DÜŞÜRÜLMÜŞ HALİ
  // -------------------------------------------------------------------------
  always @(posedge pclk) begin
      if (!presetn) begin
          qspi_ccr <= 0;
          qspi_adr <= 0; 
          qspi_done_flag <= 0;
          fifo_error_flag <= 0; 
          cmd_start_pulse <= 0;
          flush_tx_o <= 0; 
          flush_rx_o <= 0;
      end else begin
          cmd_start_pulse <= 0;
          flush_tx_o <= 0;
          flush_rx_o <= 0; 

          if (cmd_done_set_i) qspi_done_flag <= 1;
          
          // Donanım FIFO hatalarını yakalarsa bayrakları SET et
          if (fifo_tx_we_o && tx_full_i) fifo_error_flag <= 4'b0010;

          if (axi_awready_reg) begin
              case (s_axil_awaddr)
                  CCR_REG: begin
                      qspi_ccr <= s_axil_wdata;
                      if (s_axil_wdata[31]) qspi_done_flag <= 0;
                      cmd_start_pulse <= 1;
                  end
                  ADR_REG: qspi_adr <= s_axil_wdata[23:0];
                  
                  // W1C: İlgili bitlere 1 yazıldığında hataları temizle
                  STA_REG: begin
                      if (s_axil_wdata[8]) fifo_error_flag <= 4'd0; 
                      if (s_axil_wdata[9]) fifo_error_flag <= 4'd0;
                  end
                  
                  // FIFO Flush tetikleyicileri
                  FCR_REG: begin
                      if (s_axil_wdata[0]) flush_rx_o <= 1'b1;
                      if (s_axil_wdata[1]) flush_tx_o <= 1'b1;
                  end
              endcase
          end
      end
  end   
  
  // Atamalar
  assign cmd_start_o = cmd_start_pulse;
  assign fifo_tx_we_o = (axi_awready_reg && s_axil_awaddr == DR_REG);
  assign fifo_tx_data_o = s_axil_wdata;

  // AXI Okuma İşlemi
  reg [1:0] rvalid_wait;
  reg fifo_rx_re_pulse;
  assign fifo_rx_re_o = fifo_rx_re_pulse;

  always @(posedge pclk) begin
      if (!presetn) begin
          axi_arready_reg <= 0;
          s_axil_rvalid <= 0; 
          rvalid_wait <= 2'b00;
          fifo_rx_re_pulse <= 0;
      end else begin
          fifo_rx_re_pulse <= 0;
          axi_arready_reg <= ~axi_arready_reg && s_axil_arvalid && ~s_axil_rvalid && (rvalid_wait == 2'b00);

          if (axi_arready_reg) begin
              if (s_axil_araddr == DR_REG) begin
                  if (rx_empty_i) fifo_error_flag <= 4'b0001;
                  fifo_rx_re_pulse <= 1; // 1. VURUŞ: FIFO'dan veriyi iste
                  rvalid_wait <= 2'b01;
              end else begin
                  s_axil_rvalid <= 1;
              end
          end

          if (rvalid_wait == 2'b01) begin
              // 2. VURUŞ: FIFO depodan veriyi çıkar
              rvalid_wait <= 2'b10; 
          end else if (rvalid_wait == 2'b10) begin
              // 3. VURUŞ: Veri alınmak için beklemede
              rvalid_wait <= 2'b00;
              s_axil_rvalid <= 1;
              s_axil_rdata <= fifo_rx_data_i; // Hazırdaki veriyi bas
          end else if (axi_arready_reg) begin
              case (s_axil_araddr)
                  CCR_REG: s_axil_rdata <= qspi_ccr;
                  ADR_REG: s_axil_rdata <= {8'd0, qspi_adr};
                  STA_REG: s_axil_rdata <= {20'd0, fifo_error_flag, tx_empty_i, tx_full_i, rx_empty_i, rx_full_i, 2'd0, busy_i, qspi_done_flag};
                  default: s_axil_rdata <= 0;
              endcase
          end

          if (s_axil_rready && s_axil_rvalid) s_axil_rvalid <= 0;
      end
  end

  // Bu wrapper'ın QSPI ana IP'si ile bağlantısını sağlıyorum
  assign enable_o = 1'b1;
  assign xip_en_o = 1'b0; // Bootloader CMD üzerinden okuyacak
  assign quad_en_o = 1'b1;
  assign cpol_o = 1'b0; assign cpha_o = 1'b0; // SPI Mode 0
  assign lsb_first_o = 1'b0;
  assign cs_auto_o = 1'b1;
  assign dma_en_o = 1'b0;

  assign opcode_o = qspi_ccr[7:0];
  assign is_write_o = qspi_ccr[10];
  assign dummy_cycles_o = qspi_ccr[14:11]; // Max 15 dummy cycle
  assign cmd_len_o = qspi_ccr[23:16] + 1;
  assign clk_div_o = qspi_ccr[27:25];      // Prescaler
  assign cmd_addr_o = {8'd0, qspi_adr};

  // Veri hattı sayısı çözücüsü (00=x1, 01=x1, 10=x2, 11=x4)
  wire [1:0] decoded_lanes = (qspi_ccr[9:8] == 2'b11) ? 2'd2 : (qspi_ccr[9:8] == 2'b10) ? 2'd1 : 2'd0;
  assign data_lanes_o = decoded_lanes;
  assign cmd_lanes_o = 2'd0;  // Komut her zaman tek hattan gider
  assign addr_lanes_o = 2'd0; // Adres her zaman tek hattan gider
  assign addr_bytes_o = 2'd1; // FSM için 2'b01 = 24-bit (3 Bayt) adres demektir.
  assign mode_en_cfg_o = 1'b0;

  // Kullanılmayanları toprağa/sabitlere bağla
  assign cs_level_o = 2'd1; assign cs_delay_o = 2'd1;
  assign xip_addr_bytes_o = 0; assign xip_data_lanes_o = 0; assign xip_dummy_cycles_o = 0;
  assign xip_cont_read_o = 0; assign xip_mode_en_o = 0; assign xip_write_en_o = 0;
  assign xip_read_op_o = 0; assign xip_mode_bits_o = 0; assign xip_write_op_o = 0;
  assign mode_bits_o = 0; assign extra_dummy_o = 0;
  assign burst_size_o = 0; assign dma_dir_o = 0; assign incr_addr_o = 0;
  assign dma_addr_o = 0; assign dma_len_o = 0;
  assign int_en_o = 0; assign irq = 0;
  assign hold_en_o = 0; assign wp_en_o = 0;

endmodule