; command line, loaded to sectors 4 and possibly 5
; kstdio.s will follow this file.
; shellconstants.s will follow kstdio.s

org 0x1400
section .text
global _start

_start:
	push ebp
	mov ebp, esp
	
prompt:
	mov ax, commandPrompt
	push ax
	call kprint
	pop ax
inputLoop:
	call kgetch
	; al is now set to the read character...
	cmp al, 0x0D
	je cmdAccept
	mov bh, 0 ; page num
	mov ah, 0x0e
	int 0x10
	jmp inputLoop
cmdAccept:
	mov ax, commandEnter
	push ax
	call kprint
	pop ax
	jmp prompt

	mov esp, ebp
	pop ebp
	xor ax, ax

	jmp 0x200:0x0
