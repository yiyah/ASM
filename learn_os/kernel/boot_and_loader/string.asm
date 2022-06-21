[section .text]
global  memcpy

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