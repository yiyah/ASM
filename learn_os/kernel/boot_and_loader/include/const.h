#ifndef __CONST_H_
#define __CONST_H_

#define PUBLIC          /* PUBLIC is the opposite of PRIVATE */
#define PRIVATE static  /* PRIVATE x limits the scope of x */

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
