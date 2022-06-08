2_foobar:bar.o foo.o
	ld -s -m elf_i386 -o $@ bar.o foo.o
bar.o:2_bar.c
	gcc -m32 -c -o $@ $<
foo.o:2_foo.asm
	nasm -f elf -o $@ $<

clean:
	rm *.o 2_foobar