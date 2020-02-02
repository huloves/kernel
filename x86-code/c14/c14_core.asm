		;
		;
		;文件说明：保护模式微型核心程序
		;创建日期：2020-2-2

		;常量定义部分
		core_code_seg_sel		equ 0x38	;内核代码段选择子，0011 1000
		core_data_seg_sel		equ 0x30	;内核数据段选择子，0011 0000
		sys_routine_seg_sel		equ 0x28	;系统公共例程代码段选择子，0010 1000
		video_ram_seg_sel		equ 0x20	;视频显示缓冲区段选择子，0010 0000
		core_stack_seg_sel		equ 0x18	;内核堆栈段选择子，0001 1000
		mem_0_4_gb_seg_sek		equ 0x08	;整个0~4GB内存段选择子，0000 1000

;----------------------------------------------------------------------
		;系统核心的头部，用于夹在核心程序
		core_length		dd core_end	;#0x00

		sys_routine_seg	dd section.routine.start	;#0x04


		core_data_seg	dd section.core_data.start	;#0x08


		core_code_seg	dd section.core_data.start ;#0x0c



		core_entry		dd start	;入口点，0x10
						dw core_code_seg_sel	;核心程序段的选择子

;=======================================================================
		[bits 32]
;=======================================================================
SECTION sys_routine vstart=0
;-----------------------------------------------------------------------
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

;-----------------------------------------------------------------------
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
         mov eax,video_ram_seg_sel          ;0xb8000段的选择子
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

;-----------------------------------------------------------------------
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

;-----------------------------------------------------------------------
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

;-----------------------------------------------------------------------
allocate_memory:                            ;分配内存
                                            ;输入：ECX=希望分配的字节数
                                            ;输出：ECX=起始线性地址 
         push ds
         push eax
         push ebx
      
         mov eax,core_data_seg_sel
         mov ds,eax
      
         mov eax,[ram_alloc]
         add eax,ecx                        ;下一次分配时的起始地址
      
         ;这里应当有检测可用内存数量的指令
          
         mov ecx,[ram_alloc]                ;返回分配的起始地址

         mov ebx,eax
         and ebx,0xfffffffc
         add ebx,4                          ;强制对齐 
         test eax,0x00000003                ;下次分配的起始地址最好是4字节对齐
         cmovnz eax,ebx                     ;如果没有对齐，则强制对齐 
         mov [ram_alloc],eax                ;下次从该地址分配内存
                                            ;cmovcc指令可以避免控制转移 
         pop ebx
         pop eax
         pop ds

         retf

;-----------------------------------------------------------------------
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
;-----------------------------------------------------------------------
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

;-----------------------------------------------------------------------
make_gate_descriptor:						;构造门的描述符（调用门等）
											;输入：EAX = 门代码在段内偏移量
											;		BX = 门代码所在段的选择子
											;		CX = 段类型及属性等（各属
											;			 性位都在原始位置）
											;返回：EDX:EAX = 完整的描述符
		push ebx
		push eax

		mov edx,eax
		and edx,0xffff0000
		or dx,cx

		and eax,0x0000ffff
		shl ebx,16
		or eax,ebx

		pop ecx
		pop ebx

		retf

sys_routine_end:

;=======================================================================
SECTIONE core_data vstart=0
;-----------------------------------------------------------------------
		pgdt			dw 0		;用于设置和修改GDT
						dd 0

		ram_alloc		dd 0x00100000	;下次分配内存时的起始地址

		;符号地址索引表
		salt:
		salt_1			db '@PrintString'
					times 256-($-salt_1) db 0
						dd put_string
						dw sys_routine_seg_sel

		salt_2			db '@ReadDiskData'
					timed 256-($-salt_2) db 0
						dd put_string
						dw sys_routine_seg_sel

		salt_3			db '@PrintDwordAsHexString'
					times 256-($-String) db 0
						dd put_hex_dword
						dw sys_routine_seg_sel

		salt_4			db '@TerminateProgram'
					times 256-($-salt_4) db 0
						dd return_point
						dw core_code_seg_sel

		salt_item_len	equ $-salt_4
		salt_items		equ ($-salt)/salt_item_len

		message_1		db '  If you seen this message,that means we '
						db 'are now in protect mode,and the system '
						db 'core is loaded,and the video display '
						db 'routine works perfectly.',0x0d,0x0a,0

		message_2		db '  System wide CALL-GATE mounted.',0x0d,0x0a,0

		message_3		db 0x0d,0x0a,'  Loading user program...',0

		do_status		db 'Done.',0x0d,0x0a,0

		message_6		db 0x0d,0x0a,0x0d,0x0a,0x0d,0x0a
						db '  User program terminated,control returned.',0

		bin_hex			db '0123456789ABCDEF'


		core_buf	times 2048 db 0	;内核缓冲区

		eap_pointer		dd 0		;临时保存自己的栈指针

		cpu_brnd0		db 0x0d,0x0a,'  ',0
		cpu_brand	times 52 db 0
		cpu_brnd1		db 0x0d,0x0a,0x0d,0x0a,0

		;任务控制链
		tcb_chain		dd 0

data_end:

;=======================================================================
SECTION core_code vstart=0
;-----------------------------------------------------------------------
start:
		mov ecx,core_data_seg_sel
		mov ds,ecx

		mov ebx,message_1
		call sys_routine_seg_sel:put_string

		;显示处理器信息
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

		mov ebx,cpu_brnd0
		call sys_routine_seg_sel:put_string
		mov ebx,cpu_brand
		call sys_routine_seg_sel:put_string
		mov ebx,cpu_brnd1
		call sys_routine_seg_sel:put_string

		;安装为整个系统服务的调用门
		mov edi,salt		;C-SALT的起始位置
		mov ecx,salt_items	;C-SALT的条目数量，循环次数
	.b3:
		push ecx
		mov eax,[edi+256]				;该条目入口点的32位偏移地址
		mov ebx,[edi+260]				;该条目入口点的段选择子
		mov cx,1_11_0_1100_000_00000B	;属性值，特权级为3的调用门（3以上的特权级
										;才允许访问），0个参数（因为用寄存器
										;传递参数，而没有使用栈）
		call sys_routine_seg_sel:make_gate_descriptor
		call sys_routine_seg_sel:set_up_gdt_descriptor
		mov [edi+260],cx				;将返回的门描述符选择子回填
		add edi,salt_item_len			;指向下一个C-SALT条目
		pop ecx
		loop .b3

		;对门进行测试
		mov ebx,message_2
		call far [salt_1+256]			;通过门显示信息（偏移量将被忽略）

		mov ebx,message_3
		call sys_routine_seg_sel:put_string	;在内核中调用例程不需要通过门

