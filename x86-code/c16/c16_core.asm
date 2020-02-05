	;
	;
	;�ļ�˵��������ģʽ΢���ں˳���
	;�������ڣ�2020-2-5 14:56

	;�������岿��
	core_code_seg_sel	equ 0x38
	core_data_seg_sel	equ 0x30
	sys_routine_seg_sel	equ 0x28
	video_ram_seg_sel	equ 0x20
	core_stack_seg_sel	equ 0x18
	mem_0_4_gb_seg_sel	equ 0x08

;------------------------------------------------------------------------
	;ϵͳ���ĵ�ͷ�������ڼ��غ��ĳ���
	core_length		dd core_end				;���ĳ����ܳ���0x00

	sys_routine_seg	dd section.sys_routine.start
											;ϵͳ�������̶�#0x04

	core_data_seg	dd section.core_data.start
											;�������ݶ�λ��#0x08

	core_code_seg	dd sectioen.core_code.start
											;���Ĵ����λ��#0x0c


	core_entry		dd start				;���Ĵ�����ڵ�#0x10
					dw core_code_seg_sel

;========================================================================
	[bits 32]
;========================================================================
SECTION sys_routine vstart=0
;------------------------------------------------------------------------
;�ַ�����ʾ����
put_string:                                 ;��ʾ0��ֹ���ַ������ƶ���� 
                                            ;���룺DS:EBX=����ַ
         push ecx
  .getc:
         mov cl,[ebx]
         or cl,cl
         jz .exit
         call put_char
         inc ebx
         jmp .getc

  .exit:
         pop ecx
         retf                               ;�μ䷵��

;------------------------------------------------------------------------
put_char:                                   ;�ڵ�ǰ��괦��ʾһ���ַ�,���ƽ�
                                            ;��ꡣ�����ڶ��ڵ��� 
                                            ;���룺CL=�ַ�ASCII�� 
         pushad

         ;����ȡ��ǰ���λ��
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;����
         mov ah,al

         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;����
         mov bx,ax                          ;BX=������λ�õ�16λ��

         cmp cl,0x0d                        ;�س�����
         jnz .put_0a
         mov ax,bx
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

  .put_0a:
         cmp cl,0x0a                        ;���з���
         jnz .put_other
         add bx,80
         jmp .roll_screen

  .put_other:                               ;������ʾ�ַ�
         push es
         mov eax,video_ram_seg_sel          ;0x800b8000�ε�ѡ����
         mov es,eax
         shl bx,1
         mov [es:bx],cl
         pop es

         ;���½����λ���ƽ�һ���ַ�
         shr bx,1
         inc bx

  .roll_screen:
         cmp bx,2000                        ;��곬����Ļ������
         jl .set_cursor

         push ds
         push es
         mov eax,video_ram_seg_sel
         mov ds,eax
         mov es,eax
         cld
         mov esi,0xa0                       ;С�ģ�32λģʽ��movsb/w/d 
         mov edi,0x00                       ;ʹ�õ���esi/edi/ecx 
         mov ecx,1920
         rep movsd
         mov bx,3840                        ;�����Ļ���һ��
         mov ecx,80                         ;32λ����Ӧ��ʹ��ECX
  .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         pop es
         pop ds

         mov bx,1920

  .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         mov al,bh
         out dx,al
         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         mov al,bl
         out dx,al

         popad
         
         ret                                

;------------------------------------------------------------------------
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
      
         retf                               ;�μ䷵�� 

;------------------------------------------------------------------------
;������Գ����Ǽ���һ�γɹ������ҵ��Էǳ����ѡ�������̿����ṩ���� 
put_hex_dword:                              ;�ڵ�ǰ��괦��ʮ��������ʽ��ʾ
                                            ;һ��˫�ֲ��ƽ���� 
                                            ;���룺EDX=Ҫת������ʾ������
                                            ;�������
         pushad
         push ds
      
         mov ax,core_data_seg_sel           ;�л����������ݶ� 
         mov ds,ax
      
         mov ebx,bin_hex                    ;ָ��������ݶ��ڵ�ת����
         mov ecx,8
  .xlt:    
         rol edx,4
         mov eax,edx
         and eax,0x0000000f
         xlat
      
         push ecx
         mov cl,al                           
         call put_char
         pop ecx
       
         loop .xlt
      
         pop ds
         popad
         
         retf

