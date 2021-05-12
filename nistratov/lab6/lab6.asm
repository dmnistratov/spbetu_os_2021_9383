AStack    SEGMENT  STACK
          DW 64 DUP(?)
AStack    ENDS

DATA  SEGMENT
    PARAMETR_BLOCK dw 0
                   db 0
                   db 0
                   db 0
    CMD_LINE db 1h,0DH
    PATH_STR db 128 dup(0)
    FILE_NAME db "lab2.com", 0

    KEEP_SS dw 0
    KEEP_SP dw 0
    
    NORMAL_TERMINATION db 0DH, 0AH, "Termination with  msg    ", 0DH, 0AH, '$'
    CTRL_TERMINATION db 0DH, 0AH, "Termination by Ctrl-C  ", 0DH, 0AH, '$'
    DEVICE_TERMINATION db 0DH, 0AH, "Termination by device error  ", 0DH, 0AH, '$'
    FUNC_TERMINATION db 0DH, 0AH, "Termination by function 31H  ", 0DH, 0AH, '$'

    MEMORY_BLOCK_ERROR db "Memory control block error. ", 0DH, 0AH, '$'
    LOW_MEMORY db "Not enough memory. ", 0DH, 0AH, '$'
    WRONG_PTR db "Invalid memory address. ", 0DH, 0AH, '$'
    MEMORY_FREE_SUCCESS db "Memory is free. ", 0DH, 0AH, '$'

    WRONG_FUNC_NUMBER db "Wrong function number.", 0DH, 0AH, '$'
    FILE_NOT_FOUND db "File not found.", 0DH, 0AH, '$'
    DISK_ERROR db "Disk error.", 0DH, 0AH, '$'
    NOT_ENOUGH_MEMORY db "Not enough memory.", 0DH, 0AH, '$'
    WRONG_ENVIRONMENT_STRING db "Wrong environment string.", 0DH, 0AH, '$'
    WRONG_FORMAT db "Wrong format.", 0DH, 0AH, '$'


    KEEP_FLAG db 0
    KEEP_DATA db 0
DATA  ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack

WRITE proc near
    push ax
    mov ah, 9h
    int 21h
    pop ax
    ret
WRITE endp


FREE_MEMORY proc near
    push ax
    push bx
    push dx

    mov ax, offset MAIN_ENDS
    mov bx, offset KEEP_DATA
    add ax, bx
    mov bx, 10h
    xor dx, dx
    div bx
    mov bx, ax
    add bx, dx
    add bx, 100h

    mov ah, 4ah
    int 21h

    jnc MEM_S_P
    mov KEEP_FLAG, 1

    cmp ax, 7
    je M_B_D
    cmp ax, 8
    je L_M
    cmp ax, 9
    je I_A

M_B_D:
    mov dx, offset MEMORY_BLOCK_ERROR
    call WRITE
    jmp memory_free_end
L_M:
    mov dx, offset LOW_MEMORY
    call WRITE
    jmp memory_free_end
I_A:
    mov dx, offset WRONG_PTR
    call WRITE
    jmp memory_free_end
MEM_S_P:
    mov dx, offset MEMORY_FREE_SUCCESS
    call WRITE
memory_free_end:
    pop dx
    pop bx
    pop ax
    ret
FREE_MEMORY endp

PARAMETR_BLOCK_CREATE proc near
    push bx
    push dx

    mov bx, offset PARAMETR_BLOCK
    mov dx, offset CMD_LINE
    mov [bx+2], dx
    mov [bx+4], ds

    pop dx
    pop bx
    ret
PARAMETR_BLOCK_CREATE endp

PATH_FIND proc near
    push ax
    push si
    push dx
    push es
    push bx
    push di

    mov ax, es:[2Ch]
    mov es, ax
    xor si, si
