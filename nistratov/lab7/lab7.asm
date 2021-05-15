AStack    SEGMENT  STACK
          DW 64 DUP(?)
AStack    ENDS

DATA  SEGMENT
    parametr_block dw 0
                   db 0
                   db 0
                   db 0
    CMD_LINE db 1h,0DH
    PATH_STR db 128 dup(0), '$'
    OVL_ADDRESS dd 0
    OVL1_FILE db "ovl1.ovl", 0
    OVL2_FILE db "ovl2.ovl", 0
    CURRENT_FILE dw 0

    KEEP_SS dw 0
    KEEP_SP dw 0
    KEEP_PSP dw 0

    TEMP db 64 dup(0)

    MEMORY_BLOCK_ERROR db "Memory control block destroyed. ", 0DH, 0AH, '$'
    LOW_MEMORY db "Not enough memory. ", 0DH, 0AH, '$'
    WRONG_PTR db "Invalid memory block address. ", 0DH, 0AH, '$'
    MEMORY_FREE_SUCCESS db "Memory is free. ", 0DH, 0AH, 0AH, '$'

    WRONG_FUNC_NUMBER db "Wrong function number.", 0DH, 0AH, '$'
    FILE_NOT_FOUND_LOAD db "File not found.", 0DH, 0AH, '$'
    PATH_NOT_FOUND_LOAD db "Path not found.", 0DH, 0AH, '$'
    TOO_MUCH_FILES db "Too much files opened.", 0DH, 0AH, '$'
    ACCESS_ERROR db "Access error.", 0DH, 0AH, '$'
    NOT_ENOUGH_MEMORY db "Not enough memory.", 0DH, 0AH, '$'
    WRONG_ENVIRONMENT db "Wrong environment string.", 0DH, 0AH, '$'

    FILE_NOT_FOUND_ALL db "File not found.", 0DH, 0AH, '$'
    PATH_NOT_FOUND db "Path not found.", 0DH, 0AH, '$'

    LOAD_SUCCESSFUL db "Load succsessfull.", 0DH, 0AH, '$'
    ALLOCATION_SUCCESSFUL db "Memmory allocation done", 0DH, 0AH, '$'

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

PATH_FIND proc near
    push ax
    push si
    push es
    push bx
    push di
    push dx

    mov ax, KEEP_PSP
    mov es, ax
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
    pop dx
    mov di, dx
    push dx
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
    mov [bx], byte ptr '$'
    pop dx
    pop di
    pop bx
    pop es
    pop si
    pop ax
    ret
PATH_FIND endp

ALLOCATION_MEMORY proc near
    push ax
	push bx
	push cx
	push dx

	push dx
	mov dx, offset TEMP
	mov ah, 1ah
	int 21h
	pop dx
	xor cx, cx
	mov ah, 4eh
	int 21h

	jnc MEM_ALLOCATED

    cmp ax, 2
    je F_N_F_A
    cmp ax, 3
    je P_N_F_A

F_N_F_A:
	mov dx, offset FILE_NOT_FOUND_ALL
	call WRITE
	jmp MEM_ALL_END
P_N_F_A:
    mov dx, offset PATH_NOT_FOUND
    call WRITE
    jmp MEM_ALL_END
MEM_ALLOCATED:
	push di
	mov di, offset TEMP
	mov bx, [di+1ah]
	mov ax, [di+1ch]
	pop di
	push cx
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	pop cx
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	mov word ptr OVL_ADDRESS, ax
	mov dx, offset ALLOCATION_SUCCESSFUL
	call WRITE

MEM_ALL_END:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
ALLOCATION_MEMORY endp

MAIN_HANDLER proc near
    push ax
	push bx
	push cx
	push dx
	push ds
	push es

	mov ax, data
	mov es, ax
	mov bx, offset OVL_ADDRESS
	mov dx, offset PATH_STR
	mov ax, 4b03h
	int 21h


    jnc LOADED_SUCCESS
    cmp ax, 1
    je WRONG_FUNC_NUM
    cmp ax, 2
    je FILE_NOT_FOUND_ERR
    cmp ax, 3
    je DISK_ERR_FOUND_ERR
    cmp ax, 4
    je NOT_EN_MEM
    cmp ax, 6
    je ACCESS_ERR_MSG
    cmp ax, 8
    je NON_EN_MEM
    cmp ax, 10
    je FORMAT_ERROR_MSG
WRONG_FUNC_NUM:
    mov dx, offset WRONG_FUNC_NUMBER
    call WRITE
    jmp END_HANDLER
FILE_NOT_FOUND_ERR:
    mov dx, offset FILE_NOT_FOUND_LOAD
    call WRITE
    jmp END_HANDLER
DISK_ERR_FOUND_ERR:
    mov dx, offset PATH_NOT_FOUND_LOAD
    call WRITE
    jmp END_HANDLER
NOT_EN_MEM:
    mov dx, offset TOO_MUCH_FILES
    call WRITE
    jmp END_HANDLER
ACCESS_ERR_MSG:
    mov dx, offset ACCESS_ERROR
    call WRITE
    jmp END_HANDLER
NON_EN_MEM:
    mov dx, offset NOT_ENOUGH_MEMORY
    call WRITE
    jmp END_HANDLER
FORMAT_ERROR_MSG:
    mov dx, offset WRONG_ENVIRONMENT
    call WRITE
    jmp END_HANDLER
LOADED_SUCCESS:
    mov dx, offset LOAD_SUCCESSFUL
	call WRITE

	mov ax, word ptr OVL_ADDRESS
	mov es, ax
	mov word ptr OVL_ADDRESS, 0
	mov word ptr OVL_ADDRESS+2, ax

	call OVL_ADDRESS
	mov es, ax
	mov ah, 49h
	int 21h
END_HANDLER:
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
    ret
MAIN_HANDLER endp

ONE_FILE_PROCESSING proc near
    push dx
    call PATH_FIND
    mov dx, offset PATH_STR
    call ALLOCATION_MEMORY
    call MAIN_HANDLER
    pop dx

    ret
ONE_FILE_PROCESSING endp

MAIN proc far
    push  ds
    push  ax
    mov   ax,data
    mov   ds,ax

    mov KEEP_PSP, es
    call FREE_MEMORY
    cmp KEEP_FLAG, 1
    je END_ERROR

    mov dx, offset OVL1_FILE
    call ONE_FILE_PROCESSING

    mov dx, offset OVL2_FILE
    call ONE_FILE_PROCESSING
END_ERROR:
    mov ah, 4ch
	int 21h
MAIN_ENDS:
MAIN endp
CODE ends
END Main