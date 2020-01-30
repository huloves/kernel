		;
		;
		;文件说明：用于演示BIOS中断的用户程序
		;创建日期：2020-1-29 18:10

;==========================================================
SECTION header vstart=0
	program_length dd program_end

	;用户程序入口点
	code_entry dw start
			   dd section.code.start
			
	realloc_tbl_len dw (header_end-realloc_begin)/4


	realloc_begin:
	;段重定位表
	code_segment dd section.code.start
	data_segment dd section.data.start
	stack_segment dd section.stack.start

header_end:

;==========================================================
SECTION code align=16 vstart=0
start:
	mov ax,[stack_segment]
	mov ss,ax
	mov sp,ss_pointer
	mov ax,[data_segment]
	mov ds,ax

	mov cx,msg_end-message
	mov bx,message

.putc:
	mov ah,0x0e
	mov al,[bx]
	int 0x10
	inc bx
	loop .putc

.reps:
	mov ah,0x00
	int 0x16

	mov ah,0x0e
	;mov bl,0x07
	int 0x10

	jmp .reps

;==========================================================
SECTION data align=16 vstart=0

	message db 'hello,friend!', 0x0d,0x0a
			db 'this simple procedure used to demonstarts '
			db 'the BIOS interrupt.',0x0d,0x0a
			db 'Please press the keys on the keyboard ->'
	msg_end:

;=========================================================
SECTION stack align=16 vstart=0

			resb 256
ss_pointer:

;========================================================
SECTION program_trail
program_end: