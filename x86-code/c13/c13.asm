		;
		;
		;�ļ�˵�����û�����
		;�������ڣ�2020-1-31 23:45

;======================================================
SECTION header vstart=0

		program_length dd program_end

		head_len	dd header_end

		stack_seg	dd 0
		stack_len	dd 1


		pregentry	dd start
		code_seg	dd section.code.start
		code_len	dd code_end

		data_seg	dd section.data.start
		data_len	dd data_end

;------------------------------------------------------
		;����������
		salt_items	dd (header_end-salt)/256

		salt:								;0x0001:0000001
			PrintString	db '@PrintString'	;���ص��ڴ��ǰ���ֽ������̵�ƫ�Ƶ�ַ�������ֽ��Ƕ�ѡ����
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
SECTION code vstart=0
start:
		mov eax,ds	;�û�������ʼ��ַ
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
		call [fs:PrintString]

		jmp far [fs:TerminateProgram]

code_end:

;======================================================
SECTION trail
;------------------------------------------------------
program_end: