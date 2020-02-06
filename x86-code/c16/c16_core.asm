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

	core_code_seg	dd section.core_code.start
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

;---------------------------------------------------------------------
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
allocate_a_4k_page:							;分配一个4KB的页
											;输入：无
											;输出：EAX=页的物理地址
	push ebx
	push ecx
	push edx
	push ds

	mov eax,core_data_seg_sel
	mov ds,eax

	xor eax,eax
.b1:
	bts [page_bit_map],eax
	jnc .b2
	inc eax
	cmp eax,page_map_len*8
	jl .b1

	mov ebx,message_3
	call sys_routine_seg_sel:put_string
	hlt										;没有可以分配的页，停机

.b2:
	shl eax,12								;乘以0x1000(4096)

	pop ds
	pop edx
	pop ecx
	pop ebx

	ret

;------------------------------------------------------------------------
alloc_inst_a_page:							;分配一个页，并安装在当前活动的
											;层级分页结构中
											;输入：EBX=页的线性地址
	push eax
	push ebx
	push esi
	push ds

	mov eax,mem_0_4_gb_seg_sel
	mov ds,eax

	;检查该线性地址所对应的页是否存在
	mov esi,ebx
	and esi,0xffc00000
	shr esi,20								;得到页目录索引，并乘以4
	or esi,0xfffff000						;页目录自身的线性地址+表内偏移

	test dword [esi],0x00000001
	jnz .b1

	;创建该线性地址所对应的页表
	call allocate_a_4k_page
	or eax,0x00000007
	mov [esi],eax							;在页目录中登记新分配的页表

.b1:
	;开始访问该线性地址所对应的页表
	mov esi,ebx
	shr esi,10
	and esi,0x003ff000
	or esi,0xffc00000

	;得到该线性地址在页表内的对应条目（页表项）
	and ebx,0x003ff000
	shr ebx,10								;相当于右移12位，再乘以4
	or esi,ebx								;页表项的线性地址
	call allocate_a_4k_page					;分配一个页，要安装的页
	or eax,0x00000007
	mov [esi],eax

	pop ds
	pop esi
	pop ebx
	pop eax

	retf

;------------------------------------------------------------------------
create_copy_cur_pdir:						;创建新页目录，并复制当前页目录内容
											;输入：无
											;输出：EAX=新页目录的物理地址
	push ds
	push es
	push esi
	push edi
	push ebx
	push ecx

	mov ebx,mem_0_4_gb_seg_sel
	mov ds,ebx
	mov es,ebx

	call allocate_a_4k_page
	mov ebx,eax
	or ebx,0x00000007
	mov [0xfffffff8],ebx

	mov esi,0xfffff000						;esi指向当前页目录的线性地址
	mov edi,0xffffe000						;edi指向新目录的线性地址
	mov ecx,1024							;ecx=要复制的目录项数
	cld
	repe movsd

	pop ecx
	pop ebx
	pop edi
	pop esi
	pop es
	pop ds

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
	pgdt			dw	0
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
	salt_items		equ	($-salt)/salt_item_len

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
;---------------------------------------------------------------------
fill_descriptor_in_ldt:                     ;在LDT内安装一个新的描述符
                                            ;输入：EDX:EAX=描述符
                                            ;          EBX=TCB基地址
                                            ;输出：CX=描述符的选择子
         push eax
         push edx
         push edi
         push ds

         mov ecx,mem_0_4_gb_seg_sel
         mov ds,ecx

         mov edi,[ebx+0x0c]                 ;获得LDT基地址
         
         xor ecx,ecx
         mov cx,[ebx+0x0a]                  ;获得LDT界限
         inc cx                             ;LDT的总字节数，即新描述符偏移地址
         
         mov [edi+ecx+0x00],eax
         mov [edi+ecx+0x04],edx             ;安装描述符

         add cx,8                           
         dec cx                             ;得到新的LDT界限值 

         mov [ebx+0x0a],cx                  ;更新LDT界限值到TCB

         mov ax,cx
         xor dx,dx
         mov cx,8
         div cx
         
         mov cx,ax
         shl cx,3                           ;左移3位，并且
         or cx,0000_0000_0000_0100B         ;使TI位=1，指向LDT，最后使RPL=00 

         pop ds
         pop edi
         pop edx
         pop eax
     
         ret

;---------------------------------------------------------------------
load_relocate_program:						;加载并重定位用户程序
											;输入：PUSH 逻辑扇区号
											;	   push 任务控制块基地址
											;输出：无
	pushad

	push ds
	push es

	mov ebp,esp

	mov ecx,mem_0_4_gb_seg_sel
	mov es,ecx

	;清空当前页目录的前半部分（对应低2GB的局部地址空间）
	mov ebx,0xfffff000
	xor esi,esi
.b1:
	mov dword [es:ebx+esi*4],0x00000000
	inc esi
	cmp esi,512
	jl .b1

	;开始分配内存并加载用户程序
	mov eax,core_data_seg_sel
	mov ds,eax								;切换到内核数据段

	mov eax,[ebp+12*4]						;从堆栈中读取用户程序起始扇区号
	mov ebx,core_buf						;读取程序头部段
	call sys_routine_seg_sel:read_hard_disk_0

	;判断用户程序大小
	mov eax,[core_buf]
	mov ebx,eax
	and ebx,0xfffff000
	add ebx,0x1000
	test eax,0x00000fff
	cmovnz eax,ebx

	mov ecx,eax
	shr ecx,12								;程序占用的总4KB页数

	mov eax,mem_0_4_gb_seg_sel
	mov ds,eax

	mov eax,[ebp+12*4]						;读取起始逻辑扇区号
	mov esi,[ebp+11+4]						;读取TCB基地址
.b2:
	mov ebx,[es:esi+0x06]					;读取可用的线性地址
	add dword [es:esi+0x06],0x1000
	call sys_routine_seg_sel:alloc_inst_a_page

	push ecx
	mov ecx,8
