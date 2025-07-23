; OmniOS 2.0 Professional Bootloader
; Compact 512-byte bootloader with essential functionality

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
    
    ; Load kernel from disk
    call load_kernel
    
    ; Jump to kernel
    jmp 0x1000:0x0000

; Print string function
print_string:
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0A  ; Green text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; Load kernel from disk
load_kernel:
    mov si, loading_msg
    call print_string
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, 0x00
    int 0x13
    
    ; Load kernel (18 sectors starting from sector 2)
    mov ah, 0x02        ; Read sectors
    mov al, 18          ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive A
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
    cli
    hlt

; Boot messages
boot_msg    db 'OmniOS 2.0 Professional Edition', 13, 10
            db 'Booting system...', 13, 10, 0

loading_msg db 'Loading kernel...', 13, 10, 0
success_msg db 'Kernel loaded successfully!', 13, 10, 0
error_msg   db 'Disk read error!', 13, 10, 0

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55
