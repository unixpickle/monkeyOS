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
	
rpn_operate_done:
	mov sp, bp
	pop bp
	ret

