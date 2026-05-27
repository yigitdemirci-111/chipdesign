
/* Instantiation etmek için kolaylık olsun diye burada kullandığım dosyalardaki değişkenlere
   anahtar kelimeler ekledim.
*/ 
`timescale 1ns/1ps

module soc_top
#(  
    // Kullandığım dosyalarda kullanılan parametreler

    // AXI4-Lite standardına göre çevrebirimlerinin adres genişlikleri birbirine eşittir ve 
    // slave'den alınan veri boyutları da strobe değişkenleri sayesinde aynı boyutta alınır.
        parameter SYS_M_COUNT = 1,
        parameter SYS_S_COUNT = 6,
        parameter ADDR_WIDTH = 32,
        parameter DATA_WIDTH = 32,
        parameter STRB_WIDTH = 4,
    
    // I2C dosyalarının parametreleri
        parameter I2C_KEEP_WIDTH = 7,
        parameter I2C_ID_WIDTH = 32,
        parameter I2C_DEST_WIDTH = 32,
        parameter I2C_USER_WIDTH = 8
)
(

    // SOC çekirdek portları
        input wire soc_clk,
        input wire soc_resetn,

    // SOC UART portları
    
        // UART Interface (2 UART kullanacağımız için 2 ayrı interface açacağım)
        output wire                     soc_uart1_txd,   // UART transmit data
        input  wire                     soc_uart1_rxd,   // UART receive data

        output wire soc_uart2_txd,
        input wire soc_uart2_rxd,
    
        // Interrupt
        output                          soc_uart1_interrupt,
        output                          soc_uart2_interrupt,

    // SOC I2C portları
        input  wire soc_i2c_scl_i,
        output wire soc_i2c_scl_o,
        output wire soc_i2c_scl_t,
        input  wire soc_i2c_sda_i,
        output wire soc_i2c_sda_o,
        output wire soc_i2c_sda_t,

    // SOC QSPI portları

        output wire        soc_qspi_sclk,
        output wire        soc_qspi_cs_n,
        inout  wire [3:0]  soc_qspi_io, // 4-bitlik çift yönlü veri hattı

    // SOC GPIO portları    

        input  wire [15:0]            soc_gpio_in,
        output wire [15:0]            soc_gpio_out

);

    // protection bağlantıları için dummy variable'lar
    wire [8:0] dummy_awprot;
    wire [8:0] dummy_arprot;


    // axil_crossbar.v dosyasında bulunan master pinleri. 
    // Sadece çekirdek bizim masterımız olduğu için çevre birimleri ortak master kullanacak

    /*
     * AXI lite master arayüzü
     */
    wire [SYS_M_COUNT*ADDR_WIDTH-1:0]    soc_main_m_axil_awaddr;
    wire [SYS_M_COUNT*3-1:0]             soc_main_m_axil_awprot;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_awvalid;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_awready;

    wire [SYS_M_COUNT*DATA_WIDTH-1:0]    soc_main_m_axil_wdata;
    wire [SYS_M_COUNT*STRB_WIDTH-1:0]    soc_main_m_axil_wstrb;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_wvalid;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_wready;

    wire [SYS_M_COUNT*2-1:0]             soc_main_m_axil_bresp;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_bvalid;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_bready;

    wire [SYS_M_COUNT*ADDR_WIDTH-1:0]    soc_main_m_axil_araddr;
    wire [SYS_M_COUNT*3-1:0]             soc_main_m_axil_arprot;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_arvalid;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_arready;
    
    wire [SYS_M_COUNT*DATA_WIDTH-1:0]    soc_main_m_axil_rdata;
    wire [SYS_M_COUNT*2-1:0]             soc_main_m_axil_rresp;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_rvalid;
    wire [SYS_M_COUNT-1:0]               soc_main_m_axil_rready;


    // axil_crossbar.v dosyasındaki slave portları
    /*
     * AXI-Lite UART slave arayüzü(Interface 1)
     */
    wire [ADDR_WIDTH-1:0]    soc_uart1_s_axil_awaddr;
    wire [2:0]               soc_uart1_s_axil_awprot;
    wire                     soc_uart1_s_axil_awvalid;
    wire                     soc_uart1_s_axil_awready;

    wire [DATA_WIDTH-1:0]    soc_uart1_s_axil_wdata;
    wire [STRB_WIDTH-1:0]    soc_uart1_s_axil_wstrb;
    wire                     soc_uart1_s_axil_wvalid;
    wire                     soc_uart1_s_axil_wready;

    wire [1:0]               soc_uart1_s_axil_bresp;
    wire                     soc_uart1_s_axil_bvalid;
    wire                     soc_uart1_s_axil_bready;

    wire [ADDR_WIDTH-1:0]    soc_uart1_s_axil_araddr;
    wire [2:0]               soc_uart1_s_axil_arprot;
    wire                     soc_uart1_s_axil_arvalid;
    wire                     soc_uart1_s_axil_arready;

    wire [DATA_WIDTH-1:0]    soc_uart1_s_axil_rdata;
    wire [1:0]               soc_uart1_s_axil_rresp;
    wire                     soc_uart1_s_axil_rvalid;
    wire                     soc_uart1_s_axil_rready;

    /*
     * AXI-Lite UART slave arayüzü(Interface 2)
     */
    wire [ADDR_WIDTH-1:0]    soc_uart2_s_axil_awaddr;
    wire [2:0]               soc_uart2_s_axil_awprot;
    wire                     soc_uart2_s_axil_awvalid;
    wire                     soc_uart2_s_axil_awready;

    wire [DATA_WIDTH-1:0]    soc_uart2_s_axil_wdata;
    wire [STRB_WIDTH-1:0]    soc_uart2_s_axil_wstrb;
    wire                     soc_uart2_s_axil_wvalid;
    wire                     soc_uart2_s_axil_wready;

    wire [1:0]               soc_uart2_s_axil_bresp;
    wire                     soc_uart2_s_axil_bvalid;
    wire                     soc_uart2_s_axil_bready;

    wire [ADDR_WIDTH-1:0]    soc_uart2_s_axil_araddr;
    wire [2:0]               soc_uart2_s_axil_arprot;
    wire                     soc_uart2_s_axil_arvalid;
    wire                     soc_uart2_s_axil_arready;

    wire [DATA_WIDTH-1:0]    soc_uart2_s_axil_rdata;
    wire [1:0]               soc_uart2_s_axil_rresp;
    wire                     soc_uart2_s_axil_rvalid;
    wire                     soc_uart2_s_axil_rready;

    /*
     * AXI-Lite I2C slave arayüzü 
     */
    wire [ADDR_WIDTH-1:0]    soc_i2c_s_axil_awaddr;
    wire [2:0]               soc_i2c_s_axil_awprot;
    wire                     soc_i2c_s_axil_awvalid;
    wire                     soc_i2c_s_axil_awready;

    wire [DATA_WIDTH-1:0]    soc_i2c_s_axil_wdata;
    wire [STRB_WIDTH-1:0]    soc_i2c_s_axil_wstrb;
    wire                     soc_i2c_s_axil_wvalid;
    wire                     soc_i2c_s_axil_wready;

    wire [1:0]               soc_i2c_s_axil_bresp;
    wire                     soc_i2c_s_axil_bvalid;
    wire                     soc_i2c_s_axil_bready;

    wire [ADDR_WIDTH-1:0]    soc_i2c_s_axil_araddr;
    wire [2:0]               soc_i2c_s_axil_arprot;
    wire                     soc_i2c_s_axil_arvalid;
    wire                     soc_i2c_s_axil_arready;

    wire [DATA_WIDTH-1:0]    soc_i2c_s_axil_rdata;
    wire [1:0]               soc_i2c_s_axil_rresp;
    wire                     soc_i2c_s_axil_rvalid;
    wire                     soc_i2c_s_axil_rready;

    // AXI-Lite QSPI slave arayüzü
    wire [ADDR_WIDTH-1:0]    soc_qspi_s_axil_awaddr;
    wire                     soc_qspi_s_axil_awvalid;
    wire                     soc_qspi_s_axil_awready;

    wire [DATA_WIDTH-1:0]    soc_qspi_s_axil_wdata;
    wire [STRB_WIDTH-1:0]    soc_qspi_s_axil_wstrb;
    wire                     soc_qspi_s_axil_wvalid;
    wire                     soc_qspi_s_axil_wready;

    wire [1:0]               soc_qspi_s_axil_bresp;
    wire                     soc_qspi_s_axil_bvalid;
    wire                     soc_qspi_s_axil_bready;

    wire [ADDR_WIDTH-1:0]    soc_qspi_s_axil_araddr;
    wire                     soc_qspi_s_axil_arvalid;
    wire                     soc_qspi_s_axil_arready;
    wire  [DATA_WIDTH-1:0]   soc_qspi_s_axil_rdata;
    wire [1:0]               soc_qspi_s_axil_rresp;
    wire                     soc_qspi_s_axil_rvalid;
    wire                     soc_qspi_s_axil_rready;

    // AXI-Lite GPIO slave arayüzü
    wire [ADDR_WIDTH-1:0]    soc_gpio_s_axil_awaddr;
    wire                     soc_gpio_s_axil_awvalid;
    wire                     soc_gpio_s_axil_awready;

    wire [DATA_WIDTH-1:0]    soc_gpio_s_axil_wdata;
    wire [3:0]               soc_gpio_s_axil_wstrb;
    wire                     soc_gpio_s_axil_wvalid;
    wire                     soc_gpio_s_axil_wready;

    wire [1:0]               soc_gpio_s_axil_bresp;
    wire                     soc_gpio_s_axil_bvalid;
    wire                     soc_gpio_s_axil_bready;

    wire [ADDR_WIDTH-1:0]    soc_gpio_s_axil_araddr;
    wire                     soc_gpio_s_axil_arvalid;
    wire                     soc_gpio_s_axil_arready;

    wire [DATA_WIDTH-1:0]    soc_gpio_s_axil_rdata;
    wire [1:0]               soc_gpio_s_axil_rresp;
    wire                     soc_gpio_s_axil_rvalid;
    wire                     soc_gpio_s_axil_rready;

    // AXI-Lite Timer slave arayüzü
    wire [ADDR_WIDTH-1:0]    soc_timer_s_axil_awaddr;
    wire                     soc_timer_s_axil_awvalid;
    wire                     soc_timer_s_axil_awready;

    wire [DATA_WIDTH-1:0]    soc_timer_s_axil_wdata;
    wire [3:0]               soc_timer_s_axil_wstrb;
    wire                     soc_timer_s_axil_wvalid;
    wire                     soc_timer_s_axil_wready;

    wire [1:0]               soc_timer_s_axil_bresp;
    wire                     soc_timer_s_axil_bvalid;
    wire                     soc_timer_s_axil_bready;

    wire [ADDR_WIDTH-1:0]    soc_timer_s_axil_araddr;
    wire                     soc_timer_s_axil_arvalid;
    wire                     soc_timer_s_axil_arready;

    wire [DATA_WIDTH-1:0]    soc_timer_s_axil_rdata;
    wire [1:0]               soc_timer_s_axil_rresp;
    wire                     soc_timer_s_axil_rvalid;
    wire                     soc_timer_s_axil_rready;


    // Bu dosyadaki kurulan portları diğer dosyalara bağlıyorum

    // Crossbar modülü ile top dosyasının bağlantıları
    axil_crossbar #(
        .S_COUNT(1),
        .M_COUNT(6),
        .DATA_WIDTH(DATA_WIDTH),
        // Adres Haritası
        // {Timer, GPIO, QSPI, I2C, UART1, UART2} sırasına göre 6 adet 32-bit değer:
        .M_BASE_ADDR({
            32'h0500_0000, // 5. Port: Timer
            32'h0400_0000, // 4. Port: GPIO
            32'h0300_0000, // 3. Port: QSPI
            32'h0200_0000, // 2. Port: I2C
            32'h0100_0000, // 1. Port: UART1
            32'h0000_0000  // 0. Port: UART2
        }),
        // Adres Genişliği (Adres Maskesi)
        .M_ADDR_WIDTH({
            32'd16, // Timer
            32'd16, // GPIO
            32'd16, // QSPI
            32'd16, // I2C
            32'd16, // UART1
            32'd16  // UART2
        })
    ) u_axil_crossbar(
        .clk(soc_clk),
        .rst(!soc_resetn),

        .m_axil_awaddr({soc_timer_s_axil_awaddr, soc_gpio_s_axil_awaddr,soc_qspi_s_axil_awaddr,soc_i2c_s_axil_awaddr,soc_uart1_s_axil_awaddr,soc_uart2_s_axil_awaddr}),
        .m_axil_awvalid({soc_timer_s_axil_awvalid, soc_gpio_s_axil_awvalid,soc_qspi_s_axil_awvalid,soc_i2c_s_axil_awvalid,soc_uart1_s_axil_awvalid,soc_uart2_s_axil_awvalid}),
        .m_axil_awready({soc_timer_s_axil_awready, soc_gpio_s_axil_awready,soc_qspi_s_axil_awready,soc_i2c_s_axil_awready,soc_uart1_s_axil_awready,soc_uart2_s_axil_awready}),
        .m_axil_awprot({dummy_awprot,soc_i2c_s_axil_awprot,soc_uart1_s_axil_awprot,soc_uart2_s_axil_awprot}),
        
        .m_axil_wdata({soc_timer_s_axil_wdata, soc_gpio_s_axil_wdata, soc_qspi_s_axil_wdata,soc_i2c_s_axil_wdata,soc_uart1_s_axil_wdata,soc_uart2_s_axil_wdata}),
        .m_axil_wready({soc_timer_s_axil_wready, soc_gpio_s_axil_wready, soc_qspi_s_axil_wready,soc_i2c_s_axil_wready,soc_uart1_s_axil_wready,soc_uart2_s_axil_wready}),
        .m_axil_wstrb({soc_timer_s_axil_wstrb, soc_gpio_s_axil_wstrb, soc_qspi_s_axil_wstrb,soc_i2c_s_axil_wstrb,soc_uart1_s_axil_wstrb,soc_uart2_s_axil_wstrb}),
        .m_axil_wvalid({soc_timer_s_axil_wvalid, soc_gpio_s_axil_wvalid, soc_qspi_s_axil_wvalid,soc_i2c_s_axil_wvalid,soc_uart1_s_axil_wvalid,soc_uart2_s_axil_wvalid}),
        
        .m_axil_bready({soc_timer_s_axil_bready, soc_gpio_s_axil_bready, soc_qspi_s_axil_bready,soc_i2c_s_axil_bready,soc_uart1_s_axil_bready,soc_uart2_s_axil_bready}),
        .m_axil_bresp({soc_timer_s_axil_bresp, soc_gpio_s_axil_bresp, soc_qspi_s_axil_bresp,soc_i2c_s_axil_bresp,soc_uart1_s_axil_bresp,soc_uart2_s_axil_bresp}),
        .m_axil_bvalid({soc_timer_s_axil_bvalid, soc_gpio_s_axil_bvalid, soc_qspi_s_axil_bvalid,soc_i2c_s_axil_bvalid,soc_uart1_s_axil_bvalid,soc_uart2_s_axil_bvalid}),
        
        .m_axil_araddr({soc_timer_s_axil_araddr, soc_gpio_s_axil_araddr, soc_qspi_s_axil_araddr,soc_i2c_s_axil_araddr,soc_uart1_s_axil_araddr,soc_uart2_s_axil_araddr}),
        .m_axil_arprot({dummy_arprot,soc_i2c_s_axil_arprot,soc_uart1_s_axil_arprot,soc_uart2_s_axil_arprot}),
        .m_axil_arready({soc_timer_s_axil_arready, soc_gpio_s_axil_arready,soc_qspi_s_axil_arready,soc_i2c_s_axil_arready,soc_uart1_s_axil_arready,soc_uart2_s_axil_arready}),
        .m_axil_arvalid({soc_timer_s_axil_arvalid, soc_gpio_s_axil_arvalid, soc_qspi_s_axil_arvalid,soc_i2c_s_axil_arvalid,soc_uart1_s_axil_arvalid,soc_uart2_s_axil_arvalid}),
        
        .m_axil_rdata({soc_timer_s_axil_rdata, soc_gpio_s_axil_rdata, soc_qspi_s_axil_rdata,soc_i2c_s_axil_rdata,soc_uart1_s_axil_rdata,soc_uart2_s_axil_rdata}),
        .m_axil_rready({soc_timer_s_axil_rready,soc_gpio_s_axil_rready, soc_qspi_s_axil_rready,soc_i2c_s_axil_rready,soc_uart1_s_axil_rready,soc_uart2_s_axil_rready}),
        .m_axil_rresp({soc_timer_s_axil_rresp, soc_gpio_s_axil_rresp, soc_qspi_s_axil_rresp,soc_i2c_s_axil_rresp,soc_uart1_s_axil_rresp,soc_uart2_s_axil_rresp}),
        .m_axil_rvalid({soc_timer_s_axil_rvalid,soc_gpio_s_axil_rvalid, soc_qspi_s_axil_rvalid,soc_i2c_s_axil_rvalid,soc_uart1_s_axil_rvalid,soc_uart2_s_axil_rvalid}),

        .s_axil_awaddr(soc_main_m_axil_awaddr),
        .s_axil_awprot(soc_main_m_axil_awprot),
        .s_axil_awready(soc_main_m_axil_awready),
        .s_axil_awvalid(soc_main_m_axil_awvalid),

        .s_axil_wdata(soc_main_m_axil_wdata),
        .s_axil_wready(soc_main_m_axil_wready),
        .s_axil_wstrb(soc_main_m_axil_wstrb),
        .s_axil_wvalid(soc_main_m_axil_wvalid),

        .s_axil_bresp(soc_main_m_axil_bresp),
        .s_axil_bready(soc_main_m_axil_bready),
        .s_axil_bvalid(soc_main_m_axil_bvalid),

        .s_axil_araddr(soc_main_m_axil_araddr),
        .s_axil_arprot(soc_main_m_axil_arprot),
        .s_axil_arready(soc_main_m_axil_arready),
        .s_axil_arvalid(soc_main_m_axil_arvalid),

        .s_axil_rdata(soc_main_m_axil_rdata),
        .s_axil_rready(soc_main_m_axil_rready),
        .s_axil_rresp(soc_main_m_axil_rresp),
        .s_axil_rvalid(soc_main_m_axil_rvalid)

    );

    // UART modülü ile top dosyasını bağlıyorum 
    // Interface 1
    axi_lite_uart #(
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_uart1(

        .aclk(soc_clk),
        .aresetn(soc_resetn),

        .s_axi_awaddr(soc_uart1_s_axil_awaddr),
        .s_axi_awprot(soc_uart1_s_axil_awprot),
        .s_axi_awvalid(soc_uart1_s_axil_awvalid),
        .s_axi_awready(soc_uart1_s_axil_awready),

        .s_axi_wdata(soc_uart1_s_axil_wdata),
        .s_axi_wready(soc_uart1_s_axil_wready),
        .s_axi_wstrb(soc_uart1_s_axil_wstrb),
        .s_axi_wvalid(soc_uart1_s_axil_wvalid),

        .s_axi_bready(soc_uart1_s_axil_bready),
        .s_axi_bresp(soc_uart1_s_axil_bresp),
        .s_axi_bvalid(soc_uart1_s_axil_bvalid),

        .s_axi_araddr(soc_uart1_s_axil_araddr),
        .s_axi_arprot(soc_uart1_s_axil_arprot),
        .s_axi_arready(soc_uart1_s_axil_arready),
        .s_axi_arvalid(soc_uart1_s_axil_arvalid),

        .s_axi_rdata(soc_uart1_s_axil_rdata),
        .s_axi_rready(soc_uart1_s_axil_rready),
        .s_axi_rresp(soc_uart1_s_axil_rresp),
        .s_axi_rvalid(soc_uart1_s_axil_rvalid),

        .uart_txd(soc_uart1_txd),
        .uart_rxd(soc_uart1_rxd),

        .interrupt(soc_uart1_interrupt)
    );

    // Interface 2
        axi_lite_uart #(
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_uart2(

        .aclk(soc_clk),
        .aresetn(soc_resetn),

        .s_axi_awaddr(soc_uart2_s_axil_awaddr),
        .s_axi_awprot(soc_uart2_s_axil_awprot),
        .s_axi_awvalid(soc_uart2_s_axil_awvalid),
        .s_axi_awready(soc_uart2_s_axil_awready),

        .s_axi_wdata(soc_uart2_s_axil_wdata),
        .s_axi_wready(soc_uart2_s_axil_wready),
        .s_axi_wstrb(soc_uart2_s_axil_wstrb),
        .s_axi_wvalid(soc_uart2_s_axil_wvalid),

        .s_axi_bready(soc_uart2_s_axil_bready),
        .s_axi_bresp(soc_uart2_s_axil_bresp),
        .s_axi_bvalid(soc_uart2_s_axil_bvalid),

        .s_axi_araddr(soc_uart2_s_axil_araddr),
        .s_axi_arprot(soc_uart2_s_axil_arprot),
        .s_axi_arready(soc_uart2_s_axil_arready),
        .s_axi_arvalid(soc_uart2_s_axil_arvalid),

        .s_axi_rdata(soc_uart2_s_axil_rdata),
        .s_axi_rready(soc_uart2_s_axil_rready),
        .s_axi_rresp(soc_uart2_s_axil_rresp),
        .s_axi_rvalid(soc_uart2_s_axil_rvalid),

        .uart_txd(soc_uart2_txd),
        .uart_rxd(soc_uart2_rxd),

        .interrupt(soc_uart2_interrupt)
    );

    // I2C modülü ile top dosyasını bağlıyorum

    special_i2c_wrapper #(
        .CLK_FREQ(50000000)
    )
    u_special_i2c_wrapper(
        .clk(soc_clk),
        .rst_n(soc_resetn),

        .s_axil_awaddr(soc_i2c_s_axil_awaddr[4:0]),
        .s_axil_awready(soc_i2c_s_axil_awready),
        .s_axil_awvalid(soc_i2c_s_axil_awvalid),

        .s_axil_wdata(soc_i2c_s_axil_wdata),
        .s_axil_wready(soc_i2c_s_axil_wready),
        .s_axil_wstrb(soc_i2c_s_axil_wstrb),
        .s_axil_wvalid(soc_i2c_s_axil_wvalid),

        .s_axil_bready(soc_i2c_s_axil_bready),
        .s_axil_bresp(soc_i2c_s_axil_bresp),
        .s_axil_bvalid(soc_i2c_s_axil_bvalid),

        .s_axil_araddr(soc_i2c_s_axil_araddr[4:0]),
        .s_axil_arready(soc_i2c_s_axil_arready),
        .s_axil_arvalid(soc_i2c_s_axil_arvalid),

        .s_axil_rdata(soc_i2c_s_axil_rdata),
        .s_axil_rready(soc_i2c_s_axil_rready),
        .s_axil_rresp(soc_i2c_s_axil_rresp),
        .s_axil_rvalid(soc_i2c_s_axil_rvalid),

        .i2c_scl_i(soc_i2c_scl_i),
        .i2c_scl_o(soc_i2c_scl_o),
        .i2c_scl_t(soc_i2c_scl_t),
        
        .i2c_sda_i(soc_i2c_sda_i),
        .i2c_sda_o(soc_i2c_sda_o),
        .i2c_sda_t(soc_i2c_sda_t)
    );

    // QSPI modülü ile top dosyasını bağlıyorum
    qspi_controller #(
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_qspi_controller(
        .clk(soc_clk),
        .resetn(soc_resetn),

        .s_axil_awaddr(soc_qspi_s_axil_awaddr[4:0]),
        .s_axil_awready(soc_qspi_s_axil_awready),
        .s_axil_awvalid(soc_qspi_s_axil_awvalid),

        .s_axil_wdata(soc_qspi_s_axil_wdata),
        .s_axil_wready(soc_qspi_s_axil_wready),
        .s_axil_wstrb(soc_qspi_s_axil_wstrb),
        .s_axil_wvalid(soc_qspi_s_axil_wvalid),


        .s_axil_bresp(soc_qspi_s_axil_bresp),
        .s_axil_bready(soc_qspi_s_axil_bready),
        .s_axil_bvalid(soc_qspi_s_axil_bvalid),
        
        .s_axil_araddr(soc_qspi_s_axil_araddr[4:0]),
        .s_axil_arready(soc_qspi_s_axil_arready),
        .s_axil_arvalid(soc_qspi_s_axil_arvalid),

        .s_axil_rdata(soc_qspi_s_axil_rdata),
        .s_axil_rready(soc_qspi_s_axil_rready),
        .s_axil_rresp(soc_qspi_s_axil_rresp),
        .s_axil_rvalid(soc_qspi_s_axil_rvalid),

        // DMA Master portları kullanılmadığı için girişler 0 yapılıp çıkışlar boş bırakıldı
        .m_axi_awaddr   (), .m_axi_awvalid  (), .m_axi_awready  (1'b0),
        .m_axi_wdata    (), .m_axi_wvalid   (), .m_axi_wstrb    (), .m_axi_wready   (1'b0),
        .m_axi_bvalid   (1'b0), .m_axi_bresp(2'b00), .m_axi_bready(),
        .m_axi_araddr   (), .m_axi_arvalid  (), .m_axi_arready  (1'b0),
        .m_axi_rdata    (32'd0), .m_axi_rvalid(1'b0), .m_axi_rresp(2'b00), .m_axi_rready(),

        // XIP Slave portları kullanılmadığı için girişler 0 yapılıp çıkışlar boş bırakıldı 
        .s_axi_awaddr   (32'd0), .s_axi_awvalid (1'b0), .s_axi_awready  (),
        .s_axi_wdata    (32'd0), .s_axi_wstrb   (4'd0), .s_axi_wvalid   (1'b0), .s_axi_wready   (),
        .s_axi_bresp    (), .s_axi_bvalid   (), .s_axi_bready   (1'b0),
        .s_axi_araddr   (32'd0), .s_axi_arvalid (1'b0), .s_axi_arready  (),
        .s_axi_rdata    (), .s_axi_rresp    (), .s_axi_rvalid   (), .s_axi_rready   (1'b0),

        .sclk(soc_qspi_sclk),
        .cs_n(soc_qspi_cs_n),
        .io(soc_qspi_io)
    );

    // GPIO modülü ile top dosyasını bağlıyorum
    special_gpio #(
        .ADDR_WIDTH(5),
        .DATA_WIDTH(DATA_WIDTH)
    )
    u_special_gpio(
        .clk(soc_clk),
        .rst_n(soc_resetn),

        .s_axil_awaddr(soc_gpio_s_axil_awaddr[4:0]),
        .s_axil_awready(soc_gpio_s_axil_awready),
        .s_axil_awvalid(soc_gpio_s_axil_awvalid),

        .s_axil_wdata(soc_gpio_s_axil_wdata),
        .s_axil_wready(soc_gpio_s_axil_wready),
        .s_axil_wstrb(soc_gpio_s_axil_wstrb),
        .s_axil_wvalid(soc_gpio_s_axil_wvalid),

        .s_axil_bresp(soc_gpio_s_axil_bresp),
        .s_axil_bready(soc_gpio_s_axil_bready),
        .s_axil_bvalid(soc_gpio_s_axil_bvalid),

        .s_axil_araddr(soc_gpio_s_axil_araddr[4:0]),
        .s_axil_arready(soc_gpio_s_axil_arready),
        .s_axil_arvalid(soc_gpio_s_axil_arvalid),

        .s_axil_rdata(soc_gpio_s_axil_rdata),
        .s_axil_rready(soc_gpio_s_axil_rready),
        .s_axil_rresp(soc_gpio_s_axil_rresp),
        .s_axil_rvalid(soc_gpio_s_axil_rvalid),

        .gpio_in(soc_gpio_in),
        .gpio_out(soc_gpio_out)
    );

    // Timer modülü ile top dosyasını bağlıyorum
    special_timer #(
        .ADDR_WIDTH(5),
        .DATA_WIDTH(DATA_WIDTH)
    )
    u_special_timer(
        .clk(soc_clk),
        .rst_n(soc_resetn),

        .s_axil_awaddr(soc_timer_s_axil_awaddr[4:0]),
        .s_axil_awready(soc_timer_s_axil_awready),
        .s_axil_awvalid(soc_timer_s_axil_awvalid),

        .s_axil_wdata(soc_timer_s_axil_wdata),
        .s_axil_wready(soc_timer_s_axil_wready),
        .s_axil_wstrb(soc_timer_s_axil_wstrb),
        .s_axil_wvalid(soc_timer_s_axil_wvalid),

        .s_axil_bresp(soc_timer_s_axil_bresp),
        .s_axil_bready(soc_timer_s_axil_bready),
        .s_axil_bvalid(soc_timer_s_axil_bvalid),

        .s_axil_araddr(soc_timer_s_axil_araddr[4:0]),
        .s_axil_arready(soc_timer_s_axil_arready),
        .s_axil_arvalid(soc_timer_s_axil_arvalid),
        
        .s_axil_rdata(soc_timer_s_axil_rdata),
        .s_axil_rready(soc_timer_s_axil_rready),
        .s_axil_rresp(soc_timer_s_axil_rresp),
        .s_axil_rvalid(soc_timer_s_axil_rvalid)
    );  


endmodule

