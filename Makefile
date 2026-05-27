# --- Kaynak Dosyalar ---
# Paketler, Arayüzler ve En son Top modül
SRCS = axi_interfaces.sv \
       ips/cv32e40p/rtl/include/cv32e40p_apu_core_pkg.sv \
       ips/cv32e40p/rtl/include/cv32e40p_pkg.sv \
       ips/cv32e40p/rtl/include/cv32e40p_fpu_pkg.sv \
       ips/cv32e40p/rtl/vendor/pulp_platform_fpnew/src/fpnew_pkg.sv \
# --- Paketler ve Kaynaklar ---
# --- Paketler ---
PKGS = ips/cv32e40p/rtl/include/cv32e40p_pkg.sv \
       ips/cv32e40p/rtl/include/cv32e40p_apu_core_pkg.sv \
       ips/cv32e40p/rtl/include/cv32e40p_fpu_pkg.sv \
       ips/cv32e40p/rtl/vendor/pulp_platform_fpnew/src/fpnew_pkg.sv \
       ips/cv32e40p/bhv/include/cv32e40p_rvfi_pkg.sv \
       ips/cv32e40p/bhv/include/cv32e40p_tracer_pkg.sv \

# --- Bayraklar ---
FLAGS = --cc --trace --top-module soc_top \
        --Wno-WIDTH --Wno-CASEINCOMPLETE --Wno-UNOPTFLAT --Wno-PINMISSING \
        --Wno-PINCONNECTEMPTY --Wno-TIMESCALEMOD --Wno-GENUNNAMED \
        --Wno-VARHIDDEN --Wno-ASCRANGE --Wno-DECLFILENAME --Wno-WIDTHTRUNC \
        --Wno-WIDTHEXPAND --Wno-fatal \
        -DCV32E40P_SIM

# --- Arama Yolları ---
# --- Arama Yolları ---
INC = -I. \
      -Iips/cv32e40p/rtl \
      -Iips/cv32e40p/rtl/include \
      -Iips/cv32e40p/bhv \
      -y . \
      -y ips/cv32e40p/rtl/ \
      -y ips/cv32e40p/bhv/ \
      -y hw/ip/peripherals/rtl/core/cv32e40p-master/rtl/ \
      -y hw/ip/peripherals/rtl/core/cv32e40p-master/bhv/
# --- Hedefler ---
build:
	verilator $(FLAGS) $(INC) $(PKGS) hw/ip/peripherals/rtl/core/cv32e40p-master/rtl/cv32e40p_register_file_ff.sv soc_top.sv --exe sim_main.cpp

clean:
	rm -rf obj_dir
