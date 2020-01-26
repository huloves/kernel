#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>

#define INPUTLEN 100

int main()
{
    void intheadler(int);
    void quitheadler(int);
    char input[INPUTLEN];
    int  nchars;

    signal(SIGINT, intheadler);
    signal(SIGQUIT, quitheadler);

    do {
        printf("\nType a message\n");
        nchars = read(0, input, (INPUTLEN-1));
        if(nchars == -1)
            perror("read returned an error");
        else {
            input[nchars] = '\0';
            printf("You type: %s", input);
        }
    }
    while(strncmp(input, "quit", 4) != 0);

    return 0;
}

void intheadler(int s)
{
    printf("Received signal %d .. waiting\n", s);
    sleep(2);
    printf("Leaving intheadler\n");
}

void quitheadler(int s)
{
    printf("Received signal %d .. waiting\n", s);
    sleep(3);
    printf("leaving quitheadler\n");
}
