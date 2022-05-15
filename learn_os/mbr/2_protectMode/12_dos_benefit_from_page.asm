%include "pm.inc"

org     0x100
    jmp     LABEL_BEGIN

; Now we know the momory size is 32M (note that one address in PTE is 4K Bytes)
; Minimal PDE number is 32M/(4K*1K)=8
PAGE_DIR_BASEADDRES1       equ 0x200000     ; 2M
; Minimal PTE number is 32M/4K=8K
PAGE_TABLE_BASEADDRES1     equ 0x201000     ; 2M + 4K

; The privious PTE size is 8K*4=32K Bytes
PAGE_DIR_BASEADDRES2       equ 0x210000     ; 2M + 64K
PAGE_TABLE_BASEADDRES2     equ 0x211000     ; 2M + 64K + 4K

PagingDemo  equ     0x301000
LinearAddr  equ     0x401000
ProcFoo     equ     0x401000
ProcBar     equ     0x501000

[SECTION    .sgdt]
ALIGN   32

LABEL_GDT:              Descriptor       0,                0, 0
LABEL_DESC_NORMAL:      Descriptor       0,           0xFFFF, DA_DRW
LABEL_DESC_VIDEO:       Descriptor 0xB8000,             4000, DA_DRW
LABEL_DESC_STACK:       Descriptor       0,       TopOfStack, DA_DRWA
LABEL_DESC_DATA:        Descriptor       0,    LenOfData - 1, DA_DRW
LABEL_DESC_CODE32:      Descriptor       0,  LenOfCode32 - 1, DA_32 | DA_CR
LABEL_DESC_BACK2REAL:   Descriptor       0,           0xFFFF, DA_C
LABEL_DESC_FLATC:       Descriptor       0,          0xFFFFF, DA_CR|DA_32|DA_LIMIT_4K
LABEL_DESC_FLATCRW:     Descriptor       0,          0xFFFFF, DA_DRW|DA_LIMIT_4K

LenOfGDT    equ     $ - LABEL_GDT
PTROFGDT    dw      LenOfGDT - 1
            dd      0

SelNormal       equ     LABEL_DESC_NORMAL   -   LABEL_GDT
SelVideo        equ     LABEL_DESC_VIDEO    -   LABEL_GDT
SelStack        equ     LABEL_DESC_STACK    -   LABEL_GDT
SelData         equ     LABEL_DESC_DATA     -   LABEL_GDT
SelCode32       equ     LABEL_DESC_CODE32   -   LABEL_GDT
SelBack2Real    equ     LABEL_DESC_BACK2REAL-   LABEL_GDT
SelFlatC        equ     LABEL_DESC_FLATC    -   LABEL_GDT
SelFlatCRW      equ     LABEL_DESC_FLATCRW  -   LABEL_GDT

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
MemorySize:     dd      0
MinimalPDE:     dw      0
PMMESSAGE:      db      'In protect now!', 0
MEMORYINFO:     times   400     db      0
ARDSTITLE:      db      'BaseAddrL  BaseAddrH  LengetLow  LengthHigh  Type', 0
TEST:           db      1,2,3,4,5,0xef,0xF7,0xAB,0xcd,0xfe
OFFSETTEST      equ     TEST - LABEL_DATA
OFFSETARDSNUM   equ     _dwARDSNumber - LABEL_DATA
OFFSETMemorySize  equ   MemorySize - LABEL_DATA
OFFSETMinPDE    equ     MinimalPDE - LABEL_DATA
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
    mov     ebx, 0                      ; 0 when first use
    mov     ax, cs
    mov     es, ax
    mov     di, MEMORYINFO
