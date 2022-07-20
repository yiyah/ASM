#ifndef __GLOBAL_H_
#define __GLOBAL_H_


extern u32 disp_pos;
extern PUBLIC u32      k_reenter;
extern TASK task_table[NR_TASKS];
extern irq_handler irq_table[NR_IRQ];
extern u32 ticks;
extern PUBLIC  TTY     tty_table[NR_CONSOLES];
extern PUBLIC  CONSOLE console_table[NR_CONSOLES];

int     nr_current_console;

#endif
