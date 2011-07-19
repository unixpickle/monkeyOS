section .text
global _start

_start:
	mov ax, 0x100
	mov es, ax
	mov bx, 0 

	mov dl, 0 
	mov dh, 0 
	mov ch, 0 
	mov cl, 2 
	mov al, 1 

	mov ah, 2 

	int 0x13

	jmp 0x100:0x0
