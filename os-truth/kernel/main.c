#include "stdint.h"
#include "init.h"
#include "debug.h"

int main(void)
{
    put_str("i am kernel\n");
    init_all();
    put_str("!!!!!!!!!!!!!!\n");
    ASSERT(1==2);
    put_str("#########\n");
    //asm volatile ("sti");   //临时开中断
    while(1);
    return 0;
}
