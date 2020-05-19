#include "fs.h"
#include "super_block.h"
#include "inode.h"
#include "dir.h"
#include "stdint.h"
#include "stdio-kernel.h"
#include "list.h"
#include "string.h"
#include "ide.h"
#include "global.h"
#include "debug.h"
#include "memory.h"
#include "file.h"
#include "console.h"

struct partition* cur_part;   //默认情况下操作的是哪个分区

/*在分区链表中找到名为part_name的分区，并将其指针赋值给cur_part*/
static bool mount_partition(struct list_elem* pelem, int arg)
{
    char* part_name = (char*)arg;
    struct partition* part = elem2entry(struct partition, part_tag, pelem);
    if(!strcmp(part->name, part_name)) {
        cur_part = part;
        struct disk* hd = cur_part->my_disk;

        //sb_buf用来存储在硬盘上读入的超级块
        struct super_block* sb_buf = (struct super_block*)sys_malloc(SECTOR_SIZE);

        //在内存中创建分区cur_part的超级块
        cur_part->sb = (struct super_block*)sys_malloc(sizeof(struct super_block));
        if(cur_part->sb == NULL) {
            PANIC("alloc memory failed!");
        }

        //读入超级块
        memset(sb_buf, 0, SECTOR_SIZE);
        ide_read(hd, cur_part->start_lba + 1, sb_buf, 1);
        memcpy(cur_part->sb, sb_buf, sizeof(struct super_block));

        //将硬盘上的块位图读入内存
        cur_part->block_bitmap.bits = (uint8_t*)sys_malloc(sb_buf->block_bitmap_sects * SECTOR_SIZE);
        if(cur_part->block_bitmap.bits == NULL) {
            PANIC("alloc memory failed!");
        }
        cur_part->block_bitmap.btmp_bytes_len = sb_buf->block_bitmap_sects * SECTOR_SIZE;
        ide_read(hd, sb_buf->block_bitmap_lba, cur_part->block_bitmap.bits, sb_buf->block_bitmap_sects);

        //将硬盘上的inode位图读入内存
        cur_part->inode_bitmap.bits = (uint8_t*)sys_malloc(sb_buf->inode_bitmap_sects * SECTOR_SIZE);
        if(cur_part->inode_bitmap.bits == NULL) {
            PANIC("alloc memory failed!");
        }
        cur_part->inode_bitmap.btmp_bytes_len = sb_buf->inode_bitmap_sects * SECTOR_SIZE;
        ide_read(hd, sb_buf->inode_bitmap_lba, cur_part->inode_bitmap.bits, sb_buf->inode_bitmap_sects);

        list_init(&cur_part->open_inodes);
        printk("mount %s done!\n", part->name);

        return true;   //使list_traversal停止遍历
    }
    return false;   //使list_traversal继续遍历
}

