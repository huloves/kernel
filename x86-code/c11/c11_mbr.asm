		;
		;
		;�ļ�˵����Ӳ����������������
		;�������ڣ�2020-1-29 18:43

		;���ö�ջ�κ�ջָ��
		mov ax,cs
		mov ss,ax
		mov sp,0x7c00

		;����GDT���ڵ��߼��ε�ַ
		mov ax,[cs:gdt_base+0x7c00]	;��16λ
		mov dx,[cs:gdt_base+0x7c00+2]	;��16λ
		mov bx,16
		div bx
		mov ds,ax	;DSָ��öν��в���
		mov bx,dx	;����ƫ�Ƶ�ַ

		;����0#�����������ǿ������������Ǵ�������Ҫ��
		mov dword [bx+0x00],0x00
		mov dword [bx+0x04],0x00

		;����#1������������ģʽ�µĴ����������
		mov dword [bx+0x08],0x7c0001ff
		mov dword [bx+0x0c],0x00409800

		;����#2������������ģʽ�µ����ݶ����������ı�ģʽ�µ���ʾ��������
		mov dword [bx+0x10],0x8000ffff
		mov dword [bx+0x14],0x0040920b

		;����#3������������ģʽ�µĶ�ջ��������
		mov dword [bx+0x18],0x00007a00
		mov dword [bx+0x1c],0x00409600

		;��ʼ���������Ĵ���
		mov word [cs:gdt_size+0x7c00],31	;��������Ľ��ޣ����ֽ�����һ��
		
		lgdt [cs:gdt_size+0x7c00]

		in al,0x92		;����оƬ�ڵĶ˿�
		or al,0000_0010B
		out 0x92,al		;��A20

		cli	;����ģʽ���жϻ�����δ������Ӧ��ֹ�ж�

		mov eax,cr0
		or eax,1
		mov cr0,eax	;����PEλ

		;���뱣��ģʽ
		jmp dword 0x0008:flush	;16λ�Ķ�������ѡ���ӣ�32λƫ��
								;����ˮ�߲����л�������
		[bits 32]

	flush:
		mov cx,00000000000_10_000B
		mov ds,cx

		;����Ļ����ʾ��Protect mode OK.��
		mov byte [0x00],'p'
		mov byte [0x02],'r'
		mov byte [0x04],'o'
		mov byte [0x06],'t'
		mov byte [0x08],'e'
		mov byte [0x0a],'c'
		mov byte [0x0c],'t'
		mov byte [0x0e],' '
		mov byte [0x10],'m'
		mov byte [0x12],'o'
		mov byte [0x14],'d'
		mov byte [0x16],'e'
		mov byte [0x18],' '
		mov byte [0x1a],'O'
		mov byte [0x1c],'K'

		;�ü򵥵�ʵ������32λ����ģʽ�µĶ�ջ����
		mov cx,00000000000_11_000B
		mov ss,cx
		mov esp,0x7c00

		mov ebp,esp
		push byte '.'

		sub ebp,4
		cmp ebp,esp
		jnz ghalt
		pop eax
		mov [0x1e],al

	ghalt:
		hlt

	;-----------------------------------------------
		
		gdt_size dw 0
		gdt_base dd 0x00007e00

		times 510-($-$$) db 0
						 db 0x55,0xaa