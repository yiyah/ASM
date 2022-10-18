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
        for (p = proc_tables; p < proc_tables + NR_TASKS + NR_PROCS; p++) {
            if (p->ticks > greatest_ticks) {
                greatest_ticks = p->ticks;
                p_proc_ready = p;
            }
        }

        /* reload the tick if all processes decrease to 0 */
        if (!greatest_ticks) {
            for (p = proc_tables; p < proc_tables + NR_TASKS + NR_PROCS; p++){
                p->ticks = p->priority;
            }
        }        
    }
}

PUBLIC u32 sys_get_ticks()
{
    return ticks;
}

/**
  * @brief  <Ring 0~1> Calculate the linear address of a certain segment of a given proc.
  * @param  p   Whose (the proc ptr).
  * @param  idx Which (one proc has more than one segments).
  * @retval The required linear address.
  */
PUBLIC int ldt_seg_linear(PROCESS* p, int idx)
{
    DESCRIPTOR * d = &p->ldts[idx];

    return d->base_high << 24 | d->base_mid << 16 | d->base_low;
}

/**
  * @brief  <Ring 0~1> Virtual addr --> Linear addr.
  * @param  pid  PID of the proc whose address is to be calculated.
  * @param  va   Virtual address.
  * @retval The linear address for the given virtual address.
  */
PUBLIC void* va2la(int pid, void* va)
{
    PROCESS* p = &proc_tables[pid];

    u32 seg_base = ldt_seg_linear(p, INDEX_LDT_RW);
    u32 la = seg_base + (u32)va;

    if (pid < NR_TASKS + NR_PROCS) {
        // TODO
        //assert(la == (u32)va);
    }

    return (void*)la;
}
