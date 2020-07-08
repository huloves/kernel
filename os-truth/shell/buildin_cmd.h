#ifndef __SHELL_BUILDIN_CMD_H
#define __SHELL_BUILDIN_CMD_H
#include "global.h"

/*将path处理成不含..和.的绝对路径，存储在final_path*/
void make_clear_abs_path(char* path, char* final_path);
/*pwd命令的内建函数*/
void buildin_pwd(uint32_t argc, char** argv UNUSED);
/*cd命令的内建函数*/
char* buildin_cd(uint32_t argc, char** argv);
/*cd命令的内建函数*/
char* buildin_cd(uint32_t argc, char** argv);
/* ls命令的内建函数 */
void buildin_ls(uint32_t argc, char** argv);
/*clear命令内建函数*/
void buildin_clear(uint32_t argc, char** argv UNUSED);
/*mkdir命令内建函数*/
int32_t buildin_mkdir(uint32_t argc, char** argv);
/*rmdir命令内建函数*/
int32_t buildin_rmdir(uint32_t argc, char** argv);
/*rm命令内建函数*/
int32_t buildin_rm(uint32_t argc, char** argv);
void buildin_help(int32_t argc, char** argv);

#endif