#include "lnrv_plmt.h"


# define    ILM_BASE_ADDR       0x00000000

void plmt_irq_tmr_handler()
{
    uint64_t compare = 0;
    compare = lnrv_plmt_get_compare();

    // compare += 1024;
    // lnrv_plmt_set_compare(compare);
    lnrv_plmt_clr_tip();
}

void main()
{
    int i = 0;
    int sum = 0;
    int offset = 1024 * 4;

    int32_t  buf[1024];

    lnrv_plmt_set_compare(1023);
    lnrv_plmt_enable();
    lnrv_plmt_set_mode(1);


    while(1)
    {
        lnrv_plmt_get_count();
    }
}