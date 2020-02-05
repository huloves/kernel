	;
	;
	;文件说明：保护模式微型内核程序
	;创建日期：2020-2-5 14:56

	;常量定义部分
	core_code_seg_sel	equ 0x38
	core_data_seg_sel	equ 0x30
	sys_routine_seg_sel	equ 0x28
	video_ram_seg_sel	equ 0x20
	core_stack_seg_sel	equ 0x18
	mem_0_4_gb_seg_sel	equ 0x08

;------------------------------------------------------------------------
	;系统核心的头部，用于加载核心程序
	core_length		dd core_end				;核心程序总长度0x00

	sys_routine_seg	dd section.sys_routine.start
											;系统公共例程段#0x04

	core_data_seg	dd section.core_data.start
											;核心数据段位置#0x08

	core_code_seg	dd sectioen.core_code.start
											;核心代码段位置#0x0c


	core_entry		dd start				;核心代码入口点#0x10
					dw core_code_seg_sel

;========================================================================
	[bits 32]
;========================================================================
SECTION sys_routine vstart=0
;------------------------------------------------------------------------
;字符串显示例程
put_string:                                 ;显示0终止的字符串并移动光标 
                                            ;输入：DS:EBX=串地址
         push ecx
  .getc:
         mov cl,[ebx]
         or cl,cl
         jz .exit
         call put_char
         inc ebx
         jmp .getc

  .exit:
         pop ecx
         retf                               ;段间返回

;------------------------------------------------------------------------
put_char:                                   ;在当前光标处显示一个字符,并推进
                                            ;光标。仅用于段内调用 
                                            ;输入：CL=字符ASCII码 
         pushad

         ;以下取当前光标位置
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;高字
         mov ah,al

         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;低字
         mov bx,ax                          ;BX=代表光标位置的16位数

         cmp cl,0x0d                        ;回车符？
         jnz .put_0a
         mov ax,bx
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

  .put_0a:
         cmp cl,0x0a                        ;换行符？
         jnz .put_other
         add bx,80
         jmp .roll_screen

  .put_other:                               ;正常显示字符
         push es
         mov eax,video_ram_seg_sel          ;0x800b8000段的选择子
         mov es,eax
         shl bx,1
         mov [es:bx],cl
         pop es

         ;以下将光标位置推进一个字符
         shr bx,1
         inc bx

  .roll_screen:
         cmp bx,2000                        ;光标超出屏幕？滚屏
         jl .set_cursor

         push ds
         push es
         mov eax,video_ram_seg_sel
         mov ds,eax
         mov es,eax
         cld
         mov esi,0xa0                       ;小心！32位模式下movsb/w/d 
         mov edi,0x00                       ;使用的是esi/edi/ecx 
         mov ecx,1920
         rep movsd
         mov bx,3840                        ;清除屏幕最底一行
         mov ecx,80                         ;32位程序应该使用ECX
  .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         pop es
         pop ds

         mov bx,1920

  .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         mov al,bh
         out dx,al
         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         mov al,bl
         out dx,al

         popad
         
         ret                                

;------------------------------------------------------------------------
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
      
         retf                               ;段间返回 

;------------------------------------------------------------------------
;汇编语言程序是极难一次成功，而且调试非常困难。这个例程可以提供帮助 
put_hex_dword:                              ;在当前光标处以十六进制形式显示
                                            ;一个双字并推进光标 
                                            ;输入：EDX=要转换并显示的数字
                                            ;输出：无
         pushad
         push ds
      
         mov ax,core_data_seg_sel           ;切换到核心数据段 
         mov ds,ax
      
         mov ebx,bin_hex                    ;指向核心数据段内的转换表
         mov ecx,8
  .xlt:    
         rol edx,4
         mov eax,edx
         and eax,0x0000000f
         xlat
      
         push ecx
         mov cl,al                           
         call put_char
         pop ecx
       
         loop .xlt
      
         pop ds
         popad
         
         retf

;------------------------------------------------------------------------
set_up_gdt_descriptor:                      ;在GDT内安装一个新的描述符
                                            ;输入：EDX:EAX=描述符 
                                            ;输出：CX=描述符的选择子
         push eax
         push ebx
         push edx

         push ds
         push es

         mov ebx,core_data_seg_sel          ;切换到核心数据段
         mov ds,ebx

         sgdt [pgdt]                        ;以便开始处理GDT

         mov ebx,mem_0_4_gb_seg_sel
         mov es,ebx

         movzx ebx,word [pgdt]              ;GDT界限
         inc bx                             ;GDT总字节数，也是下一个描述符偏移
         add ebx,[pgdt+2]                   ;下一个描述符的线性地址

         mov [es:ebx],eax
         mov [es:ebx+4],edx

         add word [pgdt],8                  ;增加一个描述符的大小

         lgdt [pgdt]                        ;对GDT的更改生效

         mov ax,[pgdt]                      ;得到GDT界限值
         xor dx,dx
         mov bx,8
         div bx                             ;除以8，去掉余数
         mov cx,ax
         shl cx,3                           ;将索引号移到正确位置

         pop es
         pop ds

         pop edx
         pop ebx
         pop eax

         retf