.b3:
	call sys_routine_seg_sel:read_hard_disk_0
	inc eax
	loop .b3

	pop ecx
	loop .b2

	;在内核地址空间内创建用户任务的TSS
	mov eax,core_data_seg_sel
	mov ds,eax

	mov ebx,[core_next_laddr]
	call sys_routine_seg_sel:alloc_inst_a_page
	add dword [core_next_laddr],4096

	mov [es:esi+0x14],ebx					;在TCB中填写TSS的线性地址
	mov word [es:esi+0x12],103				;在TCB中填写TSS的界限值

	;在用户任务的局部地址空间内创建LDT
	mov ebx,[es:esi+0x06]					;在TCB中读取可用的线性地址
	add dword [es:esi+0x06],0x1000
	call sys_routine_seg_sel:alloc_inst_a_page
	mov [es:esi+0x0c],ebx					;在TCB中填写LDT的线性地址

	;建立程序的代码段描述符
	mov eax,0x00000000
	mov ebx,0x000fffff
	mov ecx,0x00c0f800						;4KB粒度的代码段描述符，特权级3
	call sys_routine_seg_sel:make_seg_descriptor
	mov ebx,esi
	call fill_descriptor_in_ldt
	or cx,0000_0000_0000_0011B				;设置选择子的特权级为3

	mov ebx,[es:esi+0x14]					;从TCB中获取TSS的线性地址
	mov [es:ebx+76],cx						;填写TSS的CS域

	;建立程序数据段描述符
	mov eax,0x00000000
	mov ebx,0x000fffff
	mov ecx,0x00c0f200						;4KB粒度的数据段描述符，特权级3
	call sys_routine_seg_sel:make_seg_descriptor
	mov ebx,esi
	call fill_descriptor_in_ldt
	or cx,0000_0000_0000_0011B				;设置选择子的特权级为3

	mov ebx,[es:esi+0x14]					;从TCB中获取TSS的线性地址
	mov [es:ebx+84],cx						;DS域
	mov [es:ebx+72],cx						;ES域
	mov [es:ebx+88],cx						;FS域
	mov [es:ebx+92],cx						;GS域

	;将数据段作为用户任务的3特权级固有堆栈
	mov ebx,[es:esi+0x06]					;从TCB中获取可用的线性地址
	add dword [es:esi+0x06],0x1000
	call sys_routine_seg_sel:alloc_inst_a_page

	mov ebx,[es:esi+0x14]					;从TCB获取TSS的线性地址
	mov [es:ebx+80],cx						;填写SS域
	mov edx,[es:esi+0x06]					;堆栈的高端线性地址
	mov [es:ebx+56],edx						;填写TSS的ESP域

	;在用户任务的局部地址空间内创建0特权级堆栈
	mov ebx,[es:esi+0x06]
	add dword [es:esi+0x06],0x1000
	call sys_routine_seg_sel:alloc_inst_a_page

	mov eax,0x00000000
	mov ebx,0x000fffff
	mov ecx,0x00c09200						;4KB粒度的堆栈段描述符，特权级0
	call sys_routine_seg_sel:make_seg_descriptor
	mov ebx,esi
	call fill_descriptor_in_ldt
	or cx,0000_0000_0000_0000B				;设置选择子的特权级为0

	mov ebx,[es:esi+0x14]					;从TCB中获取TSS的线性地址
	mov [es:esi+8],cx						;填写TSS的SS0域
	mov edx,[es:esi+0x06]					;堆栈的高端线性地址
	mov [es:ebx+4],edx						;填写TSS的ESP0域

	;在用户任务的局部空间内创建1特权级堆栈
	mov ebx,[es:esi+0x06]
	add dword [es:esi+0x06],0x1000
	call sys_routine_seg_sel:alloc_inst_a_page

	mov eax,0x00000000
	mov ebx,0x000fffff
	mov ecx,0x00c0b200						;4KB粒度的堆栈段描述符，特权级1
	call sys_routine_seg_sel:make_seg_descriptor
	mov ebx,esi
	call fill_descriptor_in_ldt
	or cx,0000_0000_0000_0001B				;设置选择子的特权级为1

	mov ebx,[es:esi+0x14]
	mov [es:ebx+16],cx
	mov edx,[es:esi+0x06]
	mov [es:ebx+12],edx

	;在用户任务的局部地址空间内创建2特权级堆栈
	mov ebx,[es:esi+0x06]
	add dword [es:esi+0x06],0x1000
	call sys_routine_seg_sel:alloc_inst_a_page

	mov eax,0x00000000
	mov ebx,0x000fffff
	mov ecx,0x00c0d200
	call sys_routine_seg_sel:make_seg_descriptor
	mov ebx,esi
	call fill_descriptor_in_ldt
	or cx,0000_0000_0010B

	mov ebx,[es:esi+0x14]
	mov [es:ebx+24],cx
	mov edx,[es:esi+0x06]
	mov [es:esi+20],edx


	;重定位SALT
	mov eax,mem_0_4_gb_seg_sel
	mov es,eax

	mov eax,core_data_seg_sel
	mov ds,eax

	cld

	mov ecx,[es:0x0c]						;U-SALT条目数
	mov edi,[es:0x08]						;U-SALT在4GB空间内的偏移
.b4:
	push ecx
	push edi

	mov ecx,salt_items
	mov esi,salt
.b5:
	push edi
	push esi
	push ecx

	mov ecx,64
	repe cmpsd
	jnz .b6
	mov eax,[esi]
	mov [es:edi-256],eax
	mov ax,[esi+4]
	or ax,0000000000000011B

	mov [es:edi-252],ax
.b6:

	pop ecx
	pop esi
	add esi,salt_item_len
	pop edi
	loop .b5

	pop edi
	add edi,256
	pop ecx
	loop .b4

	;在GDT中登记LDT描述符
	mov esi,[ebp+11*4]						;从堆栈中取得TCB的基地址
	mov eax,[es:esi+0x0c]					;LDT的起始线性地址
	movzx ebx,word [es:esi+0x0a]			;LDT断界限
	mov ecx,0x00408200						;属性，LDT描述符，特权级0
	call sys_routine_seg_sel:make_seg_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [es:esi+0x10],cx					;登记LDT选择子到TCB中

	mov ebx,[es:esi+0x14]					;从TCB中获取TSS的线性地址
	mov [es:esi+ebx],cx						;填写TSS的LDT域

	mov word [es:ebx+0],0					;反向链=0

	mov dx,[es:esi+0x12]					;段长度（界限）
	mov [es:ebx+102],dx						;填写TSS的I/O位图偏移域

	mov word [es:ebx+100],0					;T=0

	mov eax,[es:0x04]						;用户程序的入口点
	mov [es:ebx+32],eax						;填写TSS的EIP域

	pushfd
	pop edx
	mov [es:ebx+36],edx						;填写TSS的EFLAGS域

	;在GDT中登记TSS描述符
	mov eax,[es:esi+0x14]
	movzx ebx,word [es:esi+0x12]
	mov ecx,0x00408900						;TSS描述符，特权级0
	call sys_routine_seg_sel:make_seg_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [es:esi+0x18],cx					;登记TSS选择子到TCB

	;创建用户任务的页目录
	;注意！页的分配和使用是由位图决定的，可以不占用线性地址空间
	call sys_routine_seg_sel:create_copy_cur_pdir
	mov ebx,[es:esi+0x14]					;从TCB中获取TSS的线性地址
	mov dword [es:ebx+28],eax				;填写TSS的CR3（PDBR）域

	pop es
	pop ds

	popad

	ret 8

;---------------------------------------------------------------------
append_to_tcb_link:                         ;在TCB链上追加任务控制块
                                            ;输入：ECX=TCB线性基地址
         push eax
         push edx
         push ds
         push es
         
         mov eax,core_data_seg_sel          ;令DS指向内核数据段 
         mov ds,eax
         mov eax,mem_0_4_gb_seg_sel         ;令ES指向0..4GB段
         mov es,eax
         
         mov dword [es: ecx+0x00],0         ;当前TCB指针域清零，以指示这是最
                                            ;后一个TCB
                                             
         mov eax,[tcb_chain]                ;TCB表头指针
         or eax,eax                         ;链表为空？
         jz .notcb 
         
  .searc:
         mov edx,eax
         mov eax,[es: edx+0x00]
         or eax,eax               
         jnz .searc
         
         mov [es: edx+0x00],ecx
         jmp .retpc
         
  .notcb:       
         mov [tcb_chain],ecx                ;若为空表，直接令表头指针指向TCB
         
  .retpc:
         pop es
         pop ds
         pop edx
         pop eax
         
         ret

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
	add edi,salt_item_len
	pop ecx
	loop .b4

	;对门进行测试
	mov ebx,message_2
	call far [salt_1+256]				;通过门显示信息（偏移量将被忽略）

	;为程序管理器的TSS分配内存空间
	mov ebx,[core_next_laddr]
	call sys_routine_seg_sel:alloc_inst_a_page
	add dword [core_next_laddr],4096

	;在程序管理器的TSS中设置必要的项目
	mov word [es:ebx],0					;反向链=0

	mov eax,cr3
	mov dword [es:ebx+28],eax			;登记cr3（PDBR）

	mov word [es:ebx+96],0
	mov word [es:ebx+100],0
	mov word [es:ebx+102],103

	;创建任务管理器的TSS描述符，并安装到GDT
	mov eax,ebx
	mov ebx,103
	mov ecx,0x00408900
	call sys_routine_seg_sel:make_seg_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [program_man_tss+4],cx			;保存任务管理器的TSS选择子

	;任务寄存器TR中的内容是任务存在的标志，该内容也决定了当前任务是谁。
	;下面的指令为当前正在执行的0特权级任务“程序管理器”后补手续（TSS）。
	ltr cx

	;任务管理器 正在执行中

	;创建用户任务的任务控制块
	mov ebx,[core_next_laddr]
	call sys_routine_seg_sel:alloc_inst_a_page
	add dword [core_next_laddr],4096

	mov dword [es:ebx+0x06],0			;用户任务局部空间的分配从0开始
	mov word [es:ebx+0x0a],0xffff
	mov ecx,ebx
	call append_to_tcb_link

	push dword 50
	push ecx

	call load_relocate_program

	mov ebx,message_4
	call sys_routine_seg_sel:put_string

	call far [es:ecx+0x14]

	mov ebx,message_5
	call sys_routine_seg_sel

	hlt

core_code_end:

;---------------------------------------------------------------------
SECTION core_trail
;---------------------------------------------------------------------
core_end: