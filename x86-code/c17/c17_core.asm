	;
	;
	;文件说明：保护模式微型核心程序
	;2020-2-7 21:15
;--------------------------------------------------------------------
	;定义常量
	flat_4gb_code_seg_sel	equ	0x0008		;平坦模式下的4GB代码段选择子
	flat_4gb_data_seg_sel	equ	0x0018		;平坦模式下的4gb数据段选择子
	idt_linear_address		equ	0x8001f000	;中断描述符表的线性基地址
;--------------------------------------------------------------------
	;定义宏
;====================================================================
SECTION core vstart=0x80040000

	;系统核心的头部，用于夹在核心程序
	core_length		dd core_end				;核心程序总长度#0x00

	core_entry		dd start				;核心代码段入口点#0x04

;--------------------------------------------------------------------
	[bits 32]
;--------------------------------------------------------------------
general_interrupt_handler:					;通用的中断处理过程
	push eax

	mov al,0x20								;中断结束命令EOI
	out 0xa0,al								;向从片发送
	out 0x20,al								;向主片发送

	pop eax

	iretd
;--------------------------------------------------------------------
general_exception_handler:					;通用的异常处理过程
	mov ebx,excep_msg
	call falt_4gb_code_seg_sel:put_string

	hlt

;--------------------------------------------------------------------
rtm_0x70_interrupt_handle:					;实时时钟中断处理过程

	
;--------------------------------------------------------------------
make_gate_descriptor:                       ;构造门的描述符（调用门等）
                                            ;输入：EAX=门代码在段内偏移地址
                                            ;       BX=门代码所在段的选择子 
                                            ;       CX=段类型及属性等（各属
                                            ;          性位都在原始位置）
                                            ;返回：EDX:EAX=完整的描述符
         push ebx
         push ecx
      
         mov edx,eax
         and edx,0xffff0000                 ;得到偏移地址高16位 
         or dx,cx                           ;组装属性部分到EDX
       
         and eax,0x0000ffff                 ;得到偏移地址低16位 
         shl ebx,16                          
         or eax,ebx                         ;组装段选择子部分
      
         pop ecx
         pop ebx
      
         retf                                   

;--------------------------------------------------------------------
	pgdt			dw	0					;用于设置和修改GDT
					dd	0

	pidt			dw	0
					dd	0

	;任务控制块连
	tcb_chain		dd	0

	core_tcb	times 32 db 0				;内核（程序管理器）的TCB

	page_bit_map	db	0xff,0xff,0xff,0xff,0xff,0xff,0x55,0x55
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
					db	0x55,0x55,0x55,0x55,0x55,0x55,0x55,0x55
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
					db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	page_map_len	equ	$-page_bit_map

	;符号地址检索表
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
	;创建中断描述符表IDT
	;在此之前，禁止调用put_string过程，以及任何含有sti指令的过程

	;前20个向量是处理器异常使用的
	mov eax,general_exception_handler			;门代码在段内偏移地址
	mov bx,falt_4gb_code_seg_sel				;门代码所在段的选择子
	mov cx,0x8e00								;32位中断门，0特权级
	call falt_4gb_code_seg_sel:make_gate_descriptor

	mov ebx,idt_linear_adress					;中断描述符表的线性地址
	xor esi,esi
.idt:
	mov [ebx+esi*8],eax
	mov [ebx+esi*8+4],edx
	inc esi
	cmp esi,19									;安装前20个异常中断处理过程
	jle .idt

	;其余为保留或硬件使用的中断向量
	mov eax,general_interrupt_handler			;门代码在段内偏移地址
	mov ebx,falt_4gb_code_seg_sel
	mov cx,0x8e00
	call falt_4gb_code_seg_sel:make_gate_descriptor

	mov ebx,idt_linear_address					;中断描述符表的线性地址
.idt1:
	mov [ebx+esi*8],eax
	mov [ebx+esi*8+4],edx
	inc esi
	cmp esi,255									;安装普通的中断处理过程
	jle .idt1

	;设置实时时钟中断处理过程
	mov eax,rtm_0x70_interrupt_handle
	mov bx,falt_4gb_code_seg_sel
	mov cx,0x8e00
	call falt_4gb_code_seg_sel:make_gate_descriptor

	mov ebx,idt_linear_address
	mov [ebx+0x70*8],eax
	mov [ebx+0x70*8+4],edx