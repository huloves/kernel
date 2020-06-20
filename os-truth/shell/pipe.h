#ifndef __SHELL_PIPE_H
#define __SHELL_PIPE_H
#include "stdint.h"
#include "global.h"

#define PIPE_FLAG 0xFFFF

/*判断文件描述符local_fd是否是管道*/
bool is_pipe(uint32_t local_fd);
/*创建管道，成功返回0，失败返回-1*/
int32_t sys_pipe(int32_t pipefd[2]);
/*管道中读数据*/
uint32_t pipe_read(int32_t fd, void* buf, uint32_t count);
/*管道中写数据*/
uint32_t pipe_write(int32_t fd, const void* buf, uint32_t count);

#endif
