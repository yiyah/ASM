%include "pm.inc"
        org     0x7C00
        jmp     LABEL_BEGIN

[SECTION .gdt]
LABEL_GDT:          Descriptor        0,                0,   0
LABEL_DESC_CODE32:  Descriptor        0, SegCode32Len - 1, DA_32 + DA_C
LABEL_DESC_VIDEO:   Descriptor  0xB8000,           0xFFFF, DA_DRW

GDT_LEN    equ  $ - LABEL_GDT
GDT_PTR    dw   GDT_LEN - 1
           dd   0

; selector
SelectorCode32      equ  LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo       equ  LABEL_DESC_VIDEO  - LABEL_GDT
; END of [SECTION .gdt]

[SECTION .s16]
[BITS   16]
LABEL_BEGIN:

    xor     eax,eax
    mov     ax,cs
    shl     eax,4
    add     eax,LABEL_SEG_CODE32
    mov     [LABEL_DESC_CODE32+2],ax
    shr     eax,16
    mov     [LABEL_DESC_CODE32+4],al
    mov     [LABEL_DESC_CODE32+7],ah

    ; load gdtr
    xor     eax,eax
    mov     ax,cs
    shl     eax,4
    add     eax,LABEL_GDT
    mov     [GDT_PTR+2],eax
    lgdt    [GDT_PTR]

    cli

    in      al,92H
    or      al,00000010B
    out     92H,al

    mov     eax,cr0
    or      eax,1
    mov     cr0,eax

    jmp     dword SelectorCode32:0

; END of [SECTION .s16]

[SECTION .s32]
[BITS  32]
LABEL_SEG_CODE32:
    mov     ax,SelectorVideo
    mov     es,ax
    xor     edi,edi

    mov     al,'p'
    mov     [es:edi],al
    mov     al,0x02
    mov     [es:edi+1],al
    jmp     $

SegCode32Len    equ     $ - LABEL_SEG_CODE32
; END of [SECTION .s32]
