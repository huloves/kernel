#ifndef __USERPROG_FORK_H
#define __USERPROG_FORK_H
#include "thread.h"

/*fork子进程，内核线程不可直接调用*/
pid_t sys_fork(void);

#endif