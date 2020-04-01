#include "thread.h"
#include "stdint.h"
#include "string.h"
#include "global.h"
#include "memory.h"
#include "list.h"
#include "interrupt.h"
#include "debug.h"

#define PG_SIZE 4096

struct task_struct* main_thread;       //主线程PCB
struct list thread_ready_list;         //就绪队列
struct list thread_all_list;           //所有任务队列
static struct list_elem* thread_tag;   //用于保存队列中的线程节点

extern void switch_to(struct task_struct* cur, struct task_struct* next);

/*获取当前线程pcb指针*/
struct task_struct* running_thread()
{
    uint32_t esp;
    asm ("mov %%esp, %0" : "=g"(esp));
    //取esp的整数部分，即pcb起始地址
    return (struct task_struct*)(esp & 0xfffff000);
}

/*由kernel_thread区执行function(func_arg)*/
static void kernel_thread(thread_func* function, void* func_arg)
{
    //执行function(func_arg)前要开中断，避免后面的时钟中断被屏蔽，而无法调度其他线程
    intr_enable();
    function(func_arg);
}

/*初始化线程栈thread_stack，将待执行的函数和参数放到thread_stack中相应的位置*/
void thread_create(struct task_struct* pthread, thread_func function, void* func_arg)
{
    //先预留中断使用栈的空间，可见thread.h中定义的结构
    pthread->self_kstack -= sizeof(struct intr_stack);
    
    //再留出线程栈空间
    pthread->self_kstack -= sizeof(struct thread_stack);
    struct thread_stack* kthread_stack = (struct thread_stack*)pthread->self_kstack;
    kthread_stack->eip = kernel_thread;
    kthread_stack->function = function;
    kthread_stack->func_arg = func_arg;
    kthread_stack->ebp = kthread_stack->ebx = \
    kthread_stack->esi = kthread_stack->edi = 0;
}

/*初始化线程基本信息*/
void init_thread(struct task_struct* pthread, char* name, int prio)
{
    memset(pthread, 0, sizeof(*pthread));
    strcpy(pthread->name, name);

    if(pthread == main_thread) {
        pthread->status = TASK_RUNNING;   //由于把main函数也封装成一个线程，并且它一直是运行的，故将其直接设为TASK_RUNNING
    } else {
        pthread->status = TASK_READY;
    }

    //self_kstack是线程自己在内核态下使用的栈顶地址
    pthread->self_kstack = (uint32_t*)((uint32_t)pthread + PG_SIZE);
    pthread->priority = prio;
    pthread->ticks = prio;
    pthread->elapsed_ticks = 0;
    pthread->pgdir = NULL;
    pthread->stack_magic = 0x19870916;   //自定义魔数
}

/*创建一优先级为prio的线程，线程名为name，线程所执行的函数是function()*/
struct task_struct* thread_start(char* name, \
                                 int prio, \
                                 thread_func function, \
                                 void* func_arg) 
{
    //pcb都位于内核空间，包括用户进程的pcb也是内核空间
    struct task_struct* thread = get_kernel_pages(1);

    init_thread(thread, name, prio);
    thread_create(thread, function, func_arg);

    //确保之前不在队列中
    ASSERT(!elem_find(&thread_ready_list, &thread->general_tag));
    //加入就绪线程队列
    list_append(&thread_ready_list, &thread->general_tag);

    //确保之前不在队列中
    ASSERT(!elem_find(&thread_all_list, &thread->all_list_tag));
    //加入到全部线程队列
    list_append(&thread_all_list, &thread->all_list_tag);

   return thread;
}

/*将kernel中的main函数完善为主线程*/
static void make_main_thread(void)
{
    //因为main线程早已运行，咱们在loader.s中进入内核时mov esp,0xc0001500
    //就是为其预留pcb的，因此pcb地址为0xc0009e00，不需要另分配yiye
    main_thread = running_thread();
    init_thread(main_thread, "main", 31);

    //main函数是当前线程，当前线程不在thread_ready_list中，所以只将其加载thread_all_list中
    ASSERT(!elem_find(&thread_all_list, &main_thread->all_list_tag));
    list_append(&thread_all_list, &main_thread->all_list_tag);
}
