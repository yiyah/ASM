; flow: LABEL_BEGIN --> LABEL_SEG_CODE32 --> LABEL_CODE_RING3 --> LABEL_SEG_CODE_DEST

%include "pm.inc"
    org     0x100
    jmp     LABEL_BEGIN

[SECTION .gdt]
LABEL_DESC_GDT:     Descriptor       0,                  0,   0
LABEL_DESC_NORMAL:  Descriptor       0,             0xFFFF, DA_DRW
LABEL_DESC_STACK:   Descriptor       0,         TopOfStack, DA_DRWA | DA_32
LABEL_DESC_DATA:    Descriptor       0,      LenOfData - 1, DA_DRW
LABEL_DESC_CODE32:  Descriptor       0,    LenOfCode32 - 1, DA_32 | DA_C
LABEL_DESC_VIDEO:   Descriptor 0xB8000,             0xFFFF, DA_DRW + DA_DPL3
LABEL_DESC_CODE16:  Descriptor       0,             0xFFFF, DA_C
LABEL_DESC_DEST:    Descriptor       0,  LenOfcodeDest - 1, DA_32 | DA_C
LABEL_DESC_LDT:     Descriptor       0,       LenOfLDT - 1, DA_LDT
LABEL_DESC_STACK_RING3:Descriptor    0,    TopOfRing3Stack, DA_DRWA + DA_32 + DA_DPL3
LABEL_DESC_CODE_RING3: Descriptor    0, LenOfcodeRing3 - 1, DA_32 + DA_C + DA_DPL3
LABEL_DESC_TSS:     Descriptor       0,       LenOfTSS - 1, DA_TSS

LABEL_DESC_GATES_TEST: Gate    SelectorCodeDest,   0,    0, (DA_CGATE | DA_DPL3)    ; Note this use ()

LenOfGDT    equ     $ - LABEL_DESC_GDT
PTR_GDT     dw      LenOfGDT - 1
            dd      0

; selector
SelectorNormal      equ LABEL_DESC_NORMAL - LABEL_DESC_GDT
SelectorStack       equ LABEL_DESC_STACK  - LABEL_DESC_GDT
SelectorData        equ LABEL_DESC_DATA   - LABEL_DESC_GDT
SelectorCode32      equ LABEL_DESC_CODE32 - LABEL_DESC_GDT
SelectorVideo       equ LABEL_DESC_VIDEO  - LABEL_DESC_GDT
SelectorCode16      equ LABEL_DESC_CODE16 - LABEL_DESC_GDT
SelectorCodeDest    equ LABEL_DESC_DEST   - LABEL_DESC_GDT
SelectorLDT         equ LABEL_DESC_LDT    - LABEL_DESC_GDT
SelectorStackRing3  equ LABEL_DESC_STACK_RING3 - LABEL_DESC_GDT + SA_RPL3
SelectorCodeRing3   equ LABEL_DESC_CODE_RING3 - LABEL_DESC_GDT + SA_RPL3
SelectorTSS         equ LABEL_DESC_TSS    - LABEL_DESC_GDT

SelCallGateTest     equ LABEL_DESC_GATES_TEST - LABEL_DESC_GDT + SA_RPL3
; END OF [SECTION .gdt]

[SECTION .stack]
ALIGN   32
[BITS   32]
LABEL_SEG_STACK:
    times   512     db  0
TopOfStack  equ     $ - LABEL_SEG_STACK - 1
; END OF [SECTION .stack]

[SECTION .stackRing3]
ALIGN   32
[BITS   32]
LABEL_SEG_STACK_RING3:
    times   512     db  0
TopOfRing3Stack  equ     $ - LABEL_SEG_STACK_RING3 - 1
; END OF [SECTION .stackRing3]

[SECTION .data]
ALIGN   32
[BITS   32]
LABEL_SEG_DATA:
StackPointerInRealMode  dw  0
PMMESSAGE:  db      'hello world!', 0
GATEMSG:    db      'Ohhhh, use GATE', 0
LDTMESSAGE: db      'Now use LDT', 0
OffsetPMMessage     equ     PMMESSAGE  - LABEL_SEG_DATA
OffsetGateMsg       equ     GATEMSG    - LABEL_SEG_DATA
OffsetLDTMessage    equ     LDTMESSAGE - LABEL_SEG_DATA
LenOfData   equ     $ - LABEL_SEG_DATA
; END OF [SECTION .data]

; TSS
[SECTION .tss]
ALIGN   32
[BITS   32]
LABEL_TSS:
        DD  0                   ; Back
        DD  TopOfStack          ; stack of 0
        DD  SelectorStack
        DD  0                   ; stack of 1
        DD  0                   ;
        DD  0                   ; stack of 2
        DD  0                   ;
        DD  0                   ; CR3
        DD  0                   ; EIP
        DD  0                   ; EFLAGS
        DD  0                   ; EAX
        DD  0                   ; ECX
        DD  0                   ; EDX
        DD  0                   ; EBX
        DD  0                   ; ESP
        DD  0                   ; EBP
        DD  0                   ; ESI
        DD  0                   ; EDI
        DD  0                   ; ES
        DD  0                   ; CS
        DD  0                   ; SS
        DD  0                   ; DS
        DD  0                   ; FS
        DD  0                   ; GS
        DD  0                   ; LDT
        DW  0                   ; 调试陷阱标志
        DW  $ - LABEL_TSS + 2   ; I/O位图基址
        DB  0ffh                ; I/O位图结束标志
LenOfTSS    equ	$ - LABEL_TSS
; End of [SECTION .tss]

[SECTION .s16]
[BITS   16]
LABEL_BEGIN:
    mov     ax, cs
    mov     ss, ax
    mov     sp, 0x100

    mov     ax, cs
    mov     [LABEL_GO_BACK_TO_REAL + 3], ax
    mov     [StackPointerInRealMode], sp

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

    ; CDOE 32
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_CODE32
    mov     [LABEL_DESC_CODE32 + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_CODE32 + 4], al
    mov     [LABEL_DESC_CODE32 + 7], ah

    ; CODE 16
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_CODE16
    mov     [LABEL_DESC_CODE16 + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_CODE16 + 4], al
    mov     [LABEL_DESC_CODE16 + 7], ah

    ; code DEST (CALL GATE)
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_CODE_DEST
    mov     [LABEL_DESC_DEST + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_DEST + 4], al
    mov     [LABEL_DESC_DEST + 7], ah

    ; init segment address of LDT
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_LDT
    mov     [LABEL_DESC_LDT + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_LDT + 4], al
    mov     [LABEL_DESC_LDT + 7], ah

    ; init selector in LDT
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_CODE_A
    mov     [LABEL_DESC_LDT_CODEA + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_LDT_CODEA + 4], al
    mov     [LABEL_DESC_LDT_CODEA + 7], ah

    ; init TSS
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_TSS
    mov     [LABEL_DESC_TSS + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_TSS + 4], al
    mov     [LABEL_DESC_TSS + 7], ah

    ; init code of ring3
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_CODE_RING3
    mov     [LABEL_DESC_CODE_RING3 + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_CODE_RING3 + 4], al
    mov     [LABEL_DESC_CODE_RING3 + 7], ah

    ; init stack of ring3
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_STACK_RING3
    mov     [LABEL_DESC_STACK_RING3 + 2], ax
    shr     eax, 16
    mov     [LABEL_DESC_STACK_RING3 + 4], al
    mov     [LABEL_DESC_STACK_RING3 + 7], ah

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

LABEL_REAL_ENTRY:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, [StackPointerInRealMode]

    in      al, 92H
    and     al, 11111101B
    out     92H, al

    sti

    mov	ax, 0x4C00
    int	21h
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
    call    SelectorCode32:OffsetDispStr

    mov     ax, SelectorTSS
    ltr     ax

    push    SelectorStackRing3
    push    TopOfRing3Stack
    push    SelectorCodeRing3
    push    0
    retf    ; stop here
    ; will not run down

    mov     ax, SelectorLDT
    lldt    ax

    jmp     SelectorCodeA:0

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
OffsetDispStr       equ     $ - LABEL_SEG_CODE32
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
    retf

LenOfCode32     equ     $ - LABEL_SEG_CODE32
; END OF [SECTION .s32]

[SECTION .s16code]
ALIGN   32
[BITS   16]
LABEL_SEG_CODE16:
    mov     ax, SelectorNormal
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    mov     eax, cr0
    and     al, 11111110B
    mov     cr0, eax

LABEL_GO_BACK_TO_REAL:
    jmp     0:LABEL_REAL_ENTRY
LenOfcode16     equ     $ - $$
; END OF [SECTION .s16code]

[SECTION .sdest]
[BITS   32]
LABEL_SEG_CODE_DEST:
    push    ax
    push    ds
    push    esi
    push    edi

    mov     ax, SelectorData
    mov     ds, ax
    mov     esi, OffsetGateMsg
    mov     edi, 7*80*2+15*2
    call    SelectorCode32:OffsetDispStr

    ;mov     ax, SelectorVideo
    ;mov     es, ax
    ;mov     edi, 7*80*2+15*2
    ;mov     al, 'G'
    ;mov     ah, 0x02
    ;mov     [es:edi], ax

    pop     edi
    pop     esi
    pop     ds
    pop     ax

    mov     ax, SelectorLDT
    lldt    ax
    jmp     SelectorCodeA:0
    retf

LenOfcodeDest       equ     $ - $$
; END OF [SECTION .sdest]

; ===================== LDT =====================

[SECTION .sldt]
ALIGN   32
LABEL_LDT:
LABEL_DESC_LDT_CODEA:   Descriptor  0, LenOfCodeA - 1, DA_32 | DA_C
LenOfLDT    equ     $ - $$

SelectorCodeA   equ     LABEL_DESC_LDT_CODEA - LABEL_LDT + SA_TIL

; END OF [SECTION .ldt]

[SECTION .ldt_codea]
ALIGN   32
[BITS   32]
LABEL_CODE_A:
    mov     ax,SelectorData
    mov     ds,ax
    mov     esi,OffsetLDTMessage
    mov     edi,9*80*2
    call    SelectorCode32:OffsetDispStr

    jmp     SelectorCode16:0
LenOfCodeA      equ $ - $$
; END OF [SECTION .ldt_codea]
; ================ END OF LDT =================

[SECTION    .sring3]
ALIGN   32
[BITS   32]
LABEL_CODE_RING3:
    mov     ax,SelectorVideo
    mov     ds,ax
    mov     edi, 5*80*2+5*2
    mov     ah, 0x02
    mov     al, '3'
    mov     [ds:edi], ax

    call    SelCallGateTest:0

    jmp     $
LenOfcodeRing3      equ     $ -$$
; END of [SECTION    .sring3]
