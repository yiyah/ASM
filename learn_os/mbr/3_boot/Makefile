.PHONY:all

all:mount_file 3 4 dd_4 umount_file

mount_file:
	mount -o loop ../b.img /mnt/floppy

3:mount_file
	nasm 3_loader.asm -o 3.bin
	nasm 3_loader.asm -o 3.com
	cp 3.com /mnt/floppy
	umount /mnt/floppy

4:mount_file
	nasm 4_boot_readSector.asm -o 4.bin
	nasm 4_boot_readSector.asm -o 4.com
	cp 4.com /mnt/floppy
	umount /mnt/floppy

dd_4:
	dd if=4.bin of=../b.img bs=512 count=1 conv=notrunc

umount_file:
	umount /mnt/floppy

clean:
	rm *.bin *.com