org     0x0
    jmp     _BEGIN

BASEOFSTACK         equ     0x7C00
Loadermessage:      db      'hello world!!!', 0

_BEGIN:
    mov     ax, BASEOFSTACK
    mov     ss, ax
    mov     sp, 0

    call    ClearScreen
    mov   ax, cs
    mov   ds, ax
    mov   si, Loadermessage
    mov   di, 0*80*2+25*2
    call  DispStr
    jmp     $

; ===================================
; @Function: DispStr(ds:si, di)
; @Brief: Display string which end with 0
; @param: [IN] ds:si data from where
; @param: [IN] di data go where
; @usage:   mov   ax, cs
;           mov   ds, ax
;           mov   si, STRING
;           mov   di, 10*80*2
;           call  DispStr
; ===================================
DispStr:
    push    es
    push    ax
    push    cx
    mov     ax,0xB800
    mov     es,ax           ; set the data destination
    xor     cx,cx           ; reset cx for loop
_Disp_Str:
    xor     cx,cx
    mov     cl,[ds:si]
    jcxz    _Disp_ret       ; finish display when the data is 0x00
    mov     ch,0x02         ; set color
    mov     [es:di],cx
    inc     si              ; the next index of what to show
    add     di,2            ; the next index of where to show
    jmp     _Disp_Str
_Disp_ret:
    pop     cx
    pop     ax
    pop     es
    ret

; ===================================
; Function: clear screen
; ===================================
ClearScreen:
    push    ax
    push    cx
    push    di
    push    es

    mov     ax, 0xB800
    mov     es, ax
    mov     cx,25*80        ; total 4000 Bytes
    mov     ax,0            ; but I use ax so it will div 2
    xor     di,di
Clear_Screen:
    mov     [es:di],ax
    add     di,2
    loop    Clear_Screen

    pop     es
    pop     di
    pop     cx
    pop     ax
    ret
