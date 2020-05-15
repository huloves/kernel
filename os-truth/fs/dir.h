#ifndef __FS_DIR_H
#define __FS_DIR_H
#include "stdint.h"
#include "inode.h"
#include "fs.h"

#define MAX_FILE_NAME_LEN 16   //最大文件名长度

/*目录结构*/
struct dir
{
    struct inode* inode;   //该目录对应的inode，用于指向内存中的inode
    uint32_t dir_pos;      //记录在目录内的偏移
    uint8_t dir_buf[512];  //目录的数据缓存
};

/*目录项结构*/
struct dir_entry
{
    char filename[MAX_FILE_NAME_LEN];   //不同文件或目录名称
    uint32_t i_no;   //不同文件或目录对应的inode编号
    enum file_types f_type;   //文件类型
};

/*打开根目录*/
void open_dir(struct partition* part);
/*在分区part上打开i节点为inode_no的目录并返回目录指针*/
struct dir* dir_open(struct partition* part, uint32_t inode_no);

#endif
