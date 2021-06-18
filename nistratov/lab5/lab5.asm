ASTACK segment STACK
	dw 256 dup(?)
ASTACK ends

DATA segment
    ROUT_LOADED db 'Interruption is already loaded', 0DH, 0AH, '$'
    ROUT_CHANGED db 'Interruption is loaded successfully', 0DH, 0AH, '$'
    ROUT_IS_NOT_LOADED db 'Interruption is not loaded', 0DH, 0AH, '$'
    ROUT_UNLOADED db 'Interruption is restored', 0DH, 0AH, '$'
DATA ends

CODE segment
	assume cs:CODE, ds:DATA, ss:ASTACK

ROUT proc far
	jmp START_ST
	
	INTSEG dw 256 dup(0)
	INT_SIG dw 0ffffh
	KEEP_IP dw 0
	KEEP_CS dw 0
	KEEP_PSP dw 0
	KEEP_AX dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0

START_ST:
	mov KEEP_AX,ax
	mov KEEP_SP,sp
	mov KEEP_SS,ss
	
	mov ax,seg INTSEG
	mov ss,ax
	mov ax,offset INTSEG
	add ax,256
	mov sp,ax
	
	mov ax,KEEP_AX
	
	in al,60h
	cmp al,10h
	je K_Q
	cmp al,11h
	je K_W
	
	call dword ptr cs:[KEEP_IP]
	jmp END_ROUT_P
K_Q:
	mov al,'a'
	jmp DO
K_W:
	mov al,'s'

DO:
	push ax
	in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    xchg ah, al
    out 61h, al
    mov al, 20H
    out 20h, al
	pop ax

READS:
	mov ah, 05h
    mov cl, al
    mov ch, 00h
    int 16h
    or al, al
    jz END_ROUT_P
    mov ax, 40h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp READS

END_ROUT_P:
	mov sp,KEEP_SP
	mov ax,KEEP_SS
	mov ss,ax
	mov ax,KEEP_AX
	mov al,20h
	out 20h,al
	iret
ROUT endp

CHECK_UNLOAD proc far
	push bx
	push si

	mov ah, 35h
	mov al, 1ch
	int 21h
	
	mov si, offset INT_SIG
	sub si, offset ROUT
	mov dx, es:[bx + si]
	cmp dx, INT_SIG
	jne not_loaded
	mov ax, 1h
    jmp is_loaded_exit

not_loaded:
    mov ax, 0h

is_loaded_exit:
	pop si
	pop bx

    ret
CHECK_UNLOAD endp

LOAD_ROUT proc far
	push ax
    push bx
    push cx
    push dx
    push es
    push ds



	mov ah,35h
	mov al,1ch
	int 21h
	
	mov KEEP_CS,es
	mov KEEP_IP,bx
	

	mov dx, offset ROUT
	mov ax, seg ROUT
	mov ds,ax
	
	mov ah,25h
	mov al,1ch
	int 21h
	
	pop ds

	mov dx,offset ROUT_CHANGED
	call WRITE
	
	mov dx, offset END_ROUT_P
	mov cl,4h
	shr dx,cl
	inc dx
	
	add dx,100h
	xor ax,ax
	
	mov ah,31h
	int 21h


	pop es
    pop dx
    pop cx
    pop bx
    pop ax
	ret
LOAD_ROUT endp

UNLOAD_ROUT proc
	cli
    
    push ax
    push bx
    push dx
    push ds
    push es
    push si

    mov ah, 35h
    mov al, 1ch
    int 21h
    mov si, offset KEEP_IP
    sub si, offset ROUT
    mov dx, es:[bx + si]
    mov ax, es:[bx + si + 2]

    push ds
    mov ds, ax
    mov ah, 25h
    mov al, 1ch
    int 21h
    pop ds

    mov ax, es:[bx + si + 4]
    mov es, ax
    push es
    mov ax, es:[2ch]
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

    sti

	push dx
	mov dx,offset ROUT_UNLOADED
	call WRITE
	pop dx

    pop si
    pop es
    pop ds
    pop dx
    pop bx
    pop ax
	ret
UNLOAD_ROUT endp

WRITE proc near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
WRITE endp

CHECK_LOADED proc far
	push es
	mov ax, KEEP_PSP
    mov es, ax

	
    mov al, es:[81h+1]
	cmp al, '/'
	jne WRONG_ARG
	
	mov al, es:[81h+2]
	cmp al, 'u'
	jne WRONG_ARG
	
	mov al, es:[81h+3]
	cmp al, 'n'
	jne WRONG_ARG

    mov ax, 1h
    jmp CHECK_LOADED_exit

WRONG_ARG:
    mov ax, 0h

CHECK_LOADED_exit:
	pop es
    ret
CHECK_LOADED endp

main proc far
	mov ax,DATA
	mov ds,ax
	mov KEEP_PSP,es
	
	push es
	
	call CHECK_UNLOAD
	cmp ax,0h
	jne START_UNLOAD
	
	call LOAD_ROUT
	pop es
	jmp exit
	
START_UNLOAD:
	pop es
	call CHECK_LOADED
	cmp ax,0h
	je ALREADY_LOADED
	call UNLOAD_ROUT
	jmp exit

ALREADY_LOADED:
	mov dx,offset ROUT_LOADED
	call WRITE

exit:
	xor al,al
	mov ah,4ch
	int 21h
main endp

CODE ends
end main 