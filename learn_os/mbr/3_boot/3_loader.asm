org     0x100

    mov     ax, 0xB800
    mov     es, ax
    mov     di, 9*80*2+39*2
    mov     ah, 0x02
    mov     al, 'H'
    mov     [es:di], ax
    jmp     $
