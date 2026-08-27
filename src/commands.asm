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
    db 13, 10
    db "jOS", 13, 10
    db "Type HELP for a list of commands.", 13, 10, 13, 10, 0

command_help:
    db "HELP", 0

command_echo:
    db "ECHO", 0

command_math:
    db "MATH", 0

command_sysinfo:
    db "SYSINFO", 0

command_reboot:
    db "REBOOT", 0

message_commands:
    db "Available commands:", 13, 10
    db "  HELP", 13, 10
    db "  ECHO <text>", 13, 10
    db "  MATH <a> +|-|*|/ <b>", 13, 10
    db "  SYSINFO", 13, 10
    db "  REBOOT", 13, 10, 0

message_unknown:
    db "Bad command or file name.", 13, 10, 0

message_reboot:
    db "Rebooting...", 13, 10, 0

message_sysinfo:
    db 13, 10
    db "System Information", 13, 10
    db "-------------------", 13, 10, 0

message_conventional:
    db "Conventional memory: ", 0

message_kb:
    db " KB", 13, 10, 0

message_video:
    db "Video mode: ", 0

message_columns:
    db ", columns: ", 0
