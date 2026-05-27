module cv32e40p_register_file #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
) (
    input  logic clk,
    // ... diğer sinyalleri buraya eklemene gerek yok, 
    // sadece üstteki modül isminin match etmesi yeterli
);
    cv32e40p_register_file_ff u_impl (.*);
endmodule
