#include <stdio.h>
#include <unistd.h>
#include <signal.h>

//#define SHHH

int main()
{
    void wakeup(int);

    printf("about to aleep for 4 second\n");
    signal(SIGALRM, wakeup);
    alarm(4);
    pause();
    printf("Morning so soon? \n");

    return 0;
}

void wakeup(int signum)
{
# ifndef SHHH
    printf("Alarm received form kernel\n");
    printf("signum = %d\n", signum);
# endif
}
