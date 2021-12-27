; Display strings with int 10H

    org 0x7C00           ; tell the complier load the code to 0x7C00
    jmp LABEL_BOOT

Bootmessage:    db 'Hello world!',0

LABEL_BOOT:
    mov     ax,cs
    mov     es,ax
    mov     bp,Bootmessage
    call    Disp_Str
    jmp     $               ; stop here when display is finish


; Call this function when [es:bp] is ready
; [es:bp] is the index where the data want to display
Disp_Str:
    push    ax
    push    bx
    push    cx
    push    dx

    ; where to display
    mov     al,30
    mov     dl,al           ; dl: col
    mov     ah,10
    mov     dh,ah           ; dh: row

    mov     cx,12           ; how many letters to display

    mov     al,00
    mov     bh,al           ; bh: keep 0
    mov     al,0x02
    mov     bl,al           ; bl: set color

    mov     ax,0x1300       ; ah: select function; al: keep 0
    int     10H

    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret

times   510-($-$$) db 0
dw      0xAA55
