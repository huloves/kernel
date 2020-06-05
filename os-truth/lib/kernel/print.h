#ifndef __LIB_KERNEL_PRINT_H
#define __LIB_KERNEL_PRINT_H
#include "stdint.h"

void put_char(uint8_t char_sici);
void put_str(char* message);
void put_int(uint32_t num);         //以十六进制打印
void set_cursor(uint32_t pos);
void cls_screen(void);

#endif
