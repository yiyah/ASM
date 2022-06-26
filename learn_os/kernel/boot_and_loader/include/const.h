#ifndef __CONST_H_
#define __CONST_H_

#define PUBLIC          /* PUBLIC is the opposite of PRIVATE */
#define PRIVATE static  /* PRIVATE x limits the scope of x */

#define GDT_DESC_NUM 128
#define IDT_DESC_NUM 256

/* privilege */
#define	PRIVILEGE_KRNL	0
#define	PRIVILEGE_TASK	1
#define	PRIVILEGE_USER	3

/* define I8259A interrupt controllers ports */
#define I8259A_MASTER_PORT       0x20
#define I8259A_MASTER_PORTMASK   0x21
#define I8259A_SLAVE_PORT        0xA0
#define I8259A_SLAVE_PORTMASK    0xA1

#endif /* _CONST_H_ */
