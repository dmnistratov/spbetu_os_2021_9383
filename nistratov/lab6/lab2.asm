TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
org 100h

start: jmp begin

UNAVAILABLE_MEMORY db 'First byte of unavailable memory:     ', 0DH, 0AH, '$'
SEGMENT_ADRESS db 'Environment segment:    ', 0DH, 0AH, '$'
EMPTY_TAIL db 'Command line is empty.', 0DH, 0AH, '$'
ENVIRONMENT_AREA db 'Environment area:', 0DH, 0AH, '$'
TAIL db 'Command line tail:$'
MODULE_PATH db 'Module path:$'


TETR_TO_HEX proc near
    and al, 0fh
    cmp al, 09
    jbe next
    add al, 07

next:
    add al, 30h
    ret

TETR_TO_HEX endp

BYTE_TO_HEX proc near
    push cx
    mov ah, al
    call TETR_TO_HEX
    xchg al, ah
    mov cl, 4
    shr al, cl
    call TETR_TO_HEX
    pop cx
    ret
BYTE_TO_HEX endp

WRD_TO_HEX proc near
    push bx
    mov bh, ah
    call BYTE_TO_HEX
    mov [di], ah
    dec di
    mov [di], al
    dec di
    mov al, bh
    call BYTE_TO_HEX
    mov [di], ah
    dec di
    mov [di], al
    pop bx
    ret
WRD_TO_HEX endp


PRINT_NEW_LINE proc near
    push ax
    push dx

    mov dl, 0Dh
    mov ah, 02h
    int 21h

    mov dl, 0Ah
    mov ah, 02h
    int 21h

    pop dx
    pop ax
    ret
PRINT_NEW_LINE endp

PRINT_BUF proc near
    push ax
    mov ah, 9h
    int 21h
    pop ax
    ret
PRINT_BUF endp

GET_UNAVAILABLE_MEMORY  proc near
    push ax
    push di

    mov ax, ds:[02h]
    mov di, offset UNAVAILABLE_MEMORY
    add di, 36
    call WRD_TO_HEX
    mov dx, offset UNAVAILABLE_MEMORY
    call PRINT_BUF

    pop di
    pop ax

    ret
GET_UNAVAILABLE_MEMORY endp

GET_SEGMENT_ADRESS  proc near
    push ax
    push di

    mov ax, ds:[2Ch]
    mov di, offset SEGMENT_ADRESS
    add di, 23
    call WRD_TO_HEX
    mov dx, offset SEGMENT_ADRESS
    call PRINT_BUF

    pop di
    pop ax

    ret
GET_SEGMENT_ADRESS endp

GET_TAIL proc near
    push cx
    push ax
    push si
    push dx

    mov cl, ds:[80h]
    cmp cl, 0
    je empty_tail_print

    mov dx, offset TAIL
    call PRINT_BUF

    xor dl, dl
    xor si, si
print_loop:
    mov dl, ds:[81h+si]
    mov ah, 02h
    int 21h
    inc si
    loop print_loop

    call PRINT_NEW_LINE
    jmp end_l2


empty_tail_print:
    mov dx, offset EMPTY_TAIL
    call PRINT_BUF

end_l2:

    pop dx
    pop si
    pop ax
    pop cx
    ret
GET_TAIL endp

GET_ENVIRONMENT_AREA proc near
    push ax
    push si
    push dx
    push es

    mov dx, offset ENVIRONMENT_AREA
    call PRINT_BUF

    mov ax, ds:[2Ch]
    mov es, ax
    xor si, si
loop_1:
    mov dl, es:[si]
    cmp dl, 0
    je next_line
print_symbol:
    mov ah, 02h
    int 21h
    inc si
    jmp loop_1
next_line:
    call PRINT_NEW_LINE
    inc si
    mov dl, es:[si]
    cmp dl, 0
    jne print_symbol

    add si, 3

    mov dx, offset MODULE_PATH
    call PRINT_BUF
loop_path:
    mov dl, es:[si]
    cmp dl, 0
    je end_l3

    mov ah, 02h
    int 21h
    inc si
    jmp loop_path

end_l3:
    pop es
    pop dx
    pop si
    pop ax
    ret
GET_ENVIRONMENT_AREA endp


begin:

    call GET_UNAVAILABLE_MEMORY
    call GET_SEGMENT_ADRESS
    call GET_TAIL
    call GET_ENVIRONMENT_AREA
    xor al, al
    mov ah, 01h
	int 21h
    mov ah, 4ch
    int 21h

TESTPC  ENDS
        END start