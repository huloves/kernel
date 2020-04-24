#ifndef __USERPROG_SYSCALLINIT_H
#define __USERPROG_SYSCALLINIT_H
#include "stdint.h"

/*返回当前任务的pid*/
uint32_t sys_getpid(void);
/*初始化系统调用*/
void syscall_init(void);

#endif
