		;
		;
		;文件说明：硬盘主引导扇区代码
		;创建日期：2020-1-30 14:31

		;设置堆栈段和栈指针
		mov eax,cs
		mov ss,eax
		mov sp,0x7c00

		;计算GDT所在的逻辑段地址
		mov eax,[cs:pgdt+0x7c00+0x02]
		xor edx,edx
		mov ebx,16
		div ebx			;分解成16位逻辑地址

		mov ds,eax
		mov ebx,edx

		;创建0#描述符，空描述符，处理器的要求
		mov dword [ebx+0x00],0x00000000
		mov dword [ebx+0x04],0x00000000

		;创建1#描述符，数据段，对应0~4GB的线性地址空间
		mov dword [ebx+0x08],0x0000ffff	;基地址为0，断界限为0xfffff
		mov dword [ebx+0x0c],0x00cf9200	;粒度为4KB，存储器段描述符

		;2#创建保护模式下初始代码段描述符
		mov dword [ebx+0x10],0x7c0001ff	;基地址为0x00007c00，512字节
		mov dword [ebx+0x14],0x00409800	;粒度为1字节，代码段描述符

		;3#以上代码段的别名描述符
		mov dword [ebx+0x18],0x7c0001ff
		mov dword [ebx+0x1c],0x00409200
		;4#栈段
		mov dword [ebx+0x20],0x7c00fffe
		mov dword [ebx+0x24],0x00cf9600

		;初始化描述符表寄存器GDTR
		mov word [cs:pgdt+0x7c00],39	;描述符表的界限

		lgdt [cs:pgdt+0x7c00]

		in al,0x92
		or al,0000_0010B
		out 0x92,al	;打开A20

		cli

		mov eax,cr0
		or eax,1
		mov cr0,eax	;设置PE位

		;进入保护模式
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

		;冒泡排序
		mov ecx,pgdt-string-1	;遍历次数 = 串长度-1
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