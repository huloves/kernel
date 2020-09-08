;文件说明：主引导程序
;创建日期：2020-9-7
;-------------------------------------------------------
SECTION mbr vstart=0x7c00
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

    mov byte [gs:0x00], 'L'
    mov byte [gs:0x01], 0x07
    mov byte [gs:0x02], 'o'
    mov byte [gs:0x03], 0x07
    mov byte [gs:0x04], 'a'
    mov byte [gs:0x05], 0x07
    mov byte [gs:0x06], 'd'
    mov byte [gs:0x07], 0x07
    mov byte [gs:0x08], 'i'
    mov byte [gs:0x09], 0x07
    mov byte [gs:0x0a], 'n'
    mov byte [gs:0x0b], 0x07
    mov byte [gs:0x0c], 'g'
    mov byte [gs:0x0d], 0x07

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