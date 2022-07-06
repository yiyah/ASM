#include "type.h"
#include "const.h"
#include "proto.h"
#include "protect.h"
#include "global.h"


/* 线性地址 → 物理地址 */
#define vir2phys(seg_base, vir) (u32)(((u32)seg_base) + (u32)(vir))

extern u32 disp_pos;

/* interrupt handler */
void divide_error();
void single_step_exception();
void nmi();
void breakpoint_exception();
void overflow();
void bounds_check();
void inval_opcode();
void copr_not_available();
void double_fault();
void copr_seg_overrun();
void inval_tss();
void segment_not_present();
void stack_exception();
void general_protection();
void page_fault();
void copr_error();
/* for customize interrupt */
void hwint00();
void hwint01();
void hwint02();
void hwint03();
void hwint04();
void hwint05();
void hwint06();
void hwint07();
void hwint08();
void hwint09();
void hwint10();
void hwint11();
void hwint12();
void hwint13();
void hwint14();
void hwint15();

PRIVATE void init_IDT_Desc(u8 intVector, u8 desc_type, int_handler handler,
                           u8 privilege)
{
    u32 offset = (u32)handler;
    idt[intVector].offset_low   = offset & 0xFFFF;
    idt[intVector].selector     = SELECTOR_KERNEL_CS;
    idt[intVector].dcount       = 0; 
    idt[intVector].attr         = desc_type | (privilege << 5);
    idt[intVector].offset_high  = (offset >> 16) & 0xFFFF;
}

PRIVATE void init_Descriptor(DESCRIPTOR* p_desc, u32 base, u32 limit, u32 attr)
{
    p_desc->limit_low = limit & 0xFFFF;
    p_desc->base_low  = base & 0xFFFF;
    p_desc->base_mid  = (base>>16) & 0xFF;
    p_desc->attr1     = attr & 0xFF;
    p_desc->limit_high_attr2 = ((limit>>16) & 0xF) | ((attr>>8) & 0xF0);
    p_desc->base_high = (base>>24) & 0xFF;
}

/**
  * @brief  get physical address according to segment (selector)
  * @retval physical address
  */
PUBLIC u32 seg2phys(u16 seg)
{
    DESCRIPTOR* p_dest = &gdt[seg >> 3];
    return (p_dest->base_high<<24 | p_dest->base_mid<<16 | p_dest->base_low);
}


PUBLIC void init_prot()
{
    init_8259A();

    // 全部初始化成中断门(没有陷阱门)
    init_IDT_Desc(INT_VECTOR_DIVIDE, DA_386IGate, divide_error, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_DEBUG, DA_386IGate, single_step_exception, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_NMI, DA_386IGate, nmi, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_BREAKPOINT, DA_386IGate, breakpoint_exception, PRIVILEGE_USER);

    init_IDT_Desc(INT_VECTOR_OVERFLOW, DA_386IGate, overflow, PRIVILEGE_USER);

    init_IDT_Desc(INT_VECTOR_BOUNDS, DA_386IGate, bounds_check, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_INVAL_OP, DA_386IGate, inval_opcode, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_COPROC_NOT, DA_386IGate, copr_not_available, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_DOUBLE_FAULT, DA_386IGate, double_fault, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_COPROC_SEG, DA_386IGate, copr_seg_overrun, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_INVAL_TSS, DA_386IGate, inval_tss, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_SEG_NOT, DA_386IGate, segment_not_present, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_STACK_FAULT, DA_386IGate, stack_exception, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_PROTECTION, DA_386IGate, general_protection, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_PAGE_FAULT, DA_386IGate, page_fault, PRIVILEGE_KRNL);

    init_IDT_Desc(INT_VECTOR_COPROC_ERR, DA_386IGate, copr_error, PRIVILEGE_KRNL);

    /* for test: customize interrupt */
    init_IDT_Desc(INT_VECTOR_IRQ0+0, DA_386IGate, hwint00, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ0+1, DA_386IGate, hwint01, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ0+2, DA_386IGate, hwint02, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ0+3, DA_386IGate, hwint03, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ0+4, DA_386IGate, hwint04, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ0+5, DA_386IGate, hwint05, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ0+6, DA_386IGate, hwint06, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ0+7, DA_386IGate, hwint07, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ8+0, DA_386IGate, hwint08, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ8+1, DA_386IGate, hwint09, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ8+2, DA_386IGate, hwint10, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ8+3, DA_386IGate, hwint11, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ8+4, DA_386IGate, hwint12, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ8+5, DA_386IGate, hwint13, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ8+6, DA_386IGate, hwint14, PRIVILEGE_KRNL);
    init_IDT_Desc(INT_VECTOR_IRQ8+7, DA_386IGate, hwint15, PRIVILEGE_KRNL);

    /* init tss */
    memset(&tss, 0, sizeof(tss));
    tss.ss0 = SELECTOR_KERNEL_DS;
    init_Descriptor(&gdt[INDEX_TSS],
            vir2phys(seg2phys(SELECTOR_KERNEL_DS), &tss),
            sizeof(tss) - 1,
            DA_386TSS);
    tss.iobase = sizeof(tss);           /* 没有I/O许可位图 */

    /* init LDT */
    int i;
    u16 selector_ldt = INDEX_LDT_FIRST << 3;
    for (i = 0; i < NR_TASKS; i++) {
        init_Descriptor(
            &gdt[selector_ldt>>3],
            vir2phys(seg2phys(SELECTOR_KERNEL_DS), proc_tables[i].ldts),
            LDT_SIZE * sizeof(DESCRIPTOR) - 1,
            DA_LDT);
        selector_ldt += 1 << 3;
    }
}

PUBLIC void exception_handler(u32 vec_no, u32 err_code, u32 eip, u32 cs, u32 eflags)
{
    u8 text_color = 0x74;  /* 灰底红字 */
    char* err_msg[] = {
        "#DE Divide Error",
        "#DB RESERVED",
        "--  NMI Interrupt",
        "#BP Breakpoint",
        "#OF Overflow",
        "#BR BOUND Range Exceeded",
        "#UD Invalid Opcode (Undefined Opcode)",
        "#NM Device Not Available (No Math Coprocessor)",
        "#DF Double Fault",
        "    Coprocessor Segment Overrun (reserved)",
        "#TS Invalid TSS",
        "#NP Segment Not Present",
        "#SS Stack-Segment Fault",
        "#GP General Protection",
        "#PF Page Fault",
        "--  (Intel reserved. Do not use.)",
        "#MF x87 FPU Floating-Point Error (Math Fault)",
        "#AC Alignment Check",
        "#MC Machine Check",
        "#XF SIMD Floating-Point Exception"};

    disp_pos = 0;
    for(int i = 0; i<2*80*3; i++)
    {
        disp_str(" ");
    }
    disp_pos = 0;

    disp_color_str("vec_no:", text_color);
    disp_hex_fourByte(vec_no);

    disp_color_str("err_code:", text_color);
    disp_hex_fourByte(err_code);

    disp_color_str("eip:", text_color);
    disp_hex_fourByte(eip);

    disp_color_str("cs:", text_color);
    disp_hex_fourByte(cs);

    disp_color_str("eflags:", text_color);
    disp_hex_fourByte(eflags);
    //disp_str("\n\n");
    disp_color_str("\n\n", text_color);
    disp_color_str("msg:", text_color);
    disp_color_str(err_msg[vec_no], text_color);

}
