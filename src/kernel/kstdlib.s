
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

