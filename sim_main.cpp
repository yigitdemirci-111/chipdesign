#include <iostream>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vsoc_top.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsoc_top* top = new Vsoc_top;

    // VCD (Röntgen) kurulumu - İşlemcinin içini görmemizi sağlar
    Verilated::traceEverOn(true); 
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99); // 99 derinlik ile her şeyi kaydet
    tfp->open("soc_test.vcd");

    vluint64_t main_time = 0;
    
    // Başlangıç değerleri
    top->clk_i = 0;
    top->rst_ni = 0;
    top->fetch_enable_i = 0;

    // Simülasyon döngüsü
    while (main_time < 200000 && !Verilated::gotFinish()) {
        
        // 1. Clock mantığı
        if ((main_time % 5) == 0) {
            top->clk_i = !top->clk_i;
        }

        // 2. Reset ve Fetch mantığı
        if (main_time < 1000) {
            top->rst_ni = 0;
            top->fetch_enable_i = 0;
        } else {
            top->rst_ni = 1;
            top->fetch_enable_i = 1;
        }

        // 3. Tasarımı değerlendir ve izle
        top->eval();
        tfp->dump(main_time);

        // 4. Debug çıktısı
        if (main_time % 500 == 0) {
            std::cout << "Zaman: " << main_time << " | Clock: " << (int)top->clk_i 
                      << " | Reset: " << (int)top->rst_ni << std::endl;
        }

        main_time++;
    }

    tfp->close();
    delete top;
    
    std::cout << "Simülasyon başarıyla tamamlandı. Dosya: soc_test.vcd" << std::endl;
    return 0;
}
