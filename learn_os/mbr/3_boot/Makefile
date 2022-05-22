.PHONY:all

all:mount_file 3 umount_file

mount_file:
	mount -o loop ../b.img /mnt/floppy

3:mount_file
	nasm 3_loader.asm -o 3.bin
	nasm 3_loader.asm -o 3.com
	cp 3.com /mnt/floppy
	umount /mnt/floppy

umount_file:
	umount /mnt/floppy

clean:
	rm *.bin *.com