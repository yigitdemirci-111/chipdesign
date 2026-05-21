`ifndef MEMORY_MAP_SVH
`define MEMORY_MAP_SVH

// =========================================================================
// TEKNOFEST SoC Bellek Haritası (Memory Map) Tanımları
// =========================================================================

// 1. SRAM / Ana Bellek (64 KB)
`define SRAM_BASE_ADDR        32'h0000_0000
`define SRAM_HIGH_ADDR        32'h0000_FFFF

// 2. QSPI Flash Bellek Alanı
`define QSPI_BASE_ADDR        32'h0001_0000
`define QSPI_HIGH_ADDR        32'h0001_FFFF

// 3. GPIO Çevre Birimi Register Adresi
`define GPIO_BASE_ADDR        32'h4000_0000
`define GPIO_HIGH_ADDR        32'h4000_00FF

// 4. UART Haberleşme Register Adresi
`define UART_BASE_ADDR        32'h4000_0100
`define UART_HIGH_ADDR        32'h4000_01FF

`endif // MEMORY_MAP_SVH
