; OmniOS 2.0 Bootloader - Fixed Version
; Black background, proper kernel loading
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
    
    ; Clear screen with BLACK background
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07        ; Light gray text on BLACK background
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    
    ; Set cursor to top
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 0x10
    
    ; Display boot message
    mov si, boot_msg
    call print_string
    
    ; Save boot drive
    mov [boot_drive], dl
    
    ; Load kernel
    call load_kernel
    
    ; Jump to kernel
    jmp 0x1000:0x0000

; Print string function
print_string:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07        ; Light gray text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

; Load kernel from disk
load_kernel:
    pusha
    
    mov si, loading_msg
    call print_string
    
    ; Reset disk
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    
    ; Load kernel (simple approach)
    mov ah, 0x02        ; Read sectors
    mov al, 10          ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start sector 2
    mov dh, 0           ; Head 0
    mov dl, [boot_drive]
    mov bx, 0x1000      ; Load to 0x1000:0x0000
    mov es, bx
    mov bx, 0x0000
    int 0x13
    jc disk_error
    
    mov si, success_msg
    call print_string
    
    popa
    ret

disk_error:
    mov si, error_msg
    call print_string
    cli
    hlt

; Data
boot_msg     db 'OmniOS 2.0 Starting...', 0x0D, 0x0A, 0
loading_msg  db 'Loading OmniOS kernel...', 0x0D, 0x0A, 0
success_msg  db 'Kernel loaded!', 0x0D, 0x0A, 0
error_msg    db 'Boot Error!', 0x0D, 0x0A, 0
boot_drive   db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
