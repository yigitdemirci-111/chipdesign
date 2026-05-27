#include "Vsoc_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0; 
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Vsoc_top* top = new Vsoc_top;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("soc_test.vcd");

    // Reset aktif alçak olduğu için 0 veriyoruz
    top->rst_ni = 0; 
top->clk = 0;
    // Reset süreci (50 döngü)
    for (int i = 0; i < 50; i++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(main_time);
        main_time++;
    }

    // Reset'i kaldırıyoruz (1)
    top->rst_ni = 1;

    // Simülasyon döngüsü (Örnek: 1000 döngü çalıştır)
    for (int i = 0; i < 1000; i++) {
        top->clk = !top->clk;
        top->eval();
        tfp->dump(main_time);
        main_time++;
    }

    tfp->close();
    top->final();
    delete top;
    return 0;
}
