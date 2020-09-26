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
DISK_IMG = hd60M.img
AS = nasm
CC = gcc
LD = ld

ASMINLIB = -I src/arch/x86/boot/include/

###### MBR代码编译 ######
$(BUILD_DIR)/mbr.bin: src/arch/x86/boot/mbr.asm
	$(AS) $(ASMINLIB) $< -o $@

$(BUILD_DIR)/loader.bin: src/arch/x86/boot/loader.asm
	$(AS) $(ASMINLIB) $< -o $@

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

clean:
	cd $(BUILD_DIR) && rm -f ./*

build: $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/loader.bin

all: mk_dir build hd
