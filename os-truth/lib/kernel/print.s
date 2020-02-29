TI_GDT  equ 0
RPL0    equ 0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

;----------------------------------------------------
    [bits 32]
;----------------------------------------------------
section .text

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
    cmp cl,0x08                 ;判断是否是BS(退格)
    jz .is_backspace

    jmp .put_other

;-------------------------------------------------------
.is_backspace:
    dec bx
    shl bx,1                    ;一个字符占两个字节,乘2后是对应在显存中的偏移字节

    mov byte [gs:bx],0x20       ;将待删除的字节补为0或空格
    inc bx
    mov byte [gs:bx],0x07
    shr bx,1
    jmp .set_cursor

;------------------------------------------------------
.put_other:
    shl bx,1

    mov byte [gs:bx],cl
    inc bx
    mov byte [gs:bx],0x07
    shr bx,1
    inc bx
    cmp bx,2000
    jl .set_cursor

;-----------------------------------------------------
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

;-----------------------------------------------------
.roll_screen:                   ;超出屏幕大小,开始滚屏
    cld
    mov ecx,960                 ;2000-80=1920字符,1920*2=3840字节,3840/4=960次
    mov esi,0xc00b80a0          ;第1行行首
    mov edi,0xc00b8000          ;第0行行首
    rep movsd

    ;将最后一行填充为空白
    mov ebx,3840                ;1920*2=3840,最后一行首字符的第一个字节偏移
    mov ecx,80
.cls:
    mov word [gs:ebx],0x0720    ;黑底白字的空格键
    add ebx,2
    loop .cls

    mov bx,1920                 ;将光标重置为1920,最后一行的首字符

;-----------------------------------------------------
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

;-----------------------------------------------------
.put_char_done:
    popad

    ret