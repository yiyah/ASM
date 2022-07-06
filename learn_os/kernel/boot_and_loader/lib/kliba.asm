%include "sconst.inc"

[SECTION .data]
global  disp_pos
disp_pos    dd  0

[section .text]
global  disp_str
global  disp_color_str
global  out_byte
global  in_byte
global  disable_irq
global  enable_irq

; ===================================
; @Function: disp_str(char* pszInfo)
; @usage:
;           mov     gs, ax
;           call    disp_str
; ===================================
disp_str:
    push    ebp
    mov     ebp, esp
    push    eax
    push    ebx
    push    esi
    push    edi

    mov     ah, 0x02            ; color
    mov     esi, [ebp+8]        ; address of pszInfo
    mov     edi, [disp_pos]
DISP_STR_NEXT:
    lodsb                       ; [ds:esi] --> al and inc esi
    cmp     al, 0
    je      DISP_STR_RET
    cmp     al, 0xA             ; is "\n" (new line)?
    jne     DISP_CHAR
    push    eax
    mov     eax, edi
    mov     bl, 160
    div     bl                  ; ax/bl = al(quotient)...ah(remainder)
    and     eax, 0xFF           ; only use quotient
    inc     eax                 ; point to next display line
    mul     bl
    mov     edi, eax
    pop     eax
    jmp     DISP_STR_NEXT
DISP_CHAR:
    mov     [gs:edi], ax
    add     edi, 2
    jmp     DISP_STR_NEXT

DISP_STR_RET:
    mov     [disp_pos], edi     ; save for next display

    pop     edi
    pop     esi
    pop     ebx
    pop     eax
    mov     esp, ebp
    pop     ebp
    ret

; ===================================
; @Function: disp_color_str(char* pszInfo, db color)
; ===================================
disp_color_str:
    push    ebp
    mov     ebp, esp
    push    eax
    push    ebx
    push    esi
    push    edi
    mov     ah,  [ebp+12]           ; color
    mov     esi, [ebp+8]        ; address of pszInfo
    mov     edi, [disp_pos]
DISP_COLOR_STR_NEXT:
    lodsb                       ; [ds:esi] --> al and inc esi
    cmp     al, 0
    je      DISP_COLOR_STR_RET
    cmp     al, 0xA             ; is "\n" (new line)?
    jne     DISP_COLOR_CHAR
    push    eax
    mov     eax, edi
    mov     bl, 160
    div     bl                  ; ax/bl = al(quotient)...ah(remainder)
    and     eax, 0xFF           ; only use quotient
    inc     eax                 ; point to next display line
    mul     bl
    mov     edi, eax
    pop     eax
    jmp     DISP_COLOR_STR_NEXT
DISP_COLOR_CHAR:
    mov     [gs:edi], ax
    add     edi, 2
    jmp     DISP_COLOR_STR_NEXT

DISP_COLOR_STR_RET:
    mov     [disp_pos], edi     ; save for next display
    pop     edi
    pop     esi
    pop     ebx
    pop     eax
    pop     ebp
    ret

; ===================================
; @Function: out_byte(dw port, db val)
; ===================================
out_byte:
    push    eax
    push    edx
    mov     dx, [esp+12]    ; port
    mov     al, [esp+16]    ; val
    out     dx, al
    nop                     ; delay
    nop
    pop     edx
    pop     eax
    ret

; ===================================
; @Function: al = in_byte(dw port)
; ===================================
in_byte:
    push    edx
    mov     dx, [esp+8]     ; port
    xor     eax, eax
    in      al, dx
    nop                     ; delay
    nop
    pop     edx
    ret

; ===================================
; @Function: void disable_irq(int irq);
; @retval: 0: already disabled
;          1: disable success
; @Brief: Disable an interrupt request line by setting an 8259 bit.
; ===================================
disable_irq:
        mov     ecx, [esp + 4]          ; irq
        pushf
        cli
        mov     ah, 1
        rol     ah, cl                  ; The corresponding interrupt bit is set to 1
        cmp     cl, 8                   ; for judge irq is from master or slave 8259
        jae     disable_8               ; disable irq >= 8 at the slave 8259
disable_0:
        in      al, INT_M_CTLMASK
        test    al, ah                  ; =0 if enable
        jnz     dis_already             ; jmp if already disabled
        or      al, ah
        out     INT_M_CTLMASK, al       ; set bit at master 8259
        popf
        mov     eax, 1                  ; disabled by this function
        ret
disable_8:
        in      al, INT_S_CTLMASK
        test    al, ah                  ; =0 if enable
        jnz     dis_already             ; jmp if already disabled?
        or      al, ah
        out     INT_S_CTLMASK, al       ; set bit at slave 8259
        popf
        mov     eax, 1                  ; disabled by this function
        ret
dis_already:
        popf
        xor     eax, eax                ; already disabled
        ret

; ===================================
; @Function: void enable_irq(int irq);
; @Brief: Enable an interrupt request line by clearing an 8259 bit.
; ===================================
enable_irq:
        mov     ecx, [esp + 4]          ; irq
        pushf
        cli
        mov     ah, ~1
        rol     ah, cl                  ; The corresponding interrupt bit is set to 0
        cmp     cl, 8
        jae     enable_8                ; enable irq >= 8 at the slave 8259
enable_0:
        in      al, INT_M_CTLMASK
        and     al, ah
        out     INT_M_CTLMASK, al       ; clear bit at master 8259
        popf
        ret
enable_8:
        in      al, INT_S_CTLMASK
        and     al, ah
        out     INT_S_CTLMASK, al       ; clear bit at slave 8259
        popf
        ret
