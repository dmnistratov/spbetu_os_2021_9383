ASTACK SEGMENT STACK
   DW 200 DUP(?)
ASTACK ENDS

DATA SEGMENT
    ROUT_LOADED db 'Interruption is already loaded', 0DH, 0AH, '$'
    ROUT_CHANGED db 'Interruption is loaded successfully', 0DH, 0AH, '$'
    ROUT_IS_NOT_LOADED db 'Interruption is not loaded', 0DH, 0AH, '$'
    ROUT_UNLOADED db 'Interruption is restored', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:ASTACK

WRITE  PROC  NEAR
    push ax
    mov ah, 9
    int 21h
    pop ax
    ret
WRITE  ENDP

start:
ROUT proc far
    jmp START_ST

    KEEP_PSP DW 0
    KEEP_IP DW 0
   	KEEP_CS DW 0
    KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0
    INT_SIG DW 7777h
    INTSEG DW 64 DUP(?)
START_ST:
    mov KEEP_SP, sp
    mov KEEP_AX, ax
    mov KEEP_SS, ss

    mov ax, seg INTSEG
    mov ss, ax
    mov ax, offset START_ST
    mov sp, ax

    mov ax, KEEP_AX
    
    push bx
   	push cx
   	push dx
    push si
    push cx
    push ds
    push ax

    in al, 60h
    cmp al, 10h
    je K_Q
    cmp al, 11h
    je K_W

    call dword ptr cs:[KEEP_IP]
    jmp END_ROUT_P
K_Q:
    mov al, 'a'
    jmp DO
K_W:
    mov al, 's'

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
    pop ds
    pop es
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
	mov sp, KEEP_SP
	mov ax, KEEP_SS
	mov ss, ax
	mov ax, KEEP_AX
	mov al, 20h
	out 20h, al
	iret
ROUT endp

CHECK_UNLOAD PROC near
   	push ax
    push es

    mov cl, 0h
 
   	mov al,es:[81h+1]
   	cmp al,'/'
   	jne WRONG_ARG

   	mov al,es:[81h+2]
   	cmp al,'u'
   	jne WRONG_ARG

   	mov al,es:[81h+3]
   	cmp al,'n'
   	jne WRONG_ARG

    mov cl,1h

WRONG_ARG:
    pop es
   	pop ax
   	ret
CHECK_UNLOAD ENDP


CHECK_LOADED PROC NEAR
    push ax
    push dx
    push es
    push si

    mov cl, 0h

    mov ah, 35h
    mov al, 09h
    int 21h

    mov si, offset INT_SIG
    sub si, offset ROUT
    mov dx, es:[bx + si]
    cmp dx, INT_SIG
    jne NOT_LOADED

    mov cl, 1h

NOT_LOADED:
    pop si
    pop es
    pop dx
    pop ax
    ret
CHECK_LOADED ENDP

LOAD_ROUT PROC near
    push ax
    push cx
    push dx

    mov KEEP_PSP, es

    mov ah, 35h
    mov al, 09h
    int 21h

    mov KEEP_CS, es
    mov KEEP_IP, bx

    push es
    push bx
    push ds

    lea dx, ROUT
    mov ax, SEG ROUT
    mov ds, ax

    mov ah, 25h
    mov al, 09h
    int 21h

    pop ds
    pop bx
    pop es

    mov dx, offset ROUT_CHANGED
    call WRITE

    lea dx, END_ROUT_P
    mov cl, 4h
    shr dx, cl
    inc dx

    add dx, 100h

    xor ax,ax

    mov ah, 31h
    int 21h

    pop dx
    pop cx
    pop ax
    ret
LOAD_ROUT ENDP

UNLOAD_ROUT PROC near
    push ax
    push si

    call CHECK_LOADED
    cmp cl, 1h
    jne ROUT_ISNOT_LOADED

    cli

    push ds
    push es

    mov ah, 35h
    mov al, 09h
    int 21h

    mov si, offset KEEP_IP
    sub si, offset ROUT
    mov dx, es:[bx + si]
    mov ax, es:[bx + si + 2]
    mov ds, ax

    mov ah, 25h
    mov al, 09h
    int 21h

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

    pop es
    pop ds

    sti

    mov dx, offset ROUT_UNLOADED
    call WRITE



    jmp UNLOAD_END

ROUT_ISNOT_LOADED:
    mov dx, offset ROUT_IS_NOT_LOADED
    call WRITE

UNLOAD_END:
    pop si
    pop ax
    ret
UNLOAD_ROUT ENDP

MAIN PROC FAR
    mov   ax, DATA
    mov   ds, ax

    call CHECK_UNLOAD
    cmp cl, 1h
    je START_UNLOAD

    call CHECK_LOADED
    cmp ch, 1h
    je ALREADY_LOADED

    call LOAD_ROUT
    jmp EXIT

START_UNLOAD:
    call UNLOAD_ROUT
    jmp EXIT

ALREADY_LOADED:
    mov dx, offset ROUT_LOADED
    call WRITE
    jmp EXIT

EXIT:
    xor al, al
    mov ah, 4ch
    int 21h
MAIN endp
CODE ends
END Main