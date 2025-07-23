; OmniOS 2.0 Professional Bootloader - Compact Version
; Exactly 512 bytes with essential functionality

[BITS 16]
[ORG 0x7C00]

start:
    ; Initialize segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Clear screen
    mov ax, 0x0003
    int 0x10
    
    ; Display boot message
    mov si, boot_msg
    call print_string
    
    ; Set first boot flag
    mov byte [0x500], 1
    
    ; Load kernel
    call load_kernel
    
    ; Jump to kernel
    jmp 0x1000:0x0000

print_string:
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0A
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

load_kernel:
    mov si, loading_msg
    call print_string
    
    ; Reset disk
    mov ah, 0x00
    mov dl, 0x00
    int 0x13
    
    ; Load 18 sectors from sector 2
    mov ah, 0x02
    mov al, 18
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x00
    mov bx, 0x1000
    mov es, bx
    mov bx, 0x0000
    
    int 0x13
    jc error
    
    mov si, success_msg
    call print_string
    ret

error:
    mov si, error_msg
    call print_string
    cli
    hlt

; Compact messages
boot_msg    db 'OmniOS 2.0 Professional Edition', 13, 10
            db 'Bootloader v2.0', 13, 10, 13, 10, 0

loading_msg db 'Loading kernel...', 13, 10, 0
success_msg db 'Kernel loaded! Starting system...', 13, 10, 0
error_msg   db 'Disk error!', 13, 10, 0

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55