;------------------------------------------------------------------------
set_up_gdt_descriptor:                      ;��GDT�ڰ�װһ���µ�������
                                            ;���룺EDX:EAX=������ 
                                            ;�����CX=��������ѡ����
         push eax
         push ebx
         push edx

         push ds
         push es

         mov ebx,core_data_seg_sel          ;�л����������ݶ�
         mov ds,ebx

         sgdt [pgdt]                        ;�Ա㿪ʼ����GDT

         mov ebx,mem_0_4_gb_seg_sel
         mov es,ebx

         movzx ebx,word [pgdt]              ;GDT����
         inc bx                             ;GDT���ֽ�����Ҳ����һ��������ƫ��
         add ebx,[pgdt+2]                   ;��һ�������������Ե�ַ

         mov [es:ebx],eax
         mov [es:ebx+4],edx

         add word [pgdt],8                  ;����һ���������Ĵ�С

         lgdt [pgdt]                        ;��GDT�ĸ�����Ч

         mov ax,[pgdt]                      ;�õ�GDT����ֵ
         xor dx,dx
         mov bx,8
         div bx                             ;����8��ȥ������
         mov cx,ax
         shl cx,3                           ;���������Ƶ���ȷλ��

         pop es
         pop ds

         pop edx
         pop ebx
         pop eax

         retf
;------------------------------------------------------------------------
make_seg_descriptor:                        ;����洢����ϵͳ�Ķ�������
                                            ;���룺EAX=���Ի���ַ
                                            ;      EBX=�ν���
                                            ;      ECX=���ԡ�������λ����ԭʼ
                                            ;          λ�ã��޹ص�λ���� 
                                            ;���أ�EDX:EAX=������
         mov edx,eax
         shl eax,16
         or ax,bx                           ;������ǰ32λ(EAX)�������

         and edx,0xffff0000                 ;�������ַ���޹ص�λ
         rol edx,8
         bswap edx                          ;װ���ַ��31~24��23~16  (80486+)

         xor bx,bx
         or edx,ebx                         ;װ��ν��޵ĸ�4λ

         or edx,ecx                         ;װ������

         retf

;------------------------------------------------------------------------
make_gate_descriptor:                       ;�����ŵ��������������ŵȣ�
                                            ;���룺EAX=�Ŵ����ڶ���ƫ�Ƶ�ַ
                                            ;       BX=�Ŵ������ڶε�ѡ���� 
                                            ;       CX=�����ͼ����Եȣ�����
                                            ;          ��λ����ԭʼλ�ã�
                                            ;���أ�EDX:EAX=������������
         push ebx
         push ecx
      
         mov edx,eax
         and edx,0xffff0000                 ;�õ�ƫ�Ƶ�ַ��16λ 
         or dx,cx                           ;��װ���Բ��ֵ�EDX
       
         and eax,0x0000ffff                 ;�õ�ƫ�Ƶ�ַ��16λ 
         shl ebx,16                          
         or eax,ebx                         ;��װ��ѡ���Ӳ���
      
         pop ecx
         pop ebx
      
         retf                                   

;------------------------------------------------------------------------
terminate_current_task:                     ;��ֹ��ǰ����
                                            ;ע�⣬ִ�д�����ʱ����ǰ��������
                                            ;�����С���������ʵҲ�ǵ�ǰ�����
                                            ;һ���� 
         mov eax,core_data_seg_sel
         mov ds,eax

         pushfd
         pop edx
 
         test dx,0100_0000_0000_0000B       ;����NTλ
         jnz .b1                            ;��ǰ������Ƕ�׵ģ���.b1ִ��iretd 
         jmp far [program_man_tss]          ;������������� 
  .b1: 
         iretd

sys_routine_end:

;========================================================================
SECTION core_data vstart=0
;------------------------------------------------------------------------
	;pgdt			dw	0
					dd	0

	page_bit_map	db	0xff,0xff,0xff,0xff,0xff,0x55,0x55,0xff
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0x55,0x55,0x55,0x55,0x55,0x55,0x55,0x55
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	page_map_len	equ	$-page_bit_map

	;���ŵ�ַ������
	salt:
	salt_1			db	'@PrintString'
				times 256-($-salt_1) db 0
					dd	put_string
					dw	sys_routine_seg_sel

	salt_2			db	'@ReadDiskData'
				times 256-($-salt_2) db 0
					dd read_hard_disk_0
					dw sys_routine_seg_sel

	salt_3			db '@PrintDwordAsHexString'
				times 256-($-salt_3) db 0
					dd put_hex_dword
					dw sys_routine_seg_sel

	salt_4			db 'TerminateProgram'
				times 256-($-salt_4) db 0
					dd terminate_current_task
					dw sys_routine_seg_sel

	salt_item_len	equ	$-salt_4
	salt_tiems		equ	($-salt)/salt_item_len

	message_0		db	'  Working in system core,protect mode.'
					db	0x0d,0x0a,0

	message_1		db	'  Paging is enabled.System core is mapped to'
					db	' address 0x80000000.',0x0d,0x0a,0

	message_2		db	0x0d,0x0a
					db	'  System wide CALL-GATE mounted.',0x0d,0x0a,0

	message_3		db	'********No more pages********',0

	message_4		db	0x0d,0x0a,'  Task switching...@_@',0x0d,0x0a,0

	message_5		db	0x0d,0x0a,'  Processor HALT.',0

	bin_hex			db '0123456789ABCDEF'


	core_buf	times 512 db 0			;�ں˻�����

	cpu_brnd0		db	0x0d,0x0a,'  ',0
	cpu_brand	times 52 db	0
	cpu_brnd1		db	0x0d,0x0a,0x0d,0x0a,0

	;���������
	tcb_chain		dd	0

	;�ں���Ϣ
	core_next_laddr	dd	0x80100000		;�ں˿ռ���һ���ɷ�������Ե�ַ
	program_man_tss	dd	0				;�����������TSS������ѡ����
					dw	0

core_data_end:

;========================================================================
SECTION core_code vstart=0
;------------------------------------------------------------------------
start:
	mov ecx,core_data_seg_sel
	mov ds,ecx

	mov ecx,mem_0_4_gb_seg_sel
	mov es,ecx

	mov ebx,message_0
	call sys_routine_seg_sel:put_string

	;��ʾ������Ʒ����Ϣ 
	mov eax,0x80000002
	cpuid
	mov [cpu_brand + 0x00],eax
	mov [cpu_brand + 0x04],ebx
	mov [cpu_brand + 0x08],ecx
	mov [cpu_brand + 0x0c],edx
      
	mov eax,0x80000003
	cpuid
	mov [cpu_brand + 0x10],eax
	mov [cpu_brand + 0x14],ebx
	mov [cpu_brand + 0x18],ecx
	mov [cpu_brand + 0x1c],edx

	mov eax,0x80000004
	cpuid
	mov [cpu_brand + 0x20],eax
	mov [cpu_brand + 0x24],ebx
	mov [cpu_brand + 0x28],ecx
	mov [cpu_brand + 0x2c],edx

	mov ebx,cpu_brnd0                  ;��ʾ������Ʒ����Ϣ 
	call sys_routine_seg_sel:put_string
	mov ebx,cpu_brand
	call sys_routine_seg_sel:put_string
	mov ebx,cpu_brnd1
	call sys_routine_seg_sel:put_string

	;׼���򿪷�ҳ����

	;����ϵͳ�ں˵�ҳĿ¼��PDT
	;ҳĿ¼������
	mov ecx,1024						;ҳĿ¼��1024��洢ҳ��������ַ
	mov ebx,0x00020000					;ҳĿ¼�������ַ
	xor esi,esi							;���ڱ�������ҳĿ¼
