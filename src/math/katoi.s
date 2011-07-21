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

