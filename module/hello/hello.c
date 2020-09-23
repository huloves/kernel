#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <uapi/linux/sched.h>
#include <linux/init_task.h>
#include <linux/fdtable.h>
#include <linux/fs_struct.h>
#include <linux/mm_types.h>
#include <linux/string.h>
#include <linux/signal.h>
#include <asm/signal.h>
#include <linux/kallsyms.h>

//内核模块初始化函数
static int __init traverse_pcb(void)
{
    struct task_struct* task;
    struct task_struct* p;
    struct list_head* pos;
    int count = 0;
    
    task = &init_task;   //指向0号进程的pcb

    list_for_each(pos, &task->tasks) {
        p = list_entry(pos, struct task_struct, tasks);   //指向遍历的当前进程
        count++;
        printk("pid:%d  state:%lx name:%s\n", p->pid, p->state, p->comm);
    }
    printk("task number = %d\n", count);

    return 0;
}

static void __exit end_pcb(void)
{
    printk("traverse pcb is end\n");
}

module_init(traverse_pcb);
module_exit(end_pcb);
MODULE_LICENSE("GPL");
