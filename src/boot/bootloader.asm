; OmniOS 2.0 Bootloader - Enhanced Edition
; Simplified bootloader that loads kernel directly
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
    
    ; Load kernel directly
    call load_kernel
    
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

; Load kernel from disk
load_kernel:
    pusha
    
    mov si, loading_msg
    call print_string
    
    ; Reset disk
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    
    ; Load kernel (sectors 2-30)
    mov ah, 0x02        ; Read sectors
    mov al, 28          ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start sector 2
    mov dh, 0           ; Head 0
    mov dl, [boot_drive]
    mov bx, 0x1000      ; Load to 0x1000:0x0000
    mov es, bx
    mov bx, 0x0000
    int 0x13
    jc disk_error
    
    popa
    ret

disk_error:
    mov si, error_msg
    call print_string
    cli
    hlt

; Data
boot_msg     db 'OmniOS 2.0 - Professional Operating System', 0x0D, 0x0A, 0
loading_msg  db 'Loading system kernel...', 0x0D, 0x0A, 0
error_msg    db 'BOOT ERROR: Cannot load kernel!', 0x0D, 0x0A, 0

boot_drive   db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
