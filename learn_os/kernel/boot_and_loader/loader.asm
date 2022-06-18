; This funcion will loade in 0x9000:0x100
    org     0x100
    jmp     LOADER_BEGIN

%include    "fat12hdr.inc"
%include    "common.inc"
%include    "pm.inc"

[section .gdt]
ALIGN   32

LABEL_GDT:          Descriptor       0,       0, 0       ; empty descriptor
LABEL_DESC_FLAT_C:  Descriptor       0, 0xFFFFF, DA_CR|DA_32|DA_LIMIT_4K
LABEL_DESC_FLAT_RW: Descriptor       0, 0xFFFFF, DA_DRW|DA_32|DA_LIMIT_4K
LABEL_DESC_VIDEO:   Descriptor 0xB8000,    4000, DA_DRW|DA_DPL3

LENOFGDT    equ     $ - LABEL_GDT
PTROFGDT    dw      LENOFGDT - 1
            dd      BASEOFLOADERPHYADDR + LABEL_GDT

SelFlatC    equ     LABEL_DESC_FLAT_C - LABEL_GDT
SelFlatRW   equ     LABEL_DESC_FLAT_RW - LABEL_GDT
SelVideo    equ     LABEL_DESC_VIDEO - LABEL_GDT + SA_RPL3

[section .data]
    MemoryInfo:             times   400   db  0
    NumOfARDS:              dw      0
    MemorySize:             dd      0
    LoaderMessage:          db      'Now is in loader', 0
    KernelName:             db      'KERNEL.BIN',0  ; length <= 8 (not include ".bin")
    LENOFKERNELNAME         equ     ($ - KernelName - 1)
    GetMemFailMess:         db      'Get memory info fail!', 0
    BASEOFSTACK             equ     0x100           ; ss:sp = 0x9000:0x100
    BASEOFKERNEL            equ     0x8000
    OFFSETKERNEL            equ     0x00
    BASEOFLOADERPHYADDR     equ     BASEOFLOADER*0x10   ; physical adderss of loader
    PAGE_DIR_BASEADDRES     equ     0x100000        ; 1M
    PAGE_TBL_BASEADDRES     equ     0x101000        ; 1M+4K

[section .s16]
LOADER_BEGIN:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, BASEOFSTACK

    call    ClearScreen
    mov     si, LoaderMessage
    mov     di, 1*80*2+20*2
    call    DispStr

    mov     di, MemoryInfo
    call    GetMemInfo

    mov     [NumOfARDS], ax
    cmp     ax, 0xFFFF
    jne     _GETMEM_OK
    mov     si, GetMemFailMess  ; show message if get memory fail
    mov     di, 2*80*2+20*2
    call    DispStr
_GETMEM_OK:

    call    ResetFloppyDisk

    mov     ax, BASEOFKERNEL    ; `.
    mov     es, ax              ;  | es:bx: data go where (Root Directory)
    mov     bx, OFFSETKERNEL    ; /
    mov     si, KernelName
    push    word LENOFKERNELNAME
    push    word NUMSECTOROFROOTENTRY
    push    word INDEXOFROOTDIR
    call    FindFile
    add     sp, 6
    
    cmp     ax, 0xFFFF
    je      _REBOOT

    ; es not change
    ;mov     ax, BASEOFKERNEL
    ;mov     es, ax
    mov     bx, OFFSETKERNEL    ; save data to es:bx
    push    word INDEXOFDATABLOCK
    push    ax
    call    LoadFile
    add     sp, 4

    call    KillMotor

    ; init the pointer of GDT
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

    jmp     dword SelFlatC:(BASEOFLOADERPHYADDR+LABEL_PM_START)
    ;jmp     BASEOFKERNEL:OFFSETKERNEL
_REBOOT:
    jmp     0xFFFF:0

; ===================================
; @Function: KillMotor
; @Brief: close the motor of floppy driver
; ===================================
KillMotor:
    push    ax
	push	dx
	mov	    dx, 03F2h
	mov	    al, 0
	out	    dx, al
	pop	    dx
    pop     ax
	ret

; ===================================
; @Function: ax = GetMemInfo
; @Brief: Get memory info(ARDS) to es:di
; @return:  ax: 0xFFFF: error
;               others: number of ARDS
; @usage:
;       mov     es, ax
;       mov     di, MEMORYINFO
;       call    GetMemInfo
; ===================================
GetMemInfo:
    push    bp
    mov     bp, sp
    sub     sp, 2                       ; local variable: save the number of ARDS
    push    ebx
    push    ecx
    push    edx

    ; get memory info
    mov     ebx, 0                      ; 0 when first use
    mov     word [bp-2], 0              ; init local variable
_LOOP_GET_MEM:
    mov     eax, 0xE820
    mov     ecx, 20
    mov     edx, 0x534D4150
    int     0x15

    jc      _GET_MEM_FAIL               ; error when CF = 1
    add     di, 20                      ; point to next address to save ARDS
    inc     dword [bp-2]
    cmp     ebx, 0                      ; 0 when ARDS is the last one
    jne     _LOOP_GET_MEM               ; get next ARDS info
    jmp     _GET_MEM_OK
_GET_MEM_FAIL:
    mov     dword [bp-2], 0
_GET_MEM_OK:
    mov     ax, [bp-2]
    pop     edx
    pop     ecx
    pop     ebx
    mov     sp, bp
    pop     bp
    ret

; ======================================
; =======32 bit code====================
; ======================================
[section .s32]
[BITS   32]
ALIGN   32

LABEL_PM_START:
    mov     ax, SelFlatRW
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax
    mov     esp, TOPOFSTACK

    ;call    SetupPaging

    mov     ax, SelVideo
    mov     es, ax
    mov     edi, 3*80*2+15*2
    mov     esi, BASEOFLOADERPHYADDR+PMMessage
    call    DispStr_Long

    call    DispMemoryInfo

    mov     ax, SelFlatRW
    mov     ds, ax          ; for push memory size
    mov     es, ax          ; for init PDE PTE
    push    dword PAGE_TBL_BASEADDRES
    push    dword PAGE_DIR_BASEADDRES
    push    dword [ds:BASEOFLOADERPHYADDR+MemorySize]
    call    SetupPagingLess
    add     esp, 12

    jmp     $

; ===================================
; @Function: Display string which end with 0
; @brief: use in 32 bit mode
; @param: es:edi
; @param: ds:esi
; @usage:
;    mov     ax, SelVideo
;    mov     es, ax
;    mov     ds, ax
;    mov     edi, 5*80*2+15*2
;    mov     esi, BASEOFLOADERPHYADDR+PMMessage
;    call    DispStr_Long
; ===================================
DispStr_Long:
    push    ax

_DispStr_Long:
    xor     ax, ax
    mov     al, [ds:esi]
    cmp     al, 0
    je      Disp_ret_Long
    mov     ah, 0x02
    mov     [es:edi], ax
    inc     esi
    add     edi, 2
    jmp     _DispStr_Long
Disp_ret_Long:
    pop     ax
    ret

; ===================================
; @Function: DispMemoryInfo()
; @brief: One ARDS is 1 item, one item include 5 fields, one fields have 4 bytes.
; @usage: call DispMemoryInfo
; ===================================
DispMemoryInfo:
    push    eax
    push    ecx
    push    es
    push    ds
    push    edi
    push    esi

    mov     ax, SelVideo
    mov     es, ax
    mov     ax, SelFlatRW
    mov     ds, ax
    mov     edi, 5*80*2+3*2
    mov     esi, BASEOFLOADERPHYADDR+ARDSTITLE
    call    DispStr_Long

    mov     esi, BASEOFLOADERPHYADDR+MemoryInfo
    mov     edi, 6*80*2+3*2

    mov     cx, [ds:BASEOFLOADERPHYADDR+NumOfARDS]
_NEXT_ARDS:
    push    cx
    mov     cx, 5               ; 5 fields per item
_NEXT_ITEM_OF_ARDS:             ; an item
    push    cx
    mov     cx, 4               ; 4Bytes per filed
    add     esi, 4              ; for display hight byte
_FIELD_OF_ARDS:                 ; a filed
    dec     esi
    mov     ax, [ds:esi] 
    call    DispAL              ; ds:esi es:edi al
    loop    _FIELD_OF_ARDS      ; Finish displaying a field in an item in ARDS
    add     esi, 4
    add     edi, 6              ; for cleary display
    pop     cx
    loop    _NEXT_ITEM_OF_ARDS  ; go out when finish displaying an item in ARDS
    add     edi,2*80*2-55*2     ; 6(space of each fields)*5+5(num of fields)*5 = 55
    pop     cx
    loop    _NEXT_ARDS

    ; get memory size
    ; mov     ax, SelFlatRW
    ; mov     ds, ax
    mov     esi, BASEOFLOADERPHYADDR+MemoryInfo
    push    word [ds:BASEOFLOADERPHYADDR+NumOfARDS]
    call    GetFreeMemorySize
    add     esp, 2
    mov     [ds:BASEOFLOADERPHYADDR+MemorySize], eax

    ; display RAMSize title
    mov     edi, 17*80*2
    mov     esi, BASEOFLOADERPHYADDR+RAMMessage
    call    DispStr_Long

    ; display memory size
    mov     edi, 17*80*2+10*2
    mov     ecx, 4
    mov     esi, BASEOFLOADERPHYADDR+MemorySize+3
_DISP_NEXT_MEM_SIZE:
    mov     al, [ds:esi]
    call    DispAL
    dec     esi
    loop    _DISP_NEXT_MEM_SIZE

    pop     esi
    pop     edi
    pop     ds
    pop     es
    pop     ecx
    pop     eax
    ret

; ===================================
; Function: Display AL
; param: [IN]   es:edi  where to display
; param: [IN]   al
; param: [OUT]  edi     will point the next byte
; ===================================
DispAL:
    push    eax
    push    ebx
    push    ecx

    mov     cx, 2
    mov     ah, 0x03        ; color
    mov     bl, al          ; first deal high bits
    shr     al, 4
_loop_Disp_AL:
    and     al, 0xF
    cmp     al, 0xA
    jb      _IsNumber       ; is number
    add     al, 55          ; is character
    jmp     _Disp_AL
_IsNumber:
    add     al, 48
_Disp_AL:
    mov     [es:edi], ax    ; display
    mov     al, bl          ; deal low bits
    add     edi, 2
    loop    _loop_Disp_AL

    pop     ecx
    pop     ebx
    pop     eax
    ret

; ===================================
; @Function: eax = GetFreeMemorySize(dw NumOfARDS)
; @Brief: Get free memory size from ARDS(ds:esi)
; @retval: eax : memory size
; @Usage:
;          mov     ax, SelFlatRW
;          mov     ds, ax
;          mov     esi, BASEOFLOADERPHYADDR+MemoryInfo
;          push    NumOfARDS
;          call    GetFreeMemorySize
; ===================================
GetFreeMemorySize:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    ecx
    push    esi

    xor     ebx, ebx                ; for save which memory type is 1
    xor     ecx, ecx                ; prevent hight 16 bit not reset
    mov     cx, [ebp+8]             ; NumOfARDS
_CHECK_NEXT_ARDS:
    mov     eax, [ds:esi+16]        ; `. type: point to the type of ARDS
    cmp     eax, 1                  ;  | 0: can use
    jne      _RESERVE_FOR_OS        ; /  others: can not use
    mov     ebx, esi
