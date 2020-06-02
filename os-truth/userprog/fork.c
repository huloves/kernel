#include "fork.h"
#include "stdint.h"
#include "thread.h"
#include "string.h"
#include "global.h"
#include "memory.h"
#include "process.h"
#include "debug.h"

extern void intr_exit(void);

/*将父进程的pcb拷贝给子进程*/
static int32_t copy_pcb_vaddrbitmap_stack0(struct task_struct* child_thread, struct task_struct* parent_thread)
{
    //a. 复制pcb所在整个页，里面包含进程pcb信息及特权级0的栈，包含返回地址
    memcpy(child_thread, parent_thread, PG_SIZE);
    child_thread->pid = fork_pid();
    child_thread->elapsed_ticks = 0;
    child_thread->status = TASK_READY;
    child_thread->ticks = parent_thread->priority;
    child_thread->parent_pid = parent_thread->pid;
    child_thread->general_tag.prev = child_thread->general_tag.next = NULL;
    child_thread->all_list_tag.prev = child_thread->all_list_tag.prev = NULL;
    block_desc_init(child_thread->u_block_desc);   //初始化进程自己的内存块描述符
    //b. 复制父进程的虚拟地址池的位图
    uint32_t bitmap_pg_cnt = DIV_ROUND_UP((0xc0000000 - USER_VADDR_START) / PG_SIZE / 8, PG_SIZE);   //位图占内存页数
    void* vaddr_bitmap = get_kernel_pages(bitmap_pg_cnt);
    //此时child_thread->userprog_vaddr.vaddr_bitmap.bits指向父进程虚拟地址的位图地址
    memcpy(vaddr_bitmap, child_thread->userprog_vaddr.vaddr_bitmap.bits, bitmap_pg_cnt * PG_SIZE);
    child_thread->userprog_vaddr.vaddr_bitmap.bits = vaddr_bitmap;
    //调试用
    ASSERT(strlen(child_thread->name) <11);
    strcat(child_thread->name, "_fork");
    return 0;
}

/*复制子进程的进程体（到吗和数据）及用户栈
  buf_page必须是内核页，要用它作为所有进程的数据缓冲区
  此函数的主要功能就是拷贝进程的代码和数据资源，也就是复制一份进程体*/
static void copy_body_stack3(struct task_struct* child_thread, struct task_struct* parent_thread, void* buf_page)
{
    uint8_t* vaddr_btmp = parent_thread->userprog_vaddr.vaddr_bitmap.bits;
    uint32_t btmp_bytes_len = parent_thread->userprog_vaddr.vaddr_bitmap.btmp_bytes_len;
    uint32_t vaddr_start = parent_thread->userprog_vaddr.vaddr_start;
    uint32_t idx_byte = 0;
    uint32_t idx_bit = 0;
    uint32_t prog_vaddr = 0;

    //在父进程的用户空间中查找已有的页
    while(idx_byte < btmp_bytes_len) {
        if(vaddr_btmp[idx_byte]) {
            idx_bit = 0;
            while(idx_bit < 8) {
                if((BITMAP_MASK << idx_bit) & vaddr_btmp[idx_byte]) {
                    prog_vaddr = (idx_byte * 8 + idx_bit) * PG_SIZE + vaddr_start;

                    memcpy(buf_page, (void*)prog_vaddr, PG_SIZE);

                    page_dir_activate(child_thread);

                    get_a_page_without_opvaddrbitmap(PF_USER, prog_vaddr);

                    memcpy((void*)prog_vaddr, buf_page, PG_SIZE);

                    page_dir_activate(parent_thread);
                }
                idx_bit++;
            }
        }
        idx_byte++;
    }
}
