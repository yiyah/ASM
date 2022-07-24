%include "sconst.inc"

; need to  correspond the order in sys_call_table[] at global.c
_NR_get_ticks           equ     0
_NR_write               equ     1

INT_VECTOR_SYS_CALL     equ     0x90

global  get_ticks
global  write

;bits 32
[section .text]
[bits 32]
; ===================================
; @Function: eax = get_ticks()
; ===================================
get_ticks:
    mov     eax, _NR_get_ticks
    int     INT_VECTOR_SYS_CALL
    ret

; ===================================
; @Function: write(char* buf, int len);
; ===================================
write:
    push    ebx
    push    ecx

    mov     eax, _NR_write
    mov     ebx, [esp+4]    ; buf
    mov     ecx, [esp+8]    ; len
    int     INT_VECTOR_SYS_CALL

    pop     ecx
    pop     ebx
    ret