;------------------------------------------------------------------------
make_seg_descriptor:                        ;构造存储器和系统的段描述符
                                            ;输入：EAX=线性基地址
                                            ;      EBX=段界限
                                            ;      ECX=属性。各属性位都在原始
                                            ;          位置，无关的位清零 
                                            ;返回：EDX:EAX=描述符
         mov edx,eax
         shl eax,16
         or ax,bx                           ;描述符前32位(EAX)构造完毕

         and edx,0xffff0000                 ;清除基地址中无关的位
         rol edx,8
         bswap edx                          ;装配基址的31~24和23~16  (80486+)

         xor bx,bx
         or edx,ebx                         ;装配段界限的高4位

         or edx,ecx                         ;装配属性

         retf

;------------------------------------------------------------------------
make_gate_descriptor:                       ;构造门的描述符（调用门等）
                                            ;输入：EAX=门代码在段内偏移地址
                                            ;       BX=门代码所在段的选择子 
                                            ;       CX=段类型及属性等（各属
                                            ;          性位都在原始位置）
                                            ;返回：EDX:EAX=完整的描述符
         push ebx
         push ecx
      
         mov edx,eax
         and edx,0xffff0000                 ;得到偏移地址高16位 
         or dx,cx                           ;组装属性部分到EDX
       
         and eax,0x0000ffff                 ;得到偏移地址低16位 
         shl ebx,16                          
         or eax,ebx                         ;组装段选择子部分
      
         pop ecx
         pop ebx
      
         retf                                   

;------------------------------------------------------------------------
terminate_current_task:                     ;终止当前任务
                                            ;注意，执行此例程时，当前任务仍在
                                            ;运行中。此例程其实也是当前任务的
                                            ;一部分 
         mov eax,core_data_seg_sel
         mov ds,eax

         pushfd
         pop edx
 
         test dx,0100_0000_0000_0000B       ;测试NT位
         jnz .b1                            ;当前任务是嵌套的，到.b1执行iretd 
         jmp far [program_man_tss]          ;程序管理器任务 
  .b1: 
         iretd

sys_routine_end:

;========================================================================
SECTION core_data vstart=0
;------------------------------------------------------------------------
	;pgdt			dw	0
					dd	0

	page_bit_map	db	0xff,0xff,0xff,0xff,0xff,0x55,0x55,0xff
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0x55,0x55,0x55,0x55,0x55,0x55,0x55,0x55
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	page_map_len	equ	$-page_bit_map

	;符号地址索引表
	salt:
	salt_1			db	'@PrintString'
				times 256-($-salt_1) db 0
					dd	put_string
					dw	sys_routine_seg_sel

	salt_2			db	'@ReadDiskData'
				times 256-($-salt_2) db 0
					dd read_hard_disk_0
					dw sys_routine_seg_sel

	salt_3			db '@PrintDwordAsHexString'
				times 256-($-salt_3) db 0
					dd put_hex_dword
					dw sys_routine_seg_sel

	salt_4			db 'TerminateProgram'
				times 256-($-salt_4) db 0
					dd terminate_current_task
					dw sys_routine_seg_sel

	salt_item_len	equ	$-salt_4
	salt_tiems		equ	($-salt)/salt_item_len

	message_0		db	'  Working in system core,protect mode.'
					db	0x0d,0x0a,0

	message_1		db	'  Paging is enabled.System core is mapped to'
					db	' address 0x80000000.',0x0d,0x0a,0

	message_2		db	0x0d,0x0a
					db	'  System wide CALL-GATE mounted.',0x0d,0x0a,0

	message_3		db	'********No more pages********',0

	message_4		db	0x0d,0x0a,'  Task switching...@_@',0x0d,0x0a,0

	message_5		db	0x0d,0x0a,'  Processor HALT.',0

	bin_hex			db '0123456789ABCDEF'


	core_buf	times 512 db 0			;内核缓冲区

	cpu_brnd0		db	0x0d,0x0a,'  ',0
	cpu_brand	times 52 db	0
	cpu_brnd1		db	0x0d,0x0a,0x0d,0x0a,0

	;任务控制链
	tcb_chain		dd	0

	;内核信息
	core_next_laddr	dd	0x80100000		;内核空间下一个可分配的线性地址
	program_man_tss	dd	0				;程序管理器的TSS描述符选择子
					dw	0

core_data_end:

