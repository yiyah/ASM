[section .text]
global  _start
_start:
    ; now is at 0x0:0x30400
    ; cs, ds, es, fs, ss is point to segment address: 0
    ; gs is point to segment address: SelVideo
    mov     ah, 0x02
    mov     al, 'k'
    mov     [gs:(20*80*2+5*2)], ax
    jmp     $
