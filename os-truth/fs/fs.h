#ifndef __FS_FS_H
#define __FS_FS_H

#define MAX_FILES_PER_PART 4096   //每个分区所支持的最大创建的文件数，最多建立4096个inode
#define BITS_PER_SECTOR 4096   //每扇区的位数,512(扇区字节大小)*8(一字节位数)
#define SECTOR_SIZE 512   //扇区字节大小
#define BLOCK_SIZE SECTOR_SIZE   //块字节大小

extern struct partition* cur_part;   //默认情况下操作的是哪个分区

/*文件类型*/
enum file_types
{
    FT_UNKNOWN,   //不支持的文件类型
    FT_REGULAR,   //普通文件
    FT_DIRECTORY  //目录
};

/*在磁盘上搜索文件系统，若没有则格式化分区创建文件系统*/
void filesys_init(void);

#endif
