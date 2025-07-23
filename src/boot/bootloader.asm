; OmniOS 2.0 Enhanced Bootloader with Setup Detection
; Detects first boot and loads appropriate kernel mode
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
    
    ; Display enhanced boot message
    mov si, boot_msg
    call print_string
    
    ; Save boot drive
    mov [boot_drive], dl
    
    ; Check for first boot
    call check_first_boot
    
    ; Load kernel
    call load_kernel
    
    ; Pass first boot flag to kernel
    mov al, [first_boot_flag]
    mov [0x500], al     ; Store at known memory location
    
    ; Jump to kernel
    jmp 0x1000:0x0000

; Print string function with color support
print_string:
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
    popa
    ret

; Check if this is first boot
check_first_boot:
    pusha
    
    ; Try to read setup flag from sector 20 (after kernel)
    mov ah, 0x02        ; Read sectors
    mov al, 1           ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 20          ; Sector 20 (setup data)
    mov dh, 0           ; Head 0
    mov dl, [boot_drive]
    mov bx, 0x600       ; Load to temporary location
    mov es, bx
    mov bx, 0x0000
    int 0x13
    jc .first_boot      ; If read fails, assume first boot
    
    ; Check setup signature
    mov ax, 0x600
    mov es, ax
    cmp word [es:0x0000], 0x4F53  ; "SO" signature (Setup Ok)
    jne .first_boot
    
    ; Setup exists, not first boot
    mov byte [first_boot_flag], 0
    mov si, returning_user_msg
    call print_string
    jmp .done
    
.first_boot:
    mov byte [first_boot_flag], 1
    mov si, first_boot_msg
    call print_string
    
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
    
    ; Load kernel (sectors 2-19)
    mov ah, 0x02        ; Read sectors
    mov al, 18          ; Number of sectors to read
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
boot_msg         db 'OmniOS 2.0 Enhanced Edition Loading...', 0x0D, 0x0A, 0
first_boot_msg   db 'First boot detected - Setup will run', 0x0D, 0x0A, 0
returning_user_msg db 'Welcome back to OmniOS 2.0', 0x0D, 0x0A, 0
loading_msg      db 'Loading Enhanced Kernel...', 0x0D, 0x0A, 0
success_msg      db 'Kernel loaded successfully!', 0x0D, 0x0A, 0
error_msg        db 'Boot Error - System Halted!', 0x0D, 0x0A, 0

boot_drive       db 0
first_boot_flag  db 1

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
