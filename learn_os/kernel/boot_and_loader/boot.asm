    org     0x7C00
    jmp     LABEL_BEGIN
    nop

%include    "fat12hdr.inc"

    LoaderName:             db      'LOADER.BIN',0   ; length <= 8 (not include ".bin")
    LENOFLOADERNAME         equ     ($ - LoaderName - 1)
    BASEOFSTACK             equ     0x7C00
    BASEOFLOADER            equ     0x9000
    OFFSETLOADER            equ     0x0

LABEL_BEGIN:
    mov     ax, cs
    mov     ds, ax
    mov     ss, ax          ; actuall ss is 0, but I think it is dangerous
    mov     sp, BASEOFSTACK

    call    ResetFloppyDisk

    mov     ax, BASEOFLOADER    ; `.
    mov     es, ax              ;  | es:bx: data go where (Root Directory)
    mov     bx, OFFSETLOADER    ; /
    mov     si, LoaderName
    push    word LENOFLOADERNAME
    push    word NUMSECTOROFROOTENTRY
    push    word INDEXOFROOTDIR
    call    FindFile
    add     sp, 6
    
    cmp     ax, 0xFFFF
    je      _REBOOT

    ; es not change
    mov     bx, OFFSETLOADER    ; save data to es:bx
    push    word INDEXOFDATABLOCK
    push    ax
    call    LoadFile
    add     sp, 2
    jmp     BASEOFLOADER:OFFSETLOADER   ; stop here when display is finish
_REBOOT:
    jmp     0xFFFF:0
%include    "common.inc"

    times   510-($-$$) db 0
    dw      0xAA55
