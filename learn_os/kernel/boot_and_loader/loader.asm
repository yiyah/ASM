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
    LoaderMessage:          db      'Now is in loader', 0
    KernelName:             db      'KERNEL.BIN',0  ; length <= 8 (not include ".bin")
    LENOFKERNELNAME         equ     ($ - KernelName - 1)
    GetMemFailMess:         db      'Get memory info fail!', 0
    BASEOFSTACK             equ     0x100           ; ss:sp = 0x9000:0x100
    BASEOFKERNEL            equ     0x8000
    OFFSETKERNEL            equ     0x00
    BASEOFLOADERPHYADDR     equ     BASEOFLOADER*0x10   ; physical adderss of loader

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

    mov     ax, SelVideo
    mov     es, ax
    mov     edi, 3*80*2+15*2
    mov     esi, BASEOFLOADERPHYADDR+PMMessage
    call    DispStr_Long

    call    DispMemoryInfo
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
    mov     edi, 6*80*2+3*2
    mov     esi, BASEOFLOADERPHYADDR+ARDSTITLE
    call    DispStr_Long

    mov     esi, BASEOFLOADERPHYADDR+MemoryInfo
    mov     edi, 7*80*2+3*2

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
    add     edi, 2
    pop     cx
    loop    _NEXT_ITEM_OF_ARDS  ; go out when finish displaying an item in ARDS
    add     edi,2*80*2-45*2
    pop     cx
    loop    _NEXT_ARDS

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


[section .data32]
ALIGN   32
PMMessage:      db  'protect mode', 0
ARDSTITLE:      db  'BaseAddrL  BaseAddrH  LengetLow  LengthHigh  Type', 0

; put stack at the end of data
times   1024    db  0
TOPOFSTACK  equ BASEOFLOADERPHYADDR + $
