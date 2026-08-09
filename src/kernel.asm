;; After this, this will be the only comment in the kernel
;; since i have remembered enough to make most of it without comments.
BITS 16
ORG 0x0000

%define MAX_INPUT 80

start:
    cli

    mov ax, cs
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0xFFFE

    sti

    call shell

.hang:
    cli
    hlt
    jmp .hang


putc:
    push ax
    push bx

    mov ah, 0x0E
    mov bh, 0x00
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


getch:
    push bx
    push cx
    push dx

    xor ah, ah
    int 0x16

    pop dx
    pop cx
    pop bx
    ret


parse_uint:
    xor bx, bx
    xor cx, cx

.next_digit:
    lodsb

    cmp al, '0'
    jb .done

    cmp al, '9'
    ja .done

    sub al, '0'
    xor ah, ah

    push ax

    mov ax, bx
    mov dx, 10
    mul dx

    mov bx, ax

    pop ax
    add bx, ax

    inc cx
    jmp .next_digit

.done:
    cmp cx, 0
    je .no_digits

    mov ax, bx
    clc
    ret

.no_digits:
    xor ax, ax
    stc
    ret


parse_sign_uint:
    push bp
    mov bp, 1

    cmp byte [si], '-'
    jne .parse

    mov bp, -1
    inc si

.parse:
    xor bx, bx
    xor cx, cx

.next_digit:
    mov al, [si]

    cmp al, '0'
    jb .finish

    cmp al, '9'
    ja .finish

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
    jmp .next_digit

.finish:
    cmp cx, 0
    je .no_digits

    mov ax, bx

    cmp bp, 1
    je .positive

    neg ax

.positive:
    pop bp
    clc
    ret

.no_digits:
    xor ax, ax
    pop bp
    stc
    ret


print_uint:
    cmp ax, 0
    jne .convert

    mov al, '0'
    call putc
    ret

.convert:
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


strlen:
    xor bx, bx

.loop:
    cmp byte [si + bx], 0
    je .done

    inc bx
    jmp .loop

.done:
    mov ax, bx
    ret


strcmp:
.compare:
    mov al, [si]
    mov ah, [di]

    cmp al, ah
    jne .not_equal

    cmp al, 0
    je .equal

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

    cmp al, 0
    je .prefix_finished

    cmp al, [si]
    jne .no_match

    inc si
    inc di
    jmp .compare

.prefix_finished:
    mov al, [si]

    cmp al, 0
    je .yes_match

    cmp al, ' '
    je .yes_match

.no_match:
    pop di
    pop si

    clc
    ret

.yes_match:
    pop di
    pop si

    stc
    ret


graphics_rect:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov si, ax
    mov bp, bx
    mov di, cx

    cmp si, 320
    jae .done

    cmp bp, 200
    jae .done

    mov ax, 320
    sub ax, si

    cmp di, ax
    jbe .width_ok

    mov di, ax

.width_ok:

    mov ax, 200
    sub ax, bp

    cmp dx, ax
    jbe .height_ok

    mov dx, ax

.height_ok:

    cmp di, 0
    je .done

    cmp dx, 0
    je .done


.row:
    push dx
    mov cx, si
    mov dx, bp
    mov ax, di

.pixel:
    push ax

    mov ah, 0x0C
    mov al, 0x04
    mov bh, 0x00

    int 0x10

    pop ax

    inc cx
    dec ax

    jnz .pixel

    inc bp

    pop dx
    dec dx

    jnz .row

.done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


graphics_command:
    add si, 4

.skip_x_spaces:
    cmp byte [si], ' '
    jne .parse_x

    inc si
    jmp .skip_x_spaces

.parse_x:
    call parse_uint
    jc .usage

    mov [rect_x], ax

.skip_y_spaces:
    cmp byte [si], ' '
    jne .parse_y

    inc si
    jmp .skip_y_spaces

.parse_y:
    call parse_uint
    jc .usage

    mov [rect_y], ax

.skip_w_spaces:
    cmp byte [si], ' '
    jne .parse_w

    inc si
    jmp .skip_w_spaces

.parse_w:
    call parse_uint
    jc .usage

    mov [rect_w], ax

.skip_h_spaces:
    cmp byte [si], ' '
    jne .parse_h

    inc si
    jmp .skip_h_spaces

.parse_h:
    call parse_uint
    jc .usage

    mov [rect_h], ax

.check_end:
    cmp byte [si], 0
    je .draw

    cmp byte [si], ' '
    jne .usage

    inc si
    jmp .check_end

.draw:

    cmp word [rect_w], 0
    je .usage

    cmp word [rect_h], 0
    je .usage

    cmp word [rect_x], 800
    jae .usage

    cmp word [rect_y], 800
    jae .usage

    mov ax, 0x000D
    int 0x10

    mov ax, [rect_x]
    mov bx, [rect_y]
    mov cx, [rect_w]
    mov dx, [rect_h]

    call graphics_rect

    call getch

    mov ax, 0x0003
    int 0x10

    mov si, msg_graphics_return
    call puts

    ret


.usage:
    mov si, msg_rect_usage
    call puts
    ret


