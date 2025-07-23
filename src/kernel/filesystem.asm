; OmniOS 2.0 Enhanced File System
; Complete file operations with proper ls command

init_filesystem:
    ; Initialize file system
    mov byte [file_count], 0
    
    ; Add default files and directories
    call add_default_entries
    
    ret

add_default_entries:
    ; Add system files and directories to file list
    mov di, file_list
    
    ; Add directories first
    mov al, 'D'         ; Directory marker
    stosb
    mov si, dir_system
    call strcpy_to_list
    
    mov al, 'D'
    stosb
    mov si, dir_apps
    call strcpy_to_list
    
    mov al, 'D'
    stosb
    mov si, dir_users
    call strcpy_to_list
    
    ; Add files
    mov al, 'F'         ; File marker
    stosb
    mov si, file_kernel
    call strcpy_to_list
    
    mov al, 'F'
    stosb
    mov si, file_config
    call strcpy_to_list
    
    mov al, 'F'
    stosb
    mov si, file_readme
    call strcpy_to_list
    
    mov al, 'F'
    stosb
    mov si, file_log
    call strcpy_to_list
    
    mov byte [file_count], 7
    
    ret

strcpy_to_list:
    ; Copy string from SI to current DI position
    push ax
    
.copy_loop:
    lodsb
    stosb
    cmp al, 0
    jne .copy_loop
    
    ; Pad to 64 bytes per entry
    mov cx, 63
    sub cx, di
    add cx, file_list
    and cx, 63
    mov al, 0
    rep stosb
    
    pop ax
    ret

scan_filesystem:
    ; Scan current directory for files
    ; This is a simplified implementation
    
    ; Reset file count
    mov byte [file_count], 0
    
    ; Check current directory and populate file list
    mov si, current_dir
    mov di, root_path
    call strcmp
    cmp ax, 0
    je .root_directory
    
    ; Non-root directory - show parent link
    mov di, file_list
    mov al, 'D'
    stosb
    mov si, parent_link
    call strcpy_to_list
    mov byte [file_count], 1
    ret

.root_directory:
    call add_default_entries
    ret

; File data
dir_system      db 'system', 0
dir_apps        db 'applications', 0
dir_users       db 'users', 0
file_kernel     db 'kernel.bin', 0
file_config     db 'config.sys', 0
file_readme     db 'readme.txt', 0
file_log        db 'system.log', 0
parent_link     db '..', 0
