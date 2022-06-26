#include "const.h"
#include "type.h"
#include "protect.h"
#include "proto.h"

/* GDT */
PUBLIC u8 gdt_ptr[6];
PUBLIC DESCRIPTOR gdt[GDT_DESC_NUM];
/* IDT */
PUBLIC u8 idt_ptr[6];
PUBLIC GATE idt[IDT_DESC_NUM];

PUBLIC void cstart()
{
    disp_str("kernel start\nhello world\nyiya");

    /* init new GDT */
    memcpy(gdt,                             /* new GDT */
        (void*)(*((u32*)(&gdt_ptr[2]))),    /* base of old GDT */
        *((u16*)(&gdt_ptr[0])) + 1          /* limit of old GDT */
    );

    *((u16*)(&gdt_ptr[0])) = GDT_DESC_NUM * sizeof(DESCRIPTOR) - 1;
    *((u32*)(&gdt_ptr[2])) = (u32)gdt;

    /* init new IDT */
    *((u16*)(&idt_ptr[0])) = IDT_DESC_NUM * sizeof(GATE) - 1;
    *((u32*)(&idt_ptr[2])) = (u32)idt;

    init_prot();

}
