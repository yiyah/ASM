# Readme

## Environment and tools

1. Environment: Ubuntu_1804
2. Editor: VS code
3. Compiler: nasm
4. RunInWhere: Bochs

## commands

step1: `nasm xxx.asm -o xxx.bin`

step2: `dd if=boot.bin of=mbr.img bs=512 count=1 conv=notrunc`  // need generate an img

step3: then configure Bochs and run `bochs -f bochsrc`

others:

```shell
mount -o xx.img /mnt/floppy
cp xxx.com /mnt/floppy
umount /mnt/floppy

xxd -u -a -g 1 -s +0x2600 -l 512 xxx.img

nasm -f elf -o xxx.o xxx.asm
gcc -m32 -c -o xxx.o xxx.c       ; complie 32bit-i386 elf
ld -m elf_i386 -s -Ttext 0x30400 -o xxx.bin xxx.o yyy.o zzz.o
```

## Note

1. 0xAA55

   I found that if your img is not first created, this will result in the data would not clear when you use the command of dd.
   This affect your next code will work without 0xAA55.

   How can I fix it? It doesn't work with the flowing lines.

   ```asm
   times   510 - ($-0x7C00) db 0
   times   (0x7C00+510) - $ db 0
   times   (0x1FE - $) db 0
   ```

   It's sad that I use the manual method to calculate the size.
   As example: 2_protectMode/1_EnterProtectMode.asm

   * step1: It is setted 0 when you first build the file

      `times   0 db 0  ; replce the first 0 with (512 - file_size)`

   * step2: Get the file size

      Get the file size with `ls -al xxx.bin`.

   * step3: Calculate the remaining size and replace 0

      `512 - file_size`

   * Note: It also need changed when you modify your code.Because the file size maybe has changed.
