	;
	;
	;文件说明：硬盘主引导扇区代码
	;创建如期：2020-2-7 17:44

	core_base_address	equ	0x00040000		;内核加载的起始内存地址
	core_start_sector	equ 0x00000001		;内核起始逻辑扇区号

;=====================================================================
SECTION mbr vstart=0x00007c00

	mov ax,cs
	mov ss,ax
	mov sp,0x7c00

	;计算GDT所在的逻辑段地址
	mov eax,[cs:pgdt+0x02]					;gdt的32位物理地址
	xor edx,edx
	mov ebx,16
	div ebx									;分解成16位逻辑地址

	mov ds,eax								;ds指向gdt段
	mov ebx,edx								;ebx为段内偏移地址

	;跳过0#号描述符槽位
	;创建1#描述符，保护模式下的代码段描述符
	mov dword [ebx+0x08],0x0000ffff			;基地址为0，界限0xfffff，DPL=0
	mov dword [ebx+0x0c],0x00cf9800			;4KB粒度，代码段描述符，向上扩展
	
	;创建2#描述符，保护模式下的数据段和堆栈段描述符
	mov dword [ebx+0x10],0x0000ffff			;基地址为0，界限0xfffff，DPL=0
	mov dword [ebx+0x14],0x00cf9200			;4KB粒度，数据段描述符，向上扩展
	
	;初始化描述符表寄存器GDTR
	mov word [cs:pgdt],23					;描述符界限

	lgdt [es:pgdt]

	in al,0x92								;南桥芯片内的端口
	or al,0000_0010B
	out 0x92,al								;打开A20

	cli										;关闭中断，中断机制尚未工作

	mov eax,cr0
	or eax,1
	mov cr0,eax								;设置PE位，打开保护模式

	;进入保护模式
	jmp dword 0x0008:flush

	[bits 32]
flush:
	mov eax,0x0010							;加载数据段，0000 0000 0001 0000
	mov ds,eax
	mov es,eax
	mov fs,eax
	mov gs,eax
	mov ss,eax
	mov esp,0x7000							;堆栈指针

	;加载系统核心程序
	mov edi,core_base_address

	mov eax,core_start_sector
	mov ebx,edi								;起始地址
	call read_hard_disk_0					;读取程序的起始部分（一个扇区）
	
	;判断系统核心程序大小
	mov eax,[edi]
	xor edx,edx
	mov ecx,512
	div ecx

	or edx,edx
	jnz @1
	dec eax
@1:
	or eax,eax
	jz pge

	;读取剩余扇区
	mov ecx,eax
	mov eax,core_start_sector
	inc eax
@2:
	call read_hard_disk_0
	inc eax
	loop @2

pge:
	;准备打开分页机制

	;创建系统内核的页目录表PDT
	mov ebx,0x00020000						;页目录表PDT的物理地址

	;在页目录内创建指向目录表自己的目录项
	mov dword [ebx+4092],0x00020003

	mov edx,0x00021003
	;在页目录内创建与线性地址0x00000000对应的目录项
	mov [ebx+0x000],edx						;写入目录项（页表的物理地址和属性）
											;此目录项仅用于过渡
	;在页目录内创建与线性地址0x80000000对应的目录项
	mov [ebx+0x800],edx						;写入页目录（页表的物理地址和属性）

	;创建与上面那个目录项对应的页表，初始化页表项
	mov ebx,0x00021000						;页表的物理地址
	xor eax,eax								;起始页的物理地址
	xor esi,esi
.b1:
	mov edx,eax
	or edx,0x00000003
	mov [ebx+esi*4],edx
	add eax,0x1000
	inc esi
	cmp esi,256
	jl .b1

	;令CR3寄存器指向页目录，并正式开启页功能
	mov eax,0x00020000
	mov cr3,eax

	;将GDT的线性地址映射到从0x80000000开始的相同位置
	sgdt [pgdt]
	mov ebx,[pgdt+2]
	add dword [pgdt+2],0x80000000
	lgdt [pgdt]

	mov eax,cr0
	or eax,0x80000000
	mov cr0,eax								;开启分页机制

	;将堆栈映射到高端


	add esp,0x80000000

	jmp [0x80040004]

;--------------------------------------------------------------------
read_hard_disk_0:                           ;从硬盘读取一个逻辑扇区
                                            ;EAX=逻辑扇区号
                                            ;DS:EBX=目标缓冲区地址
                                            ;返回：EBX=EBX+512 
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                          ;读取的扇区数

         inc dx                             ;0x1f3
         pop eax
         out dx,al                          ;LBA地址7~0

         inc dx                             ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                          ;LBA地址15~8

         inc dx                             ;0x1f5
         shr eax,cl
         out dx,al                          ;LBA地址23~16

         inc dx                             ;0x1f6
         shr eax,cl
         or al,0xe0                         ;第一硬盘  LBA地址27~24
         out dx,al

         inc dx                             ;0x1f7
         mov al,0x20                        ;读命令
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                         ;不忙，且硬盘已准备好数据传输 

         mov ecx,256                        ;总共要读取的字数
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

;--------------------------------------------------------------------
	pgdt		dw 0
				dd 0x00008000
;--------------------------------------------------------------------
	times 510-($-$$) db 0
					 db 0x55,0xaa