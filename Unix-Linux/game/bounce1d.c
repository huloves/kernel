#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <curses.h>
#include <string.h>

#include "../my_function/set_ticker.h"

#define MESSAGE "hello"
#define BLANK   "     "

int row; //current row
int col; //current col
int dir; //where we are going

int main()
{
    int delay;
    int ndelay;
    int c;
    void move_msg(int); //handler for timer

    initscr();
    crmode();
    noecho();
    clear();

    row = 10;
    col = 0;
    dir = 1;
    delay = 200; //200ms = 0.2 second

    move(row, col);
    addstr(MESSAGE);
    signal(SIGALRM, move_msg);
    set_ticker(delay);

    while(1) {
        ndelay = 0;
        c = getch();
        if(c == 'Q') break;
        if(c == ' ') dir = -dir;
        if(c == 'f' && delay > 2) ndelay = delay/2;
        if(c == 's') ndelay = delay*2;
        if(ndelay > 0)
            set_ticker(delay = ndelay);
    }

    endwin();

    return 0;
}

void move_msg(int signum)
{
    signal(SIGALRM, move_msg);
    move(row, col);
    addstr(BLANK);
    col += dir;
    move(row, col);
    addstr(MESSAGE);
    refresh();

    //new handler borders
    if(dir == -1 && col <= 0)
        dir = 1;
    else if(dir == 1 && col+strlen(MESSAGE) >= COLS)
        dir = -1;
}
