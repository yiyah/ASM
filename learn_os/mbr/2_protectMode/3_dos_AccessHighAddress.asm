%include "pm.inc"
        org     0x100
        jmp     LABEL_BEGIN

[SECTION .gdt]
LABEL_GDT:          Descriptor        0,                0,   0
LABEL_DESC_NORMAL:  Descriptor        0,           0XFFFF, DA_DRW
LABEL_DESC_CODE16:  Descriptor        0,           0XFFFF, DA_C
LABEL_DESC_CODE32:  Descriptor        0, SegCode32Len - 1, DA_32 + DA_C
LABEL_DESC_VIDEO:   Descriptor  0xB8000,           0xFFFF, DA_DRW
LABEL_DESC_STACK:   Descriptor        0,       TopOfStack, DA_DRWA + DA_32
LABEL_DESC_DATA:    Descriptor        0,      DataLen - 1, DA_DRW
LABEL_DESC_TEST:    Descriptor 0x500000,           0xFFFF, DA_DRW

GDT_LEN    equ  $ - LABEL_GDT
GDT_PTR    dw   GDT_LEN - 1
           dd   0

; selector
SelectorNormal      equ  LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode16      equ  LABEL_DESC_CODE16 - LABEL_GDT
SelectorCode32      equ  LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo       equ  LABEL_DESC_VIDEO  - LABEL_GDT
SelectorStack       equ  LABEL_DESC_STACK  - LABEL_GDT
SelectorData        equ  LABEL_DESC_DATA   - LABEL_GDT
SelectorTest        equ  LABEL_DESC_TEST   - LABEL_GDT
; END of [SECTION .gdt]

[SECTION .gs]
ALIGN  32
[BITS   32]
LABEL_STACK:
    times       512     db      0
TopOfStack      equ     $ - LABEL_STACK - 1 ; Actually it's length of stack + 1
; END of [SECTION .stack]

[SECTION .data1]
ALIGN  32
[BITS   32]
LABEL_DATA:
StackPointerInRealMode    dw      0
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
    mov     ax,cs
    mov     ss,ax
    mov     sp,0x100

    ; the jmp is "0EAH(1 byte) OFFSET(2 bytes) SEGMENT(2 bytes)"
	mov	[LABEL_GO_BACK_TO_REAL+3], ax   ; so this will change segment address
	mov	[StackPointerInRealMode], sp

    ; Init Descriptor of stack
    xor     eax,eax
    mov     ax,cs
    shl     eax,4
    add     eax,LABEL_STACK
    mov     [LABEL_DESC_STACK+2],ax
    shr     eax,16
    mov     [LABEL_DESC_STACK+4],al
    mov     [LABEL_DESC_STACK+7],ah

    ; Init Descriptor of code16
    xor     eax,eax
    mov     ax,cs
    shl     eax,4
    add     eax,LABEL_SEG_CODE16
    mov     [LABEL_DESC_CODE16+2],ax
    shr     eax,16
    mov     [LABEL_DESC_CODE16+4],al
    mov     [LABEL_DESC_CODE16+7],ah

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

LABEL_REAL_ENTRY:
    mov     ax,cs
    mov     ds,ax
    mov     es,ax
    mov     ss,ax
    mov     sp,[StackPointerInRealMode]

    in      al,92H
    and     al,11111101B
    out     92H,al

    sti

	mov	ax, 0x4c00
	int	21h		    ; DOS

; END of [SECTION .s16]

[SECTION .s32]
[BITS  32]
LABEL_SEG_CODE32:
    mov     ax,SelectorStack
    mov     ss,ax
    mov     esp,TopOfStack

    mov     ax,SelectorData
    mov     ds,ax
    mov     esi,OffsetPMMessage
    mov     edi,3*80*2
    call    ClearScreen
    call    DispStr
    call    TestWrite

    mov     edi,5*80*2+15*2
    mov     ax,SelectorTest
    mov     ds,ax
    mov     esi,0
    call    DispStr     ; ds:esi edi
    jmp     SelectorCode16:0

; ===================================
; Function: clear screen
; ===================================
ClearScreen:
    push    eax
    push    ecx
    push    gs
    push    edi

    xor     eax,eax
    xor     ecx,ecx
    xor     edi,edi
    mov     ax,SelectorVideo
    mov     gs,ax
    mov     cx,25*80        ; total 4000 Bytes
    mov     ax,0            ; but I use ax so it will div 2
Clear_Screen:
    mov     [gs:edi],ax
    add     edi,2
    loop    Clear_Screen

    pop     edi
    pop     gs
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
    push    gs
    push    esi
    push    edi
    mov     ax,SelectorVideo
    mov     gs,ax
Disp_Str:
    xor     ecx,ecx
    mov     cl,[ds:esi]
    jcxz    Disp_Ret
    mov     ch,0x02     ; set green
    mov     [gs:edi],cx ; display
    inc     esi
    add     edi,2
    jmp     Disp_Str    ; stop when cx = 0    
Disp_Ret:
    pop     edi
    pop     esi
    pop     gs
    pop     ecx
    pop     ax
    ret

; ===================================
; Function: Write something in address 0x500000
; param[go]:   es:edi
; param[from]: ds:esi
; ===================================
TestWrite:
    push    ax
    push    gs
    push    ds
    push    esi
    push    edi

    mov     ax,SelectorTest
    mov     gs,ax
    xor     edi,edi
    mov     ax,SelectorData
    mov     ds,ax
    mov     esi,OffsetStrTest
    cld     ; set the ds:esi auto increase
Test_Write:
    lodsb   ; mov ds:esi to al and esi increase automally
    test    al,al   ; al & al, set flag if equal 0. Will be 0 only al=0
    jz      Test_Write_Ret
    mov     [gs:edi],al
    inc     edi
    jmp     Test_Write
Test_Write_Ret:
    mov     [gs:edi],al      ; add 0 at last
    pop     edi
    pop     esi
    pop     ds
    pop     gs
    pop     ax
    ret

SegCode32Len    equ     $ - LABEL_SEG_CODE32
; END of [SECTION .s32]

[SECTION .s16code]
ALIGN	32
[BITS   16]
LABEL_SEG_CODE16:
    mov     ax,SelectorNormal
    mov     ds,ax
    mov     es,ax
    mov     fs,ax
    mov     gs,ax
    mov     ss,ax

    mov     eax,cr0
    and     eax,11111110B
    mov     cr0,eax

LABEL_GO_BACK_TO_REAL:
    jmp     0:LABEL_REAL_ENTRY      ; segment had been modified in real mode
SegCode16Len    equ     $ - $$

; END OF [SECTION .s16code]
