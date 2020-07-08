#ifndef __LIB_USER_SYSCALL_H
#define __LIB_USER_SYSCALL_H
#include "stdint.h"
#include "thread.h"
#include "dir.h"

enum SYSCALL_NR
{
    SYS_GETPID,
    SYS_WRITE,
    SYS_MALLOC,
    SYS_FREE,
    SYS_FORK,
    SYS_READ,
    SYS_PUTCHAR,
    SYS_CLEAR,
    SYS_GETCWD,
    SYS_OPEN,
    SYS_CLOSE,
    SYS_LSEEK,
    SYS_UNLINK,
    SYS_MKDIR,
    SYS_OPENDIR,
    SYS_CLOSEDIR,
    SYS_CHDIR,
    SYS_RMDIR,
    SYS_READDIR,
    SYS_REWINDDIR,
    SYS_STAT,
    SYS_PS,
    SYS_EXECV,
    SYS_WAIT,
    SYS_EXIT,
    SYS_HELP
};

uint32_t getpid(void);
uint32_t write(int32_t fd, const void* buf, uint32_t count);
/*申请size字节大小的内存，并返回结果*/
void* malloc(uint32_t size);
/*释放ptr指向的内存*/
void free(void* ptr);
pid_t fork(void);
int32_t read(int32_t fd, void* buf, uint32_t count);
void putchar(char char_asci);
void clear(void);
/*获取当前工作目录*/
char* getcwd(char* buf, uint32_t size);
/*以flag方式打开文件pathname*/
int32_t open(char* pathname, uint8_t flag);
/*关闭文件*/
int32_t close(int32_t fd);
/*设置文件偏移量*/
int32_t lseek(int32_t fd, int32_t offset, uint32_t whence);
/*删除文件*/
int32_t unlink(const char* pathname);
/*创建目录pathname*/
int32_t mkdir(const char* pathname);
/*打开目录*/
struct dir* opendir(const char* name);
/*关闭目录*/
int32_t closedir(struct dir* dir);
/*删除目录*/
int32_t rmdir(const char* pathname);
/*读取目录dir*/
struct dir_entry* readdir(struct dir* dir);
/*回归目录指针*/
void rewinddir(struct dir* dir);
/*获取path属性到buf中*/
int32_t stat(const char* path, struct stat* buf);
/*改变工作目录*/
int32_t chdir(const char* path);
/*显示任务列表*/
void ps(void);
/*execv*/
int execv(const char* path, const char* argv[]);
pid_t wait(int32_t* status);
void exit(int32_t status);
void help(void);

#endif
