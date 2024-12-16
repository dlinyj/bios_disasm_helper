    org 100h

start:
    ; Очистка экрана
    mov ax, 0003h
    int 10h

    ; Вывод заголовка
    mov dx, header
    mov ah, 09h
    int 21h

    ; Перевод строки после заголовка
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    mov ah, 02h
    int 21h

    ; Подготовка для работы с векторами прерываний
    xor bx, bx      ; BX - номер вектора
    mov cx, 0x20    ; Счетчик для 32 векторов (0-31)

print_vector:
    ; Вывод номера вектора в hex
    mov ax, bx
    call print_hex_word

    ; Вывод табуляции
    mov dl, 09h
    mov ah, 02h
    int 21h

    ; Получаем адрес вектора прерывания
    push bx         ; Сохраняем номер вектора
    push ds         ; Сохраняем DS

    xor ax, ax
    mov ds, ax
    
    ; Вычисление адреса вектора
    shl bx, 2       ; Умножаем на 4 (размер записи вектора)
    
    ; Загрузка смещения и сегмента
    mov si, [bx]    ; Смещение
    mov dx, [bx+2]  ; Сегмент

    pop ds          ; Восстанавливаем DS
    pop bx          ; Восстанавливаем номер вектора

    ; Вывод сегмента
    mov ax, dx
    call print_hex_word

    ; Вывод ':'
    mov dl, ':'
    mov ah, 02h
    int 21h

    ; Вывод смещения
    mov ax, si
    call print_hex_word

    ; Перевод строки
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    mov ah, 02h
    int 21h

    ; Следующий вектор
    inc bx
    loop print_vector

    ; Выход
    mov ah, 4Ch
    int 21h

; Подпрограмма вывода 16-битного числа в hex
print_hex_word:
    push ax         ; Сохраняем все биты
    ; Старший байт
    mov al, ah
    call print_hex_byte

    ; Младший байт
    pop ax          ; Восстанавливаем все биты
    call print_hex_byte

    ret

; Подпрограмма вывода одного байта в hex
print_hex_byte:
    ; Старший полубайт
    push ax
    shr al, 4
    call print_hex_digit

    ; Младший полубайт
    pop ax
    and al, 0Fh
    call print_hex_digit

    ret

; Вывод одной hex-цифры
print_hex_digit:
    cmp al, 10
    jb digit
    add al, 'A' - 10
    jmp print

digit:
    add al, '0'

print:
    mov dl, al
    mov ah, 02h
    int 21h

    ret

header db 'Int Segment:Offset$'

    end
