; command line, loaded to sectors 4, 5, and 6
; kstdio.s will follow this file.
; kstdlib.s will follow kstdio.s
; katoi.s will follow kstdlib.s
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
	; mov ax, commandMsg
	; push ax
	; call kprint
	; mov ax, 0x2002
	; push ax
	; call kprint
	; add sp, 4
	
	;mov ax, commandEnter
	;push ax
	;call kprint
	;pop ax

	mov ax, 0x2002
	mov bx, exitCmd
	push ax
	push bx
	call kstrcmp
	add sp, 4
	cmp al, 1
	je shell_done

	mov ax, 0x2002
	mov bx, clearCmd
	push ax
	push bx
	call kstrcmp
	add sp, 4
	cmp al, 1
	jne noClearCmd
	call clearStack

noClearCmd:
	mov ax, 0x2002
	mov bx, stackCmd
	push ax
	push bx
	call kstrcmp
	add sp, 4
	cmp al, 1
	jne noStackCmd
	call showStack

noStackCmd:
	; check for add character ':'
	; or pop character ';'
	; or operate character '/'
	mov bx, 0x2002
	mov al, [bx]
	cmp al, 0x3A
	je addOp
	cmp al, 0x3B
	je popOp
	cmp al, 0x2F
	je performOp

	jmp prompt

addOp:
	call addOperation
	jmp prompt
popOp:
	call popOperation
	jmp prompt
performOp:
	call perfOperation
	jmp prompt

shell_done:
; return from the command line... never should happen
	mov sp, bp
	pop bp
	xor ax, ax

	retf

addOperation:
	push bp
	mov bp, sp
	
	; they have added some number to the stack
	mov bx, 0x2003
	push bx
	call katoi
	pop bx
	push ax
	call rpn_push
	pop ax
	
	mov sp, bp
	pop bp
	ret

popOperation:
	push bp
	mov bp, sp
	sub sp, 16
	
	call rpn_pop
	mov bx, sp
	push bx
	push ax
	call kitoa
	add sp, 4
	mov bx, sp
	push bx
	call kprint
	pop bx
	add sp, 16
	
	mov bx, commandEnter
	push bx
	call kprint
	pop bx
	
	mov sp, bp
	pop bp
	ret

perfOperation:
	push bp
	mov bp, sp
	
	mov bx, 0x2003
	mov al, [bx]
	mov ah, 0
	push ax
	call rpn_operate
	pop ax
	
	mov sp, bp
	pop bp
	ret

showStack:
	push bp
	mov bp, sp
	push si
	
	mov bx, 0x3000
	mov ax, [bx]
	mov si, 0x3002
showStack_loop:
	cmp ax, 0
	je showStack_loopend

	mov bx, [si]
	push ax
	sub sp, 16
	mov ax, bx
	mov bx, sp
	push bx
	push ax
	call kitoa
	add sp, 4
	mov bx, sp
	push bx
	call kprint
	add sp, 18
	
	; print newline
	mov ax, commandEnter
	push ax
	call kprint
	add sp, 2
	
	pop ax
	dec ax
	add si, 2
	jmp showStack_loop
	
showStack_loopend:
	pop si
	mov sp, bp
	pop bp
	ret

clearStack:
	push bp
	mov bp, sp
	
	mov ax, 0
	mov bx, 0x3000
	mov [bx], ax
	
	mov sp, bp
	pop bp
	ret

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
; Converts a string to an integer.
; katoi(const char * string);
; stack upon calling:
; string (2 bytes [ptr], null terminated)
; return address (2 bytes [ptr])
; return:
; ax = number to which the string was converted.
katoi:
	push bp
	mov bp, sp
	
	; dx = chars left
	; cx = end of string
	mov bx, sp
	mov cx, [bx+4]
	mov dx, 0
	; find the end of the string
	sub sp, 6
	mov bx, sp
	mov ax, 1
	mov [bx], ax
	mov ax, 0
	mov [bx+2], ax
	mov [bx+4], dx
katoi_loop1:
	mov bx, cx
	mov al, [bx]
	cmp al, 0
	je katoi_loop1end
	add dx, 1
	add cx, 1
	jmp katoi_loop1

katoi_loop1end:
	sub cx, 1
	mov bx, sp
	mov [bx+4], dx
	
	; [sp+4] = characters left
	; [sp+2] = final value
	; [sp]   = multiplier

katoi_loop2:
	mov bx, sp
	mov dx, [bx+4]
	cmp dx, 0
	je katoi_loop2end
	; read an ascii character from cx, and
	; convert it to a decimal number.
	mov bx, cx
	mov ah, 0
	mov al, [bx]
	sub al, 0x30 ; 0x30 = '0'
	; get multiplier
	mov bx, sp
	push si
	mov si, [bx]
	mov bx, si
	pop si
	
	mul bx ; multiply bx (multiplier) by ax (ascii number)
	; add the new multiplied value to the sum
	; load sum to bx
	mov bx, sp
	push si
	mov si, [bx+2]
	mov bx, si
	pop si
	; add bx with ax (new value)
	add bx, ax
	mov ax, bx
	; load back into the stack
	mov bx, sp
	mov [bx+2], ax
	; multiply the multiplier by 10
	mov bx, sp
	push si
	mov si, [bx]
	mov bx, si
	pop si
	mov ax, 10
	mul bx
	mov bx, sp
	mov [bx], ax
	
	sub cx, 1
	mov bx, sp
	mov dx, [bx+4]
	sub dx, 1
	mov [bx+4], dx
	jmp katoi_loop2

