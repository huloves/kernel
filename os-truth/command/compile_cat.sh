###### 此脚本在command目录下执行 ######

if [[ ! -d "../lib" || ! -d "../build" ]];then
    echo "dependent dir don\'t exist"
    cwd=$(pwd)
    cwd=${cwd##*/}
    cwd=${cwd%/}
    if [ $cwd != "command" ];then
        echo -e "you\'d better in command dir\n"
    fi
    exit
fi

BIN="cat"
CFLAGS="-nostdinc -m32 -Wall -c -fno-builtin -fno-stack-protector -W -Wstrict-prototypes \
		 -Wmissing-prototypes -Wsystem-headers"
LIB="-I ../lib -I ../lib/user/ -I ../lib/kernel/ -I ../kernel/ -I ../device/ -I ../thread/ \
     -I ../userprog/ -I ../fs/ -I ../shell/"
OBJS="../build/string.o ../build/syscall.o \
      ../build/stdio.o ../build/assert.o start.o ../build/print.o"
DD_IN=$BIN
DD_OUT="/home/huloves/bochs-2.6.11/hd60M.img"

nasm -f elf ./start.s -o ./start.o
ar rcs simple_crt.a $OBJS start.o
gcc $CFLAGS $LIB -o $BIN".o" $BIN".c"
ld -m elf_i386 $BIN".o" simple_crt.a -o $BIN
SET_CNT=$(ls -l $BIN|awk '{printf("%d", ($5+511)/512)}')

if [[ -f $BIN ]];then
    dd if=./$DD_IN of=$DD_OUT bs=512 \
    count=$SET_CNT seek=300 conv=notrunc
fi
