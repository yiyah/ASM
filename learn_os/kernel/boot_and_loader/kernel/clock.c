#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "proto.h"
#include "global.h"


PUBLIC void clock_handler(u32 irq)
{
    disp_str("#");
    ticks++;

    if (k_reenter != 0) {
        /* reenter */
        disp_str("!");
        return;
    }

    p_proc_ready++;
    if (p_proc_ready >= proc_tables + NR_TASKS)
    {
        p_proc_ready = proc_tables;
    }
    return;
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