;========================================================================
SECTION core_code vstart=0
;------------------------------------------------------------------------
start:
	mov ecx,core_data_seg_sel
	mov ds,ecx

	mov ecx,mem_0_4_gb_seg_sel
	mov es,ecx

	mov ebx,message_0
	call sys_routine_seg_sel:put_string

	;显示处理器品牌信息 
	mov eax,0x80000002
	cpuid
	mov [cpu_brand + 0x00],eax
	mov [cpu_brand + 0x04],ebx
	mov [cpu_brand + 0x08],ecx
	mov [cpu_brand + 0x0c],edx
      
	mov eax,0x80000003
	cpuid
	mov [cpu_brand + 0x10],eax
	mov [cpu_brand + 0x14],ebx
	mov [cpu_brand + 0x18],ecx
	mov [cpu_brand + 0x1c],edx

	mov eax,0x80000004
	cpuid
	mov [cpu_brand + 0x20],eax
	mov [cpu_brand + 0x24],ebx
	mov [cpu_brand + 0x28],ecx
	mov [cpu_brand + 0x2c],edx

	mov ebx,cpu_brnd0                  ;显示处理器品牌信息 
	call sys_routine_seg_sel:put_string
	mov ebx,cpu_brand
	call sys_routine_seg_sel:put_string
	mov ebx,cpu_brnd1
	call sys_routine_seg_sel:put_string

	;准备打开分页机制

	;创建系统内核的页目录表PDT
	;页目录表清零
	mov ecx,1024						;页目录有1024项，存储页表的物理地址
	mov ebx,0x00020000					;页目录的物理地址
	xor esi,esi							;用于遍历整个页目录
.b1:
	mov dword [es:ebx+esi],0x00000000	;页目录表项清零
	add esi,4							;每一项的P位（存在位）为0
	loop .b1

	;在目录项内创建指向目录自己的目录项
	mov dword [es:ebx+4092],0x00020003	;储存页目录地址的前20位
										;后12位为属性，P=0，RW = 1，US = 0
	;在目录内创建于现行地址0x00000000对应的目录项
	mov dword [es:ebx+0],0x00021003		;写入目录项，页表的物理地址和属性

	;创建与上面那个目录项相对应的页表，初始化页表项
	mov ebx,0x00021000					;页表的物理地址
	xor eax,eax							;起始页的物理地址
	xor esi,esi
.b2:
	mov edx,eax
	or edx,0x00000003
	mov [es:ebx+esi*4],edx				;登记页的物理地址
	add eax,0x1000						;下一个相邻页的物理地址
	inc esi								;下一个页表项
	cmp esi,256							;仅低端1MB内对对应的页才是有效的
	jl .b2								;esi小于256转移

.b3:									;剩余的页表项置为0，不使用
	mov dword [es:ebx+esi*4],0x00000000
	inc esi
	cmp esi,1024
	jl .b3

	;令CR3寄存器指向页目录，并正式开启也功能
	mov eax,0x00020000					;页目录物理基地址为0x00020000
	mov cr3,eax							;PCD=PWT=0

	mov eax,cr0
	or eax,0x80000000
	mov cr0,eax							;开启分页机制

	;在页目录表内创建与线性地址0x80000000对应的目录项
	mov ebx,0xfffff000
	mov esi,0x80000000
	shr esi,22
	shl esi,2
	mov dword [es:ebx+esi],0x00021003	;写入目录项（页表的物理地址和属性）
										;目标单元的线性地址为0xfffff200，一个目录项占4字节
	
	;将GDT中的段描述符映射到线性地址0x80000000
	sgdt [pgdt]

	mov ebx,[pgdt+2]

	or dword [es:ebx+0x10+4],0x80000000
	or dword [es:ebx+0x18+4],0x80000000
	or dword [es:ebx+0x20+4],0x80000000
	or dword [es:ebx+0x28+4],0x80000000
	or dword [es:ebx+0x30+4],0x80000000
	or dword [es:ebx+0x38+4],0x80000000

	add dword [pgdt+2],0x80000000

	lgdt [pgdt]

	jmp core_code_seg_sel:flush			;刷新段寄存器CS，启用高端线性地址

flush:
	mov eax,core_stack_seg_sel
	mov ss,eax

	mov eax,core_data_seg_sel
	mov ds,eax

	mov ebx,message_1
	call sys_routine_seg_sel:put_string

	;开始安装为整个系统服务的调用门
	mov edi,salt
	mov ecx,salt_items
.b4:
	push ecx
	mov eax,[edi+256]
	mov bx,[edi+260]
	mov cx,1_11_0_1100_000_00000B		;属性，特权级3的调用门
										;0个参数
										;使用寄存器传递参数
	call sys_routine_seg_sel:make_gate_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [edi+260],cx					;将返回的门描述符回填
	add edi+salt_item_len
	pop ecx
	loop .b4

	;对门进行测试
	mov ebx,message_2
	call far [salt_1+256]				;通过门显示信息（偏移量将被忽略）

	;为程序管理器的TSS分配内存空间
