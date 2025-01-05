#ifndef __LNRV_SOC_H
#define __LNRV_SOC_H

#include <stdint.h>
#include <stdlib.h>



#define     PLMT_BASE_ADDR              (0x00040000)

#define     MVENDORID_REG_ADDR          (0xf11)
#define     MARCHID_REG_ADDR            (0xf12)
#define     MIMPID_REG_ADDR             (0xf13)
#define     MHARTID_REG_ADDR            (0xf14)
#define     MSTATUS_REG_ADDR            (0x300)
#define     MISA_REG_ADDR               (0x301)
#define     MEDELEG_REG_ADDR            (0x302)
#define     MIDELEG_REG_ADDR            (0x303)
#define     MIE_REG_ADDR                (0x304)
#define     MTVEC_REG_ADDR              (0x305)
#define     MCOUNTEREN_REG_ADDR         (0x306)
#define     MSCRATCH_REG_ADDR           (0x340)
#define     MEPC_REG_ADDR               (0x341)
#define     MCAUSE_REG_ADDR             (0x342)
#define     MTVAL_REG_ADDR              (0x343)
#define     MIP_REG_ADDR                (0x344)
#define     MCYCLE_REG_ADDR             (0xb00)
#define     MINSTRET_REG_ADDR           (0xb02)
#define     MCYCLEH_REG_ADDR            (0xb80)
#define     MINSTRETH_REG_ADDR          (0xb82)
#define     TSELECT_REG_ADDR            (0x7a0)
#define     TDATA1_REG_ADDR             (0x7a1)
#define     TDATA2_REG_ADDR             (0x7a2)
#define     TDATA3_REG_ADDR             (0x7a3)
#define     DCSR_REG_ADDR               (0x7b0)
#define     DPC_REG_ADDR                (0x7b1)
#define     DSCRATCH0_REG_ADDR          (0x7b2)
#define     DSCRATCH1_REG_ADDR          (0x7b3)




#define     __IO_WR_32(addr, data)      (*((volatile uint32_t *)addr)) = data
#define     __IO_RD_32(addr)            (*((volatile uint32_t *)addr))


#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

#define write_csr(reg, val) ({ \
  if (__builtin_constant_p(val) && (unsigned long)(val) < 32) \
    asm volatile ("csrw " #reg ", %0" :: "i"(val)); \
  else \
    asm volatile ("csrw " #reg ", %0" :: "r"(val)); })































#endif