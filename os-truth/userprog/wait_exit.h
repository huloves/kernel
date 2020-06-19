#ifndef USERPROG_WAIT_EXIT_H
#define USERPROG_WAIT_EXIT_H
#include "thread.h"

/*等待子进程调用exit，将子进程的退出状态保存到status指向的变量，成功返回子进程的pid，失败返回-1*/
pid_t sys_wait(int32_t* status);
/*子进程用来结束自己时调用*/
void sys_exit(int32_t status);

#endif
