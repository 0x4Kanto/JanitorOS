#define MAX_INPUT 80

void putc(char c)
{
    __asm__ volatile(
        "int $0x10"
        :
        : "a"(0x0E00 | (unsigned char)c),
          "b"(0x0007)
    );
}

void puts(const char *s)
{
    while (*s)
        putc(*s++);
}

char getch(void)
{
    unsigned short ax;

    __asm__ volatile(
        "int $0x16"
        : "=a"(ax)
        : "a"(0x0000)
    );

    return (char)(ax & 0xFF);
}

void shell(void)
{
    static char input[MAX_INPUT]; // static for now until i fix the stack

    puts("\r\nJanitor Shell\r\n");
    puts("Type 'help'\r\n");

    while (1)
    {
        puts("> ");

        unsigned int len = 0;

        while (1)
        {
            char c = getch();

            if (c == '\r')
            {
                input[len] = '\0';
                puts("\r\n");
                break;
            }

            if (c == '\b')
            {
                if (len > 0)
                {
                    len--;

                    // erase character on screen
                    putc('\b');
                    putc(' ');
                    putc('\b');
                }

                continue;
            }

            if (c >= 32 && c <= 126)
            {
                if (len < MAX_INPUT - 1)
                {
                    input[len++] = c;

                    // echo typed character once
                    putc(c);
                }
            }
        }


        if (len == 4 &&
            input[0] == 'h' &&
            input[1] == 'e' &&
            input[2] == 'l' &&
            input[3] == 'p')
        {
            puts("Commands:\r\n");
            puts("  help\r\n");
            puts("  echo <text>\r\n");
        }

        else if (len >= 5 &&
                input[0] == 'e' &&
                input[1] == 'c' &&
                input[2] == 'h' &&
                input[3] == 'o' &&
                input[4] == ' ')
        {
            puts(input + 5);
            puts("\r\n");
        }
        else if (len != 0)
        {
            puts("Unknown Command!\r\n");
        }
    }
}
        

__attribute__((noreturn))
void kmain(void)
{
    shell();

    for (;;)
        __asm__ volatile ("hlt");
}
