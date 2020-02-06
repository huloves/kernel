	;
	;
	;文件说明：用户程序
	;创建日期：2020-2-6 16:47

	program_length		dd	program_end
	entry_point			dd	start
	salt_position		dd	salt_begin
	salt_items			dd	(salt_end-salt_begin)/256

;---------------------------------------------------------------------

	;符号地址检索表
	salt_begin:

	PrintString			db	'@PrintString'
				times 256-($-PrintString) db 0

	TerminateProgram	db	'@TerminateProgram'
				times 256-($-TerminateProgram) db 0
;---------------------------------------------------------------------
	
	reserved times 256*500 db 0

;---------------------------------------------------------------------
	ReadDiskData		db	'@ReadDiskData'
				times 256-($-ReadDiskData) db 0

	PrintDwordAsHex		db	'@PrintDwordAsHexString'
				times 256-($-PrintDwordAsHex) db 0

	salt_end:

	message_0			db	0x0d,0x0a,
						db	'  ............User task is running with '
						db	'paging enabled!............',0x0d,0x0a,0

	space				db	0x20,0x20,0

;---------------------------------------------------------------------
	[bits 32]
;---------------------------------------------------------------------

start:
	
	mov ebx,message_0
	call far [PrintString]

	xor esi,esi
	mov ecx,88
.b1:
	mov ebx,space
	call far [PrintString]

	mov edx,[esi*4]
	call far [PrintDwordAsHex]

	inc esi
	loop .b1

	call far [TerminateProgram]

;---------------------------------------------------------------------
program_end: