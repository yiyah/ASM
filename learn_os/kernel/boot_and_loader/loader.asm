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
    LoaderMessage:          db      'Now is in loader', 0
    KernelName:             db      'KERNEL.BIN',0  ; length <= 8 (not include ".bin")
    LENOFKERNELNAME         equ     ($ - KernelName - 1)
    BASEOFSTACK             equ     0x100           ; ss:sp = 0x9000:0x100
    BASEOFKERNEL            equ     0x8000
    OFFSETKERNEL            equ     0x00
    BASEOFLOADERPHYADDR     equ     BASEOFLOADER*0x10   ; physical adderss of loader

[section .s16]
LOADER_BEGIN:
    mov     ax, cs
    mov     ds, ax
    mov     ss, ax
    mov     sp, BASEOFSTACK

    call    ClearScreen

    mov     si, LoaderMessage
    mov     di, 2*80*2+20*2

    call    DispStr

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
    mov     edi, 5*80*2+15*2
    mov     esi, BASEOFLOADERPHYADDR+PMMessage
    call    DispStr_Long
    jmp     $

; ===================================
; @Function: Display string which end with 0
; @brief: use in 32 bit mode
; @param: es:edi
; @param: ds:esi
; @usage:
;    mov     ax, SelVideo
;    mov     es, ax
;    mov     ds, bx
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
    retf

[section .data32]
ALIGN   32
PMMessage:      db 'protect mode', 0

; put stack at the end of data
times   1024    db  0
TOPOFSTACK  equ BASEOFLOADERPHYADDR + $
