%include "sconst.inc"

; global function
extern  cstart
extern  exception_handler
extern  spurious_irq
extern  kernel_main
extern  disp_str
extern  delay
extern  clock_handler

; global variable
extern  gdt_ptr
extern  idt_ptr
extern  p_proc_ready
extern  tss
extern  k_reenter
extern  irq_table

[SECTION .data]
clock_int_msg       db  "^", 0

[section .bss]
StackSpace      resb   2*1024
StackTop:       ; Top of Stack

[section .text]
global  _start
global  divide_error
global  single_step_exception
global  nmi
global  breakpoint_exception
global  overflow
global  bounds_check
global  inval_opcode
global  copr_not_available
global  double_fault
global  copr_seg_overrun
global  inval_tss
global  segment_not_present
global  stack_exception
global  general_protection
global  page_fault
global  copr_error
global  hwint00
global  hwint01
global  hwint02
global  hwint03
global  hwint04
global  hwint05
global  hwint06
global  hwint07
global  hwint08
global  hwint09
global  hwint10
global  hwint11
global  hwint12
global  hwint13
global  hwint14
global  hwint15
global  restart

; ===================================
; @Function: _start
; @Brief: the start of kernel.bin
; ===================================
_start:
    ; now is at 0x0:0x30400
    ; cs, ds, es, fs, ss is point to segment address: 0
    ; gs is point to segment address: SelVideo
    mov     esp, StackTop       ; StackTop will be physical address, I think it related with "ld -Ttext"

    sgdt    [gdt_ptr]           ; `.
    call    cstart              ;  | will change GDTR
    lgdt    [gdt_ptr]           ; /

    lidt    [idt_ptr]

    jmp     SEL_KERNEL_CS:_csinit; for force using the GDT which we init just now
_csinit:

    xor        eax, eax
    mov        ax, SELECTOR_TSS
    ltr        ax

    ;sti
    ;hlt
    ;ud2                        ; test exception
    ;jmp     0x40:0              ; test exception
    ;push    dword 0
    ;popfd                       ; refresh eflags
    jmp     kernel_main
    hlt

; ===================================
; @Function: exception 
; ===================================
divide_error:
    push    0xFFFFFFFF      ; no err code
    push    dword 0         ; vector_no    = 0
    jmp     exception
single_step_exception:
    push    0xFFFFFFFF      ; no err code
    push    dword 1         ; vector_no    = 1
    jmp     exception
nmi:
    push    0xFFFFFFFF      ; no err code
    push    dword 2         ; vector_no    = 2
    jmp     exception
breakpoint_exception:
    push    0xFFFFFFFF      ; no err code
    push    dword 3         ; vector_no    = 3
    jmp     exception
overflow:
    push    0xFFFFFFFF      ; no err code
    push    dword 4         ; vector_no    = 4
    jmp     exception
bounds_check:
    push    0xFFFFFFFF      ; no err code
    push    dword 5         ; vector_no    = 5
    jmp     exception
inval_opcode:
    push    0xFFFFFFFF      ; no err code
    push    dword 6         ; vector_no    = 6
    jmp     exception
copr_not_available:
    push    0xFFFFFFFF      ; no err code
    push    dword 7         ; vector_no    = 7
    jmp     exception
double_fault:
    push    dword 8         ; vector_no    = 8
    jmp     exception
copr_seg_overrun:
    push    0xFFFFFFFF      ; no err code
    push    dword 9         ; vector_no    = 9
    jmp     exception
inval_tss:
    push    dword 10        ; vector_no    = A
    jmp     exception
segment_not_present:
    push    dword 11        ; vector_no    = B
    jmp     exception
stack_exception:
    push    dword 12        ; vector_no    = C
    jmp     exception
general_protection:
    push    dword 13        ; vector_no    = D
    jmp     exception
page_fault:
    push    dword 14        ; vector_no    = E
    jmp     exception
copr_error:
    push    0xFFFFFFFF      ; no err code
    push    dword 16        ; vector_no    = 10h
    jmp     exception

exception:
    call    exception_handler
    add     esp, 4*2        ; skip vector number and err code, esp point to eip, now stack status: EIP, CS, EFLAGS
    ;iretd
    hlt

; ===================================
; @Function: hardware interrupt 
; ===================================
; ---------------------------------
%macro  hwint_master    1
    call    save
    in      al, INT_M_CTLMASK               ; `.
    or      al, (1 << %1)                   ;  | No more current interruption are allowed
    out     INT_M_CTLMASK, al               ; /
    mov     al, EOI                         ; `. reenable
    out     INT_M_CTL, al                   ; / master 8259
    sti
    push    dword %1
    call    [irq_table + 4 * %1]            ; interrupt handler
    add     esp, 4
    cli
    in      al, INT_M_CTLMASK               ; `.
    and     al, ~(1 << %1)                  ;  | Allow interruption again
    out     INT_M_CTLMASK, al               ; / because we had handlered once
    ret                                     ; jmp to restar of restar_reenter
