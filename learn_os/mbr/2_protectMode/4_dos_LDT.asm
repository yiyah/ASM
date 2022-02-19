%include "pm.inc"
    org     0x100
    jmp     LABEL_BEGIN

[SECTION .gdt]
LABEL_DESC_GDT:     Descriptor  0,                  0,   0
LABEL_DESC_NORMAL:  Descriptor  0,             0xFFFF, DA_DRW
LABEL_DESC_STACK:   Descriptor  0,         TopOfStack, DA_DRWA | DA_32
LABEL_DESC_DATA:    Descriptor  0,      LenOfData - 1, DA_DRW
LABEL_DESC_CODE32:  Descriptor  0,    LenOfCode32 - 1, DA_32 | DA_C
LABEL_DESC_VIDEO:   Descriptor 0xB8000,        0xffff, DA_DRW

LenOfGDT    equ     $ - LABEL_DESC_GDT
PTR_GDT     dw      LenOfGDT - 1
            dd      0

; selector
SelectorNormal      equ LABEL_DESC_NORMAL - LABEL_DESC_GDT
SelectorStack       equ LABEL_DESC_STACK  - LABEL_DESC_GDT
SelectorData        equ LABEL_DESC_DATA   - LABEL_DESC_GDT
SelectorCode32      equ LABEL_DESC_CODE32 - LABEL_DESC_GDT
SelectorVideo       equ LABEL_DESC_VIDEO  - LABEL_DESC_GDT
; END OF [SECTION .gdt]

[SECTION .stack]
ALIGN   32
[BITS   32]
LABEL_SEG_STACK:
    times   512     db  0
TopOfStack  equ     $ - LABEL_SEG_STACK - 1
; END OF [SECTION .stack]

[SECTION .data]
ALIGN   32
[BITS   32]
LABEL_SEG_DATA:
PMMESSAGE:  db      'hello world!', 0
OffsetPMMessage     equ     PMMESSAGE - LABEL_SEG_DATA
LenOfData   equ     $ - LABEL_SEG_DATA
; END OF [SECTION .data]

[SECTION .s16]
[BITS   16]
LABEL_BEGIN:
    mov     ax, cs
    mov     ss, ax
    mov     sp, 0x100

    ; stack
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_STACK
    mov     [LABEL_DESC_STACK + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_STACK + 4], al
    mov     [LABEL_DESC_STACK + 7], ah

    ; data
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_DATA
    mov     [LABEL_DESC_DATA + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_DATA + 4], al
    mov     [LABEL_DESC_DATA + 7], ah

    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_CODE32
    mov     [LABEL_DESC_CODE32 + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_CODE32 + 4], al
    mov     [LABEL_DESC_CODE32 + 7], ah

    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_DESC_GDT
    mov     [PTR_GDT + 2], eax
    lgdt    [PTR_GDT]

    cli

    in      al,92H
    or      al,00000010B
    out     92H,al

    mov     eax,cr0
    or      eax,1
    mov     cr0,eax

    jmp     dword SelectorCode32:0

    ; END OF [SECTION .s16]

[SECTION .s32]
[BITS   32]
LABEL_SEG_CODE32:
    ; refresh the regester
    mov     ax, SelectorNormal
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    mov     ax, SelectorStack
    mov     ss, ax
    mov     esp, TopOfStack

    mov     ax,SelectorData
    mov     ds,ax
    mov     esi,OffsetPMMessage
    mov     edi,3*80*2
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
    mov     cx,25*80        ; total 4000 Bytes
    mov     ax,0            ; but I use ax so it will div 2
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
; Function: Display string which end with 0
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

LenOfCode32     equ     $ - LABEL_SEG_CODE32
; END OF [SECTION .s32]
