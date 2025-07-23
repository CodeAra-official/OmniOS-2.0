; OmniOS 2.0 Professional Bootloader
; Enhanced bootloader with first boot detection and professional design

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

    ; Clear screen with professional black background
    mov ax, 0x0003
    int 0x10

    ; Set text color to bright green on black
    mov ah, 0x09
    mov al, ' '
    mov bh, 0
    mov bl, 0x0A  ; Bright green on black
    mov cx, 2000  ; Fill entire screen
    int 0x10

    ; Display professional boot logo
    call display_logo
    
    ; Check for first boot
    call check_first_boot
    
    ; Load kernel from disk
    call load_kernel
    
    ; Jump to kernel
    jmp 0x1000:0x0000

display_logo:
    mov si, logo_msg
    call print_string
    
    mov si, version_msg
    call print_string
    
    mov si, loading_msg
    call print_string
    ret

check_first_boot:
    ; Check if this is first boot by reading a marker from disk
    ; For now, we'll assume it's always first boot for setup
    mov byte [first_boot_flag], 1
    ret

load_kernel:
    ; Reset disk system
    mov ah, 0x00
    mov dl, 0x00
    int 0x13
    jc disk_error

    ; Load kernel (18 sectors starting from sector 2)
    mov ah, 0x02        ; Read sectors function
    mov al, 18          ; Number of sectors to read
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2
    mov dh, 0           ; Head 0
    mov dl, 0           ; Drive 0 (floppy)
    mov bx, 0x1000      ; Load to 0x1000:0x0000
    mov es, bx
    mov bx, 0x0000
    int 0x13
    jc disk_error

    mov si, kernel_loaded_msg
    call print_string
    ret

disk_error:
    mov si, disk_error_msg
    call print_string
    hlt

print_string:
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0A  ; Bright green
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; Data section
logo_msg db 13, 10
         db '  ██████╗ ███╗   ███╗███╗   ██╗██╗ ██████╗ ███████╗', 13, 10
         db ' ██╔═══██╗████╗ ████║████╗  ██║██║██╔═══██╗██╔════╝', 13, 10
         db ' ██║   ██║██╔████╔██║██╔██╗ ██║██║██║   ██║███████╗', 13, 10
         db ' ██║   ██║██║╚██╔╝██║██║╚██╗██║██║██║   ██║╚════██║', 13, 10
         db ' ╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║╚██████╔╝███████║', 13, 10
         db '  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚══════╝', 13, 10, 0

version_msg db 13, 10, '           Professional Edition v2.0', 13, 10
            db '           Enhanced Operating System', 13, 10, 13, 10, 0

loading_msg db 'Initializing system components...', 13, 10
            db 'Loading kernel modules...', 13, 10, 0

kernel_loaded_msg db 'Kernel loaded successfully!', 13, 10
                  db 'Starting OmniOS 2.0...', 13, 10, 13, 10, 0

disk_error_msg db 13, 10, 'DISK ERROR: Unable to load kernel!', 13, 10
               db 'System halted.', 13, 10, 0

first_boot_flag db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
