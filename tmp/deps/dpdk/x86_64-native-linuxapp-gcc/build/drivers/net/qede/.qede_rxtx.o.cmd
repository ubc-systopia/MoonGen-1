cmd_qede_rxtx.o = gcc -Wp,-MD,./.qede_rxtx.o.d.tmp  -m64 -pthread  -march=native -DRTE_MACHINE_CPUFLAG_SSE -DRTE_MACHINE_CPUFLAG_SSE2 -DRTE_MACHINE_CPUFLAG_SSE3 -DRTE_MACHINE_CPUFLAG_SSSE3 -DRTE_MACHINE_CPUFLAG_SSE4_1 -DRTE_MACHINE_CPUFLAG_SSE4_2 -DRTE_MACHINE_CPUFLAG_AES -DRTE_MACHINE_CPUFLAG_PCLMULQDQ -DRTE_MACHINE_CPUFLAG_AVX -DRTE_MACHINE_CPUFLAG_RDRAND -DRTE_MACHINE_CPUFLAG_FSGSBASE -DRTE_MACHINE_CPUFLAG_F16C  -I/home/asabzi/msc-project/MoonGen-1/libmoon/deps/dpdk/x86_64-native-linuxapp-gcc/include -include /home/asabzi/msc-project/MoonGen-1/libmoon/deps/dpdk/x86_64-native-linuxapp-gcc/include/rte_config.h -O3 -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -Wold-style-definition -Wpointer-arith -Wcast-align -Wnested-externs -Wcast-qual -Wformat-nonliteral -Wformat-security -Wundef -Wwrite-strings -Werror -Wimplicit-fallthrough=0 -Wno-format-truncation   -Wno-error -o qede_rxtx.o -c /home/asabzi/msc-project/MoonGen-1/libmoon/deps/dpdk/drivers/net/qede/qede_rxtx.c 