LABEL_LOOP_GET_MEM:
    mov     eax, 0xE820
    mov     ecx, 20
    mov     edx, 0x534D4150
    int     0x15

    jc      LABEL_GET_MEM_FAIL          ; error when CF = 1
    add     di, 20                      ; point to next address to save ARDS
    inc     dword [_dwARDSNumber]
    cmp     ebx, 0                      ; 0 when ARDS is the last one
    jne     LABEL_LOOP_GET_MEM          ; get next ARDS info
    jmp     LABEL_GET_MEM_OK
LABEL_GET_MEM_FAIL:
    mov     dword [_dwARDSNumber], 0
    jmp     $                           ; stop when occur error
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

    ; display memory info
    call    LABEL_DISP_MEM
    call    LABEL_GET_MEM_SIZE

    ; get minimal PDE
    push    dword [ds:OFFSETMemorySize]
    call    GET_MINI_PDE
    add     esp, 4                      ; del temp variable
    mov     [ds:OFFSETMinPDE], ax
    mov     [ds:OFFSETTEST], ax
    ; display memory size
    call    LABEL_DISP_MEM_SIZE
    call    LABEL_TEST_DISPAL

    call    LABEL_SET_ENVIRONMENT

    push    word [ds:OFFSETMinPDE]
    call    SetupPagingLess
    add     esp, 2

    call    SelFlatC:PagingDemo

    push    word [ds:OFFSETMinPDE]
    call    PageSwitch
    add     esp, 2

    call    SelFlatC:PagingDemo

    jmp     SelBack2Real:0

; ===================================
; Function: Get memory size
; Brief: According [ds:OFFSETMEMINFO] to calculate
; the memory size. Save in [ds:OFFSETMemorySize].
; ===================================
LABEL_GET_MEM_SIZE:
    push    eax
    push    ebx
    push    ecx
    push    edi

    mov     ax, SelData
    mov     ds, ax
    mov     ecx, [ds:OFFSETARDSNUM]
    mov     edi, OFFSETMEMINFO+16           ; the first ARDS
_GET_MEM_SIZE:
    mov     al, [ds:edi]                    ; type of ARDS
    cmp     al, 1
    jne     _RESERVE_FOR_OS
    mov     ebx, [ds:edi-8]                 ; length of address
    mov     eax, [ds:edi-16]                ; base addres
    add     ebx, eax                        ; size

_RESERVE_FOR_OS:
    add     edi, 20
    loop    _GET_MEM_SIZE

    mov     [ds:OFFSETMemorySize], ebx      ; save in memory

    pop     edi
    pop     ecx
    pop     ebx
    pop     eax
    ret

; ===================================
; @Function: eax = GET_MINI_PDE(dw MemorySize)
; @Brief: Calculate the minimal PDE with memory size
; @param: [IN] push: MemorySize
; @param: [OUT] eax: minimal number of PDE
; ===================================
GET_MINI_PDE:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    edx

    mov     eax, [ebp+8]   ; memory size

    ; calculate how many PDE need to init
    xor     edx, edx
    mov     ebx, 0x400000
    div     ebx         ; result = eax...edx
    test    edx, edx    ; judge remainder if equal 0
    jz      _NO_REMAINDER_LESS  ; jump if equal 0
    inc     eax         ; remainder != 0 need to add one more page directory table
_NO_REMAINDER_LESS:
    nop
    ; will return eax
    pop     edx
    pop     ebx
    mov     esp, ebp
    pop     ebp
    ret

; ===================================
; Function: Display memory size
; ===================================
LABEL_DISP_MEM_SIZE:
    push    ds
    push    ecx
    mov     ax, SelData
    mov     ds, ax
    mov     ecx, 4
    mov     esi, OFFSETMemorySize+3
    mov     edi, 18*80*2+3*2
_DISP_MEM_SIZE:
    mov     al, [ds:esi]
    call    DispAL
    dec     esi
    loop    _DISP_MEM_SIZE
    pop     ecx
    pop     ds
    ret

; ===================================
; Function: Display memory
; ===================================
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
_NUM_OF_ARDS:                   ; all ARDS
    push    cx
    mov     cx, 5
