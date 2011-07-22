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
	mov al, 3 ; three sectors need to be read.
	
	mov ah, 2
	
	int 0x13

	mov ax, startCmdLine
	push ax
	call kprint
	pop ax
	
	call 0x140:0x0

	mov ax, doneKernMsg
	push ax
	call kprint
	pop ax
kernloop: jmp kernloop

global kprint
kprint:
	mov bx, sp
	add bx, 2	; stack pointer + 4 = first argument
	mov ax, [bx]
	mov bx, ax
_kprint_loop:
	; expects bx to be a ptr to the null terminated message.
	mov ah, 0x0e
	mov al, [bx]
	cmp al, 0
	je _kprint_done
	int 0x10
	add bx, 1
	jmp _kprint_loop
_kprint_done:
	xor ax, ax
	ret

global kgetch
kgetch:
	mov ah, 0x0
	int 0x16
	ret

startMsg: 		db 'Kernel started', 13, 10, 0
loadCmdLine: 	db 'Loading command line ...', 13, 10, 0
startCmdLine: 	db 'Starting command line ...', 13, 10, 0
doneKernMsg:	db 'End of kernel', 13, 10, 0

