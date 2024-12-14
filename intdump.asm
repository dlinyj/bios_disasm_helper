; Программа для сохранения обработчика прерывания с параметрами командной строки

section .data
    default_filename db 'interrupt.bin', 0
    msg_usage db 'Usage: INTDUMP <interrupt_number> [filename]', 13, 10, '$'
    msg_addr db 'Interrupt handler address: $'
    msg_error_parse db 'Error parsing interrupt number', 13, 10, '$'

section .bss
    handler_segment resw 1
    handler_offset  resw 1
    file_handle     resw 1
    filename        resb 128
    int_number      resb 2
    cmd_line_param  resb 128

section .text
    org 100h       ; COM-программа

start:
    ; Проверяем наличие параметров
    mov si, 0x80   ; Указатель на длину командной строки
    lodsb          ; Загружаем длину
    
    ; Если параметров нет, показываем справку
    cmp al, 0
    je show_usage

    ; Копируем параметры командной строки
    mov di, cmd_line_param
    mov cx, ax
    rep movsb
    mov byte [di], 0  ; Завершаем строку

    ; Парсим первый параметр (номер прерывания)
    call parse_interrupt_number
    jc error_parse_int

    ; Проверяем второй параметр (имя файла)
    call check_filename

    ; Получаем вектор прерывания
    mov ah, 0x35
    mov al, [int_number]
    int 0x21       ; Вызов DOS

    ; Сохраняем адрес обработчика
    mov [handler_segment], es
    mov [handler_offset], bx

    ; Вывод адреса обработчика на экран
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
    jc error_create
    mov [file_handle], ax

    ; Записываем обработчик в файл
    mov ah, 0x40   ; Функция записи в файл
    mov bx, [file_handle]
    mov cx, 0xFFFF ; Максимальный размер (64 кб)
    mov dx, [handler_offset]
    mov ds, [handler_segment]
    int 0x21
    jc error_write

    ; Закрываем файл
    mov ah, 0x3E
    mov bx, [file_handle]
    int 0x21

    ; Выход
    mov ax, 0x4C00
    int 0x21

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

; Парсинг номера прерывания
parse_interrupt_number:
    mov si, cmd_line_param
    ; Пропускаем начальные пробелы
.skip_spaces:
    lodsb
    cmp al, ' '
    je .skip_spaces
    cmp al, 0
    je show_usage

    ; Парсим hex-число
    xor bx, bx     ; Обнуляем результат
.parse_hex:
    ; Проверка на конец или пробел
    cmp al, ' '
    je .done
    cmp al, 0
    je .done

    ; Преобразование символа в цифру
    sub al, '0'
    jc .error
    cmp al, 9
    jle .valid_digit
    
    ; Для букв A-F
    sub al, 'A' - '0'
    jc .error
    add al, 10
    cmp al, 15
    ja .error

.valid_digit:
    shl bx, 4
    or bl, al

    ; Следующий символ
    lodsb
    jmp .parse_hex

.done:
    mov [int_number], bl
    clc
    ret

.error:
    stc
    ret

; Проверка имени файла
check_filename:
    ; Ищем второй параметр (имя файла)
    mov si, cmd_line_param
.find_space:
    lodsb
    cmp al, ' '
    je .found_space
    cmp al, 0
    jne .find_space
    ; Если второго параметра нет, используем имя по умолчанию
    mov si, default_filename
    mov di, filename
    jmp .copy_filename

.found_space:
    ; Пропускаем пробелы
.skip_spaces:
    lodsb
    cmp al, ' '
    je .skip_spaces
    
    ; Копируем имя файла
    mov di, filename
.copy_filename:
    ; Копируем до конца строки
    lodsb
    cmp al, 0
    je .done
    stosb
    jmp .copy_filename
.done:
    mov byte [di], 0  ; Завершающий ноль
    ret

; Показ справки
show_usage:
    mov ah, 0x09
    mov dx, msg_usage
    int 0x21
    mov ax, 0x4C01
    int 0x21

; Ошибка парсинга номера прерывания
error_parse_int:
    mov ah, 0x09
    mov dx, msg_error_parse
    int 0x21
    mov ax, 0x4C01
    int 0x21

; Обработчики ошибок
error_create:
    mov dx, error_create_msg
    jmp error_exit

error_write:
    mov dx, error_write_msg
    jmp error_exit

error_exit:
    mov ah, 0x09
    int 0x21
    mov ax, 0x4C01
    int 0x21

error_create_msg db 'Error creating file$'
error_write_msg db 'Error writing to file$'
