#include <stdio.h>
#include <unistd.h>
#include <pthread.h>

void* thread_func(void* _arg)
{
    unsigned int* arg = _arg;
    printf(" new thread: my tid is %u\n", *arg);
}

int main()
{
    pthread_t new_thread_id;
    pthread_create(&new_thread_id, NULL, thread_func, &new_thread_id);
    printf("main thread: my tid is %lu\n", pthread_self());
    usleep(100);
}