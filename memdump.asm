; Программа для сохранения 64 КБ памяти по указанному адресу

section .data
    filename db 'MEMDUMP.BIN', 0
    msg_addr db 'Memory dump address: $'

section .bss
    handler_segment resw 1
    handler_offset  resw 1
    file_handle     resw 1

section .text
    org 100h       ; COM-программа

start:
    ; Проверяем наличие параметров
    mov si, 0x80   ; Указатель на длину командной строки
    lodsb          ; Загружаем длину
    
    ; Если параметров нет, используем адрес по умолчанию
    cmp al, 0
    je default_addr

    ; Парсим адрес из командной строки
    mov di, handler_segment
    call parse_hex_word
    mov di, handler_offset
    call parse_hex_word

    jmp dump_memory

default_addr:
    ; Адрес по умолчанию (например, начало BIOS)
    mov word [handler_segment], 0xF000
    mov word [handler_offset], 0x0000

dump_memory:
    ; Вывод адреса на экран
    mov ah, 0x09
    mov dx, msg_addr
    int 0x21

    ; Вывод сегмента
    mov ax, [handler_segment]
    call print_hex

    ; Вывод двоеточия
    mov dl, ':'
    mov ah, 0x02
    int 0x21

    ; Вывод смещения
    mov ax, [handler_offset]
    call print_hex

    ; Создаем файл
    mov ah, 0x3C   ; Функция создания файла
    mov cx, 0      ; Обычный атрибут файла
    mov dx, filename
    int 0x21
    mov [file_handle], ax

    ; Записываем память в файл
    mov ah, 0x40   ; Функция записи в файл
    mov bx, [file_handle]
    mov cx, 0xFFFF ; Максимальный размер (64 кб)
    mov dx, [handler_offset]
    mov ds, [handler_segment]
    int 0x21

    ; Закрываем файл
    mov ah, 0x3E
    mov bx, [file_handle]
    int 0x21

    ; Выход
    mov ax, 0x4C00
    int 0x21

; Парсинг hex-слова из командной строки
parse_hex_word:
    xor ax, ax     ; Обнуляем результат
    mov si, 0x82   ; Начало параметров
    mov cx, 4      ; Максимум 4 символа

.next_char:
    mov bl, [si]
    inc si

    ; Конец строки
    cmp bl, 0x0D   ; Enter
    je .done
    cmp bl, ' '    ; Пробел
    je .done

    ; Преобразование символа
    sub bl, '0'
    cmp bl, 9
    jle .valid_digit
    
    ; Для букв A-F
    sub bl, 'A' - '0'
    add bl, 10

.valid_digit:
    shl ax, 4
    or al, bl
    loop .next_char

.done:
    mov [di], ax
    ret

; Процедура вывода 16-ричного числа
print_hex:
    push ax
    mov al, ah
    call print_hex_byte
    pop ax
    call print_hex_byte
    ret

print_hex_byte:
    push ax
    ; Старший полубайт
    shr al, 4
    call hex_digit
    mov dl, al
    mov ah, 0x02
    int 0x21

    ; Младший полубайт
    pop ax
    and al, 0x0F
    call hex_digit
    mov dl, al
    mov ah, 0x02
    int 0x21
    ret

hex_digit:
    cmp al, 10
    jl less_10
    add al, 'A' - 10
    ret
less_10:
    add al, '0'
    ret