shell:
    mov si, msg_banner
    call puts

    mov si, msg_help_hint
    call puts


.main_loop:
    mov si, prompt
    call puts

    xor bx, bx


.read_line:
    call getch

    cmp al, 0x0D
    je .line_done

    cmp al, 0x08
    je .backspace

    cmp al, 32
    jb .read_line

    cmp al, 126
    ja .read_line

    cmp bx, MAX_INPUT - 1
    jae .read_line

    mov [input + bx], al
    inc bx

    call putc
    jmp .read_line


.backspace:
    cmp bx, 0
    je .read_line

    dec bx

    mov al, 0x08
    call putc

    mov al, ' '
    call putc

    mov al, 0x08
    call putc

    jmp .read_line


.line_done:
    mov byte [input + bx], 0

    mov si, newline
    call puts

    cmp bx, 0
    je .main_loop

    mov si, input
    mov di, cmd_help
    call strcmp

    cmp ax, 0
    je .help

    mov si, input
    mov di, cmd_echo
    call starts_with

    jc .echo

    mov si, input
    mov di, cmd_math
    call starts_with

    jc .math

    mov si, input
    mov di, cmd_rect
    call starts_with

    jc .rect

    mov si, input
    mov di, cmd_reboot
    call starts_with

    jc .reboot

    mov si, msg_unknown
    call puts

    jmp .main_loop


.help:
    mov si, msg_commands
    call puts

    jmp .main_loop


.echo:
    add si, 4

.skip_echo_spaces:
    cmp byte [si], ' '
    jne .echo_print

    inc si
    jmp .skip_echo_spaces


.echo_print:
    call puts

    mov si, newline
    call puts

    jmp .main_loop


.math:
    add si, 4


.skip_a_spaces:
    cmp byte [si], ' '
    jne .parse_a

    inc si
    jmp .skip_a_spaces


.parse_a:
    call parse_sign_uint
    jc .math_usage

    mov [math_a], ax


.skip_to_operator:
    cmp byte [si], 0
    je .math_usage

    cmp byte [si], '+'
    je .operator_found

    cmp byte [si], '-'
    je .operator_found

    cmp byte [si], ' '
    je .skip_operator_space

    jmp .math_usage


.skip_operator_space:
    inc si
    jmp .skip_to_operator


.operator_found:
    mov al, [si]
    mov [math_op], al

    inc si


.skip_b_spaces:
    cmp byte [si], ' '
    jne .parse_b

    inc si
    jmp .skip_b_spaces


.parse_b:
    call parse_sign_uint
    jc .math_usage

    mov [math_b], ax


.check_math_end:
    cmp byte [si], 0
    je .calculate

    cmp byte [si], ' '
    jne .math_usage

    inc si
    jmp .check_math_end


.calculate:
    mov ax, [math_a]
    mov bx, [math_b]

    cmp byte [math_op], '+'
    je .add

    cmp byte [math_op], '-'
    je .subtract

    jmp .math_usage


.add:
    add ax, bx
    jmp .print_result


.subtract:
    sub ax, bx


.print_result:
    call print_int

    mov si, newline
    call puts

    jmp .main_loop


.math_usage:
    mov si, msg_math_usage
    call puts

    jmp .main_loop


.rect:
    call graphics_command

    jmp .main_loop


.reboot:
    mov si, msg_reboot
    call puts

    cli
    int 0x19


.reboot_hang:
    cli
    hlt
    jmp .reboot_hang


msg_banner:
    db 13, 10
    db 'Janitor Shell', 13, 10
    db 0


msg_help_hint:
    db "Type 'help'", 13, 10
    db 0


msg_commands:
    db 'Commands:', 13, 10
    db '  help', 13, 10
    db '  echo <text>', 13, 10
    db '  math <a> +|- <b>', 13, 10
    db '  rect <x> <y> <width> <height>', 13, 10
    db '  reboot', 13, 10
    db 0


msg_reboot:
    db 'Rebooting...', 13, 10, 0


msg_unknown:
    db 'Unknown Command!', 13, 10
    db 0


msg_math_usage:
    db 'Usage: math <a> +|- <b>', 13, 10
    db 0


msg_rect_usage:
    db 'Usage: rect <x> <y> <width> <height>', 13, 10
    db 'Video mode: 320x200, 16 colors', 13, 10
    db 'Example: rect 50 40 120 70', 13, 10
    db 0


msg_graphics_return:
    db 13, 10
    db 'Returned to shell.', 13, 10
    db 0


prompt:
    db '=> ', 0


newline:
    db 13, 10, 0


cmd_help:
    db 'help', 0


cmd_echo:
    db 'echo', 0


cmd_math:
    db 'math', 0


cmd_rect:
    db 'rect', 0


cmd_reboot:
    db 'reboot', 0


input:
    times MAX_INPUT db 0


math_a:
    dw 0


math_b:
    dw 0


math_op:
    db 0


rect_x:
    dw 0


rect_y:
    dw 0


rect_w:
    dw 0


rect_h:
    dw 0


times ((512 - ($ - $$) % 512) % 512) db 0
