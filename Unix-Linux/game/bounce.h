#define BLANK ' '
#define DEL_SYMBOL 'o'
#define TOP_ROW 5
#define BOT_ROW 20
#define LEFT_EDGE 10
#define RIGHT_EDGE 70
#define X_INIT 10 //start
#define Y_INIT 10 //start
#define TICKS_PRE_SEC 50 //affects speed

#define X_TTM 5
#define Y_TTM 8

struct ppball {
    int y_pos, x_pos,
        y_ttm, x_ttm,
        y_ttg, x_ttg,
        y_dir, x_dir;
    char symbol;
};