/*格式化分区，也就是初始化分区的元信息，创建文件系统*/
static void partition_format(struct partition* part)
{
    //block_bitmap_init 为方便实现，一个块大小是以扇区
    uint32_t boot_sector_sects = 1;   //ebr扇区
    uint32_t super_block_sects = 1;   //超级块扇区
    uint32_t inode_bitmap_sects = DIV_ROUND_UP(MAX_FILES_PER_PART, BITS_PER_SECTOR);   //i节点位图占用的扇区数，最多支持4096个文件
    uint32_t inode_table_sects = DIV_ROUND_UP(((sizeof(struct inode) * MAX_FILES_PER_PART)), SECTOR_SIZE);   //inode表扇区数
    uint32_t used_sects = boot_sector_sects + super_block_sects + inode_bitmap_sects + inode_table_sects;   //已使用扇区数
    uint32_t free_sects = part->sec_cnt - used_sects;   //分区中空闲扇区数

    // 简单处理块位图占据的扇区数
    uint32_t block_bitmap_sects;
    block_bitmap_sects = DIV_ROUND_UP(free_sects, BITS_PER_SECTOR);
    uint32_t block_bitmap_bit_len = free_sects - block_bitmap_sects;   //位图中位的长度，也是可用块的数量
    block_bitmap_sects = DIV_ROUND_UP(block_bitmap_bit_len, BITS_PER_SECTOR);

    // 超级块初始化
    struct super_block sb;
    sb.magic = 0x19590318;
    sb.sec_cnt = part->sec_cnt;
    sb.inode_cnt = MAX_FILES_PER_PART;
    sb.part_lba_base = part->start_lba;

    sb.block_bitmap_lba = sb.part_lba_base + 2;   //第0块是引导块，第1块是超级块
    sb.block_bitmap_sects = block_bitmap_sects;

    sb.inode_bitmap_lba = sb.block_bitmap_lba + sb.block_bitmap_sects;
    sb.inode_bitmap_sects = inode_bitmap_sects;

    sb.inode_table_lba = sb.inode_bitmap_lba + sb.inode_bitmap_sects;
    sb.inode_table_sects = inode_table_sects;

    sb.data_start_lba = sb.inode_table_lba + sb.inode_table_sects;
    sb.root_inode_no = 0;   //super_block inode-number
    sb.dir_entry_size = sizeof(struct dir_entry);

    printk("%s info:\n", part->name);
    //printk("   magic:0x%x\n   part_lba_base:0x%x\n   all_sectors:0x%x\n   inode_cnt:0x%x\n   block_bitmap_lba:%x\n   block_bitmap_sectors:0x%x\n   inode_bitmap_lba:0x%x\n   inode_bitmap_sectors:0x%x\n   inode_table_lba:0x%x\n   inode_table_sectors:0x%x\n   data_start_lba:0x%x\n", \
    //       sb.magic, sb.part_lba_base, sb.sec_cnt, sb.inode_cnt, sb.block_bitmap_lba, sb.block_bitmap_sects, sb.inode_bitmap_lba, \
    //       sb.inode_bitmap_sects, sb.inode_table_lba, sb.inode_table_sects, sb.data_start_lba);
    printk("   magic:0x%x\n   part_lba_base:0x%x\n   all_sectors:0x%x\n   inode_cnt:0x%x\n   block_bitmap_lba:0x%x\n   block_bitmap_sectors:0x%x\n   inode_bitmap_lba:0x%x\n   inode_bitmap_sectors:0x%x\n   inode_table_lba:0x%x\n   inode_table_sectors:0x%x\n   data_start_lba:0x%x\n", sb.magic, sb.part_lba_base, sb.sec_cnt, sb.inode_cnt, sb.block_bitmap_lba, sb.block_bitmap_sects, sb.inode_bitmap_lba, sb.inode_bitmap_sects, sb.inode_table_lba, sb.inode_table_sects, sb.data_start_lba);

    struct disk* hd = part->my_disk;
    // 1. 将超级块写入本分区的1扇区
    ide_write(hd, part->start_lba + 1, &sb, 1);   //跨过引导扇区
    printk("   super_block_lba:0x%x\n", part->start_lba + 1);

    // 找出数据量最大的元信息，用其尺寸做存储缓冲区
    uint32_t buf_size = (sb.block_bitmap_sects >= sb.inode_bitmap_sects ? sb.block_bitmap_sects : sb.inode_bitmap_sects);
    buf_size = (buf_size >= sb.inode_table_sects ? buf_size : sb.inode_table_sects) * SECTOR_SIZE;   //最终缓冲区大小
    uint8_t* buf = (uint8_t*)sys_malloc(buf_size);   //申请的内存由内存管理系统清0后返回

    // 2. 将块位图初始化并写入sb.block_bitmap_lba
    // 初始化块位图
    buf[0] |= 0x01;   //第0个块预留给根目录，位图中先占位
    uint32_t block_bitmap_last_byte = block_bitmap_bit_len / 8;
    uint8_t block_bitmap_last_bit = block_bitmap_bit_len % 8;
    uint32_t last_size = SECTOR_SIZE - (block_bitmap_last_byte % SECTOR_SIZE);   //位图所在最有一个扇区中，不足一扇区的其余部分

    // ①先将位图的最后一字节到其所在的扇区的结束全置为1，即超出实际块数的部分直接置为已占用
    memset(&buf[block_bitmap_last_byte], 0xff, last_size);
    // ②再将上一步中覆盖的最后一字节内的有效位重新置0
    uint8_t bit_idx = 0;
    while(bit_idx <= block_bitmap_last_bit) {
        buf[block_bitmap_last_byte] &= ~(1 << bit_idx++);
    }
    ide_write(hd, sb.block_bitmap_lba, buf, sb.block_bitmap_sects);   //写入硬盘

    // 3. 将inode位图初始化并写入sb.inode_bitmap_lba
    memset(buf, 0, buf_size);   //清空缓冲区
    buf[0] |= 0x1;   //第0个inode分配给了根目录
    ide_write(hd, sb.inode_bitmap_lba, buf, sb.inode_bitmap_sects);   //inode_bitmap占一个扇区没有无效位，直接写入硬盘

    // 4. 将inode数组初始化并写入sb.inode_table_lba
    memset(buf, 0, buf_size);
    struct inode* i = (struct inode*)buf;
    i->i_size = sb.dir_entry_size * 2;   //初始化根目录inode .和..
    i->i_no = 0;   //根目录占inode数组中第0个inode
    i->i_sectors[0] = sb.data_start_lba;   //由于上面的memset，i_sectors数组的其他元素都初始化为0
    ide_write(hd, sb.inode_table_lba, buf, sb.inode_table_sects);

    // 5. 将根目录写入sb.data_start_lba
    memset(buf, 0, buf_size);
    struct dir_entry* p_de = (struct dir_entry*)buf;
    
    // 初始化当前目录"."
    memcpy(p_de->filename, ".", 1);
    p_de->i_no = 0;
    p_de->f_type = FT_DIRECTORY;
    p_de++;

    // 初始化当前目录父目录
    memcpy(p_de->filename, "..", 2);
    p_de->i_no = 0;
    p_de->f_type = FT_DIRECTORY;

    //sb.data_start_lba已经分配给根目录，里面是根目录的目录项
    ide_write(hd, sb.data_start_lba, buf, 1);

    printk("   root_dir_lba:0x%x\n", sb.data_start_lba);
    printk("%s format done\n", part->name);
    sys_free(buf);
}

