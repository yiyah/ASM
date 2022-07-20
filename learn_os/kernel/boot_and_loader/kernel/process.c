#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "tty.h"
#include "console.h"
#include "proto.h"
#include "global.h"

PUBLIC void schedule()
{
    PROCESS* p;
    int greatest_ticks = 0;

    while (!greatest_ticks) {
        /* run the high priority process */
        for (p = proc_tables; p < proc_tables + NR_TASKS; p++) {
            if (p->ticks > greatest_ticks) {
                greatest_ticks = p->ticks;
                p_proc_ready = p;
            }
        }

        /* reload the tick if all processes decrease to 0 */
        if (!greatest_ticks) {
            for (p = proc_tables; p < proc_tables + NR_TASKS; p++){
                p->ticks = p->priority;
            }
        }        
    }
}

PUBLIC u32 sys_get_ticks()
{
    return ticks;
}
