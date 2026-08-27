BITS 16

shell:
    mov si, banner
    call puts

.main_loop:
    mov si, prompt
    call puts

    call read_line

    cmp byte [input_buffer], 0
    je .main_loop

    mov si, input_buffer
    call uppercase_string

    mov si, input_buffer
    mov di, command_help
    call strcmp
    test ax, ax
    jz .help

    mov si, input_buffer
    mov di, command_echo
    call starts_with
    jc .echo

    mov si, input_buffer
    mov di, command_math
    call starts_with
    jc .math

    mov si, input_buffer
    mov di, command_sysinfo
    call strcmp
    test ax, ax
    jz .sysinfo

    mov si, input_buffer
    mov di, command_reboot
    call strcmp
    test ax, ax
    jz .reboot

    mov si, message_unknown
    call puts
    jmp .main_loop

.help:
    mov si, message_commands
    call puts
    jmp .main_loop

.echo:
    add si, 4

.skip_spaces:
    cmp byte [si], ' '
    jne .print_echo
    inc si
    jmp .skip_spaces

.print_echo:
    call puts
    call print_newline
    jmp .main_loop

.math:
    add si, 4
    call math_command
    jmp .main_loop

.sysinfo:
    call print_sysinfo
    jmp .main_loop

.reboot:
    mov si, message_reboot
    call puts

    cli

    mov ax, 0x0040
    mov ds, ax
    mov word [0x0072], 0x0000

    jmp 0xFFFF:0x0000


print_sysinfo:
    mov si, message_sysinfo
    call puts

    int 0x12

    push ax
    mov si, message_conventional
    call puts
    pop ax

    call print_uint

    mov si, message_kb
    call puts

    mov ah, 0x0F
    int 0x10

    mov [video_mode], al
    mov [video_columns], ah

    mov si, message_video
    call puts

    xor ah, ah
    mov al, [video_mode]
    call print_uint

    mov si, message_columns
    call puts

    xor ax, ax
    mov al, [video_columns]
    call print_uint

    call print_newline
    ret


banner:
[stub@groot src]¥ ls
boot.asm  commands.asm  console.asm  input.asm  kernel.asm  math.asm
[stub@groot src]¥ cat console.asm 
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
