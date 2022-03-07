; step1: enter protect mode

%include "pm.inc"

org     0x100
jmp     LABEL_BEGIN

[SECTION    .sgdt]
ALIGN   32

LABEL_GDT:              Descriptor       0,                0, 0
LABEL_DESC_NORMAL:      Descriptor       0,           0xFFFF, DA_DRW
LABEL_DESC_VIDEO:       Descriptor 0xB8000,             4000, DA_DRW
LABEL_DESC_STACK:       Descriptor       0,       TopOfStack, DA_DRWA
LABEL_DESC_DATA:        Descriptor       0,    LenOfData - 1, DA_DRW
LABEL_DESC_CODE32:      Descriptor       0,  LenOfCode32 - 1, DA_32 | DA_C

LenOfGDT    equ     $ - LABEL_GDT
PTROFGDT    dw      LenOfGDT - 1
            dd      0

SelNormal       equ     LABEL_DESC_NORMAL   -   LABEL_GDT
SelVideo        equ     LABEL_DESC_VIDEO    -   LABEL_GDT
SelStack        equ     LABEL_DESC_STACK    -   LABEL_GDT
SelData         equ     LABEL_DESC_DATA     -   LABEL_GDT
SelCode32       equ     LABEL_DESC_CODE32   -   LABEL_GDT

; END of [SECTION    .sgdt]
[SECTION    .sstackCode32]
ALIGN   32
LABEL_STACK:
times       512     db  0
TopOfStack      equ     $ - $$ - 1
; END of [SECTION    .sdata]

; END of [SECTION    .sgdt]
[SECTION    .sdata]
ALIGN   32
LABEL_DATA:
PMMESSAGE:      db      'In protect now!', 0
OFFSETPMMEG     equ     PMMESSAGE - LABEL_DATA
LenOfData       equ     $ - $$
; END of [SECTION    .sdata]

[SECTION    .s16]
ALIGN   16
[BITS   16]
LABEL_BEGIN:
    mov     dx, cs
    mov     ss, dx
    mov     sp, 0x100

    ; init STACK segment address
    xor     eax, eax
    mov     ax, dx
    shl     eax, 4
    add     eax, LABEL_STACK
    mov     [LABEL_DESC_STACK+2], ax
    shr     eax, 16
    mov     [LABEL_DESC_STACK+4], al
    mov     [LABEL_DESC_STACK+7], ah

    ; init DATA segment address
    xor     eax, eax
    mov     ax, dx
    shl     eax, 4
    add     eax, LABEL_DATA
    mov     [LABEL_DESC_DATA+2], ax
    shr     eax, 16
    mov     [LABEL_DESC_DATA+4], al
    mov     [LABEL_DESC_DATA+7], ah

    ; init code32 segment address
    xor     eax, eax
    mov     ax, dx
    shl     eax, 4
    add     eax, LABEL_SEG_CODE32
    mov     [LABEL_DESC_CODE32+2], ax
    shr     eax, 16
    mov     [LABEL_DESC_CODE32+4], al
    mov     [LABEL_DESC_CODE32+7], ah

    ; init the pointer of GDT
    xor     eax, eax
    mov     ax, dx
    shl     eax, 4
    add     eax, LABEL_GDT
    mov     [PTROFGDT+2], eax
    lgdt    [PTROFGDT]

    ; close interruption
    cli

    ; open A20
    in      al, 0x92
    or      al, 00000010B
    out     0x92, al

    ; set PM FLAG
    mov     eax, cr0
    or      al, 00000001B
    mov     cr0, eax

    jmp     dword SelCode32:0

LenOfCode16     equ     $ - $$
; END of [SECTION    .s16]

[SECTION    .s32]
ALIGN   32
[BITS   32]
LABEL_SEG_CODE32:
    mov     ax, SelNormal
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ax, SelStack
    mov     ss, ax
    mov     sp, TopOfStack

    mov     ax, SelData
    mov     ds, ax
    mov     esi, OFFSETPMMEG
    mov     ax, SelVideo
    mov     es, ax
    mov     edi, 1*80*2+5*2
    call    ClearScreen
    call    SelCode32:OffsetDispStr
    jmp     $

%include    "Display.lib"
    OffsetDispStr   equ     DispStr - LABEL_SEG_CODE32

LenOfCode32     equ     $ - $$
; END OF [SECTION    .s32]
