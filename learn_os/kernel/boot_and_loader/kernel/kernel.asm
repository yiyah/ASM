; global function
extern  cstart

; global variable
extern  gdt_ptr

SEL_KERNEL_CS   equ     8

[section .bss]
StackSpace      resb   2*1024
StackTop:       ; Top of Stack

[section .text]
global  _start
_start:
    ; now is at 0x0:0x30400
    ; cs, ds, es, fs, ss is point to segment address: 0
    ; gs is point to segment address: SelVideo
    mov     eax, StackTop       ; StackTop will be physical address, I think it related with "ld -Ttext"

    sgdt    [gdt_ptr]           ; `.
    call    cstart              ;  | will change GDTR
    lgdt    [gdt_ptr]           ; /

    jmp     SEL_KERNEL_CS:csinit
csinit:
    push    dword 0
    popfd                       ;

    hlt
