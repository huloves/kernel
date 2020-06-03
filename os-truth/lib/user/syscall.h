#ifndef __LIB_USER_SYSCALL_H
#define __LIB_USER_SYSCALL_H
#include "stdint.h"
#include "thread.h"

enum SYSCALL_NR
{
    SYS_GETPID,
    SYS_WRITE,
    SYS_MALLOC,
    SYS_FREE,
    SYS_FORK,
    SYS_READ
};

uint32_t getpid(void);
uint32_t write(int32_t fd, const void* buf, uint32_t count);
/*申请size字节大小的内存，并返回结果*/
void* malloc(uint32_t size);
/*释放ptr指向的内存*/
void free(void* ptr);
pid_t fork(void);

#endif
