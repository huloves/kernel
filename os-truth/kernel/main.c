#include "stdint.h"
#include "init.h"
#include "debug.h"
#include "memory.h"
#include "thread.h"
#include "interrupt.h"
#include "console.h"
#include "keyboard.h"
#include "process.h"
#include "syscall-init.h"
#include "syscall.h"
#include "stdio.h"

void k_thread_a(void*);
void k_thread_b(void*);
void u_prog_a(void);
void u_prog_b(void);

int prog_a_pid = 0, prog_b_pid = 0;

int main(void)
{
    put_str("i am kernel\n");
    init_all();

    process_execute(u_prog_a, "user_prog_a");
    process_execute(u_prog_b, "user_prog_b");

    intr_enable();   //打开中断
    console_put_str(" main_pid:0x");
    console_put_int(sys_getpid());
    console_put_char('\n');
    put_str("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n");
    thread_start("k_thread_a", 31, k_thread_a, "argA");
    thread_start("k_thread_b", 31, k_thread_b, "argB");
    while(1);

    return 0;
}

void k_thread_a(void* arg)
{
    char* para = arg;
    console_put_str(" thread_a_pid:0x");
    console_put_int(sys_getpid());
    console_put_char('\n');
    while(1);
}

void k_thread_b(void* arg)
{
    char* para = arg;
    console_put_str(" thread_b_pid:0x");
    console_put_int(sys_getpid());
    console_put_char('\n');
    while(1);
}

//测试用户进程
void u_prog_a(void)
{
    printf(" prog_a_pid:0x%x\n", getpid());
    while(1);
}

void u_prog_b(void)
{
    printf(" prog_b_pid:0x%x\n", getpid());   
    while(1);
}