_ITEM_OF_ARDS:                  ; an item
    push    cx
    mov     cx, 4
_FIELD_OF_ARDS:                 ; a filed
    mov     al, [ds:esi]
    call    DispAL              ; ds:esi es:edi al
    inc     esi
    ;add     edi, 2
    loop    _FIELD_OF_ARDS      ; Finish displaying a field in an item in ARDS
    add     edi, 2
    pop     cx
    loop    _ITEM_OF_ARDS       ; Finish displaying an item in ARDS
    add     edi,2*80*2-45*2
    pop     cx
    loop    _NUM_OF_ARDS

    ret

; ===================================
; Function: Test DisplayAL
; Brief: This is a test for DisplayAL.
; ===================================
LABEL_TEST_DISPAL:
    push    eax
    push    ecx
    push    ds
    push    es
    push    esi
    push    edi

    mov     ax, SelData
    mov     ds, ax
    mov     esi, OFFSETTEST
    mov     ax, SelVideo
    mov     es, ax
    mov     edi, 20*80*2
    mov     cx, 10
_TEST_DISPAL:
    mov     al, [ds:esi]
    call    DispAL
    inc     esi
    add     edi, 2
    loop    _TEST_DISPAL

    pop     edi
    pop     esi
    pop     es
    pop     ds
    pop     ecx
    pop     eax
    ret

; ===================================
; @Function: Set environment
; @Brief: This function will copy relating code to 
;         0x301000, 0x401000 and 0x501000
; ===================================
LABEL_SET_ENVIRONMENT:
    push    ds
    mov     ax, cs              ; note that the running code must be readed
    mov     ds, ax
    mov     ax, SelFlatCRW
    mov     es, ax

    push    LenOfFoo
    push    OffsetFoo
    push    ProcFoo             ; 0x401000
    call    MemCpy
    add     esp, 12

    push    LenOfBar
    push    OffsetBar
    push    ProcBar             ; 0x501000
    call    MemCpy
    add     esp, 12

    push    LenOfLinearDemo
    push    OffsetLinearDemo
    push    PagingDemo          ; 0x301000
    call    MemCpy
    add     esp, 12
    pop     ds
    ret

LABEL_LINEAR_DEMO:
OffsetLinearDemo    equ     $ - $$
    mov     eax, LinearAddr     ; 0x401000
    call    eax
    retf
LenOfLinearDemo     equ     $ - LABEL_LINEAR_DEMO

LABEL_FOO:
OffsetFoo   equ     $ - $$
    mov     ax, SelVideo
    mov     es, ax
    mov     ah, 0x04
    mov     al, 'f'
    mov     [es:22*80*2+3*2], ax
    mov     al, 'o'
    mov     [es:22*80*2+4*2], ax
    mov     al, 'o'
    mov     [es:22*80*2+5*2], ax

    ret
LenOfFoo    equ     $ - LABEL_FOO

LABEL_BAR:
OffsetBar   equ     $ - $$
    mov     ax, SelVideo
    mov     es, ax
    mov     ah, 0x04
    mov     al, 'B'
    mov     [es:23*80*2+3*2], ax
    mov     al, 'a'
    mov     [es:23*80*2+4*2], ax
    mov     al, 'r'
    mov     [es:23*80*2+5*2], ax

    ret
LenOfBar    equ     $ - LABEL_BAR

; ===================================
; @Function: SetupPagingLess(dw NumOfPDE)
; @Brief: Setup paging according to number of PDE.
;         This will consume minimal memory.
; @param: [IN] NumOfPDE   push NumOfPDE
; ===================================
SetupPagingLess:
    push    ebp
    mov     ebp, esp
    push    ecx

    xor     ecx, ecx
    mov     cx, [ebp+8]         ; Num of PDE, size is word
    ; setup page directory
    mov     ax, SelFlatCRW
    mov     es, ax
    mov     edi, PAGE_DIR_BASEADDRES1
    mov     eax, PAGE_TABLE_BASEADDRES1 | PG_P | PG_USU | PG_RWW
