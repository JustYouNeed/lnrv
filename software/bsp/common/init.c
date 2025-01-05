#include "../includes/lnrv_soc.h"

extern void trap_entry();


void _init()
{
    // 设置中断入口函数
    write_csr(mtvec, &trap_entry);
    // 使能CPU全局中断
    // MIE = 1, MPIE = 1, MPP = 11
    write_csr(mstatus, 0x1888);

    // 使能定时器中断
    write_csr(mie, (0x1<<7));
}
