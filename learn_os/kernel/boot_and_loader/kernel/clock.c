#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "proto.h"
#include "global.h"


/**
  * @brief  called by hwint_master
  * @param  irq: it must 0
  * @retval None
  */
PUBLIC void clock_handler(u32 irq)
{
    ticks++;
    p_proc_ready->ticks--;

    if (k_reenter != 0) {
        /* reenter */
        return;
    }

    if ( p_proc_ready->ticks > 0) {
        /* run high priority process until ticks=0 */
        return;
    }

    schedule();
}

PUBLIC void init_clock()
{
    /* init 8253 PIT */
    /* set clock frequency with macro: HZ */
    out_byte(TIMER_MODE_PORT, RATE_GENERATOR);
    out_byte(TIMER0_PORT, (u8)(TIMER_FREQ/HZ));
    out_byte(TIMER0_PORT, (u8)((TIMER_FREQ/HZ)>>8));

    put_irq_handler(CLOCK_IRQ, clock_handler); /* 设定时钟中断处理程序 */
    enable_irq(CLOCK_IRQ);                     /* 让8259A可以接收时钟中断 */
}

/**
  * @brief  delay by using clock interrupt
  * @param  milli_sec: min:10 = 10ms
  * @retval None
  */
PUBLIC void milli_delay(u32 milli_sec)
{
    int t = get_ticks();
    while(((get_ticks() - t) * 1000/HZ) < milli_sec) {}
}
