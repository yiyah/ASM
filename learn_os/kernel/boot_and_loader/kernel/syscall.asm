%include "sconst.inc"

_NR_get_ticks           equ     0   ; need to  correspond the order in sys_call_table[] at global.c
INT_VECTOR_SYS_CALL     equ     0x90

global  get_ticks

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
