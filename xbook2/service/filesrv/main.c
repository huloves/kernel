#include <sys/res.h>
#include <sys/vmm.h>
#include <sys/proc.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/trigger.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <sys/kfile.h>
#include <sys/ipc.h>
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <spin.h>

#include <drivers/disk.h>
#include <fsal/fsal.h>
#include <core/filesrv.h>
#include <core/if.h>
#include "fatfs/ff.h"

#define DEBUG_LOCAL 0

/*
File Service struct:
+-----------------------+
| 文件系统接口           |
| 文件系统环境           |
\                       /
+-----------------------+
| 文件系统抽象层         |
\                       /
+-----------------------+
| FATFS | SIMPLE FS     |
\                       /
+-----------------------+
| 驱动                  |
+-----------------------+
*/

/**
 * filesrv - 文件服务
 */
int main(int argc, char *argv[])
{
    
    /* 绑定成为服务调用 */
    if (srvcall_bind(SRV_FS)  == -1)  {
        srvprint("bind srvcall failed, service stopped!\n");
        return -1;
    }
    
    /* 初始化子进程 */
    if (init_child_proc()) {
        srvprint("execute failed, service stopped!\n");
        return -1;
    }
      
    /* 初始化驱动 */
    if (init_disk_driver() < 0) {
        srvprint("init disk driver failed, service stopped!\n");
        return -1;
    }
    
    /* 初始化服务核心 */
    if (init_srvcore() < 0) {
        srvprint("init srvcore failed, service stopped!\n");
        return -1;
    }

    /* 初始化文件系统抽象层 */
    if (init_fsal() < 0) {
        srvprint("init fsal failed, service stopped!\n");
        return -1;
    }
    
    /* 处理服务 */
    srvprint("enter receving request state.\n");
    int seq;
    srvarg_t srvarg;
    int callnum;
    while (1)
    {
        memset(&srvarg, 0, sizeof(srvarg_t));
        /* 1.监听服务 */
        if (srvcall_listen(SRV_FS, &srvarg)) {  
            continue;
        }
 
        /* 2.处理服务 */
        callnum = GETSRV_DATA(&srvarg, 0, int);

#if DEBUG_LOCAL == 1
        srvprint("srvcall seq=%d call num %d.\n", seq, callnum);
#endif
        if (callnum >= 0 && callnum < FILESRV_CALL_NR) {
            filesrv_call_table[callnum](&srvarg);
        }
       
        seq++;
        /* 3.应答服务 */
        srvcall_ack(SRV_FS, &srvarg);   
    }
    return 0;
}
