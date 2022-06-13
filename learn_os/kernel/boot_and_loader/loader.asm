; This funcion will loade in 0x9000:0x100
    org     0x100
    jmp     LOADER_BEGIN

%include    "fat12hdr.inc"
%include    "common.inc"

    LoaderMessage:          db      'Now is in loader', 0
    KernelName:             db      'KERNEL.BIN',0  ; length <= 8 (not include ".bin")
    LENOFKERNELNAME         equ     ($ - KernelName - 1)
    BASEOFSTACK             equ     0x100           ; ss:sp = 0x9000:0x100
    BASEOFKERNEL            equ     0x8000
    OFFSETKERNEL            equ     0x00

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

    jmp     BASEOFKERNEL:OFFSETKERNEL
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
