; OmniOS 2.0 Print Functions - Black Background Only
print_char:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07        ; Light gray text on black
    int 0x10
    popa
    ret

print_success:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0A        ; Green text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

print_error:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0C        ; Red text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

print_colored:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F        ; White text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    pupa
    ret

delay:
    pusha
    mov cx, 0x0001
    mov dx, 0x0000
.delay_loop:
    dec dx
    jnz .delay_loop
    dec cx
    jnz .delay_loop
    popa
    ret
