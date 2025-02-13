		;代码清单6-1
		;文件名： c06_mbr.asm
		;文件说明： 硬盘主引导扇区代码
		;创建日期： 2020-1-27 23:26

		jmp near start

	mytext db 'L',0x07,'e',0x07,'b',0x07,'e',0x07,'l',0x07,' ',0x07,'o',0x07,\
			  'f',0x07,'f',0x07,'s',0x07,'e',0x07,'t',0x07,':',0x07
	number db 0,0,0,0,0

	start:
		mov ax,0x7c0
		mov ds,ax

		mov ax,0xb800
		mov es,ax
			   
		cld ;显示文本mytext
		mov si,mytext
		mov di,0
		mov cx,(number-mytext)/2 ;13字
		rep movsw

		;得到标号所代表的偏移地址
		mov ax,number

		;计算各个位数
		mov bx,ax
		mov cx,5
		mov si,10 ;除数
	digit:
		xor dx,dx
		div si
		mov[bx],dl
		inc bx
		loop digit

		;显示各个数位
		mov bx,number
		mov si,4
	show:
		mov al,[bx+si]
		add al,0x30
		mov ah,0x04
		mov [es:di],ax
		add di,2
		dec si
		jns show

		mov word [es:di],0x0744

		jmp near $

	times 510-($-$$) db 0
					 db 0x55,0xaa