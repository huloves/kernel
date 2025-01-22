#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kthread.h>
#include <linux/atomic.h>
#include <linux/percpu.h>
#include <linux/delay.h>
#include <linux/sched.h>
#include <linux/compaction.h>
#include <linux/ktime.h>

#define KTHREAD_NUM	8

static int __init atomic_init(void);
static void __exit atomic_exit(void);

static volatile u32 global_var = 0;
static atomic_t atomic_global_var = ATOMIC_INIT(0);
static volatile u32 spin_global_var = 0;
static spinlock_t spinlock;
DEFINE_PER_CPU(u32, percpu_global_var);

static struct task_struct *test_kthread[KTHREAD_NUM];
static struct completion kthread_completion[KTHREAD_NUM];
static u64 kthread_runtime_ns[KTHREAD_NUM] = { 0 };

static int kthread_ordinary_func(void *arg)
{
	const char *task_name = current->comm;
	u64 index = (u64)arg;
	ktime_t start, end;
	int i;

	printk(KERN_INFO "[%s] start\n", task_name);

	/* 获取起始时间点 */
	start = ktime_get();

	for (i = 0; i < 100000000; i++) {
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

	for (i = 0; i < 100000000; i++) {
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

static int kthread_spinlock_func(void *arg)
{
	const char *task_name = current->comm;
	u64 index = (u64)arg;
	ktime_t start, end;
	int i;

	printk(KERN_INFO "[%s] start\n", task_name);

	/* 获取起始时间点 */
	start = ktime_get();

	for (i = 0; i < 100000000; i++) {
		spin_lock(&spinlock);
		spin_global_var++;
		spin_unlock(&spinlock);
	}

	/* 获取结束时间点 */
	end = ktime_get();

	if (index == 4) {
		complete(&kthread_completion[4]);
		kthread_runtime_ns[4] = ktime_to_ns(ktime_sub(end, start));
	} else {
		complete(&kthread_completion[5]);
		kthread_runtime_ns[5] = ktime_to_ns(ktime_sub(end, start));
	}

	return 0;
}

static int kthread_percpu_func(void *arg)
{
	const char *task_name = current->comm;
	u64 index = (u64)arg;
	ktime_t start, end;
	int i;

	printk(KERN_INFO "[%s] start\n", task_name);

	/* 获取起始时间点 */
	start = ktime_get();

	for (i = 0; i < 100000000; i++) {
		this_cpu_inc(percpu_global_var);
	}

	/* 获取结束时间点 */
	end = ktime_get();

	if (index == 6) {
		complete(&kthread_completion[6]);
		kthread_runtime_ns[6] = ktime_to_ns(ktime_sub(end, start));
	} else {
		complete(&kthread_completion[7]);
		kthread_runtime_ns[7] = ktime_to_ns(ktime_sub(end, start));
	}

	return 0;
}

static int create_and_start_kthread(struct task_struct **thread,
				   int (*thread_func)(void *arg),
				   void *arg,
				   const char *name,
				   int cpu)
{
	*thread = kthread_create(thread_func, arg, name);
	if (!(*thread) || IS_ERR(*thread)) {
		printk(KERN_DEBUG "%s()-%d: kthread_create fail\n", __func__, __LINE__);
		return -ECHILD;
	}
	kthread_bind(*thread, cpu);
	wake_up_process(*thread);
	return 0;
}

static int __init atomic_init(void)
{
	int i;
	int result;

	printk(KERN_INFO "install atomic module.\n");

	for (i = 0; i < KTHREAD_NUM; i++)
		init_completion(&kthread_completion[i]);

	for (i = 0; i < KTHREAD_NUM; i++) {
		int (*thread_func)(void *) = (i < 2) ? kthread_ordinary_func :
					     (i < 4) ? kthread_atomic_func :
					     (i < 6) ? kthread_spinlock_func :
					     	       kthread_percpu_func;
		int cpu = i % 2;
		char task_name[TASK_COMM_LEN];

		sprintf(task_name, "kthread-%d(%d)", i, cpu);

		result = create_and_start_kthread(&test_kthread[i], thread_func, (void *)(long)i, task_name, cpu);
		if (result)
			return result;
	}

	return 0;
}

static void __exit atomic_exit(void)
{
	int i;

	for (i = 0; i < KTHREAD_NUM; i++)
		wait_for_completion(&kthread_completion[i]);

	printk(KERN_INFO "global_var: %d\n", global_var);
	printk(KERN_INFO "atomic: atomic_global_var: %d\n", atomic_read(&atomic_global_var));
	printk(KERN_INFO "spinlock: spin_global_var: %d\n", spin_global_var);
	printk(KERN_INFO "per-cpu: percpu_global_var[0]: %d\n", per_cpu(percpu_global_var, 0));
	printk(KERN_INFO "per-cpu: percpu_global_var[1]: %d\n", per_cpu(percpu_global_var, 1));
	printk(KERN_INFO "per-cpu: sum: %d\n", per_cpu(percpu_global_var, 0) + per_cpu(percpu_global_var, 1));

	for (i = 0; i < KTHREAD_NUM; i++)
		printk(KERN_INFO "kthread %d run time: %llu ns\n", i, kthread_runtime_ns[i]);

	printk(KERN_INFO "remove atomic module.\n");
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("name");
MODULE_DESCRIPTION("atomic test");

module_init(atomic_init);
module_exit(atomic_exit);
