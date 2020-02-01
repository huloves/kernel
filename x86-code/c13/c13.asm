		;
		;
		;文件说明：用户程序
		;创建日期：2020-1-31 23:45

;======================================================
SECTION header vstart=0

		program_length	dd program_end		;用户程序长度，#0x00

		head_len		dd header_end		;头部长度，0x04

		stack_seg		dd 0				;接收堆栈段选择子，0x08
		stack_len		dd 1				;指定用户栈大小，，0x0c


		pregentry		dd start			;用户程序入口，0x10
		code_seg		dd section.code.start	;代码段位置，0x14
		code_len		dd code_end				;代码段长度，0x18

		data_seg		dd section.data.start	;数据段位置，0x1c
		data_len		dd data_end				;数据段长度，0x20

;------------------------------------------------------
		;符号索引表
		salt_items		dd (header_end-salt)/256	;有多少项，0x24

		salt:								;0x0001:0000001，索引表，0x28
		PrintString		db '@PrintString'	;加载到内存后，前四字节是例程的偏移地址，后两字节是段选择子
					times 256-($-PrintString) db 0

		TerminateProgram db  '@TerminateProgram'
					times 256-($-TerminateProgram) db 0

		ReadDiskData	db '@ReadDiskData'
					times 256-($-ReadDiskData) db 0

header_end:

;======================================================
SECTION data vstart=0

		buffer times 1024 db 0

		message_1	db 0x0d,0x0a,0x0d,0x0a
					db '**********User program is runing**********'
					db 0x0d,0x0a,0
		message_2	db '  Disk data:',0x0d,0x0a,0

data_end:

;======================================================
		[bits 32]
;======================================================
SECTION code vstart=0
start:
		mov eax,ds	;用户程序起始地址
		mov fs,eax

		mov eax,[stack_seg]
		mov ss,eax
		mov esp,0

		mov eax,[data_seg]
		mov ds,eax

		mov ebx,message_1
		call far [fs:PrintString]

		mov eax,100
		mov ebx,buffer
		call far [fs:ReadDiskData]

		mov ebx,message_2
		call far [fs:PrintString]

		mov ebx,buffer
		call far [fs:PrintString]

		jmp far [fs:TerminateProgram]

code_end:

;======================================================
SECTION trail
;------------------------------------------------------
program_end: