    org     0x0
    jmp     KERNEL_BEGIN

%include "common.inc"

    BASEOFSTACK     equ     0x0
    KernelMessage:  db      'Now is in kernel', 0

KERNEL_BEGIN:
    ; now is at 0x8000:0
    mov     ax, cs
    mov     ds, ax
    mov     ss, ax
    mov     sp, BASEOFSTACK


    mov     si, KernelMessage
    mov     di, 4*80*2+20*2
    call    DispStr
    jmp     $
