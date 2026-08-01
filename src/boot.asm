BITS 16
ORG 0x7C00

KERNEL_SEG equ 0x1000

start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax

    xor ax, ax
    mov ss, ax
    mov sp, 0x7C00

    sti

    mov [boot_drive], dl

    ; Load kernel
    mov ax, KERNEL_SEG
    mov es, ax
    xor bx, bx

    mov ah, 0x02        ; read sectors
    mov al, 16          ; sectors to read
    mov ch, 0           ; cylinder
    mov cl, 2           ; start sector
    mov dh, 0           ; head
    mov dl, [boot_drive]

    int 0x13
    jc disk_error

    jmp KERNEL_SEG:0000


disk_error:
    mov si, error_msg
    call print

    ; Print actual AH from BIOS
    mov al, ah
    call print_hex

    cli
    hlt


print:
    lodsb
    test al, al
    jz .done

    mov ah, 0x0E
    int 0x10

    jmp print

.done:
    ret


print_hex:
    push ax

    shr al, 4
    call hex_digit

    pop ax
    and al, 0x0F
    call hex_digit

    ret


hex_digit:
    cmp al, 10
    jl .num

    add al, 'A'-10
    jmp .out

.num:
    add al, '0'

.out:
    mov ah, 0x0E
    int 0x10
    ret


boot_drive db 0
error_msg db "Disk error AH=",0


times 510-($-$$) db 0
dw 0xAA55
