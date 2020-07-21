#ifndef _LIB_ARCH_CONFIG_H
#define _LIB_ARCH_CONFIG_H

#define __LIB_32B__
//#define __LIB_64B__


#define LIB_ARCH_X86    1
#define LIB_ARCH_X64    2

#define LIB_ARCH        LIB_ARCH_X86

/* 根据不同的平台选择导入头文件 */
#if LIB_ARCH == LIB_ARCH_X86
#include "x86/xchg.h"
#include "x86/atomic.h"
#include "x86/const.h"

#endif



#endif  /* _LIB_ARCH_CONFIG_H */
