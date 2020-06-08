#ifndef __USERPROG_EXEC_H
#define __USERPROG_EXEC_h
#include "stdint.h"

/*用path指向的程序替换当前进程*/
int32_t sys_execv(const char* path, const char* argv[]);

#endif
