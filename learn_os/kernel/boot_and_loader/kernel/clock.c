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
        return;
    }

    schedule();
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
