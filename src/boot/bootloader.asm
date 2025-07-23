; OmniOS 2.0 Professional Bootloader
; Compact bootloader with essential functionality

[BITS 16]
[ORG 0x7C00]

start:
    ; Initialize segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Clear screen
    mov ax, 0x0003
    int 0x10

    ; Display boot message
    mov si, boot_msg
    call print_string
    
    ; Load kernel from disk
    call load_kernel
    
    ; Jump to kernel
    jmp 0x1000:0x0000

load_kernel:
    ; Reset disk system
    mov ah, 0x00
    mov dl, 0x00
    int 0x13
    jc disk_error

    ; Load kernel (18 sectors starting from sector 2)
    mov ah, 0x02        ; Read sectors
    mov al, 18          ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2
    mov dh, 0           ; Head 0
    mov dl, 0           ; Drive 0
    mov bx, 0x1000      ; Load to 0x1000:0x0000
    mov es, bx
    mov bx, 0x0000
    int 0x13
    jc disk_error

    mov si, success_msg
    call print_string
    ret

disk_error:
    mov si, error_msg
    call print_string
    hlt

print_string:
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; Messages
boot_msg    db 'OmniOS 2.0 Professional Edition', 13, 10
            db 'Loading kernel...', 13, 10, 0
success_msg db 'Kernel loaded!', 13, 10, 0
error_msg   db 'Disk error!', 13, 10, 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
