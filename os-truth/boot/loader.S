;文件说明:内核加载器
;创建日期:2020-2-15 13:03
%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR

    ;输出背景色蓝色,前景色红色,并且跳动的字符串"1 MBR"
    mov byte [gs:0x00],'2'
    mov byte [gs:0x01],1001_0100B

    mov byte [gs:0x02],' '
    mov byte [gs:0x03],0x94

    mov byte [gs:0x04],'L'
    mov byte [gs:0x05],0x94

    mov byte [gs:0x06],'O'
    mov byte [gs:0x07],0x94

    mov byte [gs:0x08],'A'
    mov byte [gs:0x09],0x94

    mov byte [gs:0x0a],'D'
    mov byte [gs:0x0b],0x94

    mov byte [gs:0x0c],'E'
    mov byte [gs:0x0d],0x94

    mov byte [gs:0x0e],'R'
    mov byte [gs:0x0f],0x94

    jmp $