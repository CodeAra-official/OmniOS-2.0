; OmniOS 2.0 Enhanced Print Functions with Black Background
[BITS 16]

print_colored:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F        ; White text on black background
    
.print_loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_loop
    
.done:
    popa
    ret

print_error:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0C        ; Red text on black background
    
.print_loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_loop
    
.done:
    popa
    ret

print_success:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0A        ; Green text on black background
    
.print_loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_loop
    
.done:
    popa
    ret

print_warning:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0E        ; Yellow text on black background
    
.print_loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_loop
    
.done:
    popa
    ret

newline:
    pusha
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    popa
    ret

print_char:
    pusha
    mov ah, 0x0E
    int 0x10
    popa
    ret

clear_screen:
    ; Clear screen with black background instead of blue
    mov ah, 0x06
    mov al, 0
    mov bh, 0x0F        ; White text on black background
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    
    ; Reset cursor
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 0x10
    
    ret
