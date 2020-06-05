TI_GDT  equ 0
RPL0    equ 0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

section .data
put_int_buffer dq 0             ;定义8字节缓冲区用于数字到字符的转换
;====================================================
    [bits 32]
;====================================================
section .text
;put_int_buffer dq 0             ;定义8字节缓冲区用于数字到字符的转换
;====================================================
global put_str
put_str:                        ;打印字符串
    push ebx
    push ecx
    xor ecx,ecx
    mov ebx,[esp+12]            ;从栈中得到待打印的字符串地址
.goon:
    mov cl,[ebx]
    cmp cl,0
    jz .str_over
    push ecx                    ;为put_char传递参数
    call put_char
    add esp,4                   ;回收参数占用的空间
    inc ebx                     ;指向下一个字符
    jmp .goon
.str_over:
    pop ecx
    pop ebx
    ret

;====================================================
global put_int
put_int:                        ;将小端字节序的数字变成对应的ASCII后,倒置
                                ;输入:栈中的参数为待打印的数字
                                ;输出:在屏幕打印十六进制数字,并不会打印前缀0x
    pushad
    mov ebp,esp
    mov eax,[ebp+4*9]
    mov edx,eax
    mov edi,7                   ;指定put_int_buffer中初始的偏移量
    mov ecx,8                   ;32位数字中,十六进制数字的位数是8
    mov ebx,put_int_buffer

    ;将32位数字按照十六进制的形式从低位到高位逐位处理,共处理8个十六进制数字
.16based_4bits:                 ;每4位二进制是十六进制数字的1位
    and edx,0x0000000f
    cmp edx,9
    jg .is_A2F
    add edx,'0'
    jmp .store
.is_A2F:
    sub edx,10                  ;A~F减去10得到的差,加上字符A的ASCII后就是对应的A~F的ASCII
    add edx,'A'

    ;将每一位数字转换成对应的字符后,按照类似"大端"的顺序存入到put_int_buffer中,高位存储在低地址
.store:
    mov [ebx+edi],dl            ;dl中是数字对应的ASCII
    dec edi
    shr eax,4
    mov edx,eax
    loop .16based_4bits

    ;把高位连续的字符去掉,如000123变成123
.ready_to_print:
    inc edi
.skip_prefix_0:
    cmp edi,8

    je .full0

.go_on_skip:
    mov cl,[put_int_buffer+edi]
    inc edi
    cmp cl,'0'
    je .skip_prefix_0
    dec edi
    jmp .put_each_num

.full0:
    mov cl,'0'
.put_each_num:
    push ecx
    call put_char
    add esp,4
    inc edi
    mov cl,[put_int_buffer+edi]
    cmp edi,8
    jl .put_each_num
    
    popad
    ret
;====================================================
global put_char
put_char:                       ;把栈中的1个字符写入光标所在处
    pushad                      ;备份32位寄存器环境

    mov ax,SELECTOR_VIDEO
    mov gs,ax                   ;确保gs为视频段的选择子

    ;获取当前光标高8位
    mov dx,0x03d4               ;索引寄存器
    mov al,0x0e                 ;用于提供光标位置的高8位
    out dx,al
    mov dx,0x03d5               ;通过读写数据端口0x03d5来获得或设置光标的位置
    in al,dx                    ;得到光标的高8位
    mov ah,al

    ;获取当前光标低8位
    mov dx,0x03d4
    mov al,0x0f                 ;提供光标位置的低8位
    out dx,al
    mov dx,0x03d5
    in al,dx

    mov bx,ax                   ;将光标位置存入bx
    mov ecx,[esp+36]            ;在栈中获得待打印字符
    
    cmp cl,0x0d                 ;判断是否是CR(回车)
    jz .is_carriage_return
    cmp cl,0x0a                 ;判断是否是LF(换行)
    jz .is_line_feed
    cmp cl,0x8                 ;判断是否是BS(退格)
    jz .is_backspace

    jmp .put_other

.is_backspace:
    dec bx
    shl bx,1                    ;一个字符占两个字节,乘2后是对应在显存中的偏移字节

    mov byte [gs:bx],0x20       ;将待删除的字节补为0或空格
    inc bx
    mov byte [gs:bx],0x07
    shr bx,1
    jmp .set_cursor

.put_other:
    shl bx,1

    mov byte [gs:bx],cl
    inc bx
    mov byte [gs:bx],0x07
    shr bx,1
    inc bx
    cmp bx,2000
    jl .set_cursor

.is_line_feed:                  ;处理换行,回车
.is_carriage_return:
    xor dx,dx                   ;被除数高16位,清0
    mov ax,bx
    mov si,80
    div si
    sub bx,dx

.is_carriage_return_end:        ;回车符CR处理结束
    add bx,80
    cmp bx,2000
.is_line_feed_end:              ;若是换行CR(\n),将光标+80即可
    jl .set_cursor

.roll_screen:                   ;超出屏幕大小,开始滚屏
    cld
    mov ecx,960                 ;2000-80=1920字符,1920*2=3840字节,3840/4=960次
    mov esi,0xc00b80a0          ;第1行行首
    mov edi,0xc00b8000          ;第0行行首
    ;mov esi,0xb80a0
    ;mov edi,0xb8000
    rep movsd

    ;将最后一行填充为空白
    mov ebx,3840                ;1920*2=3840,最后一行首字符的第一个字节偏移
    mov ecx,80
.cls:
    mov word [gs:ebx],0x0720    ;黑底白字的空格键
    ;mov word [gs:bx],0x0720
    add ebx,2
    loop .cls

    mov bx,1920                 ;将光标重置为1920,最后一行的首字符

.set_cursor:                    ;将光标设置为bx的值
    mov dx,0x03d4               ;索引寄存器
    mov al,0x0e                 ;索引光标位置的高8位
    out dx,al
    mov dx,0x03d5
    mov al,bh
    out dx,al

    mov dx,0x03d4
    mov al,0x0f
    out dx,al
    mov dx,0x03d5
    mov al,bl
    out dx,al

.put_char_done:
    popad

    ret

;=================================================
global set_cursor
set_cursor:
   pushad

   mov bx, [esp+36]

   mov dx, 0x03d4			  ;索引寄存器
   mov al, 0x0e				  ;用于提供光标位置的高8位
   out dx, al
   mov dx, 0x03d5			  ;通过读写数据端口0x3d5来获得或设置光标位置 
   mov al, bh
   out dx, al

   mov dx, 0x03d4
   mov al, 0x0f
   out dx, al
   mov dx, 0x03d5 
   mov al, bl
   out dx, al

   popad

   ret

global cls_screen
cls_screen:
    pushad
    mov ax, SELECTOR_VIDEO
    mov gs, ax   ;为gs赋值，用户程序使用系统调用陷入内核态gs为0

    mov ebx, 0
    mov ecx,80*25
.cls:
    mov word [gs:ebx],0x0720   ;黑底白字的空格键
    add ebx,2
    loop .cls
    mov ebx,0

   mov dx, 0x03d4			  ;索引寄存器
   mov al, 0x0e				  ;用于提供光标位置的高8位
   out dx, al
   mov dx, 0x03d5			  ;通过读写数据端口0x3d5来获得或设置光标位置 
   mov al, bh
   out dx, al

   mov dx, 0x03d4
   mov al, 0x0f
   out dx, al
   mov dx, 0x03d5 
   mov al, bl
   out dx, al
   popad
   ret
