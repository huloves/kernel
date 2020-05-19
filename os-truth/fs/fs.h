#ifndef __FS_FS_H
#define __FS_FS_H
#include "stdint.h"

#define MAX_FILES_PER_PART 4096   //每个分区所支持的最大创建的文件数，最多建立4096个inode
#define BITS_PER_SECTOR 4096   //每扇区的位数,512(扇区字节大小)*8(一字节位数)
#define SECTOR_SIZE 512   //扇区字节大小
#define BLOCK_SIZE SECTOR_SIZE   //块字节大小

#define MAX_PATH_LEN 512   //路径最大长度

extern struct partition* cur_part;   //默认情况下操作的是哪个分区

/*文件类型*/
enum file_types
{
    FT_UNKNOWN,   //0 不支持的文件类型
    FT_REGULAR,   //1 普通文件
    FT_DIRECTORY  //2 目录
};

/*打开文件的选项*/
enum oflags
{
    O_RDONLY,   //001
    O_WRONLY,   //001
    O_RDWR,     //011
    O_CREAT = 4 //100
};

/*记录查找文件过程中已找到的上级路径，也就是查找文件过程中“走过的地方”*/
struct path_search_record
{
    char searched_path[MAX_PATH_LEN];   //查找过程中的父路径，查找过程中不存在的路径
    struct dir* parent_dir;   //文件或目录所在的直接父目录
    enum file_types file_type;   //找到的是普通文件，还是目录，找不到将为未知类型
};

/*返回路径深度，比如/a/b/c，深度为3*/
int32_t path_depth_cnt(char* pathname);
/*打开或创建文件成功后，返回文件描述符，否则返回-1*/
int32_t sys_open(const char* pathname, uint8_t flags);
/*关闭文件描述符fd指向的文件，成功返回0，失败则返回-1*/
int32_t sys_close(int32_t fd);
/*将buf中连续count个字节写入文件描述符fd，成功则返回写入的字节数，失败返回-1*/
int sys_write(int32_t fd, const void* buf, uint32_t count);
/*在磁盘上搜索文件系统，若没有则格式化分区创建文件系统*/
void filesys_init(void);

#endif
