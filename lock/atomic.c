#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kthread.h>
#include <linux/atomic.h>
#include <linux/delay.h>
#include <linux/sched.h>

static int __init atomic_init(void);
static void __exit atomic_exit(void);

static unsigned long global_var = 0;
static atomic_t atomic_global_var = ATOMIC_INIT(0);

static struct task_struct *test_kthread[2] = { NULL, NULL };

static int kthread_test_func(void *arg)
{
	struct task_struct *task = current;
	int i;

	printk(KERN_INFO "[%s] start\n", task->comm);

	for (i = 0; i < 100000000; i++) {
		global_var++;
		atomic_inc(&atomic_global_var);
	}

	printk(KERN_INFO "[%s] value of global_var: %ld\n", task->comm, global_var);
	printk(KERN_INFO "[%s] value of atomic_global_var: %d\n", task->comm, atomic_read(&atomic_global_var));

	return 0;
}

static int __init atomic_init(void)
{
	printk(KERN_INFO "install atomic module.\n");

	test_kthread[0] = kthread_create(kthread_test_func, (void *)0, "kthread-test0");
	if (!test_kthread[0] || IS_ERR(test_kthread[0])) {
		printk(KERN_DEBUG "%s()-%d: kthread_create fail \n", __func__, __LINE__);
		return -ECHILD;
	}
	kthread_bind(test_kthread[0], 0);
	wake_up_process(test_kthread[0]);

	test_kthread[1] = kthread_create(kthread_test_func, (void *)1, "kthread-test1");
	if (!test_kthread[1] || IS_ERR(test_kthread[1])) {
		printk(KERN_DEBUG "%s()-%d: kthread_create fail \n", __func__, __LINE__);
		return -ECHILD;
	}
	kthread_bind(test_kthread[1], 1);
	wake_up_process(test_kthread[1]);

	return 0;
}

static void __exit atomic_exit(void)
{
	printk(KERN_INFO "value of global_var: %ld\n", global_var);
	printk(KERN_INFO "value of atomic_global_var: %d\n", atomic_read(&atomic_global_var));
	printk(KERN_INFO "remove atomic module.\n");
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("name");
MODULE_DESCRIPTION("atomic test");

module_init(atomic_init);
module_exit(atomic_exit);
