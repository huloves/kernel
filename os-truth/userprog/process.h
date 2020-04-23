#ifndef __USERPROG_H
#define __USERPROG_H
#include "stdint.h"
#include "thread.h"

#define default_prio 31
#define USER_STACK3_VADDR  (0xc0000000 - 0x1000)
#define USER_VADDR_START 0x8048000

void start_process(void* filename_);
void page_dir_activate(struct task_struct* p_thread);
void process_activate(struct task_struct* p_thread);
/**创建用户进程的页目录表，将当前页表的表示内核空间的pde复制，成功返回页目录的虚拟地址，否则返回NULL**/
uint32_t* create_page_dir(void);
/*创建用户进程虚拟地址位图*/
void create_user_vaddr_bitmap(struct task_struct* user_prog);
/*创建用户进程*/
void process_execute(void* filename, char* name);

#endif
