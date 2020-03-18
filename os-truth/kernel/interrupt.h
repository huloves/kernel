#ifndef __KERNEL_INTERRUPT_H
#define __KERNEL_INTERRUPT_H
#include "stdint.h"

typedef void* intr_handler;

/*定义中断的两种状态：
    INTR_OFF值为0，表示关中断
    INTR_ON值为1，表示开中断*/
enum intr_status        //中断状态
{
    INTR_OFF,           //中断关闭,0
    INTR_ON             //中断打开,1
};

enum intr_status intr_get_status(void);
enum intr_status intr_set_status(enum intr_status);
enum intr_status intr_enable(void);
enum intr_status intr_disable(void);

void idt_init(void);   //完成中断的所有初始化工作

#endif