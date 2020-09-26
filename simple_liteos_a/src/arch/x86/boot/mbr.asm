    %include "boot.inc"

    org 0x7c00
    [bits 16]
    
    align 16

entry:
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov sp, 0
    mov ax, 0xb800
    mov es, ax

clean_screen:
    mov ax, 0x02
    int 0x10
    ;show 'BOOT'
    mov byte [es:0],'B'
	mov byte [es:1],0x07
	mov byte [es:2],'O'
	mov byte [es:3],0x07
	mov byte [es:4],'O'
	mov byte [es:5],0x07
	mov byte [es:6],'T'
	mov byte [es:7],0x07

    mov eax, LOADER_START_SECTOR
    mov bx, LOADER_BASE_ADDR
    mov cx, 4
    call rd_disk_m_16

    jmp LOADER_BASE_ADDR   ;循环，查看是否打印

;------------------------------------------------------------------
;功能:读取硬盘n个扇区
;------------------------------------------------------------------
rd_disk_m_16:						;eax=LBA扇区号
									;bx=将数据写入的内存地址
									;cx=读入的扇区数
	
	mov esi,eax						;备份eax
	mov di,cx						;备份cx
;读写硬盘:
;step 1:设置要读取的扇区数
	mov dx,0x1f2
	mov al,cl
	out dx,al						;读取的扇区数

	mov eax,esi						;恢复eax

;step 2:将LBA地址存入0x1f3~0x1f6

	;LBA地址7~0位写入0x1f3
	mov dx,0x1f3
	out dx,al

	;LBA地址15~8位写入0x1f4
	mov cl,8
	shr eax,cl
	mov dx,0x1f4
	out dx,al

	;LBA地址23~16位写入0x1f5
	shr eax,cl
	mov dx,0x1f5
	out dx,al

	shr eax,cl
	and al,0x0f						;lba第27~24位
	or al,0xe0						;设置0x1f6 7~4位1110,表示lba模式
	mov dx,0x1f6
	out dx,al

;step 3:向0x1f7端口写入读命令,0x20
	mov dx,0x1f7
	mov al,0x20
	out dx,al

;step 4:检测硬盘状态
.not_ready:
	;同一端口,写时表示命令字,读时表示读入硬盘状态
	nop								;空操作,什么也不做,为了增加延迟,减少打扰硬盘的工作
	in al,dx
	and al,0x88						;第4位表示硬盘控制器准备好数据传输,位7表示硬盘忙
	cmp al,0x08
	jnz .not_ready

;step 5:从0x1f0端口读数据
	mov ax,di
	mov dx,256
	mul dx
	mov cx,ax						;设置循环次数,每次读取一个字,一个扇区512字节

	mov dx,0x1f0
.go_on_read:
	in ax,dx
	mov [bx],ax
	add bx,2
	loop .go_on_read
	
	ret

times 510-($-$$) db 0
    dw 0xaa55
