What is it?
===========

This is a small bootloader that can be run through a VM as a floppy disk.  The bootloader itself is in src/bootloader/bsect.s.  The bootloader loads src/bootloader/sect2.s, which loads src/kernel/kern.s.  The kernel (kern.s) simply loads src/kernel/commandline.s which will eventually contain the OS's core functionality.  In the future I may create my own programming language that will be interpreted by the command line.

What's a bootloader?
--------------------

A bootloader is a chunk of compiled code that is run by the Basic Input/Output System when a computer boots.  In the case of monkeyOS, the bootloader resides on the first block of a floppy image.

NOTE: All console input and output is managed via BIOS interrupts.

Why NASM?
=========

NASM is primarily used in monkeyOS for simplicity and compatibility.  There are NASM compilers for Windows, Mac OS X, and Linux.  NASM also has similar syntax to Intel assembly, which is more familiar to me than AT&T style syntax.
