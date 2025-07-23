; OmniOS 2.0 Professional Edition Bootloader
; Enhanced bootloader with first boot detection and professional output
[BITS 16]
[ORG 0x7C00]

; Bootloader entry point
start:
    ; Initialize segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Clear screen with black background
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07        ; Light gray on black
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
    
    ; Display bootloader header
    mov si, boot_header
    call print_string
    
    ; Check for first boot by reading setup flag from sector 20
    call check_first_boot
    
    ; Display appropriate message
    cmp byte [first_boot], 1
    je .first_boot_msg
    
    ; Not first boot
    mov si, boot_msg_normal
    call print_string
    jmp .continue_boot
    
.first_boot_msg:
    mov si, boot_msg_first
    call print_string
    
.continue_boot:
    ; Store first boot flag at memory location 0x500 for kernel
    mov al, [first_boot]
    mov [0x500], al
    
    ; Load kernel from disk
    mov si, loading_msg
    call print_string
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, 0x00        ; Drive A
    int 0x13
    jc disk_error
    
    ; Load kernel (18 sectors starting from sector 2)
    mov ah, 0x02        ; Read sectors
    mov al, 18          ; Number of sectors to read
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive A
    mov bx, 0x1000      ; Load to 0x1000:0x0000
    mov es, bx
    mov bx, 0x0000
    
    int 0x13
    jc disk_error
    
    ; Display success message
    mov si, success_msg
    call print_string
    
    ; Small delay to show message
    mov cx, 0x8000
delay_loop:
    nop
    loop delay_loop
    
    ; Jump to kernel
    jmp 0x1000:0x0000

; Check if this is first boot
check_first_boot:
    ; Try to read setup flag from sector 20
    mov ah, 0x02        ; Read sectors
    mov al, 1           ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 20          ; Sector 20
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive A
    mov bx, 0x600       ; Load to 0x600
    mov es, bx
    mov bx, 0x0000
    
    int 0x13
    jc .first_boot      ; If read fails, assume first boot
    
    ; Check for setup signature
    mov ax, [es:0x0000]
    cmp ax, 0x4F53      ; "SO" signature
    je .not_first_boot
    
.first_boot:
    mov byte [first_boot], 1
    ret
    
.not_first_boot:
    mov byte [first_boot], 0
    ret

; Disk error handler
disk_error:
    mov si, error_msg
    call print_string
    
    ; Wait for key press
    mov ah, 0x00
    int 0x16
    
    ; Reboot
    int 0x19

; Print string function
print_string:
    push ax
    push bx
    
.print_loop:
    lodsb
    cmp al, 0
    je .done
    
    ; Print character with color
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F        ; White text
    int 0x10
    
    jmp .print_loop

.done:
    pop bx
    pop ax
    ret

; Data section
boot_header         db 'OmniOS 2.0 Professional Edition Bootloader', 13, 10, 0
boot_msg_first      db 'First boot detected - Setup will be initialized', 13, 10, 0
boot_msg_normal     db 'System boot - Loading user environment', 13, 10, 0
loading_msg         db 'Loading kernel...', 13, 10, 0
success_msg         db 'Kernel loaded successfully', 13, 10, 0
error_msg           db 'Disk read error! Press any key to reboot...', 13, 10, 0

; Variables
first_boot          db 1

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55