_RESERVE_FOR_OS:
    add     esi, 20                 ; point to next ARDS
    loop    _CHECK_NEXT_ARDS
    mov     eax, [ds:ebx]
    add     eax, dword [ds:ebx+8]

    pop     esi
    pop     ecx
    pop     ebx
    mov     esp, ebp
    pop     ebp
    ret

; ===================================
; @Function: SetupPagingLess(dd MemorySize, dd PAGE_DIR_BASEADDRES, dd PAGE_TBL_BASEADDRES)
; @Brief: configure Page Directory and Page Directory Table
;         According MemorySize to calculate how many PDE to init
;         Also according with PAGE_DIR_BASEADDRES and PAGE_TBL_BASEADDRES.
;         In mu machine, need init 8 PDE, and 0x100000~0x100020(32Bytes) for Page directory, 
;         0x101000~0x109000(8*1K*4=32K) for Page table
; @Attention: must be called after GetFreeMemorySize
; @param: MemorySize: for calculate how many PDE to init, result will save in ecx
; @Usage: 
;       mov     ax, SelFlatRW
;       mov     ds, ax          ; for push memory size
;       mov     es, ax          ; for init PDE PTE
;       push    dword PAGE_TBL_BASEADDRES
;       push    dword PAGE_DIR_BASEADDRES
;       push    dword [ds:BASEOFLOADERPHYADDR+MemorySize]
;       call    SetupPagingLess
;       add     esp, 12
; ===================================
SetupPagingLess:
    push    ebp
    mov     ebp, esp
    ; calculate how many PDE need to init
    xor     edx, edx
    mov     eax, [ebp+8]
    mov     ebx, 0x400000
    div     ebx         ; result = eax...edx
    mov     ecx, eax    ; the minimum number of PDE need to init
    test    edx, edx    ; judge remainder if equal 0
    jz      _NO_REMAINDER
    inc     ecx         ; remainder != 0 need to add one more page directory table
