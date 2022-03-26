; Display.lib

; ===================================
; Function: Display string which end with 0
; param: es:edi
; param: ds:esi
; ===================================
DispStr:
FLAG_LONG_JUMP      equ     0xFE
    push    ax
    push    bx
    xor     bx, bx
    jmp     _DispStr
DispStr_Long:
    push    ax
    push    bx
    mov     bx, FLAG_LONG_JUMP

_DispStr:
    xor     ax, ax
    mov     al, [ds:esi]
    cmp     al, 0
    je      Disp_ret
    mov     ah, 0x02
    mov     [es:edi], ax
    inc     esi
    add     edi, 2
    jmp     _DispStr
Disp_ret:
    pop     ax
    cmp     bx, FLAG_LONG_JUMP
    pop     bx
    je      Disp_ret_Long
    ret
Disp_ret_Long:
    retf

; ===================================
; Function: Display AL
; param: [IN]   es:edi  where to display
; param: [IN]   al
; param: [OUT]  edi     will point the next byte
; ===================================
DispAL:
    push    eax
    push    ebx
    push    ecx

    mov     cx, 2
    mov     ah, 0x03        ; color
    mov     bl, al          ; first deal high bits
    shr     al, 4
_loop_Disp_AL:
    and     al, 0xF
    cmp     al, 0xA
    jb      _IsNumber       ; is number
    add     al, 55          ; is character
    jmp     _Disp_AL
_IsNumber:
    add     al, 48
_Disp_AL:
    mov     [es:edi], ax    ; display
    mov     al, bl          ; deal low bits
    add     edi, 2
    loop    _loop_Disp_AL

    pop     ecx
    pop     ebx
    pop     eax
    ret

; ===================================
; Function: clear screen
; param: [IN] es
; ===================================
ClearScreen:
    push    eax
    push    ecx
    push    edi

    xor     eax,eax
    xor     ecx,ecx
    xor     edi,edi
    mov     cx,25*80        ; total 4000 Bytes
    mov     ax,0            ; but I use ax so it will div 2
Clear_Screen:
    mov     [es:edi],ax
    add     edi,2
    loop    Clear_Screen

    pop     edi
    pop     ecx
    pop     eax
    ret

; ===================================
; @Function: void *memcpy(void *dest, const void *src, size_t n);
; @param: [IN]  es: dest
;         [IN]  edi:    push edi
; @param: [IN]  ds: src
;         [IN]  esi     push esi
; @param: [IN]  n:      push n
; @param: [out] eax:    dest
; @usage:   push    n
;           push    src
;           push    dest
;           call    MemCpy
;        Note that init ds and es.
; ===================================
MemCpy:
    push    ebp
    mov     ebp, esp
    push    ecx
    push    esi
    push    edi

    mov     ecx, [ebp+16]       ; n
    mov     esi, [ebp+12]       ; src
    mov     edi, [ebp+8]        ; dest

    cmp     ecx, 0
    jz      _MemCpyRet

    cld         ; DF = 0
_Mem_Cpy:
    lodsb       ; [ds:esi] --> al and inc esi
    stosb       ; al --> [es:edi] and inc edi
    loop    _Mem_Cpy
    ; rep movsb ; can do above description

    mov     eax, [ebp+8]        ; return value

_MemCpyRet:
    nop
    pop     edi
    pop     esi
    pop     ecx
    mov     esp, ebp
    pop     ebp
    ret