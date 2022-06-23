# it must have the same value with "KernelEntryPointPhyAddr" in load.asm
ENTRYPOINT	  	:= 0x30400
# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET		= 0x400

# compile tool and parameters
ASM 			= nasm
DASM 			= ndisasm
CC				= gcc
LD				= ld
ASMBFLAGS 		= -I boot/include/
ASMKFLAGS		= -f elf
CFLAGS			= -I include/ -m32
LDFLAGS			= -m elf_i386 -s -Ttext $(ENTRYPOINT)
DASMFLAGS		= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# generate file
HBOOT		= boot/boot.bin boot/loader.bin
HKERNEL 	= kernel.bin
OBJS 		= kernel/kernel.o kernel/start.o lib/kliba.o lib/string.o
DASMOUTPUT	= kernel.bin.asm

.PHONY : everything clean all buildimg disasm

everything: $(HBOOT) $(HKERNEL)

all: clean everything

# compile boot/
boot/boot.bin : boot/boot.asm boot/include/fat12hdr.inc boot/include/common.inc 
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/*
	$(ASM) $(ASMBFLAGS) -o $@ $<

# compile kernel
$(HKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

kernel/kernel.o : kernel/kernel.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/star.o : kernel/star.c include/*
	$(CC) $(CFLAGS) -o $@ $<

# compile lib
lib/kliba.o : lib/kliba.asm
	$(ASM) -f elf -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) -f elf -o $@ $<

# for setup bochs
buildimg:
	dd if=boot/boot.bin of=../../mbr/b.img bs=512 count=1 conv=notrunc
	sudo mount -o loop ../../mbr/b.img /mnt/floppy
	sudo cp -v boot/loader.bin /mnt/floppy/L.BIN
	sudo cp -v kernel.bin /mnt/floppy
	sudo umount /mnt/floppy

# for debug
disasm : $(HKERNEL)
	$(DASM) $(DASMFLAGS) $< > $(DASMOUTPUT)
	rm -f $(OBJS)

clean:
	rm -f $(HBOOT) $(HKERNEL) $(OBJS) $(DASMOUTPUT)
