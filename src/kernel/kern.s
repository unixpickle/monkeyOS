org 0x1200
; Kernel executable code located at 3rd sector on floppy
; kstdio.s will be included after this file.

section .text

global _start
_start:
	lea ax, [startMsg]
	push ax
	call kprint
	pop ax

	mov ax, loadCmdLine
	push ax
	call kprint
	pop ax
	; printed out messages, load command line from fourth sector.
	; TODO: load command line and start it.

	mov ax, 0x140
	mov es, ax
	mov bx, 0 
	
	mov dl, 0 
	mov dh, 0 
	mov ch, 0 
	mov cl, 4 ; command line is possibly two sectors long...
	mov al, 2
	
	mov ah, 2
	
	int 0x13

	mov ax, startCmdLine
	push ax
	call kprint
	pop ax
	
	jmp 0x140:0x0

	mov ax, doneKernMsg
	push ax
	call kprint
	pop ax
kernloop: jmp kernloop

