#include "stdint.h"
#include "init.h"
#include "debug.h"
#include "memory.h"
#include "thread.h"
#include "interrupt.h"
#include "console.h"

void k_thread_a(void*);
void k_thread_b(void*);
void k_thread_c(void*);
void k_thread_d(void*);

int main(void)
{
    put_str("i am kernel\n");
    init_all();

    //thread_start("k_thread_a", 31, k_thread_a, "argA ");
    //thread_start("k_thread_b", 8, k_thread_b, "argB ");
    //thread_start("k_thread_c", 16, k_thread_c, "argC ");
    //thread_start("k_thread_d", 8, k_thread_c, "argD ");

    intr_enable();   //打开中断
    while(1); //{
        //intr_disable();
        //put_str("Main ");
        //intr_enable();
        //console_put_str("Main ");
    //}

    return 0;
}

void k_thread_a(void* arg)
{
    char* para = arg;
    while(1) {
        //intr_disable();
        //put_str("argA ");
        //intr_enable();
        console_put_str(para);
    }
}

void k_thread_b(void* arg)
{
    char* para = arg;
    while(1) {
        //intr_disable();
        //put_str("argB ");
        console_put_str(para);
        //intr_enable();
    }
}

void k_thread_c(void* arg)
{
    char* para = arg;
    while(1) {
        console_put_str(para);
    }
}

void k_thread_d(void* arg)
{
    char* para = arg;
    while(1) {
        console_put_str(para);
    }
}
