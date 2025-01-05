#ifndef __LNRV_PLMT_H
#define __LNRV_PLMT_H

#include "lnrv_soc.h"


#define         PLMT_MTIME_ENABLE_REG_ADDR      (PLMT_BASE_ADDR + 0x00)
#define         PLMT_MTIME_CTRL_REG_ADDR        (PLMT_BASE_ADDR + 0x04)
#define         PLMT_MTIME_CNT_LO_REG_ADDR      (PLMT_BASE_ADDR + 0x08)
#define         PLMT_MTIME_CNT_HI_REG_ADDR      (PLMT_BASE_ADDR + 0x0c)
#define         PLMT_MTIME_CMP_LO_REG_ADDR      (PLMT_BASE_ADDR + 0x10)
#define         PLMT_MTIME_CMP_HI_REG_ADDR      (PLMT_BASE_ADDR + 0x14)
#define         PLMT_MTIME_TIP_REG_ADDR         (PLMT_BASE_ADDR + 0x18)
#define         PLMT_MTIME_SIP_REG_ADDR         (PLMT_BASE_ADDR + 0x1c)


void lnrv_plmt_enable();
void lnrv_plmt_disable();

uint64_t lnrv_plmt_get_count();
void lnrv_plmt_set_compare(uint64_t compare);
uint64_t lnrv_plmt_get_compare();

void lnrv_plmt_set_sip(void);
void lnrv_plmt_clr_sip(void);
uint32_t lnrv_plmt_get_sip(void);

void lnrv_plmt_clr_tip(void);
uint32_t lnrv_plmt_get_tip(void);

void lnrv_plmt_set_mode(uint8_t mode);


#endif