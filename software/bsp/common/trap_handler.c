#include <stdint.h>


extern void plmt_irq_tmr_handler() __attribute__((weak));


void trap_handler(uint32_t mcause, uint32_t mepc)
{
    // we have only timer0 interrupt here

    if(mcause & 0x7 == 0x07)
    {
        plmt_irq_tmr_handler();
    }
    // timer0_irq_handler();
}
