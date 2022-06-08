; nasm xxx.asm -f elf -o hello.o
; ld -m elf_i386 -s -o hello hello.o

[SECTION .data]
strHello:        db  'Hello world', 0x0A
STRLEN          equ     $ - strHello

[SECTION .text]
global      _start

_start:
    mov     edx, STRLEN
    mov     ecx, strHello
    mov     ebx, 1
    mov     eax, 4
    int     0x80
    mov     ebx, 0
    mov     eax, 1
    int     0x80
