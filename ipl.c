#include "z.h"

void load();

void __load_psw(psw_t *psw) {
  asm volatile("lpswe %0" : : "Q" (*psw) : "cc");
}

void load() {
  PANIC();
}