katoi_loop2end:
	add sp, 2
	pop ax ; get return value from stack
	mov sp, bp
	pop bp
	ret

; convert an integer to a string
; kitoa(unsigned uint16_t number, char * destination)
; stack upon calling:
; destination (2 bytes [ptr])
; number (2 bytes [int])
; return address (2 bytes [ptr])

kitoa:
	push bp
	mov bp, sp
	
	; stack:
	; bp
	; revnum [16]
	; revidx [2]
	; destin [2]
	; number [2]
	mov bx, sp
	mov dx, [bx+6] ; destination
	mov cx, [bx+4] ; number
	sub sp, 16
	mov ax, 0
	push ax
	push dx
	push cx
	
	mov bx, dx
	mov dl, 0x30
	mov [bx], dl
	; kbzero(&destination[1], 15)
	add bx, 1
	mov ax, 15
	push ax
	push bx
	call kbzero
	add sp, 4
	
	; kbzero(revnum, 16);
	mov bx, sp
	add bx, 6
	mov ax, 16
	push ax
	push bx
	call kbzero
	add sp, 4
	
kitoa_loop:
	; if the number is 0, we are done conversion
	mov bx, sp
	mov ax, [bx]
	cmp ax, 0
	je kitoa_endloop
	; divide the number by 10, use the remainder for our next digit
	mov cx, 10
	mov dx, 0
	div cx
	;mov dl, ah
	;mov ah, 0
	mov [bx], ax
	add dl, 0x30 ; 0x30 = '0'
	mov bx, sp
	mov cx, [bx+4]
	; cx is our buffer offset, bx is our buffer
	mov bx, sp
	add bx, 6
	add bx, cx
	; move the ASCII remainder to the buffer at our current offset
	mov [bx], dl
	inc cx
	mov bx, sp
	mov [bx+4], cx
	jmp kitoa_loop

kitoa_endloop:
	; reverse the revbuf into the destination buffer.
	; both should be 16 characters
	
	; load the result buffer address into bx
	mov bx, sp
	add bx, 2
	mov ax, [bx]
	mov bx, ax
	
	; preserve important registers
	push si
	push di
	
	; load the source buffer address into si
	mov si, sp
	add si, 10
	
	; read all characters
	; cx = si offset
	; si = source (added with cx to get the current character)
	; bx = destination (starts at 0)

	; read the length from the stack
	mov di, sp
	mov cx, [di+8]
kitoa_revloop:
	; go back one character in the source buffer
	cmp cx, 0
	je kitoa_ret
	dec cx
	; read character from source and put in destination
	mov di, si
	add di, cx
	mov al, [di]
	mov [bx], al
	inc bx
	mov al, 0
	mov [bx], al
	jmp kitoa_revloop

kitoa_ret:
	pop di
	pop si
kitoa_fin:
	mov sp, bp
	pop bp
	xor ax, ax
	ret

; RPN stack is stored at 0x3002, stack count is 0x3000

; push a two-byte unsigned int to the RPN stack.
; rpn_push (unsigned uint16_t num)
; stack upon calling:
; number (2 bytes [int])
; return address (2 bytes [ptr])
rpn_push:
	push bp
	mov bp, sp
	push si

	mov bx, 0x3000
	mov ax, [bx]
	mov cx, [bx]
	mov ax, cx
	inc cx
	mov [bx], cx
	mov dl, 2
	mul dl
	mov bx, sp
	mov dx, [bx+6]
	mov bx, 0x3002
	add bx, ax
	mov [bx], dx
	
	pop si
	mov sp, bp
	pop bp
	ret

; get a two byte unsigned int from the stack (if one exists)
; unsigned uint16_t rpn_pop ()
; stack upon calling:
; ...
; return address
; return:
; ax = two byte unsigned int
; bx = if no items were found, 1, otherwise 0
rpn_pop:
	push bp
	mov bp, sp
	
	; read the count, end with no result if no items
	mov bx, 0x3000
	mov ax, [bx]
	cmp ax, 0
	je rpn_pop_retnoval
	; decrement the count
	sub ax, 1
	mov [bx], ax
	; multiply by two to get the byte index
	mov cl, 2
	mul cl
	mov bx, 0x3002
	add bx, ax
	mov ax, [bx]
	xor bx, bx
	jmp rpn_pop_end
	
rpn_pop_retnoval:
	mov ax, 0
	mov bx, 1
rpn_pop_end:
	mov sp, bp
	pop bp
	ret

