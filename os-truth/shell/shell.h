#ifndef __SHELL_SHELL_H
#define __SHELL_SHELL_H
#include "file.h"

/*输出提示符*/
void print_prompt(void);
/*简单的shell*/
void my_shell(void);

extern char final_path[MAX_PATH_LEN];

#endif
