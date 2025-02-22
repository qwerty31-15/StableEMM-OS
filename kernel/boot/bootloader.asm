org 0x7C00  ; Загрузчик загружается по адресу 0x7C00

start:
    ; Настройка видеорежима
    mov ax, 0x0003  ; Текстовый режим 80x25
    int 0x10        ; Вызов BIOS

    ; Очистка экрана
    mov ax, 0x0600  ; Функция прокрутки экрана
    mov cx, 0x0000  ; Верхний левый угол
    mov dx, 0x184F  ; Нижний правый угол
    mov bh, 0x07    ; Атрибуты (светло-серый на черном)
    int 0x10        ; Вызов BIOS

    ; Установка курсора в верхний левый угол
    mov ah, 0x02
    mov bh, 0x00
    mov dx, 0x0000
    int 0x10

    ; Вывод логотипа StableEMM
    mov si, logo
    call print_string

    ; Сообщение о загрузке
    mov si, loading_msg
    call print_string

    ; Перенос строки после сообщения о загрузке
    mov ah, 0x0E
    mov al, 0x0D  ; Carriage Return
    int 0x10
    mov al, 0x0A  ; Line Feed
    int 0x10

    ; Запрос логина
    mov si, username_prompt
    call print_string
    mov di, username
    call get_input

    ; Перенос строки после ввода логина
    mov ah, 0x0E
    mov al, 0x0D  ; Carriage Return
    int 0x10
    mov al, 0x0A  ; Line Feed
    int 0x10

    ; Запрос пароля
    mov si, password_prompt
    call print_string
    mov di, password
    call get_password_input

    ; Проверка аутентификации
    call authenticate
    cmp ax, 0
    je auth_failed

    ; Переход к ядру (эмуляция)
    jmp $

auth_failed:
    ; Перенос строки перед сообщением об ошибке
    mov ah, 0x0E
    mov al, 0x0D  ; Carriage Return
    int 0x10
    mov al, 0x0A  ; Line Feed
    int 0x10

    mov si, auth_failed_msg
    call print_string
    jmp $

; =============================
; Функция для вывода строки
print_string:
    mov ah, 0x0E
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

; Функция для ввода строки
get_input:
    xor cx, cx          ; Счётчик символов
.get_char:
    mov ah, 0x00        ; Ожидаем нажатие клавиши
    int 0x16
    cmp al, 0x0D        ; Проверка на Enter
    je .done
    mov [di], al        ; Сохраняем символ
    inc di
    inc cx
    mov ah, 0x0E        ; Печатаем введённый символ
    int 0x10
    jmp .get_char
.done:
    mov byte [di], 0    ; Завершаем строку
    ret

; Функция для ввода пароля (скрытый ввод)
get_password_input:
    xor cx, cx
.get_pass_char:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .done
    mov [di], al
    inc di
    inc cx
    mov ah, 0x0E
    mov al, '*'
    int 0x10
    jmp .get_pass_char
.done:
    mov byte [di], 0
    ret

; Функция аутентификации
authenticate:
    mov si, correct_username
    mov di, username
    call strcmp
    jne auth_fail

    mov si, correct_password
    mov di, password
    call strcmp
    jne auth_fail

    mov ax, 1  ; Успех
    ret

auth_fail:
    mov ax, 0  ; Ошибка
    ret

; Функция сравнения строк
strcmp:
.compare_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .compare_loop

.not_equal:
    mov ax, 1
    ret

.equal:
    xor ax, ax
    ret

; =============================
; Данные

logo db "Welcome to StableEMM", 0x0D, 0x0A, 0

loading_msg      db "Loading StableEMM...", 0
username_prompt  db "Enter username: ", 0
password_prompt  db "Enter password: ", 0
auth_failed_msg  db "Authentication failed!", 0

username         db 20 dup(0)
password         db 20 dup(0)

correct_username db "root", 0
correct_password db "root", 0

; =============================
; Завершение загрузочного сектора

times 510 - ($ - $$) db 0
dw 0xAA55