; apply an RPN operation
; void rpn_operate (unsigned char operator);
; stack upon calling:
; operator (1 byte [char])
; return address (2 bytes [ptr])
rpn_operate:
	push bp
	mov bp, sp
	
	mov bx, sp
	mov dl, [bx+4]
	mov dh, 0
	push dx
	
	call rpn_pop
	push ax
	call rpn_pop
	push ax
	
	mov bx, sp
	mov ch, 0
	mov cl, [bx+4]
	cmp cl, 0x2b
	je rpn_operate_add
	cmp cl, 0x2d
	je rpn_operate_subtract
	cmp cl, 0x2a
	je rpn_operate_multiply
	cmp cl, 0x2f
	je rpn_operate_divide
	push cx
	call rpn_push
	pop cx
	jmp rpn_operate_done

rpn_operate_add:
	pop dx
	pop cx
	add dx, cx
	push dx
	call rpn_push
	jmp rpn_operate_done

rpn_operate_subtract:
	pop dx
	pop cx
	sub dx, cx
	push dx
	call rpn_push
	jmp rpn_operate_done

rpn_operate_multiply:
	pop ax
	pop cx
	mul cx
	push ax
	call rpn_push
	jmp rpn_operate_done

rpn_operate_divide:
	pop ax
	pop cx
	mov dx, 0
	cmp cx, 0
	je nogood
	div cx
	push ax
	call rpn_push
	jmp rpn_operate_done

nogood:
	mov ax, 0
	push ax
	call rpn_push
	jmp rpn_operate_done
	
rpn_operate_done:
	mov sp, bp
	pop bp
	ret


; kbzero(const void * buffer, unsigned uint16_t length)
; stack upon calling:
; length (2 bytes [uint])
; buffer (2 bytes [ptr])
; return address (2 bytes [ptr])
kbzero:
	push bp
	mov bp, sp
	
	; cx = buffer
	; ax = length
	mov ax, sp
	mov cx, sp
	add ax, 6
	add cx, 4
	; cx = *cx
	mov bx, cx
	mov cx, [bx]
	; ax = *ax
	mov bx, ax
	mov ax, [bx]

kbzero_loop:
	mov dl, 0
	mov bx, cx ; bx doesn't support being a pointer?!?!?!
	mov [bx], dl
	inc cx
	sub ax, 1
	cmp ax, 0
	je kbzero_done
	jmp kbzero_loop

kbzero_done:	
	mov sp, bp
	pop bp
	ret

; compare two null terminated strings
; kstrcmp(const char * buffer, const char * buffer2);
; stack upon calling:
; buffer2 (2 bytes [ptr])
; buffer (2 bytes [ptr])
; return address (2 bytes [ptr])
; return:
; al = 0 if no match
; al = 1 if math
kstrcmp:
	push bp
	mov bp, sp
	
	; ax = length
	; cx = buffer
	; dx = buffer2
	mov ax, 0 ; length
	mov bx, sp
	mov cx, [bx + 4]
	mov dx, [bx + 6]
	
kstrcmp_loop:
	push ax
	mov bx, cx
	mov al, [bx]
	mov bx, dx
	mov ah, [bx]
	cmp al, ah
	jne kstrcmp_notequal
	cmp al, 0
	je kstrcmp_gotlen
	pop ax
	inc ax
	inc cx
	inc dx
	jmp kstrcmp_loop

kstrcmp_gotlen:
	pop ax
	sub cx, ax
	sub dx, ax
	push ax
	push cx
	push dx
	call kbcmp
	add sp, 12
	
	mov sp, bp
	pop bp
	ret
kstrcmp_notequal:
	mov sp, bp
	pop bp
	mov ax, 0
	ret

; compare two buffers
; kbcmp(const void * buffer1, const void * buffer2, unsigned uint16_t length);
; stack upon calling:
; length (2 bytes [uint])
; buffer2 (2 bytes [ptr])
; buffer (2 bytes [ptr])
; return address (2 bytes [ptr])
; return:
; al = 0 if no match
; al = 1 if match
kbcmp:
	push bp
	mov bp, sp
	
	; cx = buffer1
	; dx = buffer2
	; ax = length left
	mov bx, sp
	mov cx, bx
	mov dx, bx
	mov ax, bx
	add cx, 4
	add dx, 6
	add ax, 8
	; cx = *cx
	mov bx, cx
	mov cx, [bx]
	; dx = *dx
	mov bx, dx
	mov dx, [bx]
	; ax = *ax
	mov bx, ax
	mov ax, [bx]
	
kbcmp_loop:
	push ax
	mov bx, dx
	mov al, [bx]
	mov bx, cx
	mov ah, [bx]
	cmp ah, al
	jne kbcmp_notequal
	pop ax
	sub ax, 1
	cmp ax, 0
	je kbcmp_done
	jmp kbcmp_loop
kbcmp_done:
	mov sp, bp
	pop bp
	mov ah, 0
	mov al, 1
	ret
kbcmp_notequal:
	mov sp, bp
	pop bp
	mov ax, 0
	ret


commandPrompt:	db '$ ',0
commandEnter:	db 13,10,0
commandMsg:		db 'You wrote: ',0
exitCmd:		db 'exit',0
stackCmd:		db 'stack',0
clearCmd:		db 'clear',0

