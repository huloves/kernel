    ;文件说明:内核加载器
    ;更新日期:2020-2-18 23:15
    
    %include "boot.inc"

;=======================================================
    section loader vstart=LOADER_BASE_ADDR
;-------------------------------------------------------
    LOADER_STACK_TOP    equ LOADER_BASE_ADDR
    
    jmp loader_start
;=======================================================
    ;构建gdt及其内部的描述符
    GDT_BASE:           dd  0x00000000
                        dd  0x00000000

    CODE_DESC:          dd  0x0000ffff
                        dd  DESC_CODE_HIGH4

    DATA_STACK_DESC:    dd  0x0000ffff
                        dd  DESC_DATA_HIGH4

    VIDEO_DESC:         dd  0x80000007                  ;limit=(0xbfff-0xb800)/4k = 0x7, 0x000b8000
                        dd  DESC_VIDEO_HIGH4           ;此时DPL = 0

    GDT_SIZE            equ $-GDT_BASE
    GDT_LIMIT           equ GDT_SIZE-1
              times 60  dq  0                           ;预留60个描述符的空位
    SELECTOR_CODE       equ (0x0001<<3) + TI_GDT + RPL0 ;(CODE_DESC-GDT_BASE)/8 + TI_GDT + RPL0
    SELECTOR_DATA       equ (0x0002<<3) + TI_GDT + RPL0
    SELECTOR_VIDEO      equ (0x0003<<3) + TI_GDT + RPL0

    total_mem_bytes     dd 0                            ;保存内存容量,以字节为单位 #0xb00

    ;gdt的指针,前2字节是gdt界限,后4字节是gdt的起始地址
    gdt_ptr             dw  GDT_LIMIT
                        dd  GDT_BASE
    
    ;人工对齐:total_mem_bytes+gdt_ptr+ards_buf 244+ards_nr 2,共256字节, 4+6+244+2 = 256
    ards_buf  times 244 db 0
    ards_nr             dw  0                           ;用于记录ARDS结构体数量

    ;loadermag           db  '2 loader in real.'

;========================================================
loader_start:                   ;int 0x15 
                                ;输入:eax=0x0000E820, edx=0x524D4150 ('SMAP') 获取内存布局

    xor ebx,ebx                 ;第一次调用时,ebx值为0
    mov edx,0x534d4150          ;只赋值一次,在循环体中不会改变
    mov di,ards_buf             ;ards 结构缓冲区

.e820_mem_get_loop:
    mov eax,0x0000e820          ;执行int 0x15后,eax的值变为0x534d4150,所以每次执行前要重新赋值
    mov ecx,20                  ;ards地址范围描述符结构大小是 20bytes
    int 0x15
    jc .e820_failed_so_try_e801 ;若cf位为1,则发生错误,就去尝试使用0xe801子功能
    add di,cx                   ;使di增加20字节指向缓冲区中新的ards结构的位置
    inc word [ards_nr]          ;记录ARDS的数量
    cmp ebx,0                   ;若ebx为0,且cf不为1,说明ARDS全部返回,当前已经是最后一个
    jnz .e820_mem_get_loop

    ;在所有ARDS结构中,找出(base_add_low + length_low)的最大值,即内存的容量
    mov cx,[ards_nr]            ;遍历每一个ARDS结构体,循环次数为ARDS的数量
    mov ebx,ards_buf
    xor edx,edx                 ;最大的内存容量,在此先清0

.find_max_mem_area:             ;不用判断type是否为1,最大内存块一定是可以被使用的
    mov eax,[ebx]               ;base_add_low
    add eax,[ebx+8]             ;length_low
    add ebx,20                  ;指向下一个ARDS结构体
    cmp edx,eax                 ;冒泡排序,找到最大的内存大小
    jge .next_ards
    mov edx,eax                 ;edx为最大总内存大小
.next_ards:
    loop .find_max_mem_area
    jmp .mem_get_ok

