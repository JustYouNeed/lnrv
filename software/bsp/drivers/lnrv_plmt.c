#include "lnrv_plmt.h"


void lnrv_plmt_enable()
{
    __IO_WR_32(PLMT_MTIME_ENABLE_REG_ADDR, 0x1);
}
void lnrv_plmt_disable()
{
    __IO_WR_32(PLMT_MTIME_ENABLE_REG_ADDR, 0x0);
}

uint64_t lnrv_plmt_get_count()
{
    uint64_t mtime_cnt = 0;

    mtime_cnt = __IO_RD_32(PLMT_MTIME_CNT_HI_REG_ADDR) << 32;
    mtime_cnt |= __IO_RD_32(PLMT_MTIME_CNT_LO_REG_ADDR);

    return mtime_cnt;
}

void lnrv_plmt_set_compare(uint64_t compare)
{
    uint32_t mtime_cmp_hi, mtime_cmp_lo;

    mtime_cmp_hi = (compare >> 32) & 0xffffffff;
    mtime_cmp_lo = compare & 0xffffffff;

    __IO_WR_32(PLMT_MTIME_CMP_HI_REG_ADDR, mtime_cmp_hi);
    __IO_WR_32(PLMT_MTIME_CMP_LO_REG_ADDR, mtime_cmp_lo);
}

uint64_t lnrv_plmt_get_compare()
{
    uint64_t compare = 0;

    compare = __IO_RD_32(PLMT_MTIME_CMP_HI_REG_ADDR) << 32;
    compare |= __IO_RD_32(PLMT_MTIME_CMP_LO_REG_ADDR);

    return compare;
}
void lnrv_plmt_set_sip(void)
{
    __IO_WR_32(PLMT_MTIME_SIP_REG_ADDR, 0x1);
}

void lnrv_plmt_clr_sip(void)
{
    __IO_WR_32(PLMT_MTIME_SIP_REG_ADDR, 0x0);
}

uint32_t lnrv_plmt_get_sip(void)
{
    return __IO_RD_32(PLMT_MTIME_SIP_REG_ADDR);
}

void lnrv_plmt_clr_tip(void)
{
    __IO_WR_32(PLMT_MTIME_TIP_REG_ADDR, 0x0);
}

uint32_t lnrv_plmt_get_tip(void)
{
    return __IO_RD_32(PLMT_MTIME_TIP_REG_ADDR);
}

void lnrv_plmt_set_mode(uint8_t mode)
{
    uint32_t mtime_ctrl = 0;
    mtime_ctrl = __IO_RD_32(PLMT_MTIME_CTRL_REG_ADDR);
    mtime_ctrl &= ~(1 << 0);

    mtime_ctrl |= (mode & 0x1);
    __IO_WR_32(PLMT_MTIME_CTRL_REG_ADDR, mtime_ctrl);
}