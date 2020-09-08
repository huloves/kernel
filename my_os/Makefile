BUILD_DIR = ./build
AS = nasm
CC = gcc
LD = ld
ASFLAGS = -f elf

#编译boot汇编文件
boot.bin: boot.asm
	$(AS) -f bin $< -o $@

.PHONY : hd

#写入虚拟硬盘
hd:
	dd if=boot.bin \
		of=/home/huloves/bochs-2.6.11/my_hd60M.img \
		bs=512 count=1 conv=notrunc

build: boot.bin

all: build hd