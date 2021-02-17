; .COM and .EXE diferences in strucures
; 15.02.2021
; Nistratov Dmitry

; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H
START:  JMP BEGIN
; Данные
VERSION DB "OS version:  $"; 12
DOT_VERSION DB ".  ", 0DH, 0AH, '$' ; 1 
SERIAL DB "Serial number:       ", 0DH, 0AH, '$' ; 15 + 6 - 2
OEM DB "OEM:    ",0DH, 0AH, '$'; 5

PC_TYPE_MSG DB "PC TYPE: $"
PC_TYPE_1 DB "PC", 0DH, 0AH, '$'
PC_TYPE_2 DB "PC/XT", 0DH, 0AH, '$'
PC_TYPE_3 DB "AT", 0DH, 0AH, '$'
PC_TYPE_4 DB "PS2 model 30", 0DH, 0AH, '$'
PC_TYPE_5 DB "PS2 model 50 or 60", 0DH, 0AH, '$'
PC_TYPE_6 DB "PS2 model 80", 0DH, 0AH, '$'
PC_TYPE_7 DB "PCjr", 0DH, 0AH, '$'
PC_TYPE_8 DB "PC Convertible", 0DH, 0AH, '$'
PC_TYPE_9 DB "  ", 0DH, 0AH, '$'
; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:   add AL,30h
        ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа шестн. числа AX
            push CX
            mov AH,AL
            call TETR_TO_HEX
            xchg AL,AH
            mov CL,4
            shr AL,CL
            call TETR_TO_HEX ; В AL Старшая цифра 
            pop CX           ; В AH младшая цифра
            ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; Перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа   
        push BX
        mov BH,AH
        call BYTE_TO_HEX
        mov [DI],AH
        dec DI
        mov [DI],AL
        dec DI
        mov AL,BH
        call BYTE_TO_HEX
        mov [DI],AH
        dec DI
        mov [DI],AL
        pop BX
        ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; Перевод в 10с/с, SI - адрес поля младшей цифры 
        push CX
        push DX
        xor AH,AH
        xor DX,DX
        mov CX,10
loop_bd: div CX
        or DL,30h
        mov [SI],DL
        dec SI
        xor DX,DX
        cmp AX,10
        jae loop_bd
        cmp AL,00h
        je end_l
        or AL,30h
        mov [SI],AL
end_l: pop DX
      pop CX
      ret
BYTE_TO_DEC ENDP
;-------------------------------
; КОД
WRITE PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP

OS_TYPE PROC NEAR
        mov ah, 30h
        int 21H

	push ax
	push bx
	push cx
	push dx
	push si
	push di

        mov si, offset VERSION
        add si, 12 
        call BYTE_TO_DEC
        mov dx, offset VERSION
        call WRITE

        mov si, offset DOT_VERSION
        add si, 1
        mov al, ah
        call BYTE_TO_DEC
        mov dx, offset DOT_VERSION
        call WRITE

	mov si, offset OEM
	add si, 7
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset OEM
	call WRITE

        mov di, offset SERIAL
	add di, 20
        mov al, bl
	call BYTE_TO_HEX
	mov ax, cx
	call WRD_TO_HEX	
	sub di, 2
	mov [di], ax
	mov dx, offset SERIAL
	call WRITE

	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
        ret
OS_TYPE ENDP

PC_TYPE PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push si
	push di
        push es

        mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]
        mov dx, offset PC_TYPE_MSG
        call WRITE
        cmp al, 0ffh
        jz pc_1
        cmp al, 0feh
        jz pc_2
        cmp al, 0fbh
        jz pc_2
        cmp al, 0fch
        jz pc_3
        cmp al, 0fah
        jz pc_4
        cmp al, 0fch
        jz pc_5
        cmp al, 0f8h
        jz pc_6
        cmp al, 0fdh
        jz pc_7
        cmp al, 0f9h
        jz pc_8
        jmp pc_unknown

pc_1:
        mov dx, offset PC_TYPE_1
        jmp print
pc_2:
        mov dx, offset PC_TYPE_2
        jmp print
pc_3:
        mov dx, offset PC_TYPE_3
        jmp print
pc_4:
        mov dx, offset PC_TYPE_4
        jmp print
pc_5:
        mov dx, offset PC_TYPE_5
        jmp print
pc_6:
        mov dx, offset PC_TYPE_6
        jmp print
pc_7:
        mov dx, offset PC_TYPE_7
        jmp print
pc_8:
        mov dx, offset PC_TYPE_8
        jmp print
pc_unknown:
        call BYTE_TO_HEX
        mov bx, offset PC_TYPE_9
	mov [bx], al
	mov [bx+1], ah
	mov dx, bx

print:
        call WRITE

	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
        pop es
        ret
PC_TYPE ENDP
BEGIN:
        call PC_TYPE
        call OS_TYPE
	
; Выход в DOS
        xor AL,AL
        mov AH,4Ch
        int 21H
TESTPC  ENDS
        END START ; Конец модуля, START - точка входа