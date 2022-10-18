%include "sconst.inc"

; need to  correspond the order in sys_call_table[] at global.c
_NR_get_ticks           equ     0
_NR_printx              equ     1

INT_VECTOR_SYS_CALL     equ     0x90

global  get_ticks
global  printx

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


; =========================
; void printx(char* s);
; =========================
printx:
    mov     eax, _NR_printx
    mov     edx, [esp + 4]
    int     INT_VECTOR_SYS_CALL
    ret
