#ifndef _XBOOK_VMSPACE_H
#define _XBOOK_VMSPACE_H

#include "vmm.h"
#include "memcache.h"
#include <stddef.h>
#include <stdint.h>
#include <types.h>
#include <arch/page.h>

/* map flags */
#define VMS_MAP_FIXED       0x10       /* 映射固定位置 */
#define VMS_MAP_STACK       0x20       /* 映射成栈，会动态变化 */
#define VMS_MAP_HEAP        0x40       /* 映射成堆，会动态变化 */
#define VMS_MAP_SHARED      0x80       /* 映射成共享内存 */
#define VMS_MAP_REMAP       0x100      /* 强制重写映射 */

#define MAX_VMS_STACK_SIZE  (16 * MB)   /* 最大栈拓展大小 */

#define DEFAULT_STACK_SIZE  (PAGE_SIZE * 4)   /* 默认栈大小 */

/* 最大可扩展的堆的大小,默认512MB */
#define MAX_VMS_HEAP_SIZE    (512 * MB)

/* 可映射起始地址 */
#define VMS_MAP_START_ADDR  0x60000000

/* 最大可映射的内存的大小,默认256MB */
#define MAX_VMS_MAP_SIZE    (256 * MB)

/* 虚拟内存地址空间描述 */
typedef struct vmspace {
    unsigned long start;    /* 空间开始地址 */
    unsigned long end;      /* 空间结束地址 */
    unsigned long page_prot;     /* 空间保护 */
    unsigned long flags;    /* 空间的标志 */
    vmm_t *vmm;             /* 空间对应的虚拟内存管理 */
    struct vmspace *next;   /* 所有控件构成单向链表 */
} vmspace_t;

#define vmspace_alloc() kmalloc(sizeof(vmspace_t))
#define vmspace_free    kfree


void dump_vmspace(vmm_t *vmm);
void vmspace_insert(vmm_t *vmm, vmspace_t *space);
int do_vmspace_unmap(vmm_t *vmm, unsigned long addr, unsigned long len);
int do_vmspace_map(vmm_t *vmm, unsigned long addr, unsigned long paddr, 
    unsigned long len, unsigned long prot, unsigned long flags);
void *vmspace_mmap(uint32_t addr, uint32_t paddr, uint32_t len, uint32_t prot,
    uint32_t flags);
int vmspace_unmmap(uint32_t addr, uint32_t len);
unsigned long sys_vmspace_heap(unsigned long heap);
unsigned long vmspace_get_unmaped(vmm_t *vmm, unsigned len);

#define sys_munmap  vmspace_unmmap

/**
 * vmspace_init - 初始化虚拟空间
 * 
 */
static inline void vmspace_init(vmspace_t *space, unsigned long start,
    unsigned long end, unsigned long page_prot, unsigned long flags)
{
    space->start = start;
    space->end = end;
    space->page_prot = page_prot;
    space->flags = flags;
    space->vmm = NULL;
    space->next = NULL;
}

static inline void vmspace_remove(vmm_t *vmm, vmspace_t *space, vmspace_t *prev)
{
    if (prev)   /* 没在链表头，位于中间或者后面 */
        prev->next = space->next;
    else    /* 前面没有空间，说明在链表头 */
        vmm->vmspace_head = space->next;    
    vmspace_free(space);
}

static inline vmspace_t *vmspace_find(vmm_t *vmm, unsigned long addr)
{
    vmspace_t *space = vmm->vmspace_head;
    while (space != NULL) {
        if (addr < space->end)  /* 地址小于某个控件结束位置就返回该空间 */
            return space;
        space = space->next;
    }
    return NULL;
}

static inline vmspace_t *vmspace_find_prev(vmm_t *vmm, unsigned long addr, vmspace_t **prev)
{
    *prev = NULL;    /* prev save prev space ptr, set NULL first */
    vmspace_t *space = vmm->vmspace_head;
    while (space != NULL) {
        if (addr < space->end)  /* 地址小于某个控件结束位置就返回该空间 */
            return space;
        *prev = space;   /* save prev */
        space = space->next;
    }
    return NULL;
}

/**
 * vmspace_find_intersection - 查找在指定范围内是否有空间和它相交
 * @vmm: 虚拟内存管理器
 * @start: 起始地址
 * @end: 结束地址
 * 
 * @return: 如果有空间和传入的区域相交，返回对应的空间，没有则返回NULL
 */
static inline vmspace_t *vmspace_find_intersection(vmm_t *vmm,
    unsigned long start, unsigned long end)
{
    vmspace_t *space = vmspace_find(vmm, start);
    if (space && space->start >= end) /* 如果第一个空间的开始大于第二个空间的结束，说明不相交 */
        space = NULL;
    return space;
}



#endif /* _XBOOK_VMSPACE_H */
