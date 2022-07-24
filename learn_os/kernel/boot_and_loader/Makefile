# it must have the same value with "KernelEntryPointPhyAddr" in load.asm
ENTRYPOINT		:= 0x30400
# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET		= 0x400

# compile tool and parameters
ASM				= nasm
DASM			= ndisasm
CC				= gcc
LD				= ld
ASMBFLAGS		= -I boot/include/
ASMKFLAGS		= -f elf -I include/
CFLAGS			= -I include/ -m32 -c -fno-builtin -fno-stack-protector
LDFLAGS			= -m elf_i386 -s -Ttext $(ENTRYPOINT)
DASMFLAGS		= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# generate file
HBOOT		= boot/boot.bin boot/loader.bin
HKERNEL		= kernel.bin
OBJS		= kernel/kernel.o kernel/start.o kernel/i8259.o kernel/protect.o \
			  kernel/main.o kernel/global.o kernel/clock.o kernel/process.o \
			  kernel/syscall.o kernel/keyboard.o kernel/tty.o kernel/console.o \
			  kernel/printf.o kernel/vsprintf.o lib/kliba.o lib/string.o lib/klib.o
DASMOUTPUT	= kernel.bin.asm

.PHONY : everything clean all buildimg disasm

everything: $(HBOOT) $(HKERNEL) image

all: clean everything

# compile boot/
boot/boot.bin : boot/boot.asm boot/include/fat12hdr.inc boot/include/common.inc 
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/*
	$(ASM) $(ASMBFLAGS) -o $@ $<

# compile kernel.bin
$(HKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

# compile kernel/
kernel/kernel.o : kernel/kernel.asm include/sconst.inc
	$(ASM) $(ASMKFLAGS) -o $@ $<

# we also can use "gcc -M kernel/star.c -I include/" to get dependency files
kernel/start.o : kernel/start.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/i8259.o : kernel/i8259.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/protect.o : kernel/protect.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/main.o : kernel/main.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/global.o : kernel/global.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/clock.o : kernel/clock.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/process.o : kernel/process.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/syscall.o : kernel/syscall.asm include/sconst.inc
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/keyboard.o : kernel/keyboard.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/tty.o : kernel/tty.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/console.o : kernel/console.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/printf.o : kernel/printf.c include/*
	$(CC) $(CFLAGS) -o $@ $<

kernel/vsprintf.o : kernel/vsprintf.c include/*
	$(CC) $(CFLAGS) -o $@ $<

# compile lib
lib/kliba.o : lib/kliba.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) -f elf -o $@ $<

lib/klib.o : lib/klib.c include/type.h include/const.h include/proto.h
	$(CC) $(CFLAGS) -o $@ $<

# for setup bochs
image : $(HBOOT) $(HKERNEL) buildimg

buildimg:
	dd if=boot/boot.bin of=../../mbr/b.img bs=512 count=1 conv=notrunc
	sudo mount -o loop ../../mbr/b.img /mnt/floppy
	sudo cp -v boot/loader.bin /mnt/floppy/L.BIN
	sudo cp -v kernel.bin /mnt/floppy/
	sudo umount /mnt/floppy

# for debug
disasm : $(HKERNEL)
	$(DASM) $(DASMFLAGS) $< > $(DASMOUTPUT)
	rm -f $(OBJS)

clean:
	rm -f $(HBOOT) $(HKERNEL) $(OBJS) $(DASMOUTPUT)