.b1:
	mov dword [es:ebx+esi],0x00000000	;ҳĿ¼��������
	add esi,4							;ÿһ���Pλ������λ��Ϊ0
	loop .b1

	;��Ŀ¼���ڴ���ָ��Ŀ¼�Լ���Ŀ¼��
	mov dword [es:ebx+4092],0x00020003	;����ҳĿ¼��ַ��ǰ20λ
										;��12λΪ���ԣ�P=0��RW = 1��US = 0
	;��Ŀ¼�ڴ��������е�ַ0x00000000��Ӧ��Ŀ¼��
	mov dword [es:ebx+0],0x00021003		;д��Ŀ¼�ҳ��������ַ������

	;�����������Ǹ�Ŀ¼�����Ӧ��ҳ����ʼ��ҳ����
	mov ebx,0x00021000					;ҳ��������ַ
	xor eax,eax							;��ʼҳ�������ַ
	xor esi,esi
.b2:
	mov edx,eax
	or edx,0x00000003
	mov [es:ebx+esi*4],edx				;�Ǽ�ҳ�������ַ
	add eax,0x1000						;��һ������ҳ�������ַ
	inc esi								;��һ��ҳ����
	cmp esi,256							;���Ͷ�1MB�ڶԶ�Ӧ��ҳ������Ч��
	jl .b2								;esiС��256ת��

.b3:									;ʣ���ҳ������Ϊ0����ʹ��
	mov dword [es:ebx+esi*4],0x00000000
	inc esi
	cmp esi,1024
	jl .b3

	;��CR3�Ĵ���ָ��ҳĿ¼������ʽ����Ҳ����
	mov eax,0x00020000					;ҳĿ¼�������ַΪ0x00020000
	mov cr3,eax							;PCD=PWT=0

	mov eax,cr0
	or eax,0x80000000
	mov cr0,eax							;������ҳ����

	;��ҳĿ¼���ڴ��������Ե�ַ0x80000000��Ӧ��Ŀ¼��
	mov ebx,0xfffff000
	mov esi,0x80000000
	shr esi,22
	shl esi,2
	mov dword [es:ebx+esi],0x00021003	;д��Ŀ¼�ҳ��������ַ�����ԣ�
										;Ŀ�굥Ԫ�����Ե�ַΪ0xfffff200��һ��Ŀ¼��ռ4�ֽ�
	
	;��GDT�еĶ�������ӳ�䵽���Ե�ַ0x80000000
	sgdt [pgdt]

	mov ebx,[pgdt+2]

	or dword [es:ebx+0x10+4],0x80000000
	or dword [es:ebx+0x18+4],0x80000000
	or dword [es:ebx+0x20+4],0x80000000
	or dword [es:ebx+0x28+4],0x80000000
	or dword [es:ebx+0x30+4],0x80000000
	or dword [es:ebx+0x38+4],0x80000000

	add dword [pgdt+2],0x80000000

	lgdt [pgdt]

	jmp core_code_seg_sel:flush			;ˢ�¶μĴ���CS�����ø߶����Ե�ַ

flush:
	mov eax,core_stack_seg_sel
	mov ss,eax

	mov eax,core_data_seg_sel
	mov ds,eax

	mov ebx,message_1
	call sys_routine_seg_sel:put_string

	;��ʼ��װΪ����ϵͳ����ĵ�����
	mov edi,salt
	mov ecx,salt_items
.b4:
	push ecx
	mov eax,[edi+256]
	mov bx,[edi+260]
	mov cx,1_11_0_1100_000_00000B		;���ԣ���Ȩ��3�ĵ�����
										;0������
										;ʹ�üĴ������ݲ���
	call sys_routine_seg_sel:make_gate_descriptor
	call sys_routine_seg_sel:set_up_gdt_descriptor
	mov [edi+260],cx					;�����ص�������������
	add edi+salt_item_len
	pop ecx
	loop .b4

	;���Ž��в���
	mov ebx,message_2
	call far [salt_1+256]				;ͨ������ʾ��Ϣ��ƫ�����������ԣ�

	;Ϊ�����������TSS�����ڴ�ռ�
