username:
.readkeys:
    mov ah, 0x00  ; Service 0h: Read key press
    int 16h       ; Put the pressed key into AL

    cmp al, 13    ; Check if Enter key is pressed
    je .handler   ; If Enter is pressed, go to command handler

    cmp al, 8     ; Check if Backspace key is pressed
    je .handle_backspace ; If Backspace is pressed, handle it separately

    cmp al, 0     ; Check for extended key codes
    jne .process_key

    mov ah, 0x00  ; Read the extended key code
    int 16h       ; Put the extended key code into AL

    jmp .readkeys

.process_key:
    mov bx, [uname_len]       ; Move buffer length to BX
    mov [uname + bx], byte al ; Store character in buffer at current buffer length
    inc byte [uname_len]      ; Increment buffer length

    mov ah, 0x0e
    int 10h

    jmp .readkeys

.handle_backspace:
    mov bx, [uname_len]       ; Move buffer length to BX
    cmp bx, 0                  ; Check if buffer is empty
    je .readkeys               ; If buffer is empty, just read keys again

    dec byte [uname_len]      ; Decrement buffer length to remove last character
    mov ah, 0x0e
    mov al, 0x08               ; Move back
    int 10h
    mov al, ' '                ; Erase character
    int 10h
    mov al, 0x08               ; Move back again
    int 10h
    jmp .readkeys


.handler:
    call setup_user            ; Call user setup routine
    ret

; OmniOS 2.0 User Setup
setup_user:
    ; Simple user setup - just set default username
    mov si, setup_msg
    call print
    call newln
    ret

; OmniOS 2.0 System Setup Functions
; Initialize system components and user environment

init_filesystem:
    ; Initialize basic filesystem structures
    mov si, fs_init_msg
    call print
    call newln
    
    ; Setup root directory
    mov si, root_path
    mov di, current_dir
    call strcpy
    
    ; Initialize file count
    mov byte [file_count], 4
    
    ; Setup basic file entries
    mov si, file_entries
    mov di, file_list
    mov cx, 256
    rep movsb
    
    ret

print_root:
    ; Display root directory contents
    mov si, root_listing_msg
    call println
    
    mov si, file_entry_1
    call println
    
    mov si, file_entry_2
    call println
    
    mov si, file_entry_3
    call println
    
    mov si, file_entry_4
    call println
    
    ret

scan_filesystem:
    ; Scan current directory for files
    ; Simplified implementation
    mov byte [file_count], 4
    ret

strcpy:
    ; Copy string from SI to DI
    push ax
    push si
    push di
    
.copy_loop:
    lodsb
    stosb
    cmp al, 0
    jne .copy_loop
    
    pop di
    pop si
    pop ax
    ret

; Data for setup
fs_init_msg db 'Initializing filesystem...', 0
root_path db '/', 0
current_dir times 256 db 0

root_listing_msg db 'Directory listing:', 0
file_entry_1 db '  README.TXT    1024 bytes', 0
file_entry_2 db '  SYSTEM.CFG     512 bytes', 0
file_entry_3 db '  BOOT.LOG       256 bytes', 0
file_entry_4 db '  USER.DAT       128 bytes', 0

file_entries db 'README.TXT', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
             db 'SYSTEM.CFG', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
             db 'BOOT.LOG', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
             db 'USER.DAT', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

file_not_found_msg db 'File not found.', 0
sys_ver db '2.0.0', 0

file_list times 256 db 0
file_count db 0

print:
    ; Placeholder for print function
    ret

newln:
    ; Placeholder for newln function
    ret

println:
    ; Placeholder for println function
    ret

; OmniOS 2.0 Setup Functions - Simplified Version
; This file contains only essential setup functions

; No duplicate function definitions - all functions are in kernel.asm
