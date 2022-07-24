#ifndef __PROCESS_H_
#define __PROCESS_H_


/* Number of tasks */
#define NR_TASKS    1
#define NR_PROCS    3

/* stacks of tasks */
#define STACK_SIZE_TTY      0x8000              /* 32KB */
#define STACK_SIZE_TESTA    0x8000              /* 32KB */
#define STACK_SIZE_TESTB    0x8000              /* 32KB */
#define STACK_SIZE_TESTC    0x8000              /* 32KB */
#define STACK_SIZE_TOTAL    (STACK_SIZE_TTY   + \
                             STACK_SIZE_TESTA + \
                             STACK_SIZE_TESTB + \
                             STACK_SIZE_TESTC)


typedef struct s_stackframe {

    u32 gs;
    u32 fs;
    u32 es;
    u32 ds;
    u32 edi;
    u32 esi;
    u32 ebp;
    u32 kernel_esp;
    u32 ebx;
    u32 edx;
    u32 ecx;
    u32 eax;
    u32 retaddr;
    u32 eip;            /* \                               */
    u32 cs;             /* |                               */
    u32 eflags;         /* | push by CPU during interrupt  */
    u32 esp;            /* |                               */
    u32 ss;             /* /                               */
}STACK_FRAME;


typedef struct s_proc {
    STACK_FRAME     regs;
    u16             ldt_sel;
    DESCRIPTOR      ldts[LDT_SIZE];
    int             ticks;
    int             priority;
    u32             pid;
    char            p_name[32];
    int             nr_tty;     /* print in which concole */
}PROCESS;

typedef struct s_task {
    task_f  initial_eip;
    int     stacksize;
    char    name[32];
}TASK;

#endif
