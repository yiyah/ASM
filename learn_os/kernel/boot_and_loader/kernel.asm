[section .text]
global  _start
_start:
    ; now is at 0x8000:0
    mov     ah, 0x02
    mov     al, 'k'
    mov     [gs:(20*80*2+5*2)], ax
    jmp     $
