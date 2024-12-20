org 0x7C00

start:
    ; Очистка экрана через BIOS
    mov ax, 0003h
    int 0x10

    ; Вывод заголовка
    mov si, header
    call print_string

    ; Подготовка для работы с векторами прерываний
    xor bx, bx       ; BX - номер вектора
    mov cx, 0x20     ; Счетчик для 32 векторов (0-31)

print_vector:
    push bx          ; Сохраняем номер вектора
    push cx          ; Сохраняем счетчик

    ; Вывод номера вектора в hex
    mov ax, bx
    call print_hex_word

    ; Вывод пробела
    mov al, ' '
    call print_char

    ; Получаем адрес вектора прерывания
    xor ax, ax
    mov es, ax       ; Устанавливаем ES = 0

    ; Вычисление адреса вектора
    shl bx, 2        ; Умножаем на 4 (размер записи вектора)

    ; Загрузка смещения и сегмента с явным указанием сегмента
    mov si, word [es:bx]     ; Смещение
    mov dx, word [es:bx+2]   ; Сегмент

    ; Вывод сегмента
    mov ax, dx
    call print_hex_word

    ; Вывод ':'
    mov al, ':'
    call print_char

    ; Вывод смещения
    mov ax, si
    call print_hex_word

    ; Перевод строки
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char

    ; Следующий вектор
    pop cx           ; Восстанавливаем счетчик
    pop bx           ; Восстанавливаем номер вектора
    inc bx
    loop print_vector

    ; Бесконечный цикл
    jmp $

; Вывод символа через BIOS
print_char:
    push ax          ; Сохраняем ax
    push bx          ; Сохраняем bx
    mov ah, 0x0E     ; Функция вывода символа
    mov bx, 0x0007   ; Цвет символа (если цветной режим)
    int 0x10
    pop bx           ; Восстанавливаем bx
    pop ax           ; Восстанавливаем ax
    ret

; Вывод строки
print_string:
    push ax          ; Сохраняем ax
.loop:
    lodsb
    cmp al, '$'
    je .end
    call print_char
    jmp .loop
.end:
    ; Перевод строки
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    pop ax           ; Восстанавливаем ax
    ret

; Подпрограмма вывода 16-битного числа в hex
print_hex_word:
    push ax          ; Сохраняем ax
    
    ; Старший байт (сегмент)
    mov al, ah       ; Перемещаем старший байт в al
    call print_hex_byte

    ; Младший байт (смещение)
    pop ax           ; Восстанавливаем ax
    call print_hex_byte
    ret

; Подпрограмма вывода одного байта в hex
print_hex_byte:
    push ax          ; Сохраняем ax
    ; Старший полубайт
    push ax
    shr al, 4
    call print_hex_digit

    ; Младший полубайт
    pop ax
    and al, 0Fh
    call print_hex_digit

    pop ax           ; Восстанавливаем ax
    ret

; Вывод одной hex-цифры
print_hex_digit:
    push ax          ; Сохраняем ax
    cmp al, 10
    jb .digit
    add al, 'A' - 10
    jmp .print

.digit:
    add al, '0'

.print:
    call print_char
    pop ax           ; Восстанавливаем ax
    ret

header db 'Int Segment:Offset$'

; Pad out the file to the 510th byte with zeroes.
times 510-($-$$) db 0

; MBR boot signature.
db 0x55, 0xAA