_NO_REMAINDER:
    push    ecx         ; push for PTE
    ; setup page directory
    mov     edi, [ebp+12]       ; PAGE_DIR_BASEADDRES
    xor     eax, eax                    ; `.
    mov     eax, PG_P | PG_USU | PG_RWW ;  | setup PDE
    add     eax, [ebp+16]               ; /  PAGE_TBL_BASEADDRES
_SETUP_PAGE_DIR_LESS:
    stosd
    add     eax, 4096           ; base address of next PTE
    loop    _SETUP_PAGE_DIR_LESS

    ; setup page table
    mov     edi, [ebp+16]
    pop     eax                 ; the number of PDE
    mov     ebx, 1024           ; the number of PTE in one PDE
    mul     ebx                 ; calculate how many PTE
    mov     ecx, eax
    xor     eax, eax
    mov     eax, PG_P | PG_USU | PG_RWW
_SETUP_PAGE_TABLE_LESS:
    stosd
    add     eax, 4096
    loop    _SETUP_PAGE_TABLE_LESS

    mov     eax, [ebp+12]
    mov     cr3, eax
    mov     eax, cr0
    or      eax, 0x80000000
    mov     cr0, eax

    mov    esp, ebp
    pop    ebp
    ret

; ===================================
; @Function: SetupPaging
; @Brief: configure Page Directory and Page Directory Table
;         According PAGE_DIR_BASEADDRES and PAGE_TBL_BASEADDRES.
; @Usage: call SetupPaging
; ===================================
SetupPaging:
    push    es
    push    eax
    push    ecx
    push    edi

    ; setup page directory
    mov     ax, SelFlatRW
    mov     es, ax
    mov     edi, PAGE_DIR_BASEADDRES
    mov     ecx, 1024
    xor     eax, eax
    mov     eax, PAGE_TBL_BASEADDRES | PG_P | PG_USU | PG_RWW
_SETUP_PAGE_DIR:
    stosd                       ; copy eax to es:edi
    add     eax, 4096           ; base address of next PTE
    loop    _SETUP_PAGE_DIR

    ; setup page table
    mov     edi, PAGE_TBL_BASEADDRES
    mov     ecx, 1024 * 1024
    xor     eax, eax
    mov     eax, PG_P | PG_USU | PG_RWW
_SETUP_PAGE_TABLE:
    stosd
    add     eax, 4096
    loop    _SETUP_PAGE_TABLE

    mov     eax, PAGE_DIR_BASEADDRES
    mov     cr3, eax
    mov     eax, cr0
    or      eax, 0x80000000     ; set PG flag for use page mechanism
    mov     cr0, eax
;    jmp     short _EXIT_SETUP_PAGING   ; `.
;_EXIT_SETUP_PAGING:                    ;  | This is for debug, or system will hang on.
;    nop                                ; /  But I had never debug here. Just for notes.
    pop     edi
    pop     ecx
    pop     eax
    pop     es
    ret

[section .data32]
ALIGN   32
PMMessage:      db  'protect mode', 0
ARDSTITLE:      db  'BaseAddrL  BaseAddrH  LengetLow  LengthHigh  Type', 0
RAMMessage:     db  'RAM SIZE:', 0
; put stack at the end of data
times   1024    db  0
TOPOFSTACK  equ BASEOFLOADERPHYADDR + $
