compile: bin/makeimg bin/sect2 bin/bsect bin/kernel bin/shell

bin/makeimg: src/makeimg.c
	gcc src/makeimg.c -o bin/makeimg

bin/bsect: src/bootloader/bsect.s
	nasm -f bin src/bootloader/bsect.s -o bin/bsect

bin/sect2: src/bootloader/sect2.s
	nasm -f bin src/bootloader/sect2.s -o bin/sect2

bin/kernel: src/kernel/kern.s src/kernel/constants.s src/kernel/kstdio.s
	cat src/kernel/kern.s src/kernel/kstdio.s src/kernel/constants.s >tmp/k.s
	nasm -f bin tmp/k.s -o bin/kernel

bin/shell: src/kernel/commandline.s src/kernel/kstdio.s src/kernel/shellconstants.s src/kernel/kstdlib.s src/math/katoi.s src/math/kitoa.s src/math/rpn.s
	cat src/kernel/commandline.s src/kernel/kstdio.s src/math/katoi.s src/math/kitoa.s src/math/rpn.s src/kernel/kstdlib.s src/kernel/shellconstants.s >tmp/shell.s
	nasm -f bin tmp/shell.s -o bin/shell

clean:
	rm bin/*

image: template.img bin/makeimg
	cp template.img output.img
	./bin/makeimg output.img
	
