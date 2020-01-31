		;
		;
		;�ļ�˵����Ӳ����������������
		;�������ڣ�2020-1-30 19:55

		core_base_address equ 0x00040000 ;�������ں˼��ص���ʼ�ڴ��ַ
		core_start_section equ 0x00000001;�������ں˵���ʼ�߼�������

		mov ax,cs
		mov ss,ax
		mov sp,0x7c00

		;����GDT���ڵ��߼��ε�ַ
		mov eax,[cs:pgdt+0x7c00+0x02]	;GDT��32λ�����ַ
		xor edx,edx
		mov ebx,16
		div ebx

		mov ds,eax
		mov ebx,edx

		;����0#���������Ĳ�λ
		;����1#��������0~4GB���ݶ�
		mov dword [ebx+0x08],0x7c00ffff
		mov dword [ebx+0x0c],0x00cf9200

		;2# ������ʼ�������������
		mov dword [ebx+0x10],0x7c0001ff
		mov dword [ebx+0x14],0x00409800

		;3# ������ջ������
		mov dword [ebx+0x18],0x7c00fffe
		mov dword [ebx+0x1c],0x00cf9600

		;4# ��ʾ������������
		mov dword [ebx+0x20],0x80007fff
		mov dword [ebx+0x24],0x0040820b

		;��ʼ��GDTR
		mov dword [cs:pgdt+0x7c00],39

		lgdt [cs:pgdt+0x7c00]

		in al,0x92
		or al,0000_0010B
		out 0x92,al

		cli

		mov eax,cr0
		or eax,1
		mov cr0,eax

		;���뱣��ģʽ
		jmp dword 0x0010:flush
		
		[bits 32]
	flush:
		mov eax,0x0008
		mov ds,eax
		
		mov eax,0x0018
		mov ss,eax
		xor esp,esp

		;����ϵͳ���ĳ���
		mov edi,core_base_address
		
		mov eax,core_start_section
		mov ebx,edi
		call read_hard_disk_0

		;�жϳ����ж��
		mov eax,[edi]
		xor edx,edx
		mov ecx,512
		div ecx

		or edx,edx
		jnz @1
		dec eax
	@1:
		or eax,eax
		jz setup

		;��ȡʣ������
		mov ecx,eax
		mov eax,core_start_section
		inc eax
	@2:
		call read_hard_disk_0
		inc eax
		loop @2

	setup:
		mov esi,[0x7c00+pgdt+0x02]	;�õ�GDT�Ļ���ַ

		;����������̶�������
		mov eax,[edi+0x04]	;�������̴������ʼ����ַ
		mov ebx,[edi+0x08]	;�������ݶλ���ַ
		sub ebx,eax
		dec ebx	;�������̶ν���
		add eax,edi	;�ض�λ���������̻���ַ
		mov ecx,0x00409800	;���������ԣ��ֽ����ȵĴ����������
		call make_gdt_descriptor
		mov [esi+0x28],eax
		mov [esi+0x2c],edx

		;�����������ݶ�������
		mov eax,[edi+0x08]
		mov ebx,[esi+0x0c]
		sub ebx,eax
		dec ebx
		add eax,edi
		mov ecx,0x00409200
		call make_gdt_descriptor
		mov [esi+0x30],eax
		mov [esi+0x34],edx

		;�������Ĵ����������
		mov eax,[edi+0x0c]
		mov ebx,[edi+0x00]
		sub ebx,eax
		dec ebx
		add eax,edi
		mov ecx,0x00409800
		call make_gdt_descriptor
		mov [esi+0x38],eax
		mov [esi+0x3c],edx

		mov word [0x7c00+pgdt],63

		lgdt [0x7c00+pgdt]

		jmp far [edi+0x10]

	;-----------------------------------------
	read_hard_disk_0:		;��Ӳ�̶�ȡһ���߼�����
							;EAX = �߼�������
							;DS:EBX = Ŀ�껺������ַ
							;���أ�EBX = EBX+512
		push eax
		push ecx
		push edx

		push eax

		mov dx,0x1f2
		mov al,1
		out dx,al	;��ȡ������
		
		inc dx	;0x1f3
		pop eax
		out dx,al	;LBA��ַ7~0

		inc dx	;0x1f4
		mov cl,8
		shr eax,cl
		out dx,al	;15~8

		inc dx	;0x1f5
		shr eax,cl
		out dx,al	;23~16

		inc dx
		shr eax,cl
		or al,0xe0	;��һӲ�̣�LBA��ַ27~24
		out dx,al

		inc dx	;0x1f7����������
		mov al,0x20	;������
		out dx,al

	.waits:
		in al,dx
		add al,0x88
		cmp al,0x08
		jnz .waits	;���EFLAG��ZFλΪ0������Ϊ1��˵��Ӳ����æ������ѭ��������Ļ������������ָ��

		mov ecx,256
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

	;------------------------------------------------
	make_gdt_descriptor:		;����������
								;���룺EAX = ���Ի���ַ
								;	   EBX = �Ͻ���
								;	   ECX = ���ԣ������Զ���ԭʼ
								;			λ�ã�����û�õ���λ��0��
								;���أ�EDX:EAX = ������������
		mov edx,eax
		shl eax,16
		or ax,bx	;��32λ�������

		and edx,0xffff0000
		rol edx,8
		bswap edx	;װ���ַ��31~24��23~16λ

		xor bx,bx
		or edx,ebx	;װ��ν��޵ĸ�4λ

		or edx,ecx	;װ������

		ret

	;------------------------------------------------
		pgdt dw 0
			 dd 0x00007e00
	;------------------------------------------------
		times 510-($-$$) db 0
						 db 0x55,0xaa