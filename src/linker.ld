ENTRY(_start)

SECTIONS
{
    . = 0x0000;

    .text :
    {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
    }
    .bss :
    {
        *(.bss)
        *(COMMON)
    }

    .data :
    {
        *(.data)
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
    }
}
