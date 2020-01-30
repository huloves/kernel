		;
		;
		;文件说明：硬盘主引导扇区代码
		;创建日期：2020-1-29 18:43

		;设置堆栈段和栈指针
		mov ax,cs
		mov ss,ax
		mov sp,0x7c00

		;计算GDT所在的逻辑段地址
		mov ax,[cs:gdt_base+0x7c00]	;低16位
		mov dx,[cs:gdt_base+0x7c00+2]	;高16位
		mov bx,16
		div bx
		mov ds,ax	;DS指向该段进行操作
		mov bx,dx	;段内偏移地址

		;创建0#描述符，它是空描述符，这是处理器的要求
		mov dword [bx+0x00],0x00
		mov dword [bx+0x04],0x00

		;创建#1描述符，保护模式下的代码段描述符
		mov dword [bx+0x08],0x7c0001ff
		mov dword [bx+0x0c],0x00409800

		;创建#2描述符，保护模式下的数据段描述符（文本模式下的显示缓冲区）
		mov dword [bx+0x10],0x8000ffff
		mov dword [bx+0x14],0x0040920b

		;创建#3描述符，保护模式下的堆栈段描述符
		mov dword [bx+0x18],0x00007a00
		mov dword [bx+0x1c],0x00409600

		;初始化描述符寄存器
		mov word [cs:gdt_size+0x7c00],31	;描述符表的界限（总字节数减一）
		
		lgdt [cs:gdt_size+0x7c00]

		in al,0x92		;南桥芯片内的端口
		or al,0000_0010B
		out 0x92,al		;打开A20

		cli	;保护模式下中断机制尚未建立，应禁止中断

		mov eax,cr0
		or eax,1
		mov cr0,eax	;设置PE位

		;进入保护模式
		jmp dword 0x0008:flush	;16位的段描述符选择子：32位偏移
								;清流水线并串行化处理器
		[bits 32]

	flush:
		mov cx,00000000000_10_000B
		mov ds,cx

		;在屏幕上显示“Protect mode OK.”
		mov byte [0x00],'p'
		mov byte [0x02],'r'
		mov byte [0x04],'o'
		mov byte [0x06],'t'
		mov byte [0x08],'e'
		mov byte [0x0a],'c'
		mov byte [0x0c],'t'
		mov byte [0x0e],' '
		mov byte [0x10],'m'
		mov byte [0x12],'o'
		mov byte [0x14],'d'
		mov byte [0x16],'e'
		mov byte [0x18],' '
		mov byte [0x1a],'O'
		mov byte [0x1c],'K'

		;用简单的实例阐述32位保护模式下的堆栈操作
		mov cx,00000000000_11_000B
		mov ss,cx
		mov esp,0x7c00

		mov ebp,esp
		push byte '.'

		sub ebp,4
		cmp ebp,esp
		jnz ghalt
		pop eax
		mov [0x1e],al

	ghalt:
		hlt

	;-----------------------------------------------
		
		gdt_size dw 0
		gdt_base dd 0x00007e00

		times 510-($-$$) db 0
						 db 0x55,0xaa