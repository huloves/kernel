#include "ide.h"
#include "stdint.h"
#include "global.h"
#include "stdio.h"
#include "stdio-kernel.h"
#include "debug.h"
#include "io.h"
#include "timer.h"
#include "interrupt.h"

//ata通道不同寄存器的端口
#define reg_data(channel)       (channel->port_base + 0)
#define reg_error(channel)      (channel->port_base + 1)
#define reg_sect_cnt(channel)   (channel->port_base + 2)
#define reg_lba_l(channel)      (channel->port_base + 3)
#define reg_lba_m(channel)      (channel->port_base + 4)
#define reg_lba_h(channel)      (channel->port_base + 5)
#define reg_dev(channel)        (channel->port_base + 6)
#define reg_status(channel)     (channel->port_base + 7)
#define reg_cmd(channel)        (reg_status(channel))
#define reg_alt_status(channel) (channel->port_base + 0x206)
#define reg_ctl(channel)        reg_alt_status(channel)

/*reg_status寄存器的一些关键位*/
#define BIT_ALT_STAT_BSY        0x80   //硬盘忙，勿扰
#define BIT_ALT_STAT_DRDY       0x40   //驱动器准备好，等待命令
#define BIT_ALT_STAT_DRQ        0x8    //数据传输准备好了，随时可以输出

/*device寄存器的一些关键位*/
#define BIT_DEV_MBS     0xa0   //MBS位，第7,5位固定位1
#define BIT_DEV_LBA     0x40   //lba模式
#define BIT_DEV_DEV     0x10   //主盘，从盘

/*一些硬盘操作的指令*/
#define CMD_IDENTIFY        0xec   //identify指令，硬盘识别，用来获取硬盘的身份信息
#define CMD_READ_SECTOR     0x20   //读扇区指令
#define CMD_WRITE_SECTOR    0x30   //写扇区指令

/*定义可读写的最大扇区数，调试用的*/
#define max_lba ((80*1024*1024/512) - 1)   //只支持80MB硬盘

uint8_t channel_cnt;   //按硬盘数计算的通道数
struct ide_channel channels[2];   //通道数组，有两个ide通道

/*用于记录总扩展分区的起始lba，初始为0，partition_scan时以此为标记*/
int32_t ext_lba_base = 0;

uint8_t p_no = 0, l_no = 0;   //用来记录硬盘主分区和逻辑分区的下标

struct list partition_list;   //分区队列

/*构建16字节大小的结构体，用来存分区表项*/
struct partition_table_entry
{
    uint8_t bootable;   //是否可引导
    uint8_t start_head;   //起始磁头号
    uint8_t start_sec;    //起始扇区号
    uint8_t start_chs;    //起始柱面号
    uint8_t fs_type;      //分区类型
    uint8_t end_head;     //结束磁头号
    uint8_t end_sec;      //结束扇区号
    uint8_t end_chs;      //结束柱面号
    //注意下面这两项
    uint32_t start_lba;   //本分区起始扇区的lba地址
    uint32_t sec_cnt;     //本分区的扇区数目
}__attribute__ ((packed));   //保证此结构是16字节大小。__attribute__是gcc特有的关键字，用于告诉gcc在编译时做特殊处理
                             //packed是特殊处理“压缩”，不允许编译器为对齐而在此结构中填充空隙

/*引导扇区，mbr或ebr所在的扇区*/
struct boot_sector
{
    uint8_t other[446];   //引导代码
    struct partition_table_entry partition_table[4];   //4个分区表项，共64字节
    uint16_t signature;   //启动扇区的结束标志是0x55,0xaa
}__attribute__ ((packed));

/*选择读写的硬盘，选择待操作的硬盘是主盘还是从盘*/
static void select_disk(struct disk* hd)
{
    uint8_t reg_device = BIT_DEV_MBS | BIT_DEV_LBA;
    if(hd->dev_no == 1) {   //如果是从盘，设置DEV位为1
        reg_device |= BIT_DEV_DEV;
    }
    outb(reg_dev(hd->my_channel), reg_device);
}

/*向硬盘控制器写入起始扇区地址及要读写的扇区数*/
static void select_sector(struct disk* hd, uint32_t lba, uint8_t sec_cnt)
{
    ASSERT(lba <= max_lba);
    struct ide_channel* channel = hd->my_channel;

    //写入读写的扇区数
    outb(reg_sect_cnt(channel), sec_cnt);   //如果sec_cnt 为0，则表示写入256个扇区

    //写入lba地址，即扇区号
    outb(reg_lba_l(channel), lba);   //lba地址的低8位
    outb(reg_lba_m(channel), lba >> 8);   //lba地址的8~15位
    outb(reg_lba_h(channel), lba >> 16);   //lba地址的16~23位

    //lba地址的24~27位要存储在device寄存器的0~3位，无法单独写入这四位，所以此处把device寄存器再重新写入一次
    outb(reg_dev(channel), BIT_DEV_MBS | BIT_DEV_LBA | (hd->dev_no == 1 ? BIT_DEV_DEV : 0) | lba >> 24);
}

