`ifndef MEMORY_MAP_SVH
`define MEMORY_MAP_SVH

// Yusuf'un belirlediği bellek mimarisi değerleri (8KB Instruction, 8KB Data, 30KB YZ)
localparam logic [31:0] BASE_INSTR_SRAM = 32'h0000_0000;
localparam logic [31:0] BASE_DATA_SRAM  = 32'h0000_2000; 
localparam logic [31:0] BASE_AI_SRAM    = 32'h0000_4000; 

// AXI4-Lite Çevre Birimleri (Peripherals)
localparam logic [31:0] BASE_UART        = 32'h4000_0000; 
localparam logic [31:0] BASE_TIMER       = 32'h4001_0000;
localparam logic [31:0] BASE_GPIO        = 32'h4002_0000;
localparam logic [31:0] BASE_AI_CONFIG   = 32'h4003_0000;

`endif

