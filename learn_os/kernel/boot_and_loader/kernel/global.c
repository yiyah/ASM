#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "proto.h"
#include "global.h"

PUBLIC u32 ticks;  
PUBLIC irq_handler irq_table[NR_IRQ];

/* need match NR_TASKS */
PUBLIC TASK task_table[NR_TASKS] = {{task_tty, STACK_SIZE_TTY, "tty"},
                                    {TestA, STACK_SIZE_TESTA, "TestA"},
                                    {TestB, STACK_SIZE_TESTB, "TestB"},
                                    {TestC, STACK_SIZE_TESTC, "TestC"}};
PUBLIC system_call sys_call_table[NR_SYS_CALL] = {sys_get_ticks};