FOUND_ZERO:
    inc si
    mov dl, es:[si-1]
    cmp dl, 0
    jne FOUND_ZERO
    mov dl, es:[si]
    cmp dl, 0
    jne FOUND_ZERO

    add si, 3
    mov bx, offset PATH_STR
LOOP_FINDER:
    mov dl, es:[si]
    mov [bx], dl
    cmp dl, '.'
    je LOOP_BREAK

    inc bx
    inc si

    jmp LOOP_FINDER
LOOP_BREAK:
    mov dl, [bx]
    cmp dl, '\'
    je END_LOOP
    mov dl, 0h
    mov [bx], dl
    dec bx
    jmp LOOP_BREAK
END_LOOP:
    mov di, offset FILE_NAME
    inc bx
NEW_LOOP:
    mov dl, [di]
    cmp dl, 0
    je END_PATH_FIND
    mov [bx], dl
    inc di
    inc bx
    jmp NEW_LOOP
END_PATH_FIND:
    pop di
    pop bx
    pop es
    pop dx
    pop si
    pop ax
    ret
PATH_FIND endp

MAIN_HANDLER proc near
    push ax
	push bx
	push cx
	push dx
	push di
    push si
	push es
    push ds

    mov KEEP_SP, sp
    mov KEEP_SS, ss

    mov ax, data
    mov es, ax
    mov dx, offset PATH_STR
    mov bx, offset PARAMETR_BLOCK

    mov ax, 4b00h
	int 21h

    mov ss, KEEP_SS
    mov sp, KEEP_SP
    pop ds
    pop es

    jnc LOADED_SUCCESS
    cmp ax, 1
    je WRONG_FUNC_NUM
    cmp ax, 2
    je FILE_NOT_FOUND_ERR
    cmp ax, 5
    je DISK_ERR_FOUND
    cmp ax, 8
    je NOT_EN_MEM
    cmp ax, 10
    je STRING_ERR
    cmp ax, 11
    je FORMAT_ERR
WRONG_FUNC_NUM:
    mov dx, offset WRONG_FUNC_NUMBER
    call WRITE
    jmp END_HANDLER
FILE_NOT_FOUND_ERR:
    mov dx, offset FILE_NOT_FOUND
    call WRITE
    jmp END_HANDLER
DISK_ERR_FOUND:
    mov dx, offset DISK_ERROR
    call WRITE
    jmp END_HANDLER
NOT_EN_MEM:
    mov dx, offset NOT_ENOUGH_MEMORY
    call WRITE
    jmp END_HANDLER
STRING_ERR:
    mov dx, offset WRONG_ENVIRONMENT_STRING
    call WRITE
    jmp END_HANDLER
FORMAT_ERR:
    mov dx, offset WRONG_FORMAT
    call WRITE
    jmp END_HANDLER
LOADED_SUCCESS:
    mov ax, 4d00h
    int 21h

    cmp ah, 0
    jmp NORMAL
    cmp ah, 1
    jmp CTRL_C
    cmp ah, 2
    jmp DEVICE_TER
    cmp ah, 3
    jmp FUNC_TER
NORMAL:
    mov di, offset NORMAL_TERMINATION
    add di, 24
    mov [di], al
    mov dx, offset NORMAL_TERMINATION
    call WRITE
    jmp END_HANDLER
CTRL_C:
    mov dx, offset CTRL_TERMINATION
    call WRITE
    jmp END_HANDLER
DEVICE_TER:
    mov dx, offset DEVICE_TERMINATION
    call WRITE
    jmp END_HANDLER
FUNC_TER:
    mov dx, offset FUNC_TERMINATION
    call WRITE
    jmp END_HANDLER
END_HANDLER:
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
    ret
MAIN_HANDLER endp

MAIN proc far
    push  ds
    push  ax
    mov   ax,data
    mov   ds,ax

    call FREE_MEMORY
    call PATH_FIND
    call MAIN_HANDLER

    mov ah, 4ch
	int 21h
MAIN_ENDS:
MAIN endp
CODE ends
END Main