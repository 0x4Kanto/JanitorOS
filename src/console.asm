BITS 16

console_init:
    mov ax, 0x0003
    int 0x10
    ret


putc:
    push ax
    push bx

    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07
    int 0x10

    pop bx
    pop ax
    ret


puts:
.next:
    lodsb
    test al, al
    jz .done

    call putc
    jmp .next

.done:
    ret


print_newline:
    mov si, newline
    call puts
    ret


print_uint:
    test ax, ax
    jnz .convert

    mov al, '0'
    call putc
    ret

.convert:
    push bx
    push cx
    push dx

    xor cx, cx
    mov bx, 10

.divide:
    xor dx, dx
    div bx
    push dx
    inc cx

    test ax, ax
    jnz .divide

.print:
    pop dx
    add dl, '0'
    mov al, dl
    call putc
    loop .print

    pop dx
    pop cx
    pop bx
    ret


print_int:
    test ax, ax
    jns .positive

    push ax
    mov al, '-'
    call putc
    pop ax

    neg ax

.positive:
    call print_uint
    ret
