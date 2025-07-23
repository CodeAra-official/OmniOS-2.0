; OmniOS 2.0 Custom Bootloader
; Stage 1: Master Boot Record (MBR) - 512 bytes
; Written in Assembly for optimal performance and direct hardware control

[BITS 16]
[ORG 0x7C00]

; Boot sector signature and BPB (BIOS Parameter Block)
jmp short bootloader_start
nop

; FAT32 BPB for compatibility
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

; Extended boot record
drive_number       db 0
reserved           db 0
boot_signature     db 0x29
volume_id          dd 0x12345678
volume_label       db "OMNIOS 2.0 "
filesystem_type    db "FAT12   "

bootloader_start:
    ; Initialize segments and stack
    cli                     ; Disable interrupts
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00         ; Set stack pointer
    sti                     ; Enable interrupts
    
    ; Clear screen and set video mode
    mov ax, 0x0003         ; 80x25 color text mode
    int 0x10
    
    ; Display boot message
    mov si, boot_message
    call print_string
    
    ; Save boot drive
    mov [boot_drive], dl
    
    ; Load stage 2 bootloader
    call load_stage2
    
    ; Jump to stage 2
    jmp 0x1000:0x0000

; Print string function
print_string:
    pusha
    mov ah, 0x0E           ; BIOS teletype function
.print_loop:
    lodsb                  ; Load byte from SI into AL
    cmp al, 0              ; Check for null terminator
    je .print_done
    int 0x10               ; Print character
    jmp .print_loop
.print_done:
    popa
    ret

; Load stage 2 bootloader from disk
load_stage2:
    pusha
    
    ; Display loading message
    mov si, loading_message
    call print_string
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    
    ; Load stage 2 (sectors 2-5, 4 sectors = 2KB)
    mov ah, 0x02           ; Read sectors function
    mov al, 4              ; Number of sectors to read
    mov ch, 0              ; Cylinder 0
    mov cl, 2              ; Start from sector 2
    mov dh, 0              ; Head 0
    mov dl, [boot_drive]   ; Drive number
    mov bx, 0x1000         ; Load to 0x1000:0x0000
    mov es, bx
    mov bx, 0x0000
    int 0x13
    jc disk_error
    
    ; Verify stage 2 signature
    mov ax, 0x1000
    mov es, ax
    cmp word [es:0x0000], 0x5432  ; Stage 2 signature
    jne stage2_error
    
    popa
    ret

disk_error:
    mov si, disk_error_message
    call print_string
    jmp halt_system

stage2_error:
    mov si, stage2_error_message
    call print_string
    jmp halt_system

halt_system:
    mov si, halt_message
    call print_string
    cli
    hlt
    jmp $

; Data section
boot_message        db 'OmniOS 2.0 Bootloader v1.0', 0x0D, 0x0A, 0
loading_message     db 'Loading Stage 2...', 0x0D, 0x0A, 0
disk_error_message  db 'Disk Error!', 0x0D, 0x0A, 0
stage2_error_message db 'Stage 2 Error!', 0x0D, 0x0A, 0
halt_message        db 'System Halted.', 0x0D, 0x0A, 0

boot_drive          db 0

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55
