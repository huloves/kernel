#include "wait_exit.h"
#include "stdint.h"
#include "thread.h"
#include "fs.h"

/*释放用户进程资源，页表中对应的物理页，虚拟内存池占物理页框，打开的文件*/
static void release_prog_resource(struct task_struct* release_thread)
{
    uint32_t* pgdir_vaddr = release_thread->pgdir;
    uint16_t user_pde_nr = 768, pde_idx = 0;
    uint32_t pde = 0;
    uint32_t* v_pde_ptr = NULL;   //v表示var，和函数pde_ptr区分

    uint16_t user_pte_nr = 1024, pte_idx = 0;
    uint32_t pte = 0;
    uint32_t* v_pte_ptr = NULL;

    uint32_t* first_pte_vaddr_in_pde = NULL;   //记录pde中第一个pte指向的物理页起始地址
    uint32_t pg_phy_addr = 0;

    //回收页表中用户空间的页框
    while(pde_idx < user_pde_nr) {
        v_pde_ptr = pgdir_vaddr + pde_idx;
        pde = *v_pde_ptr;
        if(pde & 0x00000001) {
            first_pte_vaddr_in_pde = pte_ptr(pde_idx * 0x400000);   //一个页表表示的内存容量是4MB，即0x400000
            pte_idx = 0;
            while(pte_idx < user_pte_nr) {
                v_pte_ptr = first_pte_vaddr_in_pde + pte_idx;
                pte = * v_pte_ptr;
                if(pte & 0x00000001) {
                    pg_phy_addr = pte & 0xfffff000;
                    free_a_phy_addr(pg_phy_addr);
                }
                pte_idx++;
            }
            //将pde中记录的物理页框直接在相应内存池的位图中清0
            pg_phy_addr = pde & 0xfffff000;
            free_a_phy_addr(pg_phy_addr);
        }
        pde_idx++;
    }

    //回收用户虚拟地址池所占的物理内存
    uint32_t bitmap_pg_cnt = (release_thread->userprog_vaddr.vaddr_bitmap.btmp_bytes_len) / PG_SIZE;
    uint8_t* user_vaddr_pool_bitmap = release_thread->userprog_vaddr.vaddr_bitmap.bits;
    mfree_page(PF_KERNEL, user_vaddr_pool_bitmap, bitmap_pg_cnt);

    //关闭进程打开的文件
    uint8_t fd_idx = 3;
    while(fd_idx < MAX_FILES_OPEN_PER_PROC) {
        if(release_thread->fd_table[fd_idx] != -1) {
            sys_close(fd_idx);
        }
        fd_idx++;
    }
}
