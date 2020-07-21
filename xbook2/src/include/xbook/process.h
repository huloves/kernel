#ifndef _XBOOK_PROCESS_H
#define _XBOOK_PROCESS_H

#include "task.h"
#include "elf32.h"
#include "rawblock.h"
#include <sys/kfile.h>

task_t *process_create(char *name, char **argv);
int proc_destroy(task_t *task, int thread);
int proc_vmm_init(task_t *task);
int proc_vmm_exit(task_t *task);
int proc_build_arg(unsigned long arg_top, unsigned long *arg_bottom, char *argv[], char **dest_argv[]);
int proc_stack_init(task_t *task, trap_frame_t *frame, char **argv);
void proc_heap_init(task_t *task);
void proc_map_space_init(task_t *task);
int proc_load_image(vmm_t *vmm, struct Elf32_Ehdr *elf_header, raw_block_t *rb);
void proc_make_trap_frame(task_t *task);
int proc_release(task_t *task);
int proc_trigger_init(task_t *task);
int proc_pthread_init(task_t *task);

int thread_release_resource(task_t *task);

int sys_fork();
void sys_exit(int status);
pid_t sys_waitpid(pid_t pid, int *status, int options);
int sys_exec_raw(char *name, char **argv);
int sys_exec_file(char *name, kfile_t *file, char **argv);

#endif /* _XBOOK_PROCESS_H */
