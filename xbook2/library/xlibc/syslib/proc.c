#include <sys/syscall.h>
#include <sys/proc.h>
#include <sys/trigger.h>

extern void _exit_cleanup();

/**
 * _exit() - exit process
 * 
 * @status: exit status, give to parent.
 * 
 * exit process, after that, the process end of it's life.
 */
void _exit(int status)
{
    _exit_cleanup();
    syscall1(int , SYS_EXIT, status);
}

/**
 * fork() - fork process
 * 
 * after fork, we have 2 process samed, but different pid.
 * p A is parent, p B is child, so B's parent pid os A's pid.
 * 
 * @return: process pid, there are 3 case:
 *          1. pid > 0: current process is A, pid is B's pid
 *          2. pid = 0: current process is B
 *          3. pid < 0: fork failed
 */
pid_t fork()
{
    return syscall0(pid_t, SYS_FORK); /* return a pid (int type) */
}

/**
 * wait() - wait process
 * 
 * @status: [out] child process's exit status.
 *          notice that this is a ptr!
 * 
 * wait one child process to exit and fetch it's exit status.
 * 
 * @return: child pid, there are 2 case:
 *          if pid = -1: no child
 *          if pid > -1: exited child's pid 
 */
int wait(int *status)
{
    return syscall3(int, SYS_WAITPID, -1, status, 0);
}

/**
 * waitpid() - wait process pid
 * 
 * @pid: wait a pid
 * @status: [out] child process's exit status.
 *          notice that this is a ptr!
 * @option: WNOHANG: if no child exit, do not block and return 0
 * 
 * wait one child process to exit and fetch it's exit status.
 * 
 * @return: child pid, there are 3 case:
 *          if pid = -1: no child
 *          if pid = 0: exit without hanging
 *          if pid > 0: exited child's pid 
 */
int waitpid(pid_t pid, int *status, int options)
{
    return syscall3(int, SYS_WAITPID, pid, status, options);
}

/**
 * execraw() - execute raw block
 * 
 * @name: raw block name
 * @argv: arguments array
 * 
 * execute a raw block process, replaces the current process with the
 * raw block and runs the process corresponding to the raw block.
 * 
 * @return: -1 is failed, no success return, if success, run the new process. 
 */
int execraw(char *name, char *argv[])
{
    return syscall2(int, SYS_EXECR, name, argv);
}

/**
 * execfile() - execute file
 * 
 * @name: file name
 * @file: file info
 * @argv: arguments array
 * 
 * execute file in process, replaces the current process with the
 * file image and runs the process corresponding to the file.
 * 
 * @return: -1 is failed, no success return, if success, run the new process. 
 */
int execfile(char *name, kfile_t *file, char *argv[])
{
    return syscall3(int, SYS_EXECF, name, file, argv);
}

pid_t getpid()
{
    return syscall0(pid_t, SYS_GETPID); /* return a pid (int type) */
}

pid_t getppid()
{
    return syscall0(pid_t, SYS_GETPPID); /* return a pid (int type) */
}

pid_t gettid()
{
    return syscall0(pid_t, SYS_GETTID); /* return a pid (int type) */
}
/**
 * sleep - task sleep
 * @second: sleep time
 * 
 * @return: return left time before wakeup
 */
unsigned long sleep(unsigned long second)
{
    return syscall1(int, SYS_SLEEP, second);
}

/**
 * sched_yeild - 让出cpu
 * 
 */
void sched_yeild()
{
    syscall0(int, SYS_SCHED_YEILD);
}


/**
 * tstate - 获取任务状态
 * 
 */
int tstate(tstate_t *ts, int *idx)
{
    return syscall2(int, SYS_TSTATE, ts, idx);
}

int getver(char *buf, int len)
{
    if (!buf || len < 1)
        return -1;
    return syscall2(int, SYS_GETVER, buf, len);
}