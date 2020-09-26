# all:

# #tools
# MAKE = make
# RM = rm
# DD = dd
# MKDIR = mkdir

# #virtual machine
# QEMU = qemu-system-i386
# BOCHS = bochs

# #kernel boot binary

BUILD_DIR = ./build
ENTRY_POINT = 0xc0001500
DISK_IMG = hd60M.img
AS = nasm
CC = gcc
LD = ld

ASMINLIB = -I src/arch/x86/boot/include/

CFLAGS = -m32 -Wall -c -D NDBUG -fno-builtin -fno-stack-protector -W -Wstrict-prototypes \
		 -Wmissing-prototypes

LDFLAGS = -m elf_i386 -Ttext $(ENTRY_POINT) -e main -Map $(BUILD_DIR)/kernel.map

OBJS = $(BUILD_DIR)/main.o

###### MBR代码编译 ######
$(BUILD_DIR)/mbr.bin: src/arch/x86/boot/mbr.asm
	$(AS) $(ASMINLIB) $< -o $@

$(BUILD_DIR)/loader.bin: src/arch/x86/boot/loader.asm
	$(AS) $(ASMINLIB) $< -o $@

###### c代码编译 ######
$(BUILD_DIR)/main.o: kernel/main.c
	$(CC) $(CFLAGS) $< -o $@

###### 连接所有文件 ######
$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

.PHONY: mk_dir hd clean all

mk_dir:
	if [ ! -d $(BUILD_DIR) ]; then mkdir $(BUILD_DIR);fi

hd:
	dd if=$(BUILD_DIR)/mbr.bin \
		of=/home/huloves/bochs-2.6.11/my_hd60M.img \
		bs=512 count=1 conv=notrunc

	dd if=$(BUILD_DIR)/loader.bin \
		of=/home/huloves/bochs-2.6.11/my_hd60M.img \
		bs=512 seek=2 count=4 conv=notrunc
	
	dd if=$(BUILD_DIR)/kernel.bin \
		of=/home/huloves/bochs-2.6.11/my_hd60M.img \
		bs=512 seek=9 count=200 conv=notrunc

clean:
	cd $(BUILD_DIR) && rm -f ./*

build: $(BUILD_DIR)/kernel.bin $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/loader.bin

all: mk_dir build hd
