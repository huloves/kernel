#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kthread.h>
#include <linux/atomic.h>
#include <linux/delay.h>
#include <linux/sched.h>
#include <linux/compaction.h>
#include <linux/ktime.h>

static int __init atomic_init(void);
static void __exit atomic_exit(void);

static volatile unsigned long global_var = 0;
static atomic_t atomic_global_var = ATOMIC_INIT(0);

static struct task_struct *test_kthread[4] = { NULL, NULL, NULL, NULL };
static struct completion kthread_completion[4];
static u64 kthread_runtime_ns[4] = { 0 };

static int kthread_ordinary_func(void *arg)
{
	const char *task_name = current->comm;
	u64 index = (u64)arg;
	ktime_t start, end;
	int i;

	printk(KERN_INFO "[%s] start\n", task_name);

	/* 获取起始时间点 */
	start = ktime_get();

	for (i = 0; i < 1000000000; i++) {
		global_var++;
	}

	/* 获取结束时间点 */
	end = ktime_get();

	if (index == 0) {
		complete(&kthread_completion[0]);
		kthread_runtime_ns[0] = ktime_to_ns(ktime_sub(end, start));
	} else {
		complete(&kthread_completion[1]);
		kthread_runtime_ns[1] = ktime_to_ns(ktime_sub(end, start));
	}

	return 0;
}

static int kthread_atomic_func(void *arg)
{
	const char *task_name = current->comm;
	u64 index = (u64)arg;
	ktime_t start, end;
	int i;

	printk(KERN_INFO "[%s] start\n", task_name);

	/* 获取起始时间点 */
	start = ktime_get();

	for (i = 0; i < 1000000000; i++) {
		atomic_inc(&atomic_global_var);
	}

	/* 获取结束时间点 */
	end = ktime_get();

	if (index == 2) {
		complete(&kthread_completion[2]);
		kthread_runtime_ns[2] = ktime_to_ns(ktime_sub(end, start));
	} else {
		complete(&kthread_completion[3]);
		kthread_runtime_ns[3] = ktime_to_ns(ktime_sub(end, start));
	}

	return 0;
}

static int __init atomic_init(void)
{
	printk(KERN_INFO "install atomic module.\n");

	init_completion(&kthread_completion[0]);
	init_completion(&kthread_completion[1]);
	init_completion(&kthread_completion[2]);
	init_completion(&kthread_completion[3]);

	test_kthread[0] = kthread_create(kthread_ordinary_func, (void *)0, "ordinary-0");
	if (!test_kthread[0] || IS_ERR(test_kthread[0])) {
		printk(KERN_DEBUG "%s()-%d: kthread_create fail \n", __func__, __LINE__);
		return -ECHILD;
	}
	kthread_bind(test_kthread[0], 0);
	wake_up_process(test_kthread[0]);

	test_kthread[1] = kthread_create(kthread_ordinary_func, (void *)1, "ordinary-1");
	if (!test_kthread[1] || IS_ERR(test_kthread[1])) {
		printk(KERN_DEBUG "%s()-%d: kthread_create fail \n", __func__, __LINE__);
		return -ECHILD;
	}
	kthread_bind(test_kthread[1], 1);
	wake_up_process(test_kthread[1]);

	test_kthread[2] = kthread_create(kthread_atomic_func, (void *)2, "atomic-0");
	if (!test_kthread[2] || IS_ERR(test_kthread[2])) {
		printk(KERN_DEBUG "%s()-%d: kthread_create fail \n", __func__, __LINE__);
		return -ECHILD;
	}
	kthread_bind(test_kthread[2], 0);
	wake_up_process(test_kthread[2]);

	test_kthread[3] = kthread_create(kthread_atomic_func, (void *)3, "atomic-1");
	if (!test_kthread[3] || IS_ERR(test_kthread[3])) {
		printk(KERN_DEBUG "%s()-%d: kthread_create fail \n", __func__, __LINE__);
		return -ECHILD;
	}
	kthread_bind(test_kthread[3], 1);
	wake_up_process(test_kthread[3]);

	return 0;
}

static void __exit atomic_exit(void)
{
	wait_for_completion(&kthread_completion[0]);
	wait_for_completion(&kthread_completion[1]);
	wait_for_completion(&kthread_completion[2]);
	wait_for_completion(&kthread_completion[3]);

	printk(KERN_INFO "value of global_var: %ld\n", global_var);
	printk(KERN_INFO "value of atomic_global_var: %d\n", atomic_read(&atomic_global_var));

	printk(KERN_INFO "Thread 0 run time: %llu ns\n", kthread_runtime_ns[0]);
	printk(KERN_INFO "Thread 1 run time: %llu ns\n", kthread_runtime_ns[1]);
	printk(KERN_INFO "Thread 2 run time: %llu ns\n", kthread_runtime_ns[2]);
	printk(KERN_INFO "Thread 3 run time: %llu ns\n", kthread_runtime_ns[3]);

	printk(KERN_INFO "remove atomic module.\n");
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("name");
MODULE_DESCRIPTION("atomic test");

module_init(atomic_init);
module_exit(atomic_exit);
