#include "stdio.h"
#include "stdint.h"
#include "global.h"
#include "syscall.h"
#include "string.h"
#include "interrupt.h"

#define va_start(ap, v) ap = (va_list)&v   //把ap指向第一个固定参数v，二级指针&v强制转换为一级指针再赋值给ap
#define va_arg(ap, t) *((t*)(ap += 4))   //ap指向下一个参数并返回其值
#define va_end(ap) ap = NULL   //清除ap

/*将整形转换成字符(integer to ascii)*/
//value为待转换的整数，buf_ptr_addr是保存转换结果的缓冲区指针的地址，base是转换的基数
static void itoa(uint32_t value, char** buf_ptr_addr, uint8_t base)
{
    uint32_t m = value % base;   //求模，最先掉下来的是最低位
    uint32_t i = value / base;   //取整
    if(i) {
        itoa(i, buf_ptr_addr, base);
    }
    if(m < 10) {   //如果余数是0~9
        *((*buf_ptr_addr)++) = m + '0';   //将数字0~9转换为字符‘0’～‘9’
    } else {
        *((*buf_ptr_addr)++) = m - 10 + 'A';   //将数字A～F转换为字符‘A’～‘F’
    }
}

uint32_t vsprintf(char* str, const char* format, va_list ap)
{
    char* buf_ptr = str;
    const char* index_ptr = format;
    char index_char = *index_ptr;
    int32_t arg_int;
    char* arg_str;
    while(index_char) {
        if(index_char != '%') {
            *(buf_ptr++) = index_char;
            index_char = *(++index_ptr);
            continue;
        }
        index_char = *(++index_ptr);   //得到%后面的字符
        switch(index_char) {
            case 'x':
                arg_int = va_arg(ap, int);   //获取下一个整形参数
                itoa(arg_int, &buf_ptr, 16);
                index_char = *(++index_ptr);   //跳过格式字符并更新index_char
                break;
            case 's':
                arg_str = va_arg(ap, char*);
                strcpy(buf_ptr, arg_str);
                buf_ptr += strlen(arg_str);
                index_char = *(++index_ptr);
                break;
            case 'c':
                *(buf_ptr++) = va_arg(ap, char);
                index_char = *(++index_ptr);
                break;
            case 'd':
                arg_int = va_arg(ap, int);
                if(arg_int < 0) {
                    arg_int = 0 - arg_int;   //获得相反数
                    *buf_ptr++ = '-';
                }
                itoa(arg_int, &buf_ptr, 10);
                index_char = *(++index_ptr);
                break;
        }
    }
    return strlen(str);
}

uint32_t sprintf(char* buf, const char* format, ...)
{
    va_list args;
    uint32_t retval;
    va_start(args, format);
    retval = vsprintf(buf, format, args);
    va_end(args);
    return retval;
}

/*格式化输出字符串format*/
uint32_t printf(const char* format, ...)
{
    va_list args;
    va_start(args, format);   //使args指向format
    char buf[1024] = {0};   //用于存储拼接后的字符串
    vsprintf(buf, format, args);
    va_end(args);
    return write(buf);
}
