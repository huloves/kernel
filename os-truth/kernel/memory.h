#ifndef __KERNEL_MEMORY_H
#define __KERNEL_MEMORY_H
#include "stdint.h"
#include "bitmap.h"
#include "list.h"

#define PG_P_1  1   //页表项或页目录项存在属性位
#define PG_P_0  0   //页表项或页目录项存在属性位
#define PG_RW_R 0   //R/W属性位值，读/执行
#define PG_RW_W 2   //R/W属性位值，读/写/执行
#define PG_US_S 0   //U/S属性位值，系统级
#define PG_US_U 4   //用户级

#define DESC_CNT 7   //内存块描述符个数

extern struct pool kernel_pool, user_pool;

/*内存池标记，用于判断用哪个内存池*/
enum pool_flags
{
    PF_KERNEL = 1,   //内核内存池
    PF_USER = 2   //用户内存池
};

/*虚拟地址池，用于虚拟地址管理*/
struct virtual_addr
{
    struct bitmap vaddr_bitmap;   //虚拟地址用到的位图结构
    uint32_t vaddr_start;   //虚拟地址起始地址
};

/*内存块*/
struct mem_block
{
    struct list_elem free_elem;   //用来添加到同规格内存块描述符的free_list中
};

/*内存块描述符*/
struct mem_block_desc
{
    uint32_t block_size;   //内存块大小，描述本描述符的规格
    uint32_t blocks_per_arena;   //本arena中可容纳此memory_block的数量
    struct list free_list;   //空闲内存块链表，目前可用的mem_block链表
};

uint32_t* pte_ptr(uint32_t vaddr);
uint32_t* pde_ptr(uint32_t vaddr);
void* malloc_page(enum pool_flags pf, uint32_t pg_cnt);
void* get_kernel_pages(uint32_t pg_cnt);
void* get_user_pages(uint32_t pg_cnt);
void* get_a_page(enum pool_flags pf, uint32_t vaddr);
/*安装1页大小的vaddr，专门针对fork时虚拟地址位图无需操作的情况*/
void* get_a_page_without_opvaddrbitmap(enum pool_flags pf, uint32_t vaddr);
void mem_init(void);
/*得到虚拟地址映射到的物理地址*/
uint32_t addr_v2p(uint32_t vaddr);
/*在堆中申请size字节内存*/
void* sys_malloc(uint32_t size);
/*将物理地址pg_phy_addr回收到物理内存池*/
void pfree(uint32_t pg_phy_addr);
/*释放以虚拟地址vaddr起始的cnt个物理页框*/
void mfree_page(enum pool_flags pf, void* _vaddr, uint32_t pg_cnt);
/*回收内存ptr*/
void sys_free(void* ptr);
/*根据物理页框地址pg_phy_addr在相应的内存池的位图清零，不改动页表*/
void free_a_phy_addr(uint32_t pg_phy_addr);

#endif