_SETUP_PAGE_DIR_LESS:
    stosd                       ; eax --> [es:edi]
    add     eax, 4096           ; base address of next PTE
    loop    _SETUP_PAGE_DIR_LESS

    ; setup page table
    mov     edi, PAGE_TABLE_BASEADDRES1
    xor     eax, eax
    mov     ax, [ebp+8]         ; the number of PDE
    mov     ebx, 1024           ; the number of PTE in one PDE
    mul     ebx                 ; calculate how many PTE
    mov     ecx, eax
    mov     eax, PG_P | PG_USU | PG_RWW
_SETUP_PAGE_TABLE_LESS:
    stosd
    add     eax, 4096
    loop    _SETUP_PAGE_TABLE_LESS

    mov     eax, PAGE_DIR_BASEADDRES1
    mov     cr3, eax
    mov     eax, cr0
    or      eax, 0x80000000
    mov     cr0, eax

    pop     ecx
    mov     esp, ebp
    pop     ebp
    ret

; ===================================
; @Function: PageSwitch(dw NumOfPDE)
; @Brief: Remapping the linear address(0x401000) to ProcBar(0x501000).
; @param: [IN] NumOfPDE   push NumOfPDE
; ===================================
PageSwitch:
    push    ebp
    mov     ebp, esp
    push    ecx

    xor     ecx, ecx
    mov     cx, [ebp+8]         ; Num of PDE, size is word
    ; setup page directory
    mov     ax, SelFlatCRW
    mov     es, ax
    mov     edi, PAGE_DIR_BASEADDRES2
    mov     eax, PAGE_TABLE_BASEADDRES2 | PG_P | PG_USU | PG_RWW
_SETUP_PAGE_DIR_LESS_PSWITCH:
    stosd                       ; eax --> [es:edi]
    add     eax, 4096           ; base address of next PTE
    loop    _SETUP_PAGE_DIR_LESS_PSWITCH

    ; setup page table
    mov     edi, PAGE_TABLE_BASEADDRES2
    xor     eax, eax
    mov     ax, [ebp+8]         ; the number of PDE
    mov     ebx, 1024           ; the number of PTE in one PDE
    mul     ebx                 ; calculate how many PTE
    mov     ecx, eax
    mov     eax, PG_P | PG_USU | PG_RWW
_SETUP_PAGE_TABLE_LESS_PSWITCH:
    stosd
    add     eax, 4096
    loop    _SETUP_PAGE_TABLE_LESS_PSWITCH

    ; The above code is likely SetupPagingLess
    ; remaping the PTE which point to 0x401000
    mov     eax, LinearAddr     ; the linear address
    shr     eax, 22             ; get PDE which used
    mov     ebx, 4096
    mul     ebx                 ; get offset of PDE address
    mov     ecx, eax
    
    mov     eax, LinearAddr
    shr     eax, 12
    and     eax, 0x3FF          ; get PTE which used
    mov     ebx, 4
    mul     ebx                 ; get offset of PTE in PDE
    add     eax, ecx
    add     eax, PAGE_TABLE_BASEADDRES2
    mov     dword [es:eax], ProcBar | PG_P | PG_USU | PG_RWW

    mov     eax, PAGE_DIR_BASEADDRES2
    mov     cr3, eax

    pop     ecx
    mov     esp, ebp
    pop     ebp
    ret

%include    "lib.inc"
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
    and     eax, 0x7FFFFFFE     ; PE(bit 0) = 0; PG(bit 31) = 0
    mov     cr0, eax

LABEL_BACK2REAL:
    jmp     0:LABEL_REAL_ENTRY

LenOfBackToReal     equ     $ - $$
; END OF [SECTION    .sBack2Real]