/*将最上层路径名称解析出来，name_store用于存储最上层路径名
功能：将最上层路径名称解析出来存储到name_store中，调用结束后返回除顶层路径之外的子路径字符串地址*/
static char* path_parse(char* pathname, char* name_store)
{
    if(pathname[0] == '/') {
        while(*(++pathname) == '/');   //路径中出现1个或多个连续的字符'/'跳过，如"///a/b"
    }

    //开始一般的路径解析
    while(*pathname != '/' && *pathname != 0) {
        *name_store++ = *pathname++;
    }

    if(pathname[0] == 0) {
        return NULL;
    }
    return pathname;
}

/*返回路径深度，比如/a/b/c，深度为3*/
int32_t path_depth_cnt(char* pathname)
{
    ASSERT(pathname != NULL);
    char* p = pathname;
    char name[MAX_FILE_NAME_LEN];   //用于path_parse的参数做路径解析
    uint32_t depth = 0;

    //解析路径，从中拆分出各级名称
    p = path_parse(p, name);
    while(name[0]) {
        depth++;
        memset(name, 0, MAX_FILE_NAME_LEN);
        if(p) {
            p = path_parse(p, name);
        }
    }

    return depth;
}

/*搜索文件pathname，若找到则返回其inode号，否则返回-1。搜索记录指针searched_record*/
static int search_file(const char* pathname, struct path_search_record* searched_record)
{
    //若带查找的是根目录，直接返回已知根目录xinxi
    if(!strcmp(pathname, "/") || !strcmp(pathname, "/.") || !strcmp(pathname, "/..")) {
        searched_record->parent_dir = &root_dir;
        searched_record->file_type = FT_DIRECTORY;
        searched_record->searched_path[0] = 0;   //搜索路径置空
        return 0;
    }

    uint32_t path_len = strlen(pathname);
    ASSERT(pathname[0] == '/' && path_len > 1 && path_len < MAX_PATH_LEN);   //保证pathname至少是这样的路径/x，且小于最大长度
    
    char* sub_path = (char*)pathname;
    struct dir* parent_dir = &root_dir;
    struct dir_entry dir_e;
    char name[MAX_FILE_NAME_LEN] = {0};   //记录路径解析出来的各级名称，如路径“/a/b/c”，数组name每次的值分别是a, b, c

    searched_record->parent_dir = parent_dir;
    searched_record->file_type = FT_UNKNOWN;
    uint32_t parent_inode_no = 0;   //父目录的inode号，备份各层解析出来的路径的父目录的inode编号

    sub_path = path_parse(sub_path, name);
    while(name[0]) {
        //记录查找过的路径，但不能超过searched_path的长度512字节
        ASSERT(strlen(searched_record->searched_path) < 512);

        //记录已存在的父目录
        strcat(searched_record->searched_path, "/");
        strcat(searched_record->searched_path, name);

        //在所给的目录中查找文件
        if(search_dir_entry(cur_part, parent_dir, name, &dir_e)) {
            memset(name, 0, MAX_FILE_NAME_LEN);
            //若sub_path不等于NULL，也就是未结束时继续拆分路径
            if(sub_path) {
                sub_path = path_parse(sub_path, name);
            }

            if(FT_DIRECTORY == dir_e.f_type) {   //如果被打开的是目录
                parent_inode_no = parent_dir->inode->i_no;
                dir_close(parent_dir);
                parent_dir = dir_open(cur_part, dir_e.i_no);   //更新父目录
                searched_record->parent_dir = parent_dir;
                continue;
            } else if(FT_REGULAR == dir_e.f_type) {   //如果是普通文件
                searched_record->file_type = FT_REGULAR;
                return dir_e.i_no;
            }
        } else {   //若找不到，则返回-1
            return -1;
        }
    }

    //执行到此，已经遍历了完整路径，并且查找的文件或目录只有同名目录存在
    dir_close(searched_record->parent_dir);

    //保证被查找目录的直接父目录
    searched_record->parent_dir = dir_open(cur_part, parent_inode_no);
    searched_record->file_type = FT_DIRECTORY;
    return dir_e.i_no;
}

