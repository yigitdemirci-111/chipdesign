#include "Vsoc_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

int main(int argc, char** argv) {
    // Verilator komut satırı argümanlarını işle
    Verilated::commandArgs(argc, argv);
    
    // Tasarım örneğini oluştur
    Vsoc_top* top = new Vsoc_top;

    // VCD izleme (waveform) ayarları
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("soc_test.vcd");

    vluint64_t main_time = 0;

    // Başlangıç değerleri
    top->clk_i = 0;
    top->rst_ni = 0;
    top->fetch_enable_i = 0;

    // Simülasyon döngüsü
// Simülasyon döngüsü
    while (main_time < 2000 && !Verilated::gotFinish()) {
        // 1. Clock üretimi
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

        // 4. Debug çıktısı (sadece saat değişimlerinde)
        if (main_time % 5 == 0) {
            std::cout << "Zaman: " << main_time << " | Clock: " << (int)top->clk_i 
                      << " | Reset: " << (int)top->rst_ni << std::endl;
        }

        // 5. Zamanı tek bir kez artır!
        main_time++;
    }

    // Döngü bittikten sonra temizlik
    tfp->close();
    delete top;
    
    std::cout << "Simülasyon başarıyla tamamlandı. Dosya: soc_test.vcd" << std::endl;
    return 0;
}
