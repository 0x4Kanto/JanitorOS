BITS 16

global _start
extern kmain

section .text

_start:
    cli

    ; set data segments to code segment
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; set up stack
    mov ax, 0x2000
    mov ss, ax
    mov sp, 0xFFFE

    sti

    call kmain

.hang:
    cli
    hlt
    jmp .hang
