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
