%include "pm.inc"
        org     0x7C00
        jmp     LABEL_BEGIN

[SECTION .gdt]
LABEL_GDT:          Descriptor        0,                0,   0
LABEL_DESC_CODE32:  Descriptor        0, SegCode32Len - 1, DA_32 + DA_C
LABEL_DESC_VIDEO:   Descriptor  0xB8000,           0xFFFF, DA_DRW
LABEL_DESC_STACK:   Descriptor   0x1000,              512, DA_DRWA | DA_32
LABEL_DESC_DATA:    Descriptor        0,      DataLen - 1, DA_DRW
LABEL_DESC_TEST:    Descriptor 0x500000,           0xFFFF, DA_DRW

GDT_LEN    equ  $ - LABEL_GDT
GDT_PTR    dw   GDT_LEN - 1
           dd   0

; selector
SelectorCode32      equ  LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo       equ  LABEL_DESC_VIDEO  - LABEL_GDT
SelectorStack       equ  LABEL_DESC_STACK  - LABEL_GDT
SelectorData        equ  LABEL_DESC_DATA   - LABEL_GDT
SelectorTest        equ  LABEL_DESC_TEST   - LABEL_GDT
; END of [SECTION .gdt]

; I can't do this in org 0x7C00
; [SECTION .stack]
; ALIGN  32
; [BITS   32]
; LABEL_STACK:
;     times       512     db      0
; TopOfStack      equ     $ - LABEL_STACK - 1 ; Actually it's length of stack + 1
; ; END of [SECTION .stack]

[SECTION .data1]
ALIGN  32
[BITS   32]
LABEL_DATA:
StackPointInRealMode    dw      0
RMMessage:          db      'In Real mode', 0
PMMessage:          db      'In Protect Mode now',0
StrTest:            db      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',0

OffsetRMMessage     equ     RMMessage - $$
OffsetPMMessage     equ     PMMessage - LABEL_DATA
OffsetStrTest       equ     StrTest   - LABEL_DATA
DataLen             equ     $ - LABEL_DATA
; END of [SECTION .data1]

[SECTION .s16]
[BITS   16]
LABEL_BEGIN:

    ; Init Descriptor of code32
    xor     eax,eax
    mov     ax,cs
    shl     eax,4
    add     eax,LABEL_SEG_CODE32
    mov     [LABEL_DESC_CODE32+2],ax
    shr     eax,16
    mov     [LABEL_DESC_CODE32+4],al
    mov     [LABEL_DESC_CODE32+7],ah

    ; DATA
    xor     eax,eax
    mov     ax,cs
    shl     eax,4
    add     eax,LABEL_DATA
    mov     [LABEL_DESC_DATA+2],ax
    shr     eax,16
    mov     [LABEL_DESC_DATA+4],al
    mov     [LABEL_DESC_DATA+7],ah

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
    mov     ax,SelectorData
    mov     ds,ax
    mov     esi,OffsetPMMessage
    mov     edi,0
    call    ClearScreen
    call    DispStr
    jmp     $

; ===================================
; Function: clear screen
; ===================================
ClearScreen:
    push    eax
    push    ecx
    push    es
    push    edi

    xor     eax,eax
    xor     ecx,ecx
    xor     edi,edi
    mov     ax,SelectorVideo
    mov     es,ax
    mov     cx,25*80*2      ; 4000 Bytes
    mov     ax,0
Clear_Screen:
    mov     [es:edi],ax
    add     edi,2
    loop    Clear_Screen

    pop     edi
    pop     es
    pop     ecx
    pop     eax
    ret

; ===================================
; param: edi
; param: ds:esi
; ===================================
DispStr:
    push    ax
    push    ecx
    push    es
    push    esi
    push    edi
    mov     ax,SelectorVideo
    mov     es,ax
Disp_Str:
    xor     ecx,ecx
    mov     cl,[ds:esi]
    jcxz    Disp_Ret
    mov     ch,0x02     ; set green
    mov     [es:edi],cx ; display
    inc     esi
    add     edi,2
    jmp     Disp_Str    ; stop when cx = 0    
Disp_Ret:
    pop     edi
    pop     esi
    pop     es
    pop     ecx
    pop     ax
    ret

SegCode32Len    equ     $ - LABEL_SEG_CODE32
; END of [SECTION .s32]

times   169   db  0
dw      0xAA55
