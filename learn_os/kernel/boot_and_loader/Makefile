BOOT:=boot.asm
LOADER:=loader.asm
KERNEL:=kernel.asm
BOOT_BIN:=$(subst .asm,.bin,$(BOOT))
LOADER_BIN:=$(subst .asm,.bin,$(LOADER))
KERNEL_BIN:=$(subst .asm,.bin,$(KERNEL))
ALL_TARGET+=$(wildcard *.bin) \
			$(wildcard *.o)
DEPENDENCY_FILE:=$(wildcard *.inc)

IMG:=../../mbr/b.img
FLOPPY:=/mnt/floppy

.PHONY : everything

test:
	nasm -f elf -o kernel.o kernel.asm
	nasm -f elf -o string.o string.asm
	nasm -f elf -o kliba.o kliba.asm
	gcc -m32 -c -o start.o start.c
	ld -m elf_i386 -s -Ttext 0x30400 -o kernel.bin kernel.o string.o start.o kliba.o
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	sudo mount -o loop $(IMG) $(FLOPPY)
	sudo cp -v $(LOADER_BIN) $(FLOPPY)/L.BIN
	sudo cp -v $(KERNEL_BIN) $(FLOPPY)
	sudo umount $(FLOPPY)

everything : $(BOOT_BIN) $(LOADER_BIN) $(KERNEL_BIN) 
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	sudo mount -o loop $(IMG) $(FLOPPY)
	sudo cp -v $(LOADER_BIN) $(FLOPPY)/L.BIN
	sudo cp -v $(KERNEL_BIN) $(FLOPPY)
	sudo umount $(FLOPPY)

$(BOOT_BIN) : $(BOOT) $(DEPENDENCY_FILE)
	nasm -o $@ $<

$(LOADER_BIN) : $(LOADER) $(DEPENDENCY_FILE)
	nasm -o $@ $<

$(KERNEL_BIN) : $(KERNEL)
	nasm -f elf -o $(subst .asm,.o,$(KERNEL)) $<
	ld -m elf_i386 -s -Ttext 0x30400 -o $@ $(subst .asm,.o,$(KERNEL))

clean:
	rm $(ALL_TARGET)
