; OmniOS 2.0 Bootloader - Enhanced Edition
; Fixed bootloader that properly loads kernel
[BITS 16]
[ORG 0x7C00]

; Jump to bootloader start
jmp short start
nop

; BIOS Parameter Block (BPB) for FAT12
oem_label           db "OMNIOS20"
bytes_per_sector    dw 512
sectors_per_cluster db 1
reserved_sectors    dw 1
fat_count          db 2
root_entries       dw 224
total_sectors      dw 2880
media_descriptor   db 0xF0
sectors_per_fat    dw 9
sectors_per_track  dw 18
heads_per_cylinder dw 2
hidden_sectors     dd 0
large_sectors      dd 0

; Extended Boot Record
drive_number       db 0
reserved           db 0
boot_signature     db 0x29
volume_id          dd 0x12345678
volume_label       db "OMNIOS 2.0 "
filesystem_type    db "FAT12   "

start:
    ; Initialize segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Clear screen with professional theme
    mov ax, 0x0003
    int 0x10
    
    ; Set blue background
    mov ah, 0x06
    mov al, 0
    mov bh, 0x1F        ; White text on blue background
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    
    ; Display boot message
    mov si, boot_msg
    call print_string
    
    ; Save boot drive
    mov [boot_drive], dl
    
    ; Load kernel directly from specific sectors
    call load_kernel_direct
    
    ; Jump to kernel
    jmp 0x1000:0x0000

; Print string function
print_string:
    pusha
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
    popa
    ret

; Load kernel directly from sectors (fixed approach)
load_kernel_direct:
    pusha
    
    mov si, loading_msg
    call print_string
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    
    ; Load kernel starting from sector 2 (after bootloader)
    ; Load multiple sectors to ensure we get the full kernel
    mov ah, 0x02        ; Read sectors function
    mov al, 50          ; Number of sectors to read (25KB)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2
    mov dh, 0           ; Head 0
    mov dl, [boot_drive] ; Drive number
    mov bx, 0x1000      ; Load to segment 0x1000
    mov es, bx
    mov bx, 0x0000      ; Offset 0
    int 0x13
    jc disk_error
    
    ; Verify we loaded something
    mov ax, 0x1000
    mov es, ax
    mov bx, 0x0000
    mov al, [es:bx]
    cmp al, 0
    je disk_error
    
    mov si, success_msg
    call print_string
    
    popa
    ret

disk_error:
    mov si, error_msg
    call print_string
    
    ; Try alternative loading method
    mov si, retry_msg
    call print_string
    
    ; Alternative: Load from different sectors
    mov ah, 0x02
    mov al, 30          ; Try fewer sectors
    mov ch, 0
    mov cl, 3           ; Try sector 3
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, 0x1000
    mov es, bx
    mov bx, 0x0000
    int 0x13
    jnc .success
    
    ; If still fails, halt
    mov si, fatal_error_msg
    call print_string
    cli
    hlt
    jmp $

.success:
    mov si, alt_success_msg
    call print_string
    ret

; Data
boot_msg         db 'OmniOS 2.0 Professional Operating System', 0x0D, 0x0A, 0
loading_msg      db 'Loading enhanced kernel...', 0x0D, 0x0A, 0
success_msg      db 'Kernel loaded successfully!', 0x0D, 0x0A, 0
error_msg        db 'Kernel load error! Trying alternative...', 0x0D, 0x0A, 0
retry_msg        db 'Attempting alternative load method...', 0x0D, 0x0A, 0
alt_success_msg  db 'Alternative load successful!', 0x0D, 0x0A, 0
fatal_error_msg  db 'FATAL: Cannot load kernel! System halted.', 0x0D, 0x0A, 0

boot_drive       db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
