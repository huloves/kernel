#ifndef __THREAD_THREAD_H
#define __THREAD_THREAD_H
#include "stdint.h"
#include "list.h"
#include "bitmap.h"
#include "memory.h"

#define MAX_FILES_OPEN_PER_PROC 8
#define TASK_NAME_LEN 16

/*自定义通用函数类型，它将在很多线程函数中作为参数类型*/
typedef void thread_func(void*);
typedef int16_t pid_t;

extern struct list thread_ready_list;   //就绪队列
extern struct list thread_all_list;   //所有任务队列

/*进程或线程的状态*/
enum task_status
{
    TASK_RUNNING,
    TASK_READY,
    TASK_BLOCKED,
    TASK_WAITING,
    TASK_HANGING,
    TASK_DIED
};

/******* 中断栈intr_stack ******
 * 此结构用于中断发生时，保护程序（线程或进程）的上下文环境：
 * 进程或线程被外部中断或软中断打断时，会按照此结构压入上下文
 * 进村器，intr_exit中的出栈操作是此结构的逆操作
 * 此栈在线程自己的内核栈中位置位置固定，所在页的最顶端
*/
struct intr_stack
{
    uint32_t vec_no;   //kernel.s宏VECTOR中push %1压入的中断号
    uint32_t edi;
    uint32_t esi;
    uint32_t ebp;
    uint32_t esp_dummy;   //虽然pushad把esp页压入，但esp是不断变化的，所以会被popadhulve
    uint32_t ebx;
    uint32_t edx;
    uint32_t ecx;
    uint32_t eax;
    uint32_t gs;
    uint32_t fs;
    uint32_t es;
    uint32_t ds;
    /*一下由cpu从低特权级进入高特权级时压入*/
    uint32_t err_code;   //err_code会被压入在eip之后
    void (*eip) (void);
    uint32_t cs;
    uint32_t eflags;
    void* esp;
    uint32_t ss;
};

/******* 线程栈thread_stack ******
 * 线程自己的栈，用于存储线程中待执行的函数
 * 此结构在线程自己的内核栈中位置不固定
 * 仅用在switch_to时保存线程环境
 * 实际位置取决于实际运行情况
*/
struct thread_stack
{
    uint32_t ebp;
    uint32_t ebx;
    uint32_t edi;
    uint32_t esi;
    
    //线程第一次执行时，eip指向待调用的函数kernel_thread，其他时候，eip指向switch_to的返回地址
    void (*eip) (thread_func* func, void* func_arg);

    //以下仅供第一次被调度上cpu时使用
    void (*unused_retaddr);//参数unused_ret只为占位置充数为返回地址
    thread_func* function;   //由kernel_thread所调用的函数名
    void* func_arg;   //由kernel_thread所调用的函数所需的参数
};

/*进程或线程的pcb，程序控制块*/
struct task_struct
{
    uint32_t* self_kstack;   //个内核线程都用自己的内核栈
    pid_t pid;
    enum task_status status;
    char name[16];
    uint8_t priority;   //线程优先级
    uint8_t ticks;   //每次处理器上执行的时间滴答数，任务的时间片

    uint32_t elapsed_ticks;   //此任务自上cpu运行后至今占用了多少cpu滴答数，从运行开始到运行结束所经历的总时钟数

    int32_t fd_table[MAX_FILES_OPEN_PER_PROC];   //文件描述符数组

    struct list_elem general_tag;   //的作用是用于线程在一般的队列中的节点，线程的标签

    struct list_elem all_list_tag;   //用于线程队列thread_all_list中的节点，用于线程被加入到全部线程队列时使用

    uint32_t* pgdir;   //进程自己页表的虚拟地址
    struct virtual_addr userprog_vaddr;   //用户进程的虚拟地址
    struct mem_block_desc u_block_desc[DESC_CNT];   //用户进程内存块描述符表
    uint32_t cwd_inode_nr;   //进程所在的工作目录的inode编号
    pid_t parent_pid;   //父进程的pid
    int8_t exit_status;   //进程结束时自己调用exit传出的参数
    uint32_t stack_magic;   //栈的边界标记，用于检测栈的溢出
};

struct task_struct* running_thread(void);
/*释放pid*/
void release_pid(pid_t pid);
/*回收thread_over的pcb和页表，并将其从调度队列中去除*/
void thread_exit(struct task_struct* thread_over, bool need_schedule);
/*根据pid找pcb，若找到则返回pcb，否则返回NULL*/
struct task_struct* pid2thread(int32_t pid);
/*为进程分配pid*/
pid_t fork_pid();
void thread_create(struct task_struct* pthread, thread_func function, void* func_arg);
void init_thread(struct task_struct* pthread, char* name, int prio);
struct task_struct* thread_start(char* name, int prio, thread_func function, void* func_arg);
void schedule(void);
void thread_block(enum task_status stat);
void thread_unblock(struct task_struct* pthread);
/*主动让出cpu，换其他线程运行*/
void thread_yield(void);
/*打印任务列表*/
void sys_ps(void);
void thread_init(void);

#endif