;--------------------------------------------------------
.e820_failed_so_try_e801:       ;int 0x15 ax=0xe801
                                ;功能:获取内存大小,最大支持4G,
                                ;返回:,ax,cx中为低16MB,bx,dx中为16MB到4GB

    mov ax,0xe801
    int 0x15
    jc .e801_failed_so_try88    ;若当前方法失败,就尝试0x88

    ;1 算出15MB 的内存,ax,cx中是以KB为单位的内存数量,将其转换为byte为单位
    mov cx,0x400
    mul cx                      ;进制转换,cx为乘数
    shl edx,16                  ;乘以64KB
    and eax,0x0000ffff          ;?
    or edx,eax
    add edx,0x100000            ;ax 只是15MB,要加1MB

    ;2 将16MB以上的内存转换为byte为单位,bx,dx中是以64KB为单位的内存数量
    xor eax,eax
    mov ax,bx
    mov ecx,0x10000
    mul ecx                     ;32为乘法,高32位存储在edx,低32位存储在eax中

    add esi,eax                 ;此方法只能测出4GB以内的内存,eax足够了
    mov edx,esi                 ;edx肯定为0,只加eax
    jmp .mem_get_ok

;--------------------------------------------------------
.e801_failed_so_try88:          ;int 0x15
                                ;功能:获取内存大小,只能获取64MB之内
                                ;输入:ah=0x88

    mov ah,0x88
    int 0x15                    ;int 0x15之后,ax中存入以KB为单位的内存容量
    jc .error_hlt
    and eax,0x0000ffff

    mov cx,0x400
    mul cx                      ;16位乘法,积为32位,高16位在dx中,低16位在ax中
    shl edx,16                  ;把dx移到高16位
    or edx,eax                  ;把积的低16位组合到edx
    add edx,0x100000            ;0x88 子功能只返回1MB以上的内存,实际内存大小要加上1MB

;--------------------------------------------------------
.mem_get_ok:                    ;获取内存容量成功

    mov [total_mem_bytes],edx

;--------------------------------------------------------
.error_hlt:                     ;获取内存容量失败

    hlt

;--------------------------------------------------------
;INT 0x10   功能号:0x13     功能描述:打印字符串
;--------------------------------------------------------
;输入:
;AH: 子功能号--0x13
;BH: 页码
;BL: 属性(若AL=0x00 或 0x01)
;CX: 字符串长度
;(DH,DL): 坐标(行,列)
;ES:BP: 字符串地址
;AL: 输出方式
;   0: 字符串中只含显示字符,其显示属性在BL中,显示后,光标位置不变
;   1: 字符串中只含显示字符,其显示属性在BL中,显示后,光标位置改变
;   2: 字符串中含显示字符和显示属性,显示后,光标位置不变
;   3: 字符串中含显示字符和显示属性,显示后,光标位置改变
;无返回值
    mov sp,LOADER_BASE_ADDR
    mov bp,loadermag
    mov cx,17
    mov ax,0x1301
    mov bx,0x001f
    mov dx,0x1800
    int 0x10

;------------ 准备进入保护模式 ------------
;1 打开A20
;2 加载GDT
;3 将CR0的PE位置1

    ;打开A20
    in al,0x92
    or al,0000_0010B
    out 0x92,al

    ;加载GDT
    lgdt [gdt_ptr]

    ;CR0的PE位置1
    mov eax,cr0
    or eax,0x00000001
    mov cr0,eax

    jmp dword SELECTOR_CODE:p_mode_start ;刷新流水线

;------------------------------------------------------------
    [bits 32]
;------------------------------------------------------------
p_mode_start:
    mov ax,SELECTOR_DATA
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,LOADER_STACK_TOP
    mov ax,SELECTOR_VIDEO
    mov gs,ax

    mov byte [gs:160],'P'
    ;mov byte [gs:161],0001_0100B

    jmp $