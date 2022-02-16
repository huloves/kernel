#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/time.h>
#include <signal.h>
#include "../my_function/set_ticker.h"

// typedef unsigned long uint64_t;

uint64_t ticks;

void signal_headler(int signum)
{
    printf("ticks = %lld\n", ticks++);
}

int main()
{
    void countdown(int);

    // signal(SIGALRM, countdown);
    signal(SIGALRM, signal_headler);
    if(set_ticker(1) == -1) {
        perror("set_ticker");
    }
    else {
        while(1) {
            pause();
        }
    }
    return 0;
}

void countdown(int signum)
{
    static int num = 10;
    printf("%d..", num--);
    fflush(stdout);
    if(num < 0) {
        printf("DOWN! \n");
        exit(0);
    }
}

/*int set_ticker(int n_msecs)
{
    struct itimerval new_timeset;
    long n_sec, n_usecs;

    n_sec = n_msecs / 1000;
    n_usecs = (n_msecs % 1000) * 1000L;

    new_timeset.it_interval.tv_sec = n_sec;
    new_timeset.it_interval.tv_usec = n_usecs;

    new_timeset.it_value.tv_sec = n_sec;
    new_timeset.it_value.tv_usec = n_usecs;

    return setitimer(ITIMER_REAL, &new_timeset, NULL);
}*/
