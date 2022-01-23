%include "pm.inc"

        org     0x7C00
        jmp     LABEL_BEGIN

[SECTION .gdt]
;                                  base,    segment limit, segment attribute
LABEL_GDT:          Descriptor        0,                0, 0
LABEL_DESC_CODE32:  Descriptor        0, SegCode32Len - 1, DA_C + DA_32
LABEL_DESC_VIDEO:   Descriptor  0xB8000,           0xFFFF, DA_DRW

GDTLEN          equ     $ - LABEL_GDT   ; length of GDT
GDTPTR          dw      GDTLEN - 1      ; limit of GDT
                dd      0               ; segment base address of GDT; Modify in 16bit code

; GDT selector
SelectorCode32      equ     LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo       equ     LABEL_DESC_VIDEO  - LABEL_GDT
; END of [SECTION .gdt]

[SECTION .s16]
[BITS   16]
LABEL_BEGIN:
        mov     ax,cs
        mov     ss,ax
        mov     sp,0x100

        ; init Descriptor
        xor     eax,eax
        mov     ax,cs
        shl     eax,4
        add     eax,LABEL_SEG_CODE32
        mov     [LABEL_DESC_CODE32+2],ax
        shr     eax,16
        mov     [LABEL_DESC_CODE32+4],al
        mov     [LABEL_DESC_CODE32+7],ah

        ; calculate gdtr
        xor     eax,eax
        mov     ax,cs
        shl     eax,4
        add     eax,LABEL_GDT
        mov     [GDTPTR+2],eax
        lgdt    [GDTPTR]

        ; close IRQ
        cli

        ; open A20
        in      al,92H
        or      al,00000010B
        out     92H,al

        ; set the protect flag
        mov     eax,cr0
        or      eax,1
        mov     cr0,eax

        ; enter protect mode
        jmp     dword SelectorCode32:0

; END of [SECTION .s16]

[SECTION .s32]
[BITS   32]
LABEL_SEG_CODE32:
        ; show something
        mov     ax,SelectorVideo
        mov     es,ax
        mov     edi,80*2*10+79*2
        
        mov     al,'P'
        mov     ah,02H
        mov     [es:edi],ax
        jmp     $

SegCode32Len    equ     $ - LABEL_SEG_CODE32
; END of [SECTION .s32]

times   365 db 0  ; replce the first argument with (512 - file_size)
dw      0xAA55
