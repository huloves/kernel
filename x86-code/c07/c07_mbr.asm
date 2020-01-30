		;
		;
		;文件说明：硬盘主引导扇区代码
		;创建时间：2020-1-28 0:31

		jmp near start

	message db '1+2+3+...+100='

	start:
		mov ax,0x7c0
		mov ds,ax

		mov ax,0xb800
		mov es,ax

		;显示字符串
		mov si,message
		mov di,0
		mov cx,start-message ;计算有多少字节
	@g:
		mov al,[si]
		mov [es:di],al
		inc di
		mov byte [es:di],0x07
		inc di
		inc si
		loop @g

		;计算1到100的和
		xor ax,ax
		mov cx,1
	@f:
		add ax,cx
		inc cx
		cmp cx,100
		jle @f

		;计算累加和的数位
		xor cx,cx ;设置堆栈段
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

		;显示各个数位
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