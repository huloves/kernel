#include "inode.h"
#include "stdint.h"
#include "ide.h"
#include "super_block.h"
#include "dir.h"
#include "fs.h"
#include "global.h"
#include "debug.h"
#include "string.h"
#include "interrupt.h"
#include "file.h"

/*记录inode所在的扇区地址及在扇区内的偏移量，用于定位inode在磁盘上的位置*/
struct inode_position
{
    bool two_sec;   //是够跨扇区
    uint32_t sec_lba;   //inode所在的扇区号
    uint32_t off_size;   //inode在扇区内的字节偏移量
};

/*获取第inode_no个inode所在扇区和扇区内的偏移量*/
static void inode_locate(struct partition* part, uint32_t inode_no, struct inode_position* inode_pos)
{
    ASSERT(inode_no < 4096);
    uint32_t inode_table_lba = part->sb->inode_table_lba;

    uint32_t inode_size = sizeof(struct inode);
    uint32_t off_size = inode_no * inode_size;   //第inode_no个i节点相对于inode_table_lba的字节偏移量
    uint32_t off_sec = off_size / 512;   //第inode_no个i节点相对于inode_table_lba的扇区偏移量
    uint32_t off_size_in_sec = off_size % 512;   //待查找的inode在所在扇区中的起始字节地址

    //判断i节点是够跨过2个扇区
    uint32_t left_in_sec = 512 - off_size_in_sec;
    if(left_in_sec < inode_size) {
        inode_pos->two_sec = true;
    } else {
        inode_pos->two_sec = false;
    }
    inode_pos->sec_lba = inode_table_lba + off_sec;
    inode_pos->off_size = off_size_in_sec;
}

/*将inode写入到分区part，io_buf是用于硬盘io的缓冲区*/
void inode_sync(struct partition* part, struct inode* inode, void* io_buf)
{
    uint8_t inode_no = inode->i_no;
    struct inode_position inode_pos;
    inode_locate(part, inode_no, &inode_pos);   //inode位置信息会存入inode_pos
    ASSERT(inode_pos.sec_lba <= (part->start_lba + part->sec_cnt));

    //硬盘中的inode中的成员inode_tag个i_open_snts是不需要的，只存在于内UC那种记录链表位置和被多少进程共享
    struct inode pure_inode;
    memcpy(&pure_inode, inode, sizeof(struct inode));

    //一下的sane成员只存在内存中
    pure_inode.i_open_cnts = 0;
    pure_inode.write_deny = false;   //置为false，保证在硬盘中读出时为可写
    pure_inode.inode_tag.prev = pure_inode.inode_tag.next = NULL;

    char* inode_buf = (char*)io_buf;
    if(inode_pos.two_sec) {
        //读写硬盘是以扇区为单位，若写入的数据小于一扇区，将原硬盘的内容先读出来再和新数据拼接成一扇区后写入
        ide_read(part->my_disk, inode_pos.sec_lba, inode_buf, 2);
        memcpy((inode_buf + inode_pos.off_size), &pure_inode, sizeof(struct inode));
        ide_write(part->my_disk, inode_pos.sec_lba, inode_buf, 2);
    } else {
        ide_read(part->my_disk, inode_pos.sec_lba, inode_buf, 1);
        memcpy((inode_buf + inode_pos.off_size), &pure_inode, sizeof(struct inode));
        ide_write(part->my_disk, inode_pos.sec_lba, inode_buf, 1);
    }
}

/*根据i节点号返回相应的i节点*/
struct inode* inode_open(struct partition* part, uint32_t inode_no)
{
    //先在已打开的inode链表中找inode，此链表是为提速创建的缓冲区
    struct list_elem* elem = part->open_inodes.head.next;
    struct inode* inode_found;
    while(elem != &part->open_inodes.tail) {
        inode_found = elem2entry(struct inode, inode_tag, elem);
        if(inode_found->i_no == inode_no) {
            inode_found->i_open_cnts++;
            return inode_found;
        }
        elem = elem->next;
    }

    //由于open_inodes链表中找不到，从硬盘上读取此inode并加入到此链表
    struct inode_position inode_pos;
    inode_locate(part, inode_no, &inode_pos);   //定位此inode

    //为使通过sys_malloc创建的新inode被所有任务共享，需要将inode只与内核空间
    //所以需要临时将cur_pcb->pgdir置为NULL
    struct task_struct* cur = running_thread();
    uint32_t* cur_pagedir_bak = cur->pgdir;
    cur->pgdir = NULL;   //后面分配的内存将位于内核区
    inode_found = (struct indoe*)sys_malloc(sizeof(struct inode));
    cur->pgdir = cur_pagedir_bak;   //恢复pgdir

    char* inode_buf;   //从硬盘读取inode的缓冲区
    if(inode_pos.two_sec) {
        inode_buf = (char*)sys_malloc(1024);
        ide_read(part->my_disk, inode_pos.sec_lba, inode_buf, 2);
    } else {
        inode_buf = (char*)sys_malloc(512);
        ide_read(part->my_disk, inode_pos.sec_lba, inode_buf, 1);
    }
    memcpy(inode_found, inode_buf + inode_pos.off_size, sizeof(struct inode));

