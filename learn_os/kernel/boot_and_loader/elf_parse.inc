; ===================================
; @Function: InitELF(dd PhysicalAddresOfELF)
; @Brief:   ds:esi point to ELF file
;           es: only set it's segment base address is 0, for MemCpy
; @Usage:
;           mov   ds, ax
;           mov   es, ax
;           mov   esi, ax
;           push  PhysicalAddresOfELF
;           call  InitELF
;           add   esp, 4
; ===================================

InitELF:
    push    ebp
    mov     ebp, esp
    push    eax
    push    ecx
    push    esi

    ; parse ELF Header
    mov     cx, [ds:esi+0x2C]       ; e_phnum: number of Program Header
    movzx   ecx, cx                 ; reset hight 16 bits
    mov     esi, [ds:esi+0x1C]      ; e_phoff: offset of Program Header Table in file
    add     esi, [ebp+8]            ; PhysicalAddresOfELF + offset of Program Header Table
                                    ; now esi had pointed to the first Program Header
    ; parse Program Header
_NEXT_PROGRAM_HEADER:
    mov     eax, [ds:esi+0]         ; p_type: segment type
    cmp     eax, 1
    jne     _NO_ACTION
    mov     eax, [ds:esi+4]         ; p_offset: offset of segment
    add     eax, [ebp+8]            ; PhysicalAddresOfELF + offset of Program Header Table
    push    dword [ds:esi+0x10]     ; p_filesz: size of segment
    push    eax                     ; src
    push    dword [ds:esi+0x8]      ; dest: p_vaddr: virtual adderss of segment
    call    MemCpy
    add     esp, 12
_NO_ACTION:
    add     esi, 0x20               ; e_phentsize: Program Header size always is fixed: 0x20
    loop    _NEXT_PROGRAM_HEADER
    
    pop     esi
    pop     ecx
    pop     eax
    mov     esp, ebp
    pop     ebp
    ret

; ===================================
; @Function: eax = void *memcpy(void *dest, const void *src, size_t n);
; @param: [out] eax:    dest
; @usage:   
;           mov     es, ax
;           mov     ds, ax
;           push    n
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