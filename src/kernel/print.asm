; OmniOS 2.0 Kernel Print Functions
; Additional print functions for kernel use

print_hex:
    ; Print hexadecimal number in AX
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 4
    mov bx, ax
    
.hex_loop:
    rol bx, 4
    mov al, bl
    and al, 0x0F
    cmp al, 9
    jle .digit
    add al, 7
.digit:
    add al, '0'
    mov ah, 0x0E
    int 0x10
    loop .hex_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_dec:
    ; Print decimal number in AX
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    mov cx, 0
    
.dec_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .dec_loop
    
.print_loop:
    pop ax
    add al, '0'
    mov ah, 0x0E
    int 0x10
    loop .print_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
