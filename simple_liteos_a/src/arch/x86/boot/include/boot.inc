;------ loader and kernel ------

LOADER_BASE_ADDR    equ 0x900   ;leader加载地址
LOADER_START_SECTOR equ 0x2     ;loader所在扇区

;------------ gdt描述符属性 ------------
;                       G D L AVL    P    S TYPE
DESC_G_4K			equ 1_0_0_0_0000_0_00_0_0000_00000000B
DESC_D_32			equ   1_0_0_0000_0_00_0_0000_00000000B
DESC_L				equ     0_0_0000_0_00_0_0000_00000000B	;64位代码标记,置为0
DESC_AVL			equ       0_0000_0_00_0_0000_00000000B	;CPU不用此位,暂置为0
DESC_LIMIT_CODE2	equ         1111_0_00_0_0000_00000000B	;代码段界限
DESC_LIMIT_DATA2	equ         1111_0_00_0_0000_00000000B	;数据段界限
DESC_LIMIT_VIDEO2	equ          000_0_00_0_0000_00000000B	;?
DESC_P				equ              1_00_0_0000_00000000B
DESC_DPL_0			equ                00_0_0000_00000000B
DESC_DPL_1			equ                01_0_0000_00000000B
DESC_DPL_2			equ                10_0_0000_00000000B
DESC_DPL_3			equ                11_0_0000_00000000B
DESC_S_CODE			equ                   1_0000_00000000B
DESC_S_DATA			equ                   1_0000_00000000B
DESC_S_sys			equ                   0_0000_00000000B
DESC_TYPE_CODE		equ                     1000_00000000B	;x=1,c=0,r=0,a=0,可执行,非一致性(非依从),不可读,已访问位a清0
DESC_TYPE_DATA		equ                     0010_00000000B	;x=0,e=0,w=1,a=0,不可执行,向上扩展,可写,已访问位清0

DESC_CODE_HIGH4		equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
DESC_DATA_HIGH4		equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
DESC_VIDEO_HIGH4	equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b

;------------ 选择子属性 ------------
RPL0	equ   00B
RPL1	equ   01B
RPL2	equ   10B
RPL3	equ   11B
TI_GDT	equ 0_00B
TI_LDT	equ 1_00B
