; command line, loaded to sectors 4 and possibly 5
; kstdio.s will follow this file.
; kstdlib.s will follow kstdio.s
; shellconstants.s will follow kstdlib.s

; 0x2000 = command buffer length
; 0x2002 = command buffer

org 0x1400
section .text
global _start

_start:
	push bp
	mov bp, sp
	
prompt:
	mov ax, commandPrompt
	push ax
	call kprint
	add sp, 2
	; kbzero(commandbuffer, 512)
	mov ax, 514
	mov bx, 0x2000
	push ax ; length
	push bx ; buffer
	call kbzero
	add sp, 4

inputLoop:
	call kgetch
	; al is now set to the read character...
	cmp al, 0x0D ; \r is enter...
	je cmdAccept ; if they hit enter, cmdAccept()
	cmp al, 0x08 ; if they hit backspace, print space first.
	jne appendBuffer
	; print space, restoring previous backspace character

; only reached if the user hit backspace.
; backspace: should decrement the command length and clear the active cell
backspace:
	mov al, 0x08
	mov bh, 0
	mov ah, 0x0e
	int 0x10
	; clear the cell
	mov al, 0x20
	mov bh, 0
	mov ah, 0x0e
	int 0x10
	mov al, 0x08 ; move back again

	; decrement the buffer length
	mov bx, 0x2000
	mov cx, [bx]
	cmp cx, 0
	je inputLoop	; if there is nothing to delete, loop
	sub cx, 1
	mov [bx], cx
	; zero the current character
	mov bx, 0x2002
	add bx, cx
	mov cl, 0
	mov [bx], cl
	; jump directly to the echo function to echo the backspace.
	; we do not want to append the backspace ASCII code to our
	; character buffer
	jmp echoInput

; called if the user didn't hit backspace.
; appendBuffer: should append the value of al to the cmd buffer and increment
; the length.
appendBuffer:
	mov bx, 0x2000
	mov cx, [bx]
	mov bx, 0x2002
	add bx, cx
	mov [bx], al ; add a new byte to the buffer
	add cx, 1
	mov bx, 0x2000
	mov [bx], cx

; echo the value of al and jump to the input loop
echoInput:
	mov bh, 0 ; page num
	mov ah, 0x0e
	int 0x10
	jmp inputLoop

; the user hit enter.
; cmdAccept: should print the last command and jump back to a new prompt
cmdAccept:
	mov ax, commandEnter
	push ax
	call kprint
	pop ax

	; print the previous command
	mov ax, commandMsg
	push ax
	call kprint
	mov ax, 0x2002
	push ax
	call kprint
	add sp, 4
	
	mov ax, commandEnter
	push ax
	call kprint
	pop ax

	mov ax, 0x2002
	mov bx, exitCmd
	push ax
	push bx
	call kstrcmp
	add sp, 4
	cmp al, 1
	je shell_done

	jmp prompt

shell_done:
; return from the command line... never should happen
	mov sp, bp
	pop bp
	xor ax, ax

	retf

