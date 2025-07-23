; OmniOS 2.0 Enhanced Bootloader with First Boot Detection
; Professional bootloader with setup flag management
[BITS 16]
[ORG 0x7C00]

bootloader_start:
    ; Initialize segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Save boot drive
    mov [boot_drive], dl
    
    ; Clear screen with black background (professional look)
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07        ; Light gray text on black background
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
    
    ; Check for first boot by reading setup flag from sector 20
    call check_first_boot
    
    ; Store first boot flag at memory location 0x500 for kernel
    mov [0x500], al
    
    ; Load kernel from disk
    call load_kernel
    
    ; Display jump message
    mov si, jump_msg
    call print_string
    
    ; Small delay to show message
    mov cx, 0x8000
.delay:
    nop
    loop .delay
    
    ; Jump to kernel with proper segment setup
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    jmp 0x1000:0x0000

; Check if this is the first boot
check_first_boot:
    ; Read sector 20 to check for setup completion flag
    mov ah, 0x02        ; Read sectors
    mov al, 1           ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 20          ; Sector 20
    mov dh, 0           ; Head 0
    mov dl, [boot_drive] ; Boot drive
    mov bx, 0x600       ; Load to 0x600
    push es
    mov ax, 0x0000
    mov es, ax
    
    int 0x13
    pop es
    jc .first_boot      ; If read fails, assume first boot
    
    ; Check for setup completion signature
    push ds
    mov ax, 0x0000
    mov ds, ax
    mov ax, [0x600]
    pop ds
    cmp ax, 0x4F53      ; "SO" signature (Setup Ok)
    je .not_first_boot
    
.first_boot:
    mov al, 1           ; First boot flag
    mov si, first_boot_msg
    call print_string
    ret

.not_first_boot:
    mov al, 0           ; Not first boot
    mov si, normal_boot_msg
    call print_string
    ret

; Load kernel from disk
load_kernel:
    mov si, loading_msg
    call print_string
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    
    ; Load kernel (18 sectors starting from sector 2)
    mov ah, 0x02        ; Read sectors
    mov al, 18          ; Number of sectors (9KB kernel)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2
    mov dh, 0           ; Head 0
    mov dl, [boot_drive] ; Boot drive
    mov bx, 0x1000      ; Load kernel to 0x1000:0x0000
    mov es, bx
    mov bx, 0x0000
    
    int 0x13
    jc disk_error
    
    mov si, kernel_loaded_msg
    call print_string
    ret

; Handle disk read error
disk_error:
    mov si, disk_error_msg
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

; Boot messages
boot_msg            db 'OmniOS 2.0 Professional Edition Bootloader', 13, 10, 0
first_boot_msg      db 'First boot detected - Setup will be initialized', 13, 10, 0
normal_boot_msg     db 'System configured - Loading user authentication', 13, 10, 0
loading_msg         db 'Loading kernel...', 13, 10, 0
kernel_loaded_msg   db 'Kernel loaded successfully', 13, 10, 0
jump_msg            db 'Starting kernel...', 13, 10, 0
disk_error_msg      db 'Disk read error! Press any key to reboot...', 13, 10, 0

; Boot drive storage
boot_drive          db 0

; Boot sector signature
times 510-($-$$) db 0
dw 0xAA55
