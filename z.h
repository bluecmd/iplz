#ifndef __Z__
#define __Z__

#include <stdint.h>

#define _THIS_IP_  ({ __label__ __here; __here: (unsigned long)&&__here; })

#define PSW_MASK_PER            0x4000000000000000UL
#define PSW_MASK_DAT            0x0400000000000000UL
#define PSW_MASK_IO             0x0200000000000000UL
#define PSW_MASK_EXT            0x0100000000000000UL
#define PSW_MASK_BASE           0x0000000000000000UL
#define PSW_MASK_KEY            0x00F0000000000000UL
#define PSW_MASK_MCHECK         0x0004000000000000UL
#define PSW_MASK_WAIT           0x0002000000000000UL
#define PSW_MASK_PSTATE         0x0001000000000000UL
#define PSW_MASK_ASC            0x0000C00000000000UL
#define PSW_MASK_CC             0x0000300000000000UL
#define PSW_MASK_PM             0x00000F0000000000UL
#define PSW_MASK_RI             0x0000008000000000UL
#define PSW_MASK_EA             0x0000000100000000UL
#define PSW_MASK_BA             0x0000000080000000UL

#define PSW_MASK_USER           0x0000FF0180000000UL

#define PSW_ADDR_AMODE          0x0000000000000000UL
#define PSW_ADDR_INSN           0xFFFFFFFFFFFFFFFFUL

#define PSW_DEFAULT_KEY         (((unsigned long) PAGE_DEFAULT_ACC) << 52)

#define PSW_ASC_PRIMARY         0x0000000000000000UL
#define PSW_ASC_ACCREG          0x0000400000000000UL
#define PSW_ASC_SECONDARY       0x0000800000000000UL
#define PSW_ASC_HOME            0x0000C00000000000UL

typedef struct {
  uint64_t mask;
  uint64_t addr;
} __attribute__ ((aligned(8))) psw_t;

void __load_psw(psw_t *psw);

#define PANIC() do { \
  psw_t psw; \
  psw.mask = PSW_MASK_BASE | PSW_MASK_WAIT | PSW_MASK_BA | PSW_MASK_EA; \
  psw.addr = _THIS_IP_; \
  __load_psw(&psw); \
  while(1) {} \
} while(0)

#endif
