;loader and kernel

;------ FAT12 filesystem mbr information ------
label_start                equ 0x3e  ;要跳转的引导程序在引导扇区中的偏移,3
bytes_per_sector           equ 512   ;每扇区字节数,2
sector_per_cluster         equ 0x1   ;每簇扇区数,1
reserved_sector            equ 0x1   ;保留扇区数,2
number_of_FAT_table        equ 0x2   ;FAT表份数,1
root_entry_count           equ 224   ;根目录可容纳的目录项数,2
total_sector_16            equ 2880     ;总扇区数,2
media_disc                 equ 0xf0  ;介质描述符,1
sector_number_per_FAT      equ 9     ;每FAT扇区数,2
sector_per_track           equ 63    ;每磁道扇区数,2
number_of_heads            equ 16    ;磁头数,2
number_of_hidden_sector    equ 0     ;隐藏扇区数,4
total_sector_32            equ 0     ;如果total_sector_16的大小为0，则用这个值记录扇区数,4
driver_number              equ 0     ;int 0x13的驱动号,1
reserved1                  equ 0     ;保留,1
boot_signature             equ 0x29  ;拓展引导标记,1
vol_id                     equ 0     ;卷序列号,4
;vol_lab                   boot loader   ;卷标,11
;filesys_type              FAT12 ;文件系统类型,8
