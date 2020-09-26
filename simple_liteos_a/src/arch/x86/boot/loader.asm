    %include "boot.inc"

;===============================================
    section loader vstart=LOADER_BASE_ADDR
;-----------------------------------------------
    LOADER_STACK_TOP equ LOADER_BASE_ADDR
    
    jmp loader_start

loader_start:
    mov byte [es:0], 'L'

    jmp $