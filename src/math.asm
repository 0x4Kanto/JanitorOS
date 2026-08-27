BITS 16

math_command:

.skip_a_spaces:
    cmp byte [si], ' '
    jne .parse_a
    inc si
    jmp .skip_a_spaces

.parse_a:
    call parse_signed
    jc .usage

    mov [math_a], ax

.skip_operator_spaces:
    cmp byte [si], ' '
    jne .find_operator
    inc si
    jmp .skip_operator_spaces

.find_operator:
    mov al, [si]

    cmp al, '+'
    je .operator_found

    cmp al, '-'
    je .operator_found

    cmp al, '*'
    je .operator_found

    cmp al, '/'
    jne .usage

.operator_found:
    mov [math_operator], al
    inc si

.skip_b_spaces:
    cmp byte [si], ' '
    jne .parse_b
    inc si
    jmp .skip_b_spaces

.parse_b:
    call parse_signed
    jc .usage

    mov [math_b], ax

.skip_end_spaces:
    cmp byte [si], 0
    je .calculate

    cmp byte [si], ' '
    jne .usage

    inc si
    jmp .skip_end_spaces

.calculate:
    mov ax, [math_a]
    mov bx, [math_b]

    cmp byte [math_operator], '+'
    je .add

    cmp byte [math_operator], '-'
    je .subtract

    cmp byte [math_operator], '*'
    je .multiply

    cmp bx, 0
    je .division_by_zero

    cwd
    idiv bx
    jmp .print

.add:
    add ax, bx
    jmp .print

.subtract:
    sub ax, bx
    jmp .print

.multiply:
    imul bx
    jmp .print

.division_by_zero:
    mov si, message_division_zero
    call puts
    ret

.print:
    call print_int
    call print_newline
    ret

.usage:
    mov si, message_math_usage
    call puts
    ret


parse_signed:
    push bx
    push cx
    push dx
    push di

    xor bx, bx
    xor cx, cx
    xor di, di

    cmp byte [si], '-'
    jne .digits

    mov di, 1
    inc si

.digits:
    mov al, [si]

    cmp al, '0'
    jb .done_digits

    cmp al, '9'
    ja .done_digits

    sub al, '0'
    xor ah, ah

    push ax

    mov ax, bx
    mov dx, 10
    mul dx
    mov bx, ax

    pop ax
    add bx, ax

    inc si
    inc cx
    jmp .digits

.done_digits:
    cmp cx, 0
    je .no_digits

    mov ax, bx

    test di, di
    jz .success

    neg ax

.success:
    pop di
    pop dx
    pop cx
    pop bx
    clc
    ret

.no_digits:
    xor ax, ax

    pop di
    pop dx
    pop cx
    pop bx
    stc
    ret


message_math_usage:
    db "Usage: MATH <a> +|-|*|/ <b>", 13, 10, 0

message_division_zero:
    db "Division by zero.", 13, 10, 0
