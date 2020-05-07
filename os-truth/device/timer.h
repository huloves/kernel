#ifndef __DEVICE_TIMER_H
#define __DEVICE_TIMER_H
#include "stdint.h"

void timer_init(void);   //初始化PIT
/*以毫秒为单位的sleep  1s = 1000ms*/
void mtime_sleep(uint32_t m_seconds);

#endif