/*向通道channel发命令cmd*/
static void cmd_out(struct ide_channel* channel, uint8_t cmd)
{
    //只要向硬盘发了命令便将此标记置为true，硬盘中断处理程序需要根据它来判断
    channel->expecting_intr = true;
    outb(reg_cmd(channel), cmd);
}

/*硬盘hd读入sec_cnt个扇区的数据到buf*/
static void read_from_sector(struct disk* hd, void* buf, uint8_t sec_cnt)
{
    uint32_t size_in_byte;
    if(sec_cnt == 0) {
        //因为sec_cnt是8为变量，由主调函数将其复制，若为256则将最高位的1丢掉变为0
        size_in_byte = 256 * 512;
    } else {
        size_in_byte = sec_cnt * 512;
    }
    insw(reg_data(hd->my_channel), buf, size_in_byte / 2);
}

/*将buf中sec_cnt扇区的数据写入硬盘hd*/
static void write2sector(struct disk* hd, void* buf, uint8_t sec_cnt)
{
    uint32_t size_in_byte;
    if(sec_cnt == 0) {
        size_in_byte = 256 * 512;
    } else {
        size_in_byte = sec_cnt * 512;
    }
    outsw(reg_data(hd->my_channel), buf, size_in_byte / 2);
}

/*等待30s，函数为忙等待，一般忙等待是指cpu空转*/
static bool busy_wait(struct disk* hd)
{
    struct ide_channel* channel = hd->my_channel;
    uint16_t time_limit = 30 * 1000;   //可以等待3000ms
    while(time_limit -= 10 >= 0) {
        if(!(inb(reg_status(channel)) & BIT_ALT_STAT_BSY)) {
            return (inb(reg_status(channel)) & BIT_ALT_STAT_DRQ);   //DRQ位为1表示硬盘已经准备号数据了
        } else {
            mtime_sleep(10);
        }
    }
    return false;
}

/*从硬盘读取sec_cnt个扇区到buf*/
void ide_read(struct disk* hd, uint32_t lba, void* buf, uint32_t sec_cnt)
{
    ASSERT(lba <= max_lba);
    ASSERT(sec_cnt > 0);
    lock_acquire(&hd->my_channel->lock);

    //1. 选择操作的硬盘
    select_disk(hd);

    uint32_t secs_op;   //每次操作的扇区数
    uint32_t secs_done = 0;   //已完成的扇区数
    while(secs_done < sec_cnt) {
        if((secs_done + 256) <= sec_cnt) {
            secs_op = 256;
        } else {
            secs_op = sec_cnt - secs_done;
        }

        //2. 写入待读取的扇区数和起始扇区号
        select_sector(hd, lba + secs_done, secs_op);

        //3. 执行的命令写入reg_cmd寄存器
        cmd_out(hd->my_channel, CMD_READ_SECTOR);   //准备开始读数据

        //阻塞自己的时机
        //在硬盘已经开始工作后才能阻塞自己，将自己阻塞，等待硬盘完成读操作后通过中断处理程序唤醒自己
        sema_down(&hd->my_channel->disk_done);

        //4. 检测硬盘状态是否可读，醒来后执行下面的代码
        if(!busy_wait(hd)) {
            char error[64];
            sprintf(error, "%s, read sector %d failed!!!!!!\n", hd->name, lba);
            PANIC(error);
        }

        //5. 把数据从硬盘的缓冲区中读出
        read_from_sector(hd, (void*)((uint32_t)buf + secs_done * 512), secs_op);
        secs_done += secs_op;
    }
    lock_release(&hd->my_channel->lock);
}

/*将buf中sec_cnt扇区数据写入硬盘*/
void ide_write(struct disk* hd, uint32_t lba, void* buf, uint32_t sec_cnt)
{
    ASSERT(lba <= max_lba);
    ASSERT(sec_cnt > 0);
    lock_acquire(&hd->my_channel->lock);

    //1. 选择要操作的硬盘
    select_disk(hd);

    uint32_t secs_op;   //每次操作的扇区数
    uint32_t secs_done;   //已完成的扇区数
    while(secs_done < sec_cnt) {
        if(secs_done + 256 < sec_cnt) {
            secs_op = 256;
        } else {
            secs_op = sec_cnt - secs_done;
        }

        //2. 写入待写入的扇区数和起始扇区号
        select_sector(hd, lba + secs_done, secs_op);

        //3. 执行的命令写入reg_cmd寄存器
        cmd_out(hd->my_channel, CMD_WRITE_SECTOR);   //准备写数据

        //4. 检测硬盘状态是否可读
        if(!busy_wait(hd)) {
            char error[64];
            sprintf(error, "%s write sector %d failed!!!!!!\n", hd->name, lba);
            PANIC(error);
        }

        //5. 将数据写入硬盘
        write2sector(hd, (void*)((uint32_t)buf + secs_done * 512), secs_op);

        //在硬盘响应期间阻塞自己
        sema_down(&hd->my_channel->disk_done);
        secs_done += secs_op;
    }
    lock_release(&hd->my_channel->lock);
}

