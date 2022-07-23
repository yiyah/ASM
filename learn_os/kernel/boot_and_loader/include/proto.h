#ifndef __PROTO_H_
#define __PROTO_H_


/* string.asm */
PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);
PUBLIC void memset(void* p_dst, u8 ch, u32 size);
PUBLIC char* strcpy(char* p_dst, char* p_src);

/* kliba.asm */
PUBLIC void disp_str(char* pszInfo);
PUBLIC void disp_color_str(char* pszInfo, u8 color);
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8   in_byte(u16 port);
PUBLIC void disable_irq(u32 irq);
PUBLIC void enable_irq(u32 irq);
PUBLIC void enable_int();
PUBLIC void disable_int();

/* syscall.asm */
PUBLIC void sys_call();
PUBLIC u32 get_ticks();

/* kernel.asm */
PUBLIC void restart();

/* i8259.c */
PUBLIC void init_8259A();
PUBLIC void spurious_irq(u32 irq);
PUBLIC void put_irq_handler(u32 irq, irq_handler handler);

/* protect.c */
PUBLIC void init_prot();

/* klib.c */
PUBLIC void disp_hex_oneByte(u8 hex);
PUBLIC void disp_hex_fourByte(u32 hex);
PUBLIC void delay(u16 timef);
PUBLIC void ClearScreen();

/* main.c */
extern PROCESS* p_proc_ready;
extern PUBLIC PROCESS proc_tables[NR_TASKS+NR_PROCS];

/* start.c */
extern PUBLIC TSS tss;
extern PUBLIC DESCRIPTOR gdt[GDT_DESC_NUM];
extern PUBLIC GATE idt[IDT_DESC_NUM];

/* main.c */
void TestA();
void TestB();
void TestC();

/* clock.c */
PUBLIC void clock_handler(u32 irq);
PUBLIC void init_clock();
PUBLIC void milli_delay(u32 milli_sec);

/* process.c */
PUBLIC void schedule();
PUBLIC u32 sys_get_ticks();

/* keyboard.c */
PUBLIC void init_keyboard();
PUBLIC void keyboard_read();

/* tty.c */
PUBLIC void task_tty();
PUBLIC void in_process(TTY* p_tty, u32 key);

#endif
