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
	mov cl, 10
	div cl
	mov dl, ah
	mov ah, 0
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

