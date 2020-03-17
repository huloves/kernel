#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/init_task.h>

MODULE_LICENSE("GPL");

static int year=2020;

static int hello_init(void)
{
    struct task_struct *p;
    p = NULL;
    p = &init_task;
    printk(KERN_WARNING "名称\t\t进程号\t状态\t优先级\t父进程号\t");
    for_each_process(p) {
        if(p->mm == NULL) {
            printk(KERN_WARNING "%s\t\t%d\t%ld\t%d\n", p->comm,p->pid, p->state,p->normal_prio,p->parent->pid);
        }
    }
    printk(KERN_WARNING "hello kernel, it is %d\n", year);
    return 0;
}

static void hello_exit(void)
{
    printk("Bye, kernel!\n");
}

module_init(hello_init);
module_exit(hello_exit);
