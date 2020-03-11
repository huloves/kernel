#include "stdint.h"
#include "init.h"

void main(void)
{
    put_str("i am kernel\n");
    init_all();
    asm volatile ("sti");   //临时开中断
    while(1);    
}