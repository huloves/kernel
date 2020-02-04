	;
	;
	;文件说明：用户程序
	;创建日期：2020-2-4 18:02

;=================================================================
SECTION header vstart=0
	
	program_length	dd program_end			;程序总长度#0x00

	head_len		dd header_end			;程序头部长度#0x04

	stack_seg		dd 0					;接受堆栈段选择子#0x08
	stack_len		dd 1					;建议堆栈段大小#0x0c
											;4KB为单位

	pregentry		dd start				;程序入口#0x10
	code_seg		dd section.code.start	;代码段位置#0x14
	code_len		dd code_end				;代码段长度#0x18

	data_seg		dd section.data.start	;数据段位置#0x1c
	data_len		dd data_end				;数据段长度#0x20
;-----------------------------------------------------------------
	;符号地址索引表
	salt_items		dd (header_end-salt)/256;#用户符号索引表项数0x24

	salt:									;索引表起始位置#0x28
	PrintString		db '@PrintString'
				times 256-($-PrintString) db 0

	TerminateProgram	db '@TerminateProgram'
				times 256-($-TerminateProgram) db 0

	ReadDiskData	db '@ReadDiskData'
				times 256-($-ReadDiskData) db 0

header_end:

;=================================================================
SECTION data vstart=0
	
	message_1		db 0x0d,0x0a
					db '[USER TASK]: Hi! nice to meet you,'
					db 'I am run at CPL=',0

	message_2		db 0
					db '.Now,I must exit...',0x0d,0x0a,0

data_end:

;=================================================================
SECTION code vstart=0
start:
	;任务启动时，DS指向头部段，也不需要设置堆栈，TSS中有记录，处理器自动获取
	mov eax,ds
	mov fs,eax							;fs存储头部段，以访问内核例程
	
	mov eax,[data_seg]
	mov ds,eax

	mov ebx,message_1
	call far [fs:PrintString]

	mov ax,cs
	and al,0000_0011B
	or al,0x0030
	mov [message_2],al

	mov ebx,message_2
	call far [fs:TerminateProgram]		;退出，并将控制权返回到核心程序

code_end:

;-----------------------------------------------------------------
SECTION trail
;-----------------------------------------------------------------
program_end: