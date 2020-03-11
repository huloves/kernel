#ifndef __KERNEL_INTERRUPT_H
#define __KERNEL_INTERRUPT_H

typedef void* intr_handler;

void idt_init();   //完成中断的所有初始化工作

#endif