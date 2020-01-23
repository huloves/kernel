#include <stdio.h>
#include <curses.h>

int main()
{
    int i;

    initscr();
    clear();
    for(i=0; i<LINES; i++) {
        move(i, i+1);
        if(i % 2 == 1)
            standout();
        addstr("Hello, World");
        if(i % 2 == 1)
            standend();
    }
    refresh();
    getch();
    endwin();

    return 0;
}
