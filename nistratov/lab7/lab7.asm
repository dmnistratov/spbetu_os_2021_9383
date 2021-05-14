AStack SEGMENT  STACK
	DW 128 DUP(?)   
AStack ENDS


DATA SEGMENT 

    FILE_NAME db "overlay.ova", 0
    KEEP_PSP dw 0
    KEEP_SP dw 0
    KEEP_SS dw 0

    CMD_LINE db 1h,0DH
    PATH_STR db 128 dup(0)

    FREE_MEM_MSG db "Memory is free", 0DH, 0AH, '$'
    CONTROL_ERROR_MSG db "Control block was destroyed", 0DH, 0AH, '$'
    FUNCTION_ERROR_MSG db "Not enough memory for function", 0DH, 0AH, '$'
    ADDRESS_ERROR_MSG db "Wrong address for block of memory", 0DH, 0AH, '$'

    NUMBER_ERROR_MSG db "Wrong function number", 0DH, 0AH, '$'
    NO_FILE_MSG db "Can not find file", 0DH, 0AH, '$'
    DISK_ERROR_SMG db "Error with disk", 0DH, 0AH, '$'
    MEMORY_ERROR_MSG db "Not enough memory", 0DH, 0AH, '$'
    STRING_ERROR_MSG db "Wrong environment string", 0DH, 0AH, '$'
    FORMAT_ERROR_MSG db "Wrong format", 0DH, 0AH, '$'

    CODE_END db 0DH, 0AH, "Code end:  ", 0DH, 0AH, '$'
    BREAK_END db 0DH, 0AH, "End by ctrl+C", 0DH, 0AH, '$'
    ERROR_END db 0DH, 0AH, "End by error ", 0DH, 0AH, '$'
    FUNCTION_END db 0DH, 0AH, "End by function 31h", 0DH, 0AH, '$'

    CHECK_CF db 0
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack

WRITE PROC
   	push ax
   	mov ah, 09h
   	int 21h
   	pop ax
   	ret
WRITE ENDP


FREE_MEMORY PROC
   	push ax
   	push bx
   	push cx
   	push dx
   	mov ax, offset END_DATA
   	mov bx, offset END_PROG
   	add bx, ax
   	shr bx, 1
   	shr bx, 1
   	shr bx, 1
   	shr bx, 1
   	add bx, 2bh
   	mov ah, 4ah
   	int 21h

   	jnc end_free_memory
   
   	lea dx, MEMORY_7
   	cmp ax, 7
   	je print
   	lea dx, MEMORY_8
   	cmp ax, 8
   	je print
   	lea dx, MEMORY_9
   	cmp ax, 9
   	je pri
   	call WRITE
   	mov dx, offset OVL2
   	call START_OVERLAY
   
end_:
   	xor al,al
   	mov ah,4ch
   	int 21h

Main ENDP

END_PROG:
CODE ENDS
END MAIN 