#ifndef __DEVICE_IDE_H
#define __DEVICE_IDE_H
#include "stdint.h"
#include "sync.h"
#include "global.h"
#include "list.h"
#include "bitmap.h"

/*分区结构*/
struct partition
{
    uint32_t start_lba;           //起始扇区
    uint32_t sec_cnt;             //扇区数
    struct disk* my_disk;         //分区所属的硬盘
    struct list_elem part_tag;    //用于队列中的标记
    char name[8];                 //分区名称
    struct super_block* sb;       //本分区的超级块
    struct bitmap block_bitmap;   //块位图，这里一个块由一个扇区组成
    struct bitmap inode_bitmap;   //inode节点位图
    struct list open_inodes;      //本分区打开的inode节点队列
};

/*硬盘结构*/
struct disk
{
    char name[8];   //本硬盘的名称
    struct ide_channel* my_channel;   //此块硬盘归属于哪个ide通道
    uint8_t dev_no;   //本硬盘是主0，还是从1
    struct partition prim_parts[4];   //主分区最多是4个
    struct partition logic_parts[8];   //逻辑分区数量无限，但总得有个支持的上限
};

/*通道结构*/
struct ide_channel
{
    char name[8];   //本ata通道名称
    uint16_t port_base;   //本通道的起始端口号
    uint8_t irq_no;   //本通道所用的中断号
    struct lock lock;   //通道锁
    bool expecting_intr;   //表示等待硬盘的中断，中断处理程序利用此位判断此次的中断是否因为之前的硬盘操作命令引起的
    struct semaphore disk_done;   //用于阻塞、唤醒驱动程序。驱动程序向硬盘发送命令后，在等待硬盘工作期间通过此命令阻塞自己。
    struct disk devices[2];   //一个通道上连接两个硬盘，一主一从
};

/*硬盘数据结构初始化*/
void ide_init();

#endif
