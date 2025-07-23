; OmniOS 2.0 Print Functions
; Enhanced printing with colors and formatting

print_colored:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F        ; White text
    
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
    mov bl, 0x0C        ; Red text
    
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
    mov bl, 0x0A        ; Green text
    
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
