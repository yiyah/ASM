; nasm -f elf -o foo.o 2_foo.asm
; gcc -m32 -c -o bar.o 2_bar.c
; ld -s -m elf_i386 -o foobar bar.o foo.o

extern  choose      ; int choose(int a, int b)

[SECTION .data]
var_a:      dd  11
var_b:      dd  6

[SECTION .text]
global      _start
global      myprint

_start:
    push    dword   [var_b]
    push    dword   [var_a]
    call    choose
    add     sp, 8

    mov     ebx, 0
    mov     eax, 1
    int     0x80

; void myprint(char *str, int len)
myprint:
    mov     edx, [esp+8]
    mov     ecx, [esp+4]
    mov     ebx, 1
    mov     eax, 4
    int     0x80
    ret