/*硬盘中断处理程序*/
void intr_hd_handler(uint8_t irq_no)
{
    ASSERT(irq_no == 0x2e || irq_no == 0x2f);
    uint8_t ch_no = irq_no - 0x2e;   //获取通道号
    struct ide_channel* channel = &channels[ch_no];
    ASSERT(channel->irq_no == irq_no);
    //不用担心此中断是否对应的是这一次的expecting_intr，每次读写硬盘时会申请锁，从而保证同步一致性
    if(channel->expecting_intr) {
        channel->expecting_intr = false;
        sema_up(&channel->disk_done);

        //读取状态寄存器是硬盘控制器认为此次的中断已被处理，从而硬盘可以继续执行新的读写
        inb(reg_status(channel));
    }
}

/*将dst中len个相邻字节交换位置后存入buf*/
static void swap_pairs_bytes(const char* dst, char* buf, uint32_t len)
{
    uint8_t idx;
    for(idx = 0; idx < len; idx += 2) {
        buf[idx + 1] = *dst++;
        buf[idx] = *dst++;
    }
    buf[idx] = '\0';
}

/*获得硬盘参数信息*/
static void identify_disk(struct disk* hd)
{
    char id_info[512];
    select_disk(hd);   //通道上选择硬盘
    cmd_out(hd->my_channel, CMD_IDENTIFY);   //通道cmd寄存器写入命令

    sema_down(&hd->my_channel->disk_done);   //等待硬盘准备好数据

    //醒来后执行下面的代码
    if(!busy_wait(hd)) {
        char error[64];
        sprintf(error, "%s identify failed!!!!!!\n", hd->name);
        PANIC(error);
    }
    read_from_sector(hd, id_info, 1);   //将硬盘的信息读入到id_info中

    char buf[64];
    uint8_t sn_start = 10 * 2, sn_len = 20, md_start = 27 * 2, md_len = 40;
    swap_pairs_bytes(&id_info[sn_start], buf, sn_len);
    printk("      MODULE: %s\n", buf);
    uint32_t sectors = *(uint32_t)&id_info[60 * 2];
    printk("      SECTORS: %d\n", sectors);
    printk("      CAPACITY: %dMB\n", sectors * 512 / 1024 / 1024);
}

/*硬盘数据结构初始化*/
void ide_init()
{
    printk("ide_init start\n");
    uint8_t hd_cnt = *((uint8_t*)(0x475));   //获取硬盘数量
    ASSERT(hd_cnt > 0);
    channel_cnt = DIV_ROUND_UP(hd_cnt, 2);   //hd_cnt向上取整，一个ide通道上有两个硬盘，根据硬盘数量反推有几个ide。
    
    struct ide_channel* channel;
    uint8_t channel_no = 0;

    /*处理每个通道上的硬盘*/
    while(channel_no < channel_cnt) {
        channel = &channels[channel_no];
        sprintf(channel->name, "ide%d", channel_no);   //ide0, ide1

        /*为每个ide通道初始化端口基址及中断向量*/
        switch(channel_no) {
            case 0:
                channel->port_base = 0x1f0;
                channel->irq_no = 0x20 + 14;   //0x2e 从片8259A上倒数第二个中断引脚-硬盘，也就是ide0的中断向量号
                break;
            case 1:
                channel->port_base = 0x170;
                channel->irq_no = 0x20 + 15;   //0x2f 8259A最后一个中断引脚，用来响应ide1通道上的硬盘中断
                break;
        }

        channel->expecting_intr = false;   //未向硬盘写入指令时不期待硬盘的中断
        lock_init(&channel->lock);
        //信号量初始化为0，目的是向硬盘控制器请求数据后，硬盘驱动sema_down此信号会阻塞线程，知道硬盘完成后通过发中断
        //由中断处理程序将此信号量sema_up，唤醒线程
        sema_init(&channel->disk_done, 0);

        register_handler(channel->irq_no, intr_hd_handler);
        channel_no++;
    }
    printk("ide_init done\n");
}
