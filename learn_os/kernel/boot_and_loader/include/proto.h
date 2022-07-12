#ifndef __PROTO_H_
#define __PROTO_H_

#include "protect.h"
#include "process.h"

extern PROCESS* p_proc_ready;

/* string.asm */
PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);
PUBLIC void memset(void* p_dst, u8 ch, u32 size);
PUBLIC char* strcpy(char* p_dst, char* p_src);
void disable_irq(u32 irq);
void enable_irq(u32 irq);

/* kliba.asm */
PUBLIC void disp_str(char* pszInfo);
PUBLIC void disp_color_str(char* pszInfo, u8 color);
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8   in_byte(u16 port);

/* i8259.c */
PUBLIC void init_8259A();
PUBLIC void spurious_irq(u32 irq);
PUBLIC void put_irq_handler(u32 irq, irq_handler handler);

PUBLIC void init_prot();
PUBLIC void disp_hex_oneByte(u8 hex);
PUBLIC void disp_hex_fourByte(u32 hex);
PUBLIC void restart();

PUBLIC void delay(u16 timef);

extern PUBLIC PROCESS proc_tables[NR_TASKS];
extern PUBLIC TSS tss;
extern PUBLIC DESCRIPTOR gdt[GDT_DESC_NUM];
extern PUBLIC GATE idt[IDT_DESC_NUM];

/* main.c */
void TestA();
void TestB();
void TestC();

/* clock.c */
PUBLIC void clock_handler(u32 irq);
PUBLIC void milli_delay(u32 milli_sec);

/* proc.c */
PUBLIC void schedule();
PUBLIC u32 sys_get_ticks();

/* syscall.asm */
PUBLIC void sys_call();
PUBLIC u32 get_ticks();

#endif
