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


/*
 * Simple unsigned integer parser.
 * Example: "123" -> 123
 */
unsigned int parse_uint(const char *s)
{
    unsigned int n = 0;

    while (*s >= '0' && *s <= '9')
    {
        n = (n * 10) + (*s - '0');
        s++;
    }

    return n;
}


/*
 * Prints an unsigned integer without printf.
 * Static buffer avoids stack usage.
 */
void print_uint(unsigned int n)
{
    static char buf[10];
    int i = 0;

    if (n == 0)
    {
        putc('0');
        return;
    }

    while (n > 0)
    {
        buf[i++] = '0' + (n % 10);
        n /= 10;
    }

    while (i > 0)
    {
        putc(buf[--i]);
    }
}

int parse_sign_uint(const char *s)
{
    int sign = 1;
    int n = 0;

    if (*s == '-')
    {
        sign = -1;
        s++;
    }

    while (*s >= '0' && *s <= '9')
    {
        n = (n * 10) + (*s - '0');
        s++;
    }

    return n * sign;
}


void print_int(int n)
{
    if (n < 0)
    {
        putc('-');
        n = -n;
    }

    print_uint((unsigned int)n);
}


void shell(void)
{
    static char input[MAX_INPUT]; // static until stack is ready

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
                    putc(c);
                }
            }
        }



        // help
        if (len == 4 &&
            input[0] == 'h' &&
            input[1] == 'e' &&
            input[2] == 'l' &&
            input[3] == 'p')
        {
            puts("Commands:\r\n");
            puts("  help\r\n");
            puts("  echo <text>\r\n");
            puts("  math <num> +|- <num>\r\n");
        }



        // echo output
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


        // math
        else if (len >= 5 &&
                input[0] == 'm' &&
                input[1] == 'a' &&
                input[2] == 't' &&
                input[3] == 'h' &&
                input[4] == ' ')
        {
            char *p = input + 5;

            int a = parse_sign_uint(p);

            while (*p && *p != ' ')
                p++;

            if (*p == ' ')
            {
                p++;

                char op = *p;

                while (*p && *p != ' ')
                    p++;

                if (*p == ' ')
                    p++;

                int b = parse_sign_uint(p);
                int result;

                if (op == '+')
                {
                    result = a + b;
                }
                else if (op == '-')
                {
                    result = a + (-b);
                }
                else
                {
                    puts("Use + or -\r\n");
                    continue;
                }

                print_int(result);
                puts("\r\n");
            }
            else
            {
                puts("Usage: math <num> +|- <num>\r\n");
            }
        }

        // empty input / unknown command
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
