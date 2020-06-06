#include "shell.h"
#include "stdint.h"
#include "file.h"
#include "ioqueue.h"
#include "print.h"
#include "string.h"
#include "assert.h"
#include "syscall.h"
#include "global.h"
#include "file.h"

#define cmd_len 128   //最大支持键入128个字符的命令行输入
#define MAX_ARG_NR 16   //加上命令外，最多支持15个参数

/*存储输入的命令*/
static char cmd_line[cmd_len] = {0};
char final_path[MAX_PATH_LEN];

/*用来记录当前目录，是当前目录的缓存，每次执行cd命令时会更新此目录*/
char cwd_cache[64] = {0};

/*输出提示符*/
void print_prompt(void)
{
    printf("huloves@huloves:~%s $ ", cwd_cache);
}

/*从键盘缓冲区中最多读入count个字节到buf*/
static void readline(char* buf, int32_t count)
{
    assert(buf != NULL && count > 0);
    char* pos = buf;
    while(read(stdin_no, pos, 1) != -1 && (pos - buf) < count) {
        switch(*pos) {
            //找到回车或换行符后认为键入的命令结束，直接返回
            case '\n':
            case '\r':
                *pos = 0;   //添加cmd_line的终止字符
                putchar('\n');
                return;
            
            case '\b':
                if(buf[0] != '\b') {   //阻止删除非本次输入的信息
                    --pos;   //退回到缓冲区cmd_line中上一个字符
                    putchar('\b');
                }
                break;

            case 'l'-'a':
                //1. 先将当前字置为0
                *pos = 0;
                //2. 在清空屏幕
                clear();
                //3. 打印提示符
                print_prompt();
                //将之前键入的内容再次打印
                printf("%s", buf);
                break;

            case 'u'-'a':
                while(buf != pos) {
                    putchar('\b');
                    *(pos--) = 0;
                }
                break;

            //非控制键则输出字符
            default:
                putchar(*pos);
                pos++;
        }
    }
    printf("readline: can't find entry_key in the cmd_line, max num of char is 128\n");
}

/*分析字符串cmd_str中以token为分隔符的单词，将各单词的指针存储argv数组*/
static int32_t cmd_parse(char* cmd_str, char** argv, char token)
{
    assert(cmd_str != NULL);
    int32_t arg_idx = 0;
    while(arg_idx < MAX_ARG_NR) {
        argv[arg_idx] = NULL;
        arg_idx++;
    }
    char* next = cmd_str;
    int32_t argc = 0;
    while(*next) {
        //取出命令字或参数之间的空格
        while(*next == token) {
            next++;
        }
        //处理最后一个参数后接空格的情况
        if(*next == 0) {
            break;
        }
        argv[argc] = next;

        //处理命令行汇总的每个命令字及参数
        while(*next && *next != token) {
            next++;
        }

        //如果未结束，是token变为0
        if(*next) {
            *next++ = 0;
        }

        //避免argv数组访问y越界，参数过多则返回-1
        if(argc > MAX_ARG_NR) {
            return -1;
        }
        argc++;
    }
    return argc;
}

char* argv[MAX_ARG_NR];   //argv必须为全局变量，为了以后exec的程序可访问参数
char argc = -1;

/*简单的shell*/
void my_shell(void)
{
    cwd_cache[0] = '/';
    while(1) {
        print_prompt();
        memset(final_path, 0, MAX_PATH_LEN);
        memset(cmd_line, 0, cmd_len);
        readline(cmd_line, cmd_len);
        if(cmd_line[0] == 0) {
            continue;
        }
        argc = -1;
        argc = cmd_parse(cmd_line, argv, ' ');
        if(argc == -1) {
            printf("num of arguments exceed %d\n", MAX_ARG_NR);
            continue;
        }

        int32_t arg_idx = 0;
        while(arg_idx < argc) {
            printf("%s ", argv[arg_idx]);
            arg_idx++;
        }
        printf("\n");
    }
    panic("my_shell: should not be here");
}
