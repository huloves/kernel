	;
	;
	;�ļ�˵��������ģʽ΢�ͺ��ĳ���
	;2020-2-7 21:15
;--------------------------------------------------------------------
	;���峣��
	flat_4gb_code_seg_sel	equ	0x0008		;ƽ̹ģʽ�µ�4GB�����ѡ����
	flat_4gb_data_seg_sel	equ	0x0018		;ƽ̹ģʽ�µ�4gb���ݶ�ѡ����
	idt_linear_address		equ	0x8001f000	;�ж�������������Ի���ַ
;--------------------------------------------------------------------
	;�����
;====================================================================
SECTION core vstart=0x80040000

	;ϵͳ���ĵ�ͷ�������ڼ��ں��ĳ���
	core_length		dd core_end				;���ĳ����ܳ���#0x00

	core_entry		dd start				;���Ĵ������ڵ�#0x04

;--------------------------------------------------------------------
	[bits 32]
;--------------------------------------------------------------------
general_interrupt_handler:					;ͨ�õ��жϴ������
	push eax

	mov al,0x20								;�жϽ�������EOI
	out 0xa0,al								;���Ƭ����
	out 0x20,al								;����Ƭ����

	pop eax

	iretd
;--------------------------------------------------------------------
general_exception_handler:					;ͨ�õ��쳣�������
	mov ebx,excep_msg
	call falt_4gb_code_seg_sel:put_string

	hlt

;--------------------------------------------------------------------
rtm_0x70_interrupt_handle:					;ʵʱʱ���жϴ������

	
;--------------------------------------------------------------------
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

;--------------------------------------------------------------------
	pgdt			dw	0					;�������ú��޸�GDT
					dd	0

	pidt			dw	0
					dd	0

	;������ƿ���
	tcb_chain		dd	0

	core_tcb	times 32 db 0				;�ںˣ��������������TCB

	page_bit_map	db	0xff,0xff,0xff,0xff,0xff,0xff,0x55,0x55
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
					dd put_string
					dw falt_4gb_code_seg_sel

	salt_2			db	'@ReadDiskData'
				times 256-($-salt_2) db 0
					dd read_hard_disk_0
					dw flat_4gb_code_seg_sel

	salt_3			db	'@PrintDwordAsHexString'
				times 256-($-salt_3) db 0
					dd put_hex_dword
					dw falt_4gb_code_seg_sel

	salt_4			db	'@TerminateProgram'
				times 256-($-salt_4) db 0
					dd terminate_current_task
					dw falt_4gb_code_seg_sel

	salt_item_len	equ	$-salt_4
	salt_items		equ	($-salt)/salt_item_len

	excep_msg		db	'********Exception encounted********',0

	message_0			db	'  Working in system core with protection '
					db	'and paging are all enabled.System core is mapped '
					db	'to address 0x80000000.',0x0d,0x0a,0

	message_1		db	'  System wide CALL-GATE mounted.',0x0d,0x0a,0

	message_3		db	'********No more pages********',0

	core_msg		db	'  System core task running!',0x0d,0x0a,0

	bin_hex			db	'123456789ABCDEF'


	core_buf	times 512 db 0

	cpu_brnd0		db	0x0d,0x0a,'  ',0
	cpu_brand	times 52 db 0
	cpu_brnd1		db	0x0d,0x0a,0x0d,0x0a,0

;---------------------------------------------------------------------
start:
	;�����ж���������IDT
	;�ڴ�֮ǰ����ֹ����put_string���̣��Լ��κκ���stiָ��Ĺ���

	;ǰ20�������Ǵ������쳣ʹ�õ�
	mov eax,general_exception_handler			;�Ŵ����ڶ���ƫ�Ƶ�ַ
	mov bx,falt_4gb_code_seg_sel				;�Ŵ������ڶε�ѡ����
	mov cx,0x8e00								;32λ�ж��ţ�0��Ȩ��
	call falt_4gb_code_seg_sel:make_gate_descriptor

	mov ebx,idt_linear_adress					;�ж�������������Ե�ַ
	xor esi,esi
.idt:
	mov [ebx+esi*8],eax
	mov [ebx+esi*8+4],edx
	inc esi
	cmp esi,19									;��װǰ20���쳣�жϴ������
	jle .idt

	;����Ϊ������Ӳ��ʹ�õ��ж�����
	mov eax,general_interrupt_handler			;�Ŵ����ڶ���ƫ�Ƶ�ַ
	mov ebx,falt_4gb_code_seg_sel
	mov cx,0x8e00
	call falt_4gb_code_seg_sel:make_gate_descriptor

	mov ebx,idt_linear_address					;�ж�������������Ե�ַ
.idt1:
	mov [ebx+esi*8],eax
	mov [ebx+esi*8+4],edx
	inc esi
	cmp esi,255									;��װ��ͨ���жϴ������
	jle .idt1

	;����ʵʱʱ���жϴ������
	mov eax,rtm_0x70_interrupt_handle
	mov bx,falt_4gb_code_seg_sel
	mov cx,0x8e00
	call falt_4gb_code_seg_sel:make_gate_descriptor

	mov ebx,idt_linear_address
	mov [ebx+0x70*8],eax
	mov [ebx+0x70*8+4],edx