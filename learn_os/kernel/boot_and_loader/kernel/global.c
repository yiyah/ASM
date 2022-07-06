#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"
#include "proto.h"
#include "global.h"


PUBLIC irq_handler irq_table[NR_IRQ];
PUBLIC TASK task_table[NR_TASKS] = {{TestA, STACK_SIZE_TESTA, "TestA"},
                                    {TestB, STACK_SIZE_TESTA, "TestB"}};
