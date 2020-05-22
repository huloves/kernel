#ifndef __FS_INODE_H
#define __FS_INODE_H
#include "stdint.h"
#include "global.h"
#include "list.h"
#include "ide.h"

/*inode结构*/
struct inode
{
    uint32_t i_no;         //inode编号

    uint32_t i_size;       //当此inode是文件时，i_size是指文件大小，若是目录，i_size是指目录下所有目录项大小之和

    uint32_t i_open_cnts;   //记录此文件被打开的次数
    bool write_deny;        //写文件不能并行，进程写文件前检查此标志

    uint32_t i_sectors[13]; //0~11是直接块，12永远存储一级间接块指针
    struct list_elem inode_tag;   //此inode的标识，用于加入已打开的inode列表
};

/*将inode写入到分区part，io_buf是用于硬盘io的缓冲区*/
void inode_sync(struct partition* part, struct inode* inode, void* io_buf);
/*根据i节点号返回相应的i节点*/
struct inode* inode_open(struct partition* part, uint32_t inode_no);
/*关闭inode或减少inode的打开数*/
void inode_close(struct inode* inode);
/*初始化new_indoe*/
void inode_init(uint32_t inode_no, struct inode* new_inode);
/*将硬盘分区part上的inode清空*/
void inode_delete(struct partition* part, uint32_t inode_no, void* io_buf);
/*回收inode的数据块和inode本身*/
void inode_release(struct partition* part, uint32_t inode_no);

#endif
