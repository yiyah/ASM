[SECTION .data]
disp_pos	dd	0

[section .text]
global  disp_str

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