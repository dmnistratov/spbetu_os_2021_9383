CODE SEGMENT
ASSUME CS:CODE, DS:NOTHING, SS:NOTHING

MAIN proc far
    push ax
    push dx
    push ds
    push di

    mov ax, cs
    mov ds, ax
    mov di, offset OVL_ADDRESS
    add di, 16
    call WRD_TO_HEX
    mov dx, offset OVL_ADDRESS
    call WRITE

    pop di
    pop ds
    pop dx
    pop ax
    retf
MAIN endp

OVL_ADDRESS db "OVL1 address:    ", 0AH, 0DH, 0AH, '$'

WRITE proc near
    push dx
    push ax
    mov ah, 09h
    int 21h
    pop ax
    pop dx
    ret
WRITE endp


TETR_TO_HEX proc near
    and al,0fh
    cmp al,09
    jbe JUMP
    add al,07
JUMP:
    add al,30h
    ret
TETR_TO_HEX endp


BYTE_TO_HEX proc near
    push cx
    mov ah, al
    call TETR_TO_HEX
    xchg al,ah
    mov cl,4
    shr al,cl
    call TETR_TO_HEX
    pop cx
    ret
BYTE_TO_HEX endp


WRD_TO_HEX proc near
    push	bx
    mov	bh,ah
    call BYTE_TO_HEX
    mov	[di],ah
    dec	di
    mov	[di],al
    dec	di
    mov	al,bh
    xor	ah,ah
    call BYTE_TO_HEX
    mov	[di],ah
    dec	di
    mov	[di],al
    pop	bx
    ret
WRD_TO_HEX endp

CODE ends
end MAIN