/*打开或创建文件成功后，返回文件描述符，否则返回-1*/
int32_t sys_open(const char* pathname, uint8_t flags)
{
    //对目录要用dir_open这里只有open文件
    if(pathname[strlen(pathname) - 1] == '/') {
        printk("can't open a directory %s\n", pathname);
        return -1;
    }
    ASSERT(flags <= 7);
    int32_t fd = -1;   //默认找不到

    struct path_search_record searched_record;   //记录文件查找时所遍历过的目录
    memset(&searched_record, 0, sizeof(struct path_search_record));

    //记录目录深度，帮助判断中间某个目录不存在的情况
    uint32_t pathname_depth = path_depth_cnt((char*)pathname);

    //先检查文件是否存在
    int inode_no = search_file(pathname, &searched_record);
    bool found = inode_no != -1 ? true : false;

    if(searched_record.file_type == FT_DIRECTORY) {
        printk("can't open a directory with open(), use opendir() to instead\n");
        dir_close(searched_record.parent_dir);
        return -1;
    }

    uint32_t path_search_depth = path_depth_cnt(searched_record.searched_path);

    //先判断是否把pathname的各层目录都访问到了，即是否在某个中间目录就失败了
    if(pathname_depth != path_search_depth) {
        printk("cannot access %s: not a directory, subpath %s is't exist\n", pathname, searched_record.searched_path);
        dir_close(searched_record.parent_dir);
        return -1;
    }

    //若是在最后一个路径上没找到，并且不是要创建文件，直接返回-1
    if(!found && !(flags & O_CREAT)) {
        printk("in path %s, file %s isn't exist\n", searched_record.searched_path, (strrchr(searched_record.searched_path, '/') + 1));
        dir_close(searched_record.parent_dir);
        return -1;
    } else if(found && flags & O_CREAT) {
        printk("%s has already exist\n", pathname);
        dir_close(searched_record.parent_dir);
        return -1;
    }

    switch(flags & O_CREAT) {
        case O_CREAT:
            printk("creating file\n");
            fd = file_create(searched_record.parent_dir, (strrchr(pathname, '/') + 1), flags);
            printk("sys_open: fd = %d\n", fd);
            dir_close(searched_record.parent_dir);
        //其余为打开文件
        default:
            fd = file_open(inode_no, flags);
    }

    return fd;
}