    //根据程序局部性原理，一会很可能会用到此inode，将其插入到队首便于提前检索到
    list_push(&part->open_inodes, &inode_found->inode_tag);
    inode_found->i_open_cnts = 1;
    
    sys_free(inode_buf);
    return inode_found;
}

/*关闭inode或减少inode的打开数*/
void inode_close(struct inode* inode)
{
    //若没有进程在打开此文件，将此inode去掉并释放空间
    enum intr_status old_status = intr_disable();
    if(--inode->i_open_cnts == 0) {
        list_remove(&inode->inode_tag);   //将i节点从part->open_inodes中去掉
        //释放inode空间，该部分内存在内核空间
        struct task_struct* cur = running_thread();
        uint32_t* cur_pagedir_bak = cur->pgdir;
        cur->pgdir = NULL;
        sys_free(inode);
        cur->pgdir = cur_pagedir_bak;
    }
    intr_set_status(old_status);
}

/*初始化new_indoe*/
void inode_init(uint32_t inode_no, struct inode* new_inode)
{
    new_inode->i_no = inode_no;
    new_inode->i_size = 0;
    new_inode->i_open_cnts = 0;
    new_inode->write_deny = false;

    //初始化索引数组i_sector
    uint8_t sec_idx = 0;
    while(sec_idx < 13) {
        new_inode->i_sectors[sec_idx] = 0;
        sec_idx++;
    }
}

/*将硬盘分区part上的inode清空*/
void inode_delete(struct partition* part, uint32_t inode_no, void* io_buf)
{
    ASSERT(inode_no < 4096);
    struct inode_position inode_pos;
    inode_locate(part, inode_no, &inode_pos);   //inode位置信息会存入inode_pos
    ASSERT(inode_pos.sec_lba <= (part->start_lba + part->sec_cnt));

    char* inode_buf = (char*)io_buf;
    if(inode_pos.two_sec) {   //inode跨扇区，读入2个扇区
        ide_read(part->my_disk, inode_pos.sec_lba, inode_buf, 2);
        memset((inode_buf + inode_pos.off_size), 0, sizeof(struct inode));   //将inode_buf清0
        ide_write(part->my_disk, inode_pos.sec_lba, inode_buf, 2);   //用清0的内存数据覆盖磁盘
    } else {
        ide_read(part->my_disk, inode_pos.sec_lba, inode_buf, 1);
        memset((inode_buf + inode_pos.off_size), 0, sizeof(struct inode));
        ide_write(part->my_disk, inode_pos.sec_lba, inode_buf, 1);
    }
}

/*回收inode的数据块和inode本身*/
void inode_release(struct partition* part, uint32_t inode_no)
{
    struct inode* inode_to_del = inode_open(part, inode_no);
    ASSERT(inode_to_del->i_no == inode_no);

    //1. 回收inode占用的所有块
    uint8_t block_idx = 0, block_cnt = 12;
    uint32_t block_bitmap_idx;
    uint32_t all_blocks[140] = {0};   //12个直接块 + 128个间接块

    //a 先将前12个直接块存入all_blocks
    while(block_idx < 12) {
        all_blocks[block_idx] = inode_to_del->i_sectors[block_idx];
        block_idx++;
    }

    //b 如果一级间接块表存在，将其128个间接块索引读到all_blocks[12~]，并释放一级间接块表所占的扇区
    if(inode_to_del->i_sectors[12] != 0) {
        ide_read(part->my_disk, inode_to_del->i_sectors[12], all_blocks + 12, 1);
        block_cnt = 140;

        //回收一级间接块表占用的扇区
        block_bitmap_idx = inode_to_del->i_sectors[12] - part->sb->data_start_lba;
        ASSERT(block_bitmap_idx > 0);
        bitmap_set(&part->block_bitmap, block_bitmap_idx, 0);
        bitmap_sync(cur_part, block_bitmap_idx, BLOCK_BITMAP);
    }

    //c inode所有的块地址已经收集到all_blocks中，下面逐个回收
    block_idx = 0;
    while(block_idx < block_cnt) {
        if(all_blocks[block_idx] != 0) {
            block_bitmap_idx = 0;
            block_bitmap_idx = all_blocks[block_idx] - part->sb->data_start_lba;
            ASSERT(block_bitmap_idx > 0);
            bitmap_set(&part->block_bitmap, block_bitmap_idx, 0);
            bitmap_sync(cur_part, block_bitmap_idx, BLOCK_BITMAP);
        }
        block_idx++;
    }

    //2. 回收该inode所占用的inode
    bitmap_set(&part->inode_bitmap, inode_no, 0);
    bitmap_sync(cur_part, inode_no, INODE_BITMAP);

    //一下inode_delete是调试用
    void* io_buf = sys_malloc(1024);
    inode_delete(part, inode_no, io_buf);
    sys_free(io_buf);

    inode_close(inode_to_del);
}
