		;
		;
		;�ļ�˵����Ӳ����������������
		;�������ڣ�2020-1-30 14:31

		;���ö�ջ�κ�ջָ��
		mov eax,cs
		mov ss,eax
		mov sp,0x7c00

		;����GDT���ڵ��߼��ε�ַ
		mov eax,[cs:pgdt+0x7c00+0x02]
		xor edx,edx
		mov ebx,16
		div ebx			;�ֽ��16λ�߼���ַ

		mov ds,eax
		mov ebx,edx

		;����0#��������������������������Ҫ��
		mov dword [ebx+0x00],0x00000000
		mov dword [ebx+0x04],0x00000000

		;����1#�����������ݶΣ���Ӧ0~4GB�����Ե�ַ�ռ�
		mov dword [ebx+0x08],0x0000ffff	;����ַΪ0���Ͻ���Ϊ0xfffff
		mov dword [ebx+0x0c],0x00cf9200	;����Ϊ4KB���洢����������

		;2#��������ģʽ�³�ʼ�����������
		mov dword [ebx+0x10],0x7c0001ff	;����ַΪ0x00007c00��512�ֽ�
		mov dword [ebx+0x14],0x00409800	;����Ϊ1�ֽڣ������������

		;3#���ϴ���εı���������
		mov dword [ebx+0x18],0x7c0001ff
		mov dword [ebx+0x1c],0x00409200
		;4#ջ��
		mov dword [ebx+0x20],0x7c00fffe
		mov dword [ebx+0x24],0x00cf9600

		;��ʼ����������Ĵ���GDTR
		mov word [cs:pgdt+0x7c00],39	;��������Ľ���

		lgdt [cs:pgdt+0x7c00]

		in al,0x92
		or al,0000_0010B
		out 0x92,al	;��A20

		cli

		mov eax,cr0
		or eax,1
		mov cr0,eax	;����PEλ

		;���뱣��ģʽ
		jmp dword 0x0010:flush

		[bits 32]
	flush:
		mov eax,0x0018	;0000 0000 0001 1000
		mov ds,eax
		
		mov eax,0x0008	;0000 0000 0000 1000
		mov es,eax
		mov fs,eax
		mov gs,eax

		mov eax,0x0020	;0000 0000 0010 0000
		mov ss,eax
		xor esp,esp

		mov dword [es:0x0b8000],0x072e0750
		mov dword [es:0x0b8004],0x072e074d
		mov dword [es:0x0b8008],0x07200720
		mov dword [es:0x0b800c],0x076b076f

		;ð������
		mov ecx,pgdt-string-1	;�������� = ������-1
	@@1:
		push ecx
		xor bx,bx
	@@2:
		mov ax,[string+bx]
		cmp ah,al
		jge @@3
		xchg al,ah
		mov [string+bx],ax
	@@3:
		inc bx
		loop @@2
		pop ecx
		loop @@1

		mov ecx,pgdt-string
		xor ebx,ebx
	@@4:
		mov ah,0x07
		mov al,[string+ebx]
		mov [es:0xb80a0+ebx*2],ax
		inc ebx
		loop @@4

		hlt

	;---------------------------------------------
		string db 'askdjhfaeuhdjkhfaskldjhfz.'
	;---------------------------------------------
		pgdt dw 0
			 dd 0x00007e00
	;---------------------------------------------
		times 510-($-$$) db 0
					 db 0x55,0xaa