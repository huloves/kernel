		;
		;
		;文件说明：硬盘主引导扇区代码
		;创建日期：2020-1-30 19:55

		core_base_address equ 0x00040000 ;常数，内核加载的起始内存地址
		core_start_section equ 0x00000001;常数，内核的起始逻辑扇区号

		mov ax,cs
		mov ss,ax
		mov sp,0x7c00

		;计算GDT所在的逻辑段地址
		mov eax,[cs:pgdt+0x7c00+0x02]	;GDT的32位物理地址
		xor edx,edx
		mov ebx,16
		div ebx

		mov ds,eax
		mov ebx,edx

		;跳过0#号描述符的槽位
		;创建1#描述符，0~4GB数据段
		mov dword [ebx+0x08],0x7c00ffff
		mov dword [ebx+0x0c],0x00cf9200

		;2# 创建初始化代码段描述符
		mov dword [ebx+0x10],0x7c0001ff
		mov dword [ebx+0x14],0x00409800

		;3# 创建堆栈描述符
		mov dword [ebx+0x18],0x7c00fffe
		mov dword [ebx+0x1c],0x00cf9600

		;4# 显示缓冲区描述符
		mov dword [ebx+0x20],0x80007fff
		mov dword [ebx+0x24],0x0040820b

		;初始化GDTR
		mov dword [cs:pgdt+0x7c00],39

		lgdt [cs:pgdt+0x7c00]

		in al,0x92
		or al,0000_0010B
		out 0x92,al

		cli

		mov eax,cr0
		or eax,1
		mov cr0,eax

		;进入保护模式
		jmp dword 0x0010:flush
		
		[bits 32]
	flush:
		mov eax,0x0008
		mov ds,eax
		
		mov eax,0x0018
		mov ss,eax
		xor esp,esp

		;加载系统核心程序
		mov edi,core_base_address
		
		mov eax,core_start_section
		mov ebx,edi
		call read_hard_disk_0

		;判断程序有多大
		mov eax,[edi]
		xor edx,edx
		mov ecx,512
		div ecx

		or edx,edx
		jnz @1
		dec eax
	@1:
		or eax,eax
		jz setup

		;读取剩余扇区
		mov ecx,eax
		mov eax,core_start_section
		inc eax
	@2:
		call read_hard_disk_0
		inc eax
		loop @2

	setup:
		mov esi,[0x7c00+pgdt+0x02]	;得到GDT的基地址

		;建立公用里程段描述符
		mov eax,[edi+0x04]	;公共例程代码段起始汇编地址
		mov ebx,[edi+0x08]	;核心数据段汇编地址
		sub ebx,eax
		dec ebx	;公共例程段界限
		add eax,edi	;重定位，公共例程基地址
		mov ecx,0x00409800	;描述符属性，字节粒度的代码段描述符
		call make_gdt_descriptor
		mov [esi+0x28],eax
		mov [esi+0x2c],edx

		;建立核心数据段描述符
		mov eax,[edi+0x08]
		mov ebx,[esi+0x0c]
		sub ebx,eax
		dec ebx
		add eax,edi
		mov ecx,0x00409200
		call make_gdt_descriptor
		mov [esi+0x30],eax
		mov [esi+0x34],edx

		;建立核心代码段描述符
		mov eax,[edi+0x0c]
		mov ebx,[edi+0x00]
		sub ebx,eax
		dec ebx
		add eax,edi
		mov ecx,0x00409800
		call make_gdt_descriptor
		mov [esi+0x38],eax
		mov [esi+0x3c],edx

		mov word [0x7c00+pgdt],63

		lgdt [0x7c00+pgdt]

		jmp far [edi+0x10]

	;-----------------------------------------
	read_hard_disk_0:		;从硬盘读取一个逻辑扇区
							;EAX = 逻辑扇区号
							;DS:EBX = 目标缓冲区地址
							;返回：EBX = EBX+512
		push eax
		push ecx
		push edx

		push eax

		mov dx,0x1f2
		mov al,1
		out dx,al	;读取扇区数
		
		inc dx	;0x1f3
		pop eax
		out dx,al	;LBA地址7~0

		inc dx	;0x1f4
		mov cl,8
		shr eax,cl
		out dx,al	;15~8

		inc dx	;0x1f5
		shr eax,cl
		out dx,al	;23~16

		inc dx
		shr eax,cl
		or al,0xe0	;第一硬盘，LBA地址27~24
		out dx,al

		inc dx	;0x1f7，设置命令
		mov al,0x20	;读命令
		out dx,al

	.waits:
		in al,dx
		add al,0x88
		cmp al,0x08
		jnz .waits	;如果EFLAG的ZF位为0，则结果为1，说明硬盘在忙，继续循环，否则的话，继续下面的指令

		mov ecx,256
		mov dx,0x1f0
	.readw:
		in ax,dx
		mov [ebx],ax
		add ebx,2
		loop .readw

		pop edx
		pop ecx
		pop eax

		ret

	;------------------------------------------------
	make_gdt_descriptor:		;构造描述符
								;输入：EAX = 线性基地址
								;	   EBX = 断界限
								;	   ECX = 属性（各属性都在原始
								;			位置，其他没用到的位置0）
								;返回：EDX:EAX = 完整的描述符
		mov edx,eax
		shl eax,16
		or ax,bx	;低32位构造完成

		and edx,0xffff0000
		rol edx,8
		bswap edx	;装配基址的31~24和23~16位

		xor bx,bx
		or edx,ebx	;装配段界限的高4位

		or edx,ecx	;装配属性

		ret

	;------------------------------------------------
		pgdt dw 0
			 dd 0x00007e00
	;------------------------------------------------
		times 510-($-$$) db 0
						 db 0x55,0xaa