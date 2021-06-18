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

;функция вывода символа из AL
outputAL PROC 
	push AX
	push BX
	push CX
	mov AH, 09h
	mov BH, 0
	mov CX, 1
	int 10h
	pop CX
	pop BX
	pop AX
	ret
outputAL ENDP

; Функция вывода строки по адресу ES:BP на экран
outputBP PROC NEAR
    push ax
    push bx
    push dx
    push cx
    mov ah,13h 
    mov al, 0 
    mov bh, 0
    mov dh, 22
    mov dl, 0
    int 10h
    pop cX
    pop dx
    pop bx
    pop ax
    ret
outputBP ENDP

; Установка позиции курсора
; установка на строку 25 делает курсор невидимым
setCurs PROC NEAR
    mov ah, 02h
    mov bh, 0h
    mov dh, 0h
    mov dl, 0h
    int 10h
    ret
setCurs ENDP

;
; 03H читать позицию и размер курсора
;   вход: BH = видео страница
;   выход: DH, DL = текущая строка, колонка курсора
;          CH, CL = текущие начальная, конечная строки курсора
getCurs PROC NEAR
    mov ah, 03h
    mov bh, 0
    int 10h
    ret
getCurs ENDP

ROUT PROC FAR
    jmp START

    INT_COUNTER db 'Interruption counter: 0000$'
    INT_SIG dw 7777h
    KEEP_IP dw 0
    KEEP_CS dw 0
    KEEP_PSP dw ?
    KEEP_SS dw 0
    KEEP_SP dw 0
    KEEP_AX dw 0
    INTSEG dw 16 dup(?)

START:
    mov KEEP_SP, sp
    mov KEEP_AX, ax
    mov ax, ss
    mov KEEP_SS, ax

    mov ax, KEEP_AX

    mov sp, OFFSET START
    mov ax, seg INTSEG
    mov ss, ax

    ; Cохранение изменяемого регистра
	push ax 
	push cx 
	push dx

    call getCurs
    push dx
    call setCurs

	push si
	push cx
	push ds
	push bp

    mov ax, SEG INT_COUNTER
    mov ds, ax
    mov si, offset INT_COUNTER
    add si, 21
    mov cx, 4

LOOP_ELEM:
    mov bp, cx
    mov ah, [si+bp]
    inc ah
    mov [si+bp], ah
    cmp ah, 3ah
    jne UPDATE_RES
    mov ah, 30h
    mov [si+bp], ah

    loop LOOP_ELEM

UPDATE_RES:
	
	pop bp
	pop ds
	pop cx
	pop si

	push es
	push bp
	
    mov ax, SEG INT_COUNTER
    mov es,ax
    mov ax, offset INT_COUNTER
    mov bp,ax

    mov ah, 13h
    mov al, 00h
    mov bh, 0
    mov cx, 26
    int 10h

    pop bp
    pop es

    pop dx
    mov ah, 02h
    mov bh, 0h
    int 10h


    ; Восстановление регистра

    pop dx
    pop cx 
    pop ax 

    mov sp, KEEP_SP
    mov ax, KEEP_SS
    mov ss, ax
    mov ax, KEEP_AX

    mov al, 20h	
    out 20h, al	
    iret

END_ROUT_P:
ROUT ENDP

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
    mov al, 1ch
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
    mov al, 1ch
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
    mov al, 1ch
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
    mov al, 1ch
    int 21h

    mov si, offset KEEP_IP
    sub si, offset ROUT
    mov dx, es:[bx + si]
    mov ax, es:[bx + si + 2]
    mov ds, ax

    mov ah, 25h
    mov al, 1ch
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
    cmp cl, 0h
    jne START_UNLOAD

    call CHECK_LOADED
    cmp cl, 0h
    jne ALREADY_LOADED

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

MAIN ENDP

CODE ENDS
END MAIN