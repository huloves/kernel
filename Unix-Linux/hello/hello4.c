#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <curses.h>

int main()
{
    int i;

    initscr();
        clear();
        for(i=0; i<LINES; i++) {
            move(i, i+1);
            if(i%2 == 1) 
                standout();
            addstr("hello, world");
            if(i%2 == 1)
                standend();
            refresh();
            sleep(1);
            move(i, i+1);
            addstr("             ");
        }
    endwin();

    return 0;
}
