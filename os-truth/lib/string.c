#include "string.h"
#include "global.h"
#include "debug.h"
#include "stdint.h"

/*将dst_起始的size个字节置为value*/
void memset(void* dst_, uint8_t value, uint32_t size)
{
    ASSERT(dst_ != NULL);
    uint8_t* dst = (uint8_t*)dst_;
    while(size-- > 0) {
        *dst++ = value;
    }
}

/*将src_起始的size个字节复制到dst_*/
void memcpy(void* dst_, const void* src_, uint32_t size)
{
    ASSERT(dst_ != NULL && src_ != NULL);
    uint8_t* dst = dst_;
    const uint8_t* src = src_;
    while(size-- > 0) {
        *dst++ = *src++;
    }
}

/*连续比较以地址a_和地址b_开头的size个字节*/
int memcmp(const void* a_, const void* b_, uint32_t size)
{
    const char* a = a_;
    const char* b = b_;
    ASSERT(a != NULL && b != NULL);
    while(size-- > 0) {
        if(*a != *b) {
            return *a > *b ? 1 : -1;
        }
        a++;
        b++;
    }
    return 0;
}

/*将字符串从src_复制到dst_*/
char* strcpy(char* dst_, const char* src_)
{
    ASSERT(dst_ != NULL && src_ != NULL);
    char* r = dst_;   //用来返回目的字符串起始地址
    while((*dst_++ = *src_++));
    return r;
}

/*返回字符串长度*/
uint32_t strlen(const char* str)
{
    ASSERT(str != NULL);
    const char* p = str;
    while(*p++);
    return (p - str -1);
}

/*比较两个字符串*/
int8_t strcmp(const char* a, const char* b)
{
    ASSERT(a != NULL && b != NULL);
    while(*a != 0 && *a == *b) {
        a++;
        b++;
    }
    return *a < *b ? -1 : *a > *b;
}

/*从左到右查找字符串str中首次出现字符ch的地址*/
char* strchr(const char* str, const uint8_t ch)
{
    ASSERT(str != NULL);
    while(*str != 0) {
        if(*str == ch) {
            return (char*)str;
        }
        str++;
    }
    return NULL;
}

/*从后往前找字符串str中首次出现字符ch的地址*/
char* strrchr(const char* str, const uint8_t ch)
{
    ASSERT(str != NULL);
    const char* last_char = NULL;
    while(*str != 0) {
        if(*str == ch) {
            last_char = str;
        }
        str++;
    }
    return (char*)last_char;
}

/*将字符串src_拼接到dst_后，并返回拼接的地址*/
char* strcat(char* dst_, const char* src)
{
    ASSERT(dst_ != NULL && src != NULL);
    char* str = dst_;
    while(*str++);
    --str;
    while((*str++ = *src++));
    return dst_;
}

/*在字符串str中查找ch出现的次数*/
uint32_t strchrs(const char* str, uint8_t ch)
{
    ASSERT(str != NULL);
    uint32_t ch_cnt = 0;
    const char* p = str;
    while(*p != 0) {
        if(*p == ch) {
            ch_cnt++;
        }
        p++;
    }
    return ch_cnt;
}
