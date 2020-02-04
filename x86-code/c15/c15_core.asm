		;
		;
		;�ļ�˵��������ģʽ΢�ͺ��ĳ���
		;����ʱ�䣺2020-2-4 12:12

		;���³������岿�֡��ں˵Ĵ󲿷����ݶ�Ӧ���̶� 
        core_code_seg_sel     equ  0x38    ;�ں˴����ѡ����
        core_data_seg_sel     equ  0x30    ;�ں����ݶ�ѡ���� 
        sys_routine_seg_sel   equ  0x28    ;ϵͳ�������̴���ε�ѡ���� 
        video_ram_seg_sel     equ  0x20    ;��Ƶ��ʾ�������Ķ�ѡ����
        core_stack_seg_sel    equ  0x18    ;�ں˶�ջ��ѡ����
        mem_0_4_gb_seg_sel    equ  0x08    ;����0-4GB�ڴ�Ķε�ѡ����

;------------------------------------------------------------------------
		;������ϵͳ���ĵ�ͷ�������ڼ��غ��ĳ��� 
        core_length      dd core_end       ;���ĳ����ܳ���#00

        sys_routine_seg  dd section.sys_routine.start
                                           ;ϵͳ�������̶�λ��#04

        core_data_seg    dd section.core_data.start
                                           ;�������ݶ�λ��#08

        core_code_seg    dd section.core_code.start
                                           ;���Ĵ����λ��#0c


        core_entry       dd start          ;���Ĵ������ڵ�#10
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
         mov eax,video_ram_seg_sel          ;0xb8000�ε�ѡ����
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
allocate_memory:                            ;�����ڴ�
                                            ;���룺ECX=ϣ��������ֽ���
                                            ;�����ECX=��ʼ���Ե�ַ 
         push ds
         push eax
         push ebx
      
         mov eax,core_data_seg_sel
         mov ds,eax
      
         mov eax,[ram_alloc]
         add eax,ecx                        ;��һ�η���ʱ����ʼ��ַ
      
         ;����Ӧ���м������ڴ�������ָ��
          
         mov ecx,[ram_alloc]                ;���ط������ʼ��ַ

         mov ebx,eax
         and ebx,0xfffffffc
         add ebx,4                          ;ǿ�ƶ��� 
         test eax,0x00000003                ;�´η������ʼ��ַ�����4�ֽڶ���
         cmovnz eax,ebx                     ;���û�ж��룬��ǿ�ƶ��� 
         mov [ram_alloc],eax                ;�´δӸõ�ַ�����ڴ�
                                            ;cmovccָ����Ա������ת�� 
         pop ebx
         pop eax
         pop ds

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
;========================================================================
SECTION core_data vstart=0
;------------------------------------------------------------------------
         pgdt             dw  0             ;�������ú��޸�GDT 
                          dd  0

         ram_alloc        dd  0x00100000    ;�´η����ڴ�ʱ����ʼ��ַ

         ;���ŵ�ַ������
         salt:
         salt_1           db  '@PrintString'
                     times 256-($-salt_1) db 0
                          dd  put_string
                          dw  sys_routine_seg_sel

         salt_2           db  '@ReadDiskData'
                     times 256-($-salt_2) db 0
                          dd  read_hard_disk_0
                          dw  sys_routine_seg_sel

         salt_3           db  '@PrintDwordAsHexString'
                     times 256-($-salt_3) db 0
                          dd  put_hex_dword
                          dw  sys_routine_seg_sel

         salt_4           db  '@TerminateProgram'
                     times 256-($-salt_4) db 0
                          dd  terminate_current_task
                          dw  sys_routine_seg_sel

         salt_item_len   equ $-salt_4
         salt_items      equ ($-salt)/salt_item_len

         message_1        db  '  If you seen this message,that means we '
                          db  'are now in protect mode,and the system '
                          db  'core is loaded,and the video display '
                          db  'routine works perfectly.',0x0d,0x0a,0

         message_2        db  '  System wide CALL-GATE mounted.',0x0d,0x0a,0
         
         bin_hex          db '0123456789ABCDEF'
                                            ;put_hex_dword�ӹ����õĲ��ұ� 

         core_buf   times 2048 db 0         ;�ں��õĻ�����

         cpu_brnd0        db 0x0d,0x0a,'  ',0
         cpu_brand  times 52 db 0
         cpu_brnd1        db 0x0d,0x0a,0x0d,0x0a,0

         ;������ƿ���
         tcb_chain        dd  0

         ;�����������������Ϣ 
         prgman_tss       dd  0             ;�����������TSS����ַ
                          dw  0             ;�����������TSS������ѡ���� 

         prgman_msg1      db  0x0d,0x0a
                          db  '[PROGRAM MANAGER]: Hello! I am Program Manager,'
                          db  'run at CPL=0.Now,create user task and switch '
                          db  'to it by the CALL instruction...',0x0d,0x0a,0
                 
         prgman_msg2      db  0x0d,0x0a
                          db  '[PROGRAM MANAGER]: I am glad to regain control.'
                          db  'Now,create another user task and switch to '
                          db  'it by the JMP instruction...',0x0d,0x0a,0
                 
         prgman_msg3      db  0x0d,0x0a
                          db  '[PROGRAM MANAGER]: I am gain control again,'
                          db  'HALT...',0

         core_msg0        db  0x0d,0x0a
                          db  '[SYSTEM CORE]: Uh...This task initiated with '
                          db  'CALL instruction or an exeception/ interrupt,'
                          db  'should use IRETD instruction to switch back...'
                          db  0x0d,0x0a,0

         core_msg1        db  0x0d,0x0a
                          db  '[SYSTEM CORE]: Uh...This task initiated with '
                          db  'JMP instruction,  should switch to Program '
                          db  'Manager directly by the JMP instruction...'
                          db  0x0d,0x0a,0

