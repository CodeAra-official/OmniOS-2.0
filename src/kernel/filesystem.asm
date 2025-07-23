; OmniOS 2.0 File System Functions
; Fixed file system with proper ls command

init_filesystem:
    ; Initialize file system
    mov byte [file_count], 0
    
    ; Add default files
    call add_default_files
    
    ret

add_default_files:
    ; Add system files to file list
    mov si, file_kernel
    mov di, file_list
    call strcpy
    
    mov si, file_system
    mov di, file_list
    add di, 32
    call strcpy
    
    mov si, file_config
    mov di, file_list
    add di, 64
    call strcpy
    
    mov si, file_readme
    mov di, file_list
    add di, 96
    call strcpy
    
    mov byte [file_count], 4
    
    ret

scan_filesystem:
    ; Scan for files (simplified implementation)
    ; In a real system, this would read from disk
    
    ; Reset file count
    mov byte [file_count], 0
    
    ; Add files based on current directory
    mov si, current_dir
    mov di, root_path
    call strcmp
    cmp ax, 0
    je .root_directory
    
    ; Non-root directory (empty for now)
    ret

.root_directory:
    call add_default_files
    ret

strcmp:
    push si
    push di
    
.compare_loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .not_equal
    
    cmp al, 0
    je .equal
    
    inc si
    inc di
    jmp .compare_loop

.equal:
    mov ax, 0
    jmp .done

.not_equal:
    mov ax, 1

.done:
    pop di
    pop si
    ret

; File data
file_kernel     db 'kernel.bin', 0
                times 21 db 0

file_system     db 'system.cfg', 0
                times 21 db 0

file_config     db 'config.txt', 0
                times 21 db 0

file_readme     db 'readme.txt', 0
                times 21 db 0
