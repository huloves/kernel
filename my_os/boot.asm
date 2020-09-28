;文件说明：主引导程序
;创建日期：2020-9-7
;-------------------------------------------------------
	org 0x7c00

	base_of_stack     equ 0x7c00
	base_of_loader    equ 0x1000
	off_set_of_loader equ 0x00

	root_dir_sectors             equ 14
	sector_num_of_root_dir_start equ 19
	sector_num_of_fat1_start     equ 1
	sector_balance               equ 17

	jmp short label_start
	nop
	BS_OEMName  db 'MINEboot'
	BPB_BytesPerSec  dw 512
	BPB_SecPerClus   db 1
	BPB_RsvdSecCnt   dw 1
	BPB_NumFATs      db 2
	BPB_RootEntCnt   dw 224
	BPB_TotSec16     dw 2880
	BPB_Media        db 0xf0
	BPB_FATSz16      dw 9
	BPB_SecPerTrk    dw 18
	BPB_NumHeads     dw 2
	BPB_HiddSec      dd 0
	BPB_TotSec32     dd 0
	BS_DrvNum        db 0
	BS_Reserved1     db 0
	BS_BootSig       db 0x29
	BS_VolID         dd 0
	BS_VolLab        db 'boot leader'
	BS_FileSysType   db 'FAT12'

label_start:
    mov ax,cx
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax

;清屏
;利用0x06号功能,上卷全部行,则可清屏
;---------------------------------------
;INT 0x10 功能号:0x06 功能描述:上卷窗口
;---------------------------------------
;输入:
;AH 功能号= 0x06
;AL = 上卷的行数(如果为0,表示全部)
;BH = 上卷行的属性
;(CL,CH) = 窗口左上角的(X,Y)位置
;(DL,DH) = 窗口右下角的(X,Y)位置
;无返回值:
    mov ax,0x0600
    mov bx,0x0700
    mov cx,0					;左上角:(0,0)
    mov dx,0x184f				;右下角:(80,25)
								;VGA文本模式,一行容纳80个字符,共25行
								;下标从0开始,0x18=24,0x4f=80
    int 0x10					;int 0x10

	;set focus
	mov ax, 0x0200
	mov bx, 0x0000
	mov dx, 0x0000
	int 0x10

	;display on screen : Start Booting
	mov ax, 0x1301
	mov bx, 0x000f
	mov dx, 0x0000
	mov cx, 10
	push ax
	mov ax, ds
	mov es, ax
	pop ax
	mov bp, StartBootMessage
	int 0x10

	jmp $

StartBootMessage: db "Start Boot"

;------------------------------------------------------
read_hard_disk_0:			    ;从硬盘读取一个扇区
								;输入：DI:SI = 起始逻辑扇区号
								;	   DS:BX = 目标缓冲区地址
	push ax
	push bx
	push cx
	push dx

	mov dx,0x1f2
	mov al,1
	out dx,al	;读取的扇区数

	inc dx		;0x1f3
	mov ax,si
	out dx,al	;LBA地址7~0

	inc dx		;0x1f4
	mov al,ah
	out dx,al	;LBA地址15~8

	inc dx		;0x1f5
	mov ax,di
	out dx,al	;LBA地址23~16

	inc dx		;0x1f6
	mov al, 0xe0	;LBA28模式，主盘
	or al,ah	;LBA地址27~24
	out dx,al

	inc dx		;0x1f7
	mov al,0x20	;读命令
	out dx,al

.waits:
	in al,dx
	and al,0x88
	cmp al,0x08
	jnz .waits	;不忙，且硬盘已准备好数据传输

	mov cx,256	;总共要读取的字数
	mov dx,0x1f0
.readw:
	in ax,dx
	mov [bx],ax
	add bx,2
	loop .readw

	pop dx
	pop cx
	pop bx
	pop ax

	ret

;-------------------------------------------------------

infi: jmp near infi   ;循环悬停

times 510-($-$$) db 0
                 db 0x55, 0xaa