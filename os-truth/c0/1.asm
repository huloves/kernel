section .bss
resb 2*32

section file1data

strHello    db  "hello,world",0AH
STRLEN  equ $-strHello

section file1text
extern print

global _start

_start:
    push STRLEN
    push strHello
    call print
            
;返回操作系统
    mov ebx,0
    mov eax,1
    int 0x80
