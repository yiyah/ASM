#ifndef __CONST_H_
#define __CONST_H_

#define PUBLIC          /* PUBLIC is the opposite of PRIVATE */
#define PRIVATE static  /* PRIVATE x limits the scope of x */

/* Boolean */
#define TRUE    1
#define FALSE   0

#define GDT_DESC_NUM 128
#define IDT_DESC_NUM 256

/* privilege */
#define PRIVILEGE_KRNL  0
#define PRIVILEGE_TASK  1
#define PRIVILEGE_USER  3

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

/* system call */
#define NR_SYS_CALL     1

#endif /* _CONST_H_ */
