#ifndef __CONST_H_
#define __CONST_H_

#define PUBLIC          /* PUBLIC is the opposite of PRIVATE */
#define PRIVATE static  /* PRIVATE x limits the scope of x */

#define STR_DEFAULT_LEN 1024

/* Color */
/*
 * e.g. MAKE_COLOR(BLUE, RED)
 *      MAKE_COLOR(BLACK, RED) | BRIGHT
 *      MAKE_COLOR(BLACK, RED) | BRIGHT | FLASH
 */
#define BLACK   0x0     /* 0000 */
#define WHITE   0x7     /* 0111 */
#define RED     0x4     /* 0100 */
#define GREEN   0x2     /* 0010 */
#define BLUE    0x1     /* 0001 */
#define FLASH   0x80    /* 1000 0000 */
#define BRIGHT  0x08    /* 0000 1000 */
#define MAKE_COLOR(x,y) ((x<<4) | y) /* MAKE_COLOR(Background,Foreground) */

/* Boolean */
#define TRUE    1
#define FALSE   0

#define GDT_DESC_NUM 128
#define IDT_DESC_NUM 256

/* privilege */
#define PRIVILEGE_KRNL  0
#define PRIVILEGE_TASK  1
#define PRIVILEGE_USER  3

/* Process */
#define SENDING   0x02  /* set when proc trying to send */
#define RECEIVING 0x04  /* set when proc trying to recv */

/* TTY */
#define NR_CONSOLES     3

/* define I8259A interrupt controllers ports */
#define I8259A_MASTER_PORT       0x20
#define I8259A_MASTER_PORTMASK   0x21
#define I8259A_SLAVE_PORT        0xA0
#define I8259A_SLAVE_PORTMASK    0xA1

/* 8253/8254 PIT (Programmable Interval Timer) */
#define TIMER0_PORT     0x40 /* I/O port for timer channel 0 */
#define TIMER_MODE_PORT 0x43 /* I/O port for timer mode control */
#define RATE_GENERATOR  0x34 /* 00-11-010-0 :
                             * Counter0 - LSB then MSB - rate generator - binary
                             */
#define TIMER_FREQ      1193182L /* clock frequency for timer in PC and AT */
#define HZ              100      /* clock freq (software settable on IBM-PC) */

/* AT keyboard */
/* 8042 ports */
#define KB_DATA     0x60    /* I/O port for keyboard data
                               Read : Read Output Buffer
                               Write: Write Input Buffer(8042 Data&8048 Command) */
#define KB_CMD      0x64    /* I/O port for keyboard command
                               Read : Read Status Register
                               Write: Write Input Buffer(8042 Command) */
#define LED_CODE    0xED
#define KB_ACK      0xFA

/* VGA */
#define CRTC_ADDR_REG   0x3D4       /* CRT Controller Registers - Addr Register */
#define CRTC_DATA_REG   0x3D5       /* CRT Controller Registers - Data Register */
#define START_ADDR_H    0xC         /* reg index of video mem start addr (MSB)  */
#define START_ADDR_L    0xD         /* reg index of video mem start addr (LSB)  */
#define CURSOR_H        0xE         /* reg index of cursor position (MSB)       */
#define CURSOR_L        0xF         /* reg index of cursor position (LSB)       */
#define V_MEM_BASE      0xB8000     /* base of color video memory               */
#define V_MEM_SIZE      0x8000      /* 32K: B8000H -> BFFFFH                    */

/* Hardware interrupts */
#define NR_IRQ          16  /* Number of IRQs */
#define CLOCK_IRQ       0
#define KEYBOARD_IRQ    1
#define CASCADE_IRQ     2   /* cascade enable for 2nd AT controller */
#define ETHER_IRQ       3   /* default ethernet interrupt vector */
#define SECONDARY_IRQ   3   /* RS232 interrupt vector for port 2 */
#define RS232_IRQ       4   /* RS232 interrupt vector for port 1 */
#define XT_WINI_IRQ     5   /* xt winchester */
#define FLOPPY_IRQ      6   /* floppy disk */
#define PRINTER_IRQ     7
#define AT_WINI_IRQ     14  /* at winchester */

/* Hard Drive */
#define SECTOR_SIZE     512

/* tasks */
/* 注意 TASK_XXX 的定义要与 global.c 中对应 */
#define INTERRUPT       -10
#define TASK_TTY        0
#define TASK_SYS        1
#define TASK_HD         2
#define ANY             (NR_TASKS + NR_PROCS + 10)
#define NO_TASK         (NR_TASKS + NR_PROCS + 20)

/* system call */
#define NR_SYS_CALL     2

/* ipc */
#define SEND            1
#define RECEIVE         2
#define BOTH            3       /* BOTH = (SEND | RECEIVE) */

/* magic chars used by `printx' */
#define MAG_CH_PANIC    '\002'
#define MAG_CH_ASSERT   '\003'

/* the assert macro */
#define ASSERT
#ifdef  ASSERT
void assertion_failure(char *exp, char *file, char *base_file, int line);
#define assert(exp) if (exp) ; \
        else assertion_failure(#exp, __FILE__, __BASE_FILE__, __LINE__)
#else
#define asser(exp)
#endif

/**
 * @enum msgtype
 * @brief MESSAGE types
 */
enum msgtype {
    /* 
     * when hard interrupt occurs, a msg (with type==HARD_INT) will
     * be sent to some tasks
     */
    HARD_INT = 1,

    /* SYS task */
    GET_TICKS,

    /* message type for drivers */
    DEV_OPEN = 1001,
};

#define RETVAL  u.m3.m3i1

#endif /* _CONST_H_ */
