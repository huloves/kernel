		;
		;
		;�ļ�˵����Ӳ����������������
		;����ʱ�䣺2020-1-28 0:31

		jmp near start

	message db '1+2+3+...+100='

	start:
		mov ax,0x7c0
		mov ds,ax

		mov ax,0xb800
		mov es,ax

		;��ʾ�ַ���
		mov si,message
		mov di,0
		mov cx,start-message ;�����ж����ֽ�
	@g:
		mov al,[si]
		mov [es:di],al
		inc di
		mov byte [es:di],0x07
		inc di
		inc si
		loop @g

		;����1��100�ĺ�
		xor ax,ax
		mov cx,1
	@f:
		add ax,cx
		inc cx
		cmp cx,100
		jle @f

		;�����ۼӺ͵���λ
		xor cx,cx ;���ö�ջ��
		mov ss,cx
		mov sp,cx

		mov bx,10
		xor cx,cx
	@d:
		inc cx
		xor dx,dx
		div bx
		or dl,0x30
		push dx
		cmp ax,0
		jne @d

		;��ʾ������λ
	@a:
		pop dx
		mov [es:di],dl
		inc di
		mov byte [es:di],0x07
		inc di
		loop @a

		jmp near $


	times 510-($-$$) db 0
					 db 0x55,0xaa