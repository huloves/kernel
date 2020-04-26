#include "syscall-init.h"
#include "stdint.h"
#include "thread.h"
#include "print.h"
#include "syscall.h"
#include "console.h"
#include "string.h"

#define syscall_nr 32
typedef void* syscall;
syscall syscall_table[syscall_nr];

/*返回当前任务的pid*/
uint32_t sys_getpid(void)
{
    return running_thread()->pid;
}

/*输出*/
uint32_t sys_write(char* str)
{
    console_put_str(str);
    return strlen(str);
}

/*初始化系统调用*/
void syscall_init(void)
{
    put_str("syscall_init start\n");
    syscall_table[SYS_GETPID] = sys_getpid;
    syscall_table[SYS_WRITE] = sys_write;
    put_str("syscall_init done\n");
}
