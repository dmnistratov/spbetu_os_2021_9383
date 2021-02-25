; Исследование интерфейсов программных модулей 
; 18.02.2021
; Nistratov Dmitry

; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H
START:  JMP BEGIN
; Данные
MEM_ADRESS db 'Locked memory address:     ', 0DH, 0AH, '$' ; 22 + space + hex
ENV_ADRESS db 'Environment address:      ', 0DH, 0AH, '$' ; 20 + space + hex 
TAIL db 'Command line tail:$'
EMPTY_TAIL db 'In Command tail no sybmols', 0DH, 0AH, '$'
CONTENT db 'Content:', 0DH, 0AH, '$'
END_STRING db 0DH, 0AH, '$'
PATH db 'Path:  ', 0DH, 0AH, '$'

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

WRITEBYTE  PROC  NEAR
        push ax
        mov ah, 02h
        int 21h
        pop ax
        ret
WRITEBYTE  ENDP

PSP_MEMORY PROC near
; Сегментный адрес недоступной памяти
        push ax
        push dx
        push di

        mov ax,ds:[02h]
        mov di, offset MEM_ADRESS
        add di, 26
        call WRD_TO_HEX
        mov dx, offset MEM_ADRESS
        call WRITE

        pop ax
        pop dx
        pop di
        ret
PSP_MEMORY ENDP

PSP_ENVIROMENT  PROC near 
; Сегментный адрес среды
        push ax
        push dx
        push di

        mov ax,ds:[2Ch]
        mov di, offset ENV_ADRESS
        add di, 24
        call WRD_TO_HEX
        mov dx, offset ENV_ADRESS
        call WRITE

        pop ax
        pop dx
        pop di
        ret
PSP_ENVIROMENT ENDP

PSP_TAIL PROC near   
; хвост командной строки
        push ax
        push cx
        push dx
        push di

        xor cx, cx
	xor di, di

        mov cl, ds:[80h]
        cmp cl, 0h
        je empty

        mov dx, offset TAIL
        CALL WRITE
read: 
	mov dl, ds:[81h+di]
        call WRITEBYTE
        inc di

	loop read

        mov dx, 0dh
        call WRITEBYTE

        mov dl, 0ah
        call WRITEBYTE
	jmp end_pop
empty:
        mov dx, offset EMPTY_TAIL
        call WRITE 
end_pop: 
        
        pop ax
        pop cx
        pop dx
        pop di
        ret
PSP_TAIL ENDP

PSP_CONTENT PROC near
;Содержимое области среды и путь загрузочного модуля
        push ax
        push cx
        push dx
        push di
        
 	mov dx, offset CONTENT
	call WRITE
	xor di,di
	mov ds, ds:[2ch]
read_string:
	cmp byte ptr [di], 00h
	jz end_str
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp find_end
end_str:
	cmp byte ptr [di+1],00h
	jz find_end
	push ds
	mov cx, cs
	mov ds, cx
	mov dx, offset END_STRING
	call WRITE
	pop ds
find_end:
	inc di
	cmp word ptr [di], 0001h
	jz read_path
	jmp read_string
read_path:
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset PATH
	call WRITE
	pop ds
	add di, 2
loop_path:
	cmp byte ptr [di], 00h
	jz end_pop_content
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp loop_path
end_pop_content:
        pop ax
        pop cx
        pop dx
        pop di

	ret
PSP_CONTENT ENDP

BEGIN:
   call PSP_MEMORY
   call PSP_ENVIROMENT
   call PSP_TAIL
   call PSP_CONTENT
	
; Выход в DOS
        xor AL,AL
        mov AH,4Ch
        int 21H
TESTPC  ENDS
        END START ; Конец модуля, START - точка входа