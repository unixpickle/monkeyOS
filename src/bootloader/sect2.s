org 0x1000

section .text
global _start

_start:
	mov ah, 0x03		
	xor bh, bh
	int 0x10

	lea bx, [loadingMsg]
	call print
	
	mov ax, 0x200
	mov es, ax
	mov bx, 0 
	
	mov dl, 0 
	mov dh, 0 
	mov ch, 0 
	mov cl, 3 ; kernel is located at third sector
	mov al, 1
	
	mov ah, 2
	
	int 0x13
	
	lea bx, [startingMsg]
	call print
	
	call 0x200:0x0

	lea bx, [kernelExitMsg]
	call print
	
loop1: jmp loop1

print:
	; expects bx to be a ptr to the null terminated message.
	mov ah, 0x0e
	mov al, [bx]
	cmp al, 0
	je print__done
	int 0x10
	add bx, 1
	jmp print
print__done:
	ret

; constants section
loadingMsg:		db 'Loading kernel...',13,10,0
startingMsg:	db 'Starting kernel...',13,10,0
kernelExitMsg:	db 'Kernel exitted...',13,10,0
