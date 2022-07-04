#ifndef __PROTO_H_
#define __PROTO_H_

#include "protect.h"
#include "process.h"

extern PROCESS* p_proc_ready;

/* string.asm */
PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);
PUBLIC void memset(void* p_dst, u8 ch, u32 size);
PUBLIC char* strcpy(char* p_dst, char* p_src);

/* kliba.asm */
PUBLIC void disp_str(char* pszInfo);
PUBLIC void disp_color_str(char* pszInfo, u8 color);
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8   in_byte(u16 port);

PUBLIC void init_prot();
PUBLIC void init_8259A();
PUBLIC void disp_hex_oneByte(u8 hex);
PUBLIC void disp_hex_fourByte(u32 hex);
PUBLIC void restart();

PUBLIC void delay(u16 timef);

extern PUBLIC PROCESS proc_tables[NR_TASKS];
extern PUBLIC TSS tss;
extern PUBLIC DESCRIPTOR gdt[GDT_DESC_NUM];
extern PUBLIC GATE idt[IDT_DESC_NUM];

void TestA();
void TestB();

#endif
