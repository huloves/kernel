;文件说明:主引导程序
;创建日期:2020-2-14 21:45

;LOADER_BASE_ADDR equ 0xA000
;LOADER_START_SECTION equ 0x2

;-------------------------------------------------------------------
SECTION MBR vstart=0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax

;清屏
;利用0x06号功能,上卷全部行,则可清屏
;---------------------------------------------------------------------
;INT 0x10 功能号:0x06 功能描述:上卷窗口
;---------------------------------------------------------------------
    mov ax,0x0600
    mov bx,0x0700
    mov cx,0
    mov dx,0x184f

    int 0x10

    ;输出背景色蓝色,前景色红色,并且跳动的字符串"1 MBR"
    mov byte [gs:0x00],'1'
    mov byte [gs:0x01],1001_0100B

    mov byte [gs:0x02],' '
    mov byte [gs:0x03],0x94

    mov byte [gs:0x04],'M'
    mov byte [gs:0x05],0x94

    mov byte [gs:0x06],'B'
    mov byte [gs:0x07],0x94

    mov byte [gs:0x08],'R'
    mov byte [gs:0x09],0x94

    jmp $

    times 510-($-$$) db 0
    db 0x55,0xaa