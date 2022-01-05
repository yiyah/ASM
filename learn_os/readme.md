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
