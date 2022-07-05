#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "proto.h"
#include "global.h"


PUBLIC u32      k_reenter;
PUBLIC PROCESS* p_proc_ready;
PUBLIC PROCESS  proc_tables[NR_TASKS];
PUBLIC u8       task_stack[STACK_SIZE_TOTAL];       /* include all process stack */


void TestA()
{
    int i = 0;
    while(1)
    {
        disp_str("A");
        disp_hex_oneByte(i++);
        disp_str(".");
        delay(10);
    }
    return;
}

void TestB()
{
    int i = 0x00;
    while(1)
    {
        disp_str("B");
        disp_hex_oneByte(i++);
        disp_str(".");
        delay(10);
    }
    return;
}


PUBLIC void kernel_main()
{
    disp_str("--------kernel main begins--------\n");

    PROCESS* p_proc = proc_tables;
    TASK*    p_task = task_table;
    char*    p_task_stack = task_stack + STACK_SIZE_TOTAL;      /* top of stack */
    u16      selector_ldt = SELECTOR_LDT_FIRST;
    int i = 0;

    for(i = 0; i < NR_TASKS; i++) {
        strcpy(p_proc->p_name, p_task->name);
        p_proc->pid = i;

        /* init descriptor in LDT */
        p_proc->ldt_sel = selector_ldt;
        memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS>>3], sizeof(DESCRIPTOR));
        p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5;
        memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS>>3], sizeof(DESCRIPTOR));
        p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK << 5;
        p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK ;
        p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK ;
        p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK ;
        p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK ;
        p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK ;
        p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;
        p_proc->regs.eip = (u32)p_task->initial_eip;
        p_proc->regs.esp = (u32)p_task_stack;
        p_proc->regs.eflags = 0x1202;        // IF=1, IOPL=1, bit 2 is always 1.

        /* for next init LDT */
        p_task_stack -= p_task->stacksize;
        p_proc++;
        p_task++;
        selector_ldt += 1 << 3;
    }

    k_reenter = 0;              /* the first time will self-decrement */

    p_proc_ready = proc_tables;
    restart();

    while(1){}
    return;
}
