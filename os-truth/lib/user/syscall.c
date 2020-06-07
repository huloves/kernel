#include "syscall.h"
#include "thread.h"

/*无参数的系统调用*/
#define _syscall0(NUMBER) ({ \
    int retval; \
    asm volatile ( \
        "int $0x80" \
        : "=a"(retval) \
        : "a"(NUMBER) \
        : "memory" \
    ); \
    retval; \
})

#define _syscall1(NUMBER, ARG1) ({ \
    int retval; \
    asm volatile ( \
        "int $0x80" \
        : "=a"(retval) \
        : "a"(NUMBER), "b"(ARG1) \
        : "memory" \
    ); \
    retval; \
})

#define _syscall2(NUMBER, ARG1, ARG2) ({ \
    int retval; \
    asm volatile ( \
        "int $0x80" \
        : "=a"(retval) \
        : "a"(NUMBER), "b"(ARG1), "c"(ARG2) \
        : "memory" \
    ); \
    retval; \
})

#define _syscall3(NUMBER, ARG1, ARG2, ARG3) ({ \
    int retval; \
    asm volatile ( \
        "int $0x80" \
        : "=a"(retval) \
        : "a"(NUMBER), "b"(ARG1), "c"(ARG2), "d"(ARG3) \
        : "memory" \
    ); \
    retval; \
})

/*返回当前任务的pid*/
uint32_t getpid()
{
    return _syscall0(SYS_GETPID);
}

uint32_t write(int32_t fd, const void* buf, uint32_t count)
{
    return _syscall3(SYS_WRITE, fd, buf, count);
}

/*申请size字节大小的内存，并返回结果*/
void* malloc(uint32_t size)
{
    return (void*)_syscall1(SYS_MALLOC, size);
}

/*释放ptr指向的内存*/
void free(void* ptr)
{
    _syscall1(SYS_FREE, ptr);
}

pid_t fork(void)
{
    return _syscall0(SYS_FORK);
}

int32_t read(int32_t fd, void* buf, uint32_t count)
{
    return _syscall3(SYS_READ, fd, buf, count);
}

void putchar(char char_asci)
{
    _syscall1(SYS_PUTCHAR, char_asci);
}

void clear(void)
{
    _syscall0(SYS_CLEAR);
}

/*获取当前工作目录*/
char* getcwd(char* buf, uint32_t size)
{
    return (char*)_syscall2(SYS_GETCWD, buf, size);
}

/*以flag方式打开文件pathname*/
int32_t open(char* pathname, uint8_t flag)
{
    return _syscall2(SYS_OPEN, pathname, flag);
}

/*关闭文件*/
int32_t close(int32_t fd)
{
    return _syscall1(SYS_CLOSE, fd);
}

/*设置文件偏移量*/
int32_t lseek(int32_t fd, int32_t offset, uint32_t whence)
{
    return _syscall3(SYS_LSEEK, fd, offset, whence);
}

/*删除文件*/
int32_t unlink(const char* pathname)
{
    return _syscall1(SYS_UNLINK, pathname);
}

/*创建目录pathname*/
int32_t mkdir(const char* pathname)
{
    return _syscall1(SYS_MKDIR, pathname);
}

/*打开目录*/
struct dir* opendir(const char* name)
{
    return (struct dir*)_syscall1(SYS_OPENDIR, name);
}

/*关闭目录*/
int32_t closedir(struct dir* dir)
{
    return _syscall1(SYS_CLOSEDIR, dir);
}

/*删除目录*/
int32_t rmdir(const char* pathname)
{
    return _syscall1(SYS_RMDIR, pathname);
}

/*读取目录dir*/
struct dir_entry* readdir(struct dir* dir)
{
    return (struct dir_entrh*)_syscall1(SYS_READDIR, dir);
}

/*回归目录指针*/
void rewinddir(struct dir* dir)
{
    _syscall1(SYS_REWINDIR, dir);
}

/*获取path属性到buf中*/
int32_t stat(const char* path, struct stat* buf)
{
    return _syscall2(SYS_STAT, path, buf);
}

/*改变工作目录*/
int32_t chdir(const char* path)
{
    return _syscall1(SYS_CHDIR, path);
}

/*显示任务列表*/
void ps(void)
{
    _syscall0(SYS_PS);
}
