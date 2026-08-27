BITS 16

read_line:
    push bx
    push di

    xor bx, bx
    mov di, input_buffer

.read:
    xor ah, ah
    int 0x16

    cmp al, 13
    je .enter

    cmp al, 8
    je .backspace

    cmp al, 32
    jb .read

    cmp al, 126
    ja .read

    cmp bx, MAX_INPUT - 1
    jae .read

    stosb
    inc bx
    call putc
    jmp .read

.backspace:
    cmp bx, 0
    je .read

    dec bx
    dec di

    mov al, 8
    call putc

    mov al, ' '
    call putc

    mov al, 8
    call putc

    jmp .read

.enter:
    mov al, 0
    stosb
    call print_newline

    pop di
    pop bx
    ret


uppercase_string:
    push si

.next:
    mov al, [si]
    test al, al
    jz .done

    cmp al, 'a'
    jb .not_lowercase

    cmp al, 'z'
    ja .not_lowercase

    sub byte [si], 32

.not_lowercase:
    inc si
    jmp .next

.done:
    pop si
    ret


strcmp:
.compare:
    mov al, [si]
    cmp al, [di]
    jne .not_equal

    test al, al
    jz .equal

    inc si
    inc di
    jmp .compare

.equal:
    xor ax, ax
    ret

.not_equal:
    mov ax, 1
    ret


starts_with:
    push si
    push di

.compare:
    mov al, [di]
    test al, al
    jz .prefix_done

    cmp al, [si]
    jne .no_match

    inc si
    inc di
    jmp .compare

.prefix_done:
    mov al, [si]

    test al, al
    jz .match

    cmp al, ' '
    je .match

.no_match:
    pop di
    pop si
    clc
    ret

.match:
    pop di
    pop si
    stc
    ret
