module axi_interconnect_custom (
    input  logic [31:0] s_axi_awaddr,
    output logic        ram_sel,
    output logic        gpio_sel
);
    always_comb begin
        ram_sel  = (s_axi_awaddr >= 32'h0000 && s_axi_awaddr < 32'h1000);
        gpio_sel = (s_axi_awaddr >= 32'h1000 && s_axi_awaddr < 32'h2000);
    end
endmodule
