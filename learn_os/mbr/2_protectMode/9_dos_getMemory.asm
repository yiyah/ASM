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
LABEL_DESC_BACK2REAL:   Descriptor       0,           0xFFFF, DA_C

LenOfGDT    equ     $ - LABEL_GDT
PTROFGDT    dw      LenOfGDT - 1
            dd      0

SelNormal       equ     LABEL_DESC_NORMAL   -   LABEL_GDT
SelVideo        equ     LABEL_DESC_VIDEO    -   LABEL_GDT
SelStack        equ     LABEL_DESC_STACK    -   LABEL_GDT
SelData         equ     LABEL_DESC_DATA     -   LABEL_GDT
SelCode32       equ     LABEL_DESC_CODE32   -   LABEL_GDT
SelBack2Real    equ     LABEL_DESC_BACK2REAL-   LABEL_GDT

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
StackPointerInRealMode    dw      0
_dwARDSNumber:  dw      0
PMMESSAGE:      db      'In protect now!', 0
MEMORYINFO:     times   400     db      0
ARDSTITLE:      db      'BaseAddrL  BaseAddrH  LengetLow  LengthHigh  Type', 0
TEST:           db      1,2,3,4,5,0xef,0xF7,0xAB,0xcd,0xfe
OFFSETTEST      equ     TEST - LABEL_DATA
OFFSETARDSNUM   equ     _dwARDSNumber - LABEL_DATA
OFFSETPMMEG     equ     PMMESSAGE - LABEL_DATA
OFFSETMEMINFO   equ     MEMORYINFO - LABEL_DATA
OFFSETARDSTITL  equ     ARDSTITLE - LABEL_DATA
LenOfData       equ     $ - $$
; END of [SECTION    .sdata]

[SECTION    .s16]
ALIGN   16
[BITS   16]
LABEL_BEGIN:
    mov     ax, cs
    mov     ss, ax
    mov     sp, 0x100
    ; prepare for back to real mode
    mov     [LABEL_BACK2REAL+3], ax
    mov     [StackPointerInRealMode], sp

    ; get memory info
    mov     ebx, 0
    mov     ax, cs
    mov     es, ax
    mov     di, MEMORYINFO
LABEL_LOOP_GET_MEM:
    mov     eax, 0xE820
    mov     ecx, 20
    mov     edx, 0x534D4150
    int     0x15

    jc      LABEL_GET_MEM_FAIL
    add     di, 20
    inc     dword [_dwARDSNumber]
    cmp     ebx, 0
    jne     LABEL_LOOP_GET_MEM
    jmp     LABEL_GET_MEM_OK
LABEL_GET_MEM_FAIL:
    mov     dword [_dwARDSNumber], 0
LABEL_GET_MEM_OK:

    ; init STACK segment address
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_STACK
    mov     [LABEL_DESC_STACK+2], ax
    shr     eax, 16
    mov     [LABEL_DESC_STACK+4], al
    mov     [LABEL_DESC_STACK+7], ah

    ; init DATA segment address
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_DATA
    mov     [LABEL_DESC_DATA+2], ax
    shr     eax, 16
    mov     [LABEL_DESC_DATA+4], al
    mov     [LABEL_DESC_DATA+7], ah

    ; init code32 segment address
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_CODE32
    mov     [LABEL_DESC_CODE32+2], ax
    shr     eax, 16
    mov     [LABEL_DESC_CODE32+4], al
    mov     [LABEL_DESC_CODE32+7], ah

    ; init back_to_real code segment address
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4
    add     eax, LABEL_SEG_BackToReal
    mov     [LABEL_DESC_BACK2REAL+2], ax
    shr     eax, 16
    mov     [LABEL_DESC_BACK2REAL+4], al
    mov     [LABEL_DESC_BACK2REAL+7], ah

    ; init the pointer of GDT
    xor     eax, eax
    mov     ax, cs
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

LABEL_REAL_ENTRY:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, [StackPointerInRealMode]

    in      al, 0x92
    and     al, 11111101B
    out     0x92, al

    sti

	mov	    ax, 0x4c00
    int     21H
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
    call    SelCode32:OffsetDispStr     ; call DispStr

    mov     esi, OFFSETTEST
    mov     edi, 20*80*2

    mov     cx, 10
LABEL_TEST:
    mov     al, [ds:esi]
    call    DispAL
    add     edi, 2
    inc     esi
    loop    LABEL_TEST

    call    LABEL_DISP_MEM

    jmp     SelBack2Real:0

LABEL_DISP_MEM:
    mov     ax, SelData
    mov     ds, ax
    mov     esi, OFFSETARDSTITL
    mov     ax, SelVideo
    mov     es, ax
    mov     edi, 3*2*80+3*2
    call    DispStr

    mov     esi, OFFSETMEMINFO
    mov     edi, 5*80*2+3*2

    mov     cx, [ds:OFFSETARDSNUM]
_NUM_OF_ARDS:
    push    cx
    mov     cx, 4
_ITEM_OF_ARDS:
    push    cx
    mov     cx, 4
_FIELD_OF_ARDS:
    mov     al, [ds:esi]
    call    DispAL              ; ds:esi es:edi al
    inc     esi
    ;add     edi, 2
    loop    _FIELD_OF_ARDS      ; Finish displaying a field in an item in ARDS
    add     edi, 2
    pop     cx
    loop    _ITEM_OF_ARDS       ; Finish displaying an item in ARDS
    add     edi,2*80*2-36*2
    pop     cx
    loop    _NUM_OF_ARDS

    ret

%include    "Display.lib"
    OffsetDispStr   equ     DispStr - LABEL_SEG_CODE32

LenOfCode32     equ     $ - $$
; END OF [SECTION    .s32]

[SECTION    .sBack2Real]
ALIGN   32
[BITS   16]
LABEL_SEG_BackToReal:
    mov     ax, SelNormal
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    mov     eax, cr0
    and     al, 11111110B
    mov     cr0, eax

LABEL_BACK2REAL:
    jmp     0:LABEL_REAL_ENTRY

LenOfBackToReal     equ     $ - $$
; END OF [SECTION    .sBack2Real]
