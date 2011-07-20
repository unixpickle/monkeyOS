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

commandPrompt:	db '$ ',0
commandEnter:	db '  OK  ',13,10,0

