#include <arch/time.h>

void __udelay(int usec)
{
    int i, j;
    for (i = 0; i < 10 * usec; i++);
        for (j = 0; j < 100; j++);
}