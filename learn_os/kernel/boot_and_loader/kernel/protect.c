#include "type.h"
#include "const.h"
#include "proto.h"
#include "protect.h"

extern u32 disp_pos;
extern PUBLIC GATE idt[IDT_DESC_NUM];

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
