#include <xbook/mutexlock.h>
#include <xbook/schedule.h>


/**
 * mutex_lock - 互斥锁加锁
 * @mutex: 锁对象
 */
void mutex_lock(mutexlock_t *mutex)
{
    do {
        /* 保证整个函数是原子的 */
        disable_intr();

        /* 循环+等待，做更深的判断 */
        if (!atomic_xchg(&mutex->count, 1)) {
            /* 如果获取到锁，直接返回 */
            enable_intr();
            return;
        }
        
        mutex->waiters++;
        task_t *task = current_task;
        
        list_add_tail(&task->list, &mutex->wait_list);
        /*
        SET_TASK_STATUS(task, TASK_BLOCKED);
        enable_intr();
        schedule();*/
        task_block(TASK_BLOCKED);
    } while (1);
}

/**
 * mutex_unlock - 互斥锁解锁
 * @mutex: 锁对象
 */
void mutex_unlock(mutexlock_t *mutex)
{
    /* 保证整个函数是原子的 */
    disable_intr();
    atomic_set(&mutex->count, 0); /* set lock unused */

    if (mutex->waiters == 0) {
        enable_intr();
        return;
    }
    /* 获取第一个等待者 */
    task_t *task = list_first_owner(&mutex->wait_list, task_t, list);
    list_del_init(&task->list);
    mutex->waiters--;
    enable_intr();
    
    task_wakeup(task);
}
