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
    jmp     $               ; stop here when display is finish

; Call this function when di, ds:[si] is ready
; The string must end of 0x00
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
    jcxz    Disp_ret        ; finish display when the data is 0x00
    mov     ch,0x02         ; set color
    mov     [es:di],cx
    inc     si              ; the next index of what to show
    add     di,2            ; the next index of where to show
    jmp     DispStr
Disp_ret:
    pop     cx
    pop     ax
    pop     es
    ret

times   510-($-$$) db 0
dw      0xAA55