%endmacro
; ---------------------------------

ALIGN   16
hwint00:                ; Interrupt routine for irq 0 (the clock).
        hwint_master    0

ALIGN   16
hwint01:                ; Interrupt routine for irq 1 (keyboard)
        hwint_master    1

ALIGN   16
hwint02:                ; Interrupt routine for irq 2 (cascade!)
        hwint_master    2

ALIGN   16
hwint03:                ; Interrupt routine for irq 3 (second serial)
        hwint_master    3

ALIGN   16
hwint04:                ; Interrupt routine for irq 4 (first serial)
        hwint_master    4

ALIGN   16
hwint05:                ; Interrupt routine for irq 5 (XT winchester)
        hwint_master    5

ALIGN   16
hwint06:                ; Interrupt routine for irq 6 (floppy)
        hwint_master    6

ALIGN   16
hwint07:                ; Interrupt routine for irq 7 (printer)
        hwint_master    7

; ---------------------------------
%macro  hwint_slave     1
        push    dword %1
        call    spurious_irq
        add     esp, 4
        hlt
%endmacro
; ---------------------------------

ALIGN   16
hwint08:                ; Interrupt routine for irq 8 (realtime clock).
        hwint_slave     8

ALIGN   16
hwint09:                ; Interrupt routine for irq 9 (irq 2 redirected)
        hwint_slave     9

ALIGN   16
hwint10:                ; Interrupt routine for irq 10
        hwint_slave     10

ALIGN   16
hwint11:                ; Interrupt routine for irq 11
        hwint_slave     11

ALIGN   16
hwint12:                ; Interrupt routine for irq 12
        hwint_slave     12

ALIGN   16
hwint13:                ; Interrupt routine for irq 13 (FPU exception)
        hwint_slave     13

ALIGN   16
hwint14:                ; Interrupt routine for irq 14 (AT winchester)
        hwint_slave     14

ALIGN   16
hwint15:                ; Interrupt routine for irq 15
        hwint_slave     15


; ===================================
; @Function: save
; @Brief: save register for process
;         Will change TopStack to kernel stack
; ===================================
save:
    pushad          ;`.
    push    ds      ; |
    push    es      ; | save register for process which be interrupted
    push    fs      ; |
    push    gs      ;/
    mov     ax, ss
    mov     ds, ax
    mov     es, ax

    mov     eax, esp                        ; esp is point to process table

    inc     dword [k_reenter]               ; increase when enter interrupt
    cmp     dword [k_reenter], 0
    jne     _RE_ENTER                       ; reenter
    
    mov     esp, StackTop                   ; change to kernel stack

    push    restart
    jmp     [eax + RETADR - P_STACKBASE]        ; exit save()
_RE_ENTER:
    push    restar_reenter
    jmp     [eax + RETADR - P_STACKBASE]        ; exit save()

; ===================================
; @Function: restart
; @Brief: start the process
; ===================================
restart:
    mov     esp, [p_proc_ready]
    lldt    [esp + P_LDT_SEL] 
    lea     eax, [esp + P_STACKTOP]
    mov     dword [tss + TSS3_S_SP0], eax
restar_reenter:
    dec     dword [k_reenter]
    pop     gs
    pop     fs
    pop     es
    pop     ds
    popad

    add     esp, 4

    iretd
