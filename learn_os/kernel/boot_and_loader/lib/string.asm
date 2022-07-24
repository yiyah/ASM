[section .text]
global  memcpy
global  memset
global  strcpy
global  strlen

; ===================================
; @Function: eax = void *memcpy(void* es:dest, const void* es:src, size_t n);
; @retval: eax: dest
; @usage:   
;           mov     es, ax
;           mov     ds, ax
;           push    n
;           push    src
;           push    dest
;           call    memcpy
;        Note that init ds and es.
; ===================================
memcpy:
    push    ebp
    mov     ebp, esp
    push    ecx
    push    esi
    push    edi

    mov     ecx, [ebp+16]       ; n
    mov     esi, [ebp+12]       ; src
    mov     edi, [ebp+8]        ; dest

    cmp     ecx, 0
    jz      _memcpyRet

    cld         ; DF = 0
_memCpy:
    lodsb       ; [ds:esi] --> al and inc esi
    stosb       ; al --> [es:edi] and inc edi
    loop    _memCpy
    ; rep movsb ; can do above description

_memcpyRet:
    mov     eax, [ebp+8]        ; return value
    pop     edi
    pop     esi
    pop     ecx
    mov     esp, ebp
    pop     ebp
    ret

; ===================================
; @Function: memset(void* p_dst, u8 ch, u32 size);
; ===================================
memset:
    push    ebp
    mov     ebp, esp
    push    eax
    push    ecx
    push    edi

    mov     edi, [ebp+8]    ; p_dst
    mov     al, [ebp+12]    ; ch
    mov     ecx, [ebp+16]   ; size

    cld                     ; DF=0: edi++
    rep     stosb           ; al --> es:edi unless ecx < 0

    pop     edi
    pop     ecx
    pop     eax
    pop     ebp
    ret

; ===================================
; @Function: char* strcpy(char* p_dst, char* p_src);
; @retval: p_dst
; ===================================
strcpy:
    push    ebp
    mov     ebp, esp
    push    eax
    push    esi
    push    edi

    mov     esi, [ebp+8]    ; p_dst
    mov     edi, [ebp+12]   ; p_src

    cld                     ; DF = 0
_strcpy_next:
    lodsb                   ; [ds:esi] --> al
    cmp     al, 0           ; if al = '\0'
    je      _strcpy_exit
    stosb                   ; al --> [es:edi]
    jmp     _strcpy_next
_strcpy_exit:
    pop     edi
    pop     esi
    pop     eax
    pop     ebp
    ret

; ===================================
; @Function: int strlen(char* p_str);
; @retval:  eax: length
; @retval: length of p_str
; ===================================
strlen:
    push    ebp
    mov     ebp, esp
    push    esi

    xor     eax, eax
    mov     esi, [ebp + 8]
_strlen_next:
    cmp     byte [esi], 0
    je      _strlen_Ret
    inc     esi
    inc     eax
    jmp     _strlen_next
_strlen_Ret:
    pop     esi
    pop     ebp
    ret
