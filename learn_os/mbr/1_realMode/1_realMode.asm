; Show the Bootmessage when power on

    org 0x7C00           ; tell the complier load the code to 0x7C00
    jmp LABEL_BOOT

Bootmessage:    db 'Hello world!',0

LABEL_BOOT:
    mov     ax,cs
    mov     ds,ax
    mov     si,Bootmessage
    xor     di,di
    call    Disp_Str
    jmp     $

; Call this function when di, ds:[si] is ready
Disp_Str:
    push    es
    push    ax
    push    cx
    mov     ax,0xB800
    mov     es,ax           ; set the data destination
    xor     cx,cx           ; reset cx for loop
DispStr:
    xor     cx,cx
    mov     cl,[ds:si]
    jcxz    Disp_ret
    mov     ch,0x02
    mov     [es:di],cx
    inc     si
    add     di,2            ; the high 8bit is color
    jmp     DispStr
Disp_ret:
    pop     cx
    pop     ax
    pop     es
    ret

times   510-($-$$) db 0
dw      0xAA55
