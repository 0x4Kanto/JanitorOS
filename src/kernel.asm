BITS 16
org 0x0000

%define KERNEL_SEG      0x1000
%define MAX_INPUT       80

start:
    cli

    mov ax, KERNEL_SEG
    mov ds, ax
    mov es, ax
    mov ss,ax
    mov sp, 0xFFFE

    sti

    call console_init
    call shell

.hang:
    cli
    hlt
    jmp .hang

%include "src/console.asm"
%include "src/input.asm"
%include "src/commands.asm"
%include "src/math.asm"



prompt              db "A:\>", 0
newline             db 13, 10, 0

input_buffer        times MAX_INPUT db 0

math_a              dw 0
math_b              dw 0
math_operator       db 0

video_mode          db 0
video_columns       db 0