core_data_end:

;========================================================================
SECTION core_code vstart=0
;------------------------------------------------------------------------
fill_descriptor_in_ldt:                     ;��LDT�ڰ�װһ���µ�������
                                            ;���룺EDX:EAX=������
                                            ;          EBX=TCB����ַ
                                            ;�����CX=��������ѡ����
         push eax
         push edx
         push edi
         push ds

         mov ecx,mem_0_4_gb_seg_sel
         mov ds,ecx

         mov edi,[ebx+0x0c]                 ;���LDT����ַ
         
         xor ecx,ecx
         mov cx,[ebx+0x0a]                  ;���LDT����
         inc cx                             ;LDT�����ֽ���������������ƫ�Ƶ�ַ
         
         mov [edi+ecx+0x00],eax
         mov [edi+ecx+0x04],edx             ;��װ������

         add cx,8                           
         dec cx                             ;�õ��µ�LDT����ֵ 

         mov [ebx+0x0a],cx                  ;����LDT����ֵ��TCB

         mov ax,cx
         xor dx,dx
         mov cx,8
         div cx
         
         mov cx,ax
         shl cx,3                           ;����3λ������
         or cx,0000_0000_0000_0100B         ;ʹTIλ=1��ָ��LDT�����ʹRPL=00 

         pop ds
         pop edi
         pop edx
         pop eax
     
         ret

;------------------------------------------------------------------------
;------------------------------------------------------------------------
append_to_tcb_link:                         ;��TCB����׷��������ƿ�
                                            ;���룺ECX=TCB���Ի���ַ
         push eax
         push edx
         push ds
         push es
         
         mov eax,core_data_seg_sel          ;��DSָ���ں����ݶ� 
         mov ds,eax
         mov eax,mem_0_4_gb_seg_sel         ;��ESָ��0..4GB��
         mov es,eax
         
         mov dword [es: ecx+0x00],0         ;��ǰTCBָ�������㣬��ָʾ������
                                            ;��һ��TCB
                                             
         mov eax,[tcb_chain]                ;TCB��ͷָ��
         or eax,eax                         ;����Ϊ�գ�
         jz .notcb 
         
  .searc:
         mov edx,eax
         mov eax,[es: edx+0x00]
         or eax,eax               
         jnz .searc
         
         mov [es: edx+0x00],ecx
         jmp .retpc
         
  .notcb:       
         mov [tcb_chain],ecx                ;��Ϊ�ձ�ֱ�����ͷָ��ָ��TCB
         
  .retpc:
         pop es
         pop ds
         pop edx
         pop eax
         
         ret

;------------------------------------------------------------------------
start:
         mov ecx,core_data_seg_sel          ;��DSָ��������ݶ� 
         mov ds,ecx

         mov ecx,mem_0_4_gb_seg_sel         ;��ESָ��4GB���ݶ� 
         mov es,ecx

         mov ebx,message_1                    
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

         ;���¿�ʼ��װΪ����ϵͳ����ĵ����š���Ȩ��֮��Ŀ���ת�Ʊ���ʹ����
         mov edi,salt                       ;C-SALT�����ʼλ�� 
         mov ecx,salt_items                 ;C-SALT�����Ŀ���� 
  .b3:
         push ecx   
         mov eax,[edi+256]                  ;����Ŀ��ڵ��32λƫ�Ƶ�ַ 
         mov bx,[edi+260]                   ;����Ŀ��ڵ�Ķ�ѡ���� 
         mov cx,1_11_0_1100_000_00000B      ;��Ȩ��3�ĵ�����(3���ϵ���Ȩ����
                                            ;�������)��0������(��Ϊ�üĴ���
                                            ;���ݲ�������û����ջ) 
         call sys_routine_seg_sel:make_gate_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+260],cx                   ;�����ص���������ѡ���ӻ���
         add edi,salt_item_len              ;ָ����һ��C-SALT��Ŀ 
         pop ecx
         loop .b3

         ;���Ž��в��� 
         mov ebx,message_2
         call far [salt_1+256]              ;ͨ������ʾ��Ϣ(ƫ������������) 

		 ;Ϊ�����������TSS����ռ�
		 mov ecx,104						;Ϊ�����TSS�����ڴ�
		 call sys_routine_seg_sel:allocate_memory
		 mov [prgman_tss+0x00],ecx			;��������������TSS����ַ

		 ;�ڳ����������TSS�����ñ�Ҫ����Ŀ
		 mov word [es:ecx+96],0				;û��LDT
		 mov word [es:ecx+102],103			;û��I/Oλͼ
		 mov word [es:ecx+0],0				;������ = 0
		 mov word [es:ecx+28],0				;�Ǽ�CR3��PDBR��
		 mov word [es:ecx+100],0			;T = 0������λ
											;����Ҫ0��1��2��Ȩ����ջ
											;0��Ȩ����������Ȩ������ת��

		;����TSS������������װ��GDT��
		mov eax,ecx
		mov ebx,103
		mov ecx,0x00408900					;TSS����������Ȩ��0
		call sys_routine_seg_sel:make_seg_descriptor
		call sys_routine_seg_sel:set_up_gdt_descriptor
		mov [prgman_tss+0x04],cx			;��������������TSS��������ѡ����

		;����Ĵ���TR�е�������������ڵı�־��������Ҳ�����˵�ǰ������˭��
        ;�����ָ��Ϊ��ǰ����ִ�е�0��Ȩ�����񡰳������������������TSS����
        ltr cx

		;�������������ִ��
		mov ebx,prgman_msg1
		call sys_routine_seg_sel:put_string

