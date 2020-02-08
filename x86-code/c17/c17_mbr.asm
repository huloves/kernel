	;
	;
	;�ļ�˵����Ӳ����������������
	;�������ڣ�2020-2-7 17:44

	core_base_address	equ	0x00040000		;�ں˼��ص���ʼ�ڴ��ַ
	core_start_sector	equ 0x00000001		;�ں���ʼ�߼�������

;=====================================================================
SECTION mbr vstart=0x00007c00

	mov ax,cs
	mov ss,ax
	mov sp,0x7c00

	;����GDT���ڵ��߼��ε�ַ
	mov eax,[cs:pgdt+0x02]					;gdt��32λ�����ַ
	xor edx,edx
	mov ebx,16
	div ebx									;�ֽ��16λ�߼���ַ

	mov ds,eax								;dsָ��gdt��
	mov ebx,edx								;ebxΪ����ƫ�Ƶ�ַ

	;����0#����������λ
	;����1#������������ģʽ�µĴ����������
	mov dword [ebx+0x08],0x0000ffff			;����ַΪ0������0xfffff��DPL=0
	mov dword [ebx+0x0c],0x00cf9800			;4KB���ȣ��������������������չ
	
	;����2#������������ģʽ�µ����ݶκͶ�ջ��������
	mov dword [ebx+0x10],0x0000ffff			;����ַΪ0������0xfffff��DPL=0
	mov dword [ebx+0x14],0x00cf9200			;4KB���ȣ����ݶ���������������չ
	
	;��ʼ����������Ĵ���GDTR
	mov word [cs:pgdt],23					;����������

	lgdt [es:pgdt]

	in al,0x92								;����оƬ�ڵĶ˿�
	or al,0000_0010B
	out 0x92,al								;��A20

	cli										;�ر��жϣ��жϻ�����δ����

	mov eax,cr0
	or eax,1
	mov cr0,eax								;����PEλ���򿪱���ģʽ

	;���뱣��ģʽ
	jmp dword 0x0008:flush

	[bits 32]
flush:
	mov eax,0x0010							;�������ݶΣ�0000 0000 0001 0000
	mov ds,eax
	mov es,eax
	mov fs,eax
	mov gs,eax
	mov ss,eax
	mov esp,0x7000							;��ջָ��

	;����ϵͳ���ĳ���
	mov edi,core_base_address

	mov eax,core_start_sector
	mov ebx,edi								;��ʼ��ַ
	call read_hard_disk_0					;��ȡ�������ʼ���֣�һ��������
	
	;�ж�ϵͳ���ĳ����С
	mov eax,[edi]
	xor edx,edx
	mov ecx,512
	div ecx

	or edx,edx
	jnz @1
	dec eax
@1:
	or eax,eax
	jz pge

	;��ȡʣ������
	mov ecx,eax
	mov eax,core_start_sector
	inc eax
@2:
	call read_hard_disk_0
	inc eax
	loop @2

pge:
	;׼���򿪷�ҳ����

	;����ϵͳ�ں˵�ҳĿ¼��PDT
	mov ebx,0x00020000						;ҳĿ¼��PDT�������ַ

	;��ҳĿ¼�ڴ���ָ��Ŀ¼���Լ���Ŀ¼��
	mov dword [ebx+4092],0x00020003

	mov edx,0x00021003
	;��ҳĿ¼�ڴ��������Ե�ַ0x00000000��Ӧ��Ŀ¼��
	mov [ebx+0x000],edx						;д��Ŀ¼�ҳ��������ַ�����ԣ�
											;��Ŀ¼������ڹ���
	;��ҳĿ¼�ڴ��������Ե�ַ0x80000000��Ӧ��Ŀ¼��
	mov [ebx+0x800],edx						;д��ҳĿ¼��ҳ��������ַ�����ԣ�

	;�����������Ǹ�Ŀ¼���Ӧ��ҳ����ʼ��ҳ����
	mov ebx,0x00021000						;ҳ��������ַ
	xor eax,eax								;��ʼҳ�������ַ
	xor esi,esi
.b1:
	mov edx,eax
	or edx,0x00000003
	mov [ebx+esi*4],edx
	add eax,0x1000
	inc esi
	cmp esi,256
	jl .b1

	;��CR3�Ĵ���ָ��ҳĿ¼������ʽ����ҳ����
	mov eax,0x00020000
	mov cr3,eax

	;��GDT�����Ե�ַӳ�䵽��0x80000000��ʼ����ͬλ��
	sgdt [pgdt]
	mov ebx,[pgdt+2]
	add dword [pgdt+2],0x80000000
	lgdt [pgdt]

	mov eax,cr0
	or eax,0x80000000
	mov cr0,eax								;������ҳ����

	;����ջӳ�䵽�߶�


	add esp,0x80000000

	jmp [0x80040004]

;--------------------------------------------------------------------
read_hard_disk_0:                           ;��Ӳ�̶�ȡһ���߼�����
                                            ;EAX=�߼�������
                                            ;DS:EBX=Ŀ�껺������ַ
                                            ;���أ�EBX=EBX+512 
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                          ;��ȡ��������

         inc dx                             ;0x1f3
         pop eax
         out dx,al                          ;LBA��ַ7~0

         inc dx                             ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                          ;LBA��ַ15~8

         inc dx                             ;0x1f5
         shr eax,cl
         out dx,al                          ;LBA��ַ23~16

         inc dx                             ;0x1f6
         shr eax,cl
         or al,0xe0                         ;��һӲ��  LBA��ַ27~24
         out dx,al

         inc dx                             ;0x1f7
         mov al,0x20                        ;������
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                         ;��æ����Ӳ����׼�������ݴ��� 

         mov ecx,256                        ;�ܹ�Ҫ��ȡ������
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

;--------------------------------------------------------------------
	pgdt		dw 0
				dd 0x00008000
;--------------------------------------------------------------------
	times 510-($-$$) db 0
					 db 0x55,0xaa