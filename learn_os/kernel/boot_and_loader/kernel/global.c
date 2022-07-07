#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "proto.h"
#include "global.h"

PUBLIC u32 ticks;  
PUBLIC irq_handler irq_table[NR_IRQ];
PUBLIC TASK task_table[NR_TASKS] = {{TestA, STACK_SIZE_TESTA, "TestA"},
                                    {TestB, STACK_SIZE_TESTA, "TestB"}};
PUBLIC system_call sys_call_table[NR_SYS_CALL] = {sys_get_ticks};
