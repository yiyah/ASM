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

## Note

1. 0xAA55
   I found that if your img is not first created, this will result in the data would not clear when you use the command of dd.
   This affect your next code will work without 0xAA55.

   How can I fix it? It doesn't work with the flowing lines.
   `times   510 - ($-0x7C00) db 0`
   `times   (0x7C00+510) - $ db 0`
   `times   (0x1FE - $) db 0`

   It's sad that I use the manual method to calculate the size.
   As example: 2_protectMode/1_EnterProtectMode.asm

   * step1: It is setted 0 when you first build the file
      `times   0 db 0  ; replce the first 0 with (512 - file_size)`

   * step2: Get the file size
      Get the file size with `ls -al xxx.bin`.

   * step3: Calculate the remaining size and replace 0
      `512 - file_size`