/*将文件描述符转化为文件表的下标*/
static uint32_t fd_local2global(uint32_t local_fd)
{
    struct task_struct* cur = running_thread();
    int32_t global_fd = cur->fd_table[local_fd];
    ASSERT(global_fd >=0 && global_fd < MAX_FILE_OPEN);
    return (uint32_t)global_fd;
}

/*关闭文件描述符fd指向的文件，成功返回0，失败则返回-1*/
int32_t sys_close(int32_t fd)
{
    int32_t ret = -1;   //返回值默认为-1，即失败
    if(fd > 2) {
        uint32_t _fd = fd_local2global(fd);
        ret = file_close(&file_table[_fd]);
        running_thread()->fd_table[fd] = -1;   //使该文件描述符可用
    }
    return ret;
}

/*将buf中连续count个字节写入文件描述符fd，成功则返回写入的字节数，失败返回-1*/
int sys_write(int32_t fd, const void* buf, uint32_t count)
{
    if(fd < 0) {
        printk("sys_write: fd error\n");
        return -1;
    }
    if(fd == stdout_no) {
        char tmp_buf[1024] = {0};
        memcpy(tmp_buf, buf, count);
        console_put_str(tmp_buf);
        return count;
    }
    uint32_t _fd = fd_local2global(fd);
    //printk("_fd = %d\n", _fd);
    struct file* wr_file = &file_table[_fd];
    if(wr_file->fd_flag & O_WRONLY || wr_file->fd_flag & O_RDWR) {
        uint32_t bytes_written = file_write(wr_file, buf, count);
        return bytes_written;
    } else {
        console_put_str("sys_write: not allowed to write file without flag O_RDWR or O_WRONLY");
        return -1;
    }
}

/*在磁盘上搜索文件系统，若没有则格式化分区创建文件系统*/
void filesys_init()
{
    uint8_t channel_no = 0, dev_no, part_idx = 0;

    //sb_buf用来存储硬盘上读入的超级块
    struct super_block* sb_buf = (struct super_block*)sys_malloc(SECTOR_SIZE);

    if(sb_buf == NULL) {
        PANIC("alloc memory failed!");
    }
    printk("searching filesystem......\n");
    while(channel_no < channel_cnt) {
        dev_no = 0;
        while(dev_no < 2) {
            if(dev_no == 0) {
                dev_no++;
                continue;
            }
            struct disk* hd = &channels[channel_no].devices[dev_no];
            struct partition* part = hd->prim_parts;
            while(part_idx < 12) {   //4个主分区+8个逻辑分区
                if(part_idx == 4) {
                    part = hd->logic_parts;
                }            
                //partition中的成员默认为0.若partition未初始化，则partition的成员仍未0
                //处理存在的分区
                if(part->sec_cnt != 0) {
                    memset(sb_buf, 0, SECTOR_SIZE);

                    //读取分区的超级块，分局魔数是否正确来判断是否存在文件系统
                    ide_read(hd, part->start_lba + 1, sb_buf, 1);
                    //只支持自己的文件系统，若磁盘上已经有文件系统就不在格式化了
                    if(sb_buf->magic == 0x19590318) {
                        printk("%s has filesystem\n", part->name);
                    } else {
                        printk("formatting %s's partition %s......\n", hd->name, part->name);
                        partition_format(part);
                    }
                }
                part_idx++;
                part++;   //下一个分区
            }
            dev_no++;   //下一个磁盘
        }
        channel_no++;   //下一个通道
    }
    sys_free(sb_buf);
    
    //确认默认操作的分区
    char default_part[8] = "sdb1";
    //挂载分区
    list_traversal(&partition_list, mount_partition, (int)default_part);

    //将当前分区的根目录打开
    open_root_dir(cur_part);

    //初始化文件表
    uint32_t fd_idx = 0;
    while(fd_idx < MAX_FILE_OPEN) {
        file_table[fd_idx++].fd_inode = NULL;
    }
    printk("filesys init done!!!!!!\n");
}
