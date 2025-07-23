; OmniOS 2.0 Enhanced Kernel
[BITS 16]
[ORG 0x0000]

; Kernel entry point
kernel_start:
    ; Set up segments
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF
    
    ; Clear screen with black background
    call clear_screen
    
    ; Display welcome banner
    call display_banner
    
    ; Initialize system
    call init_system
    
    ; Start command loop
    jmp command_loop

clear_screen:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07        ; Light gray on black
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 0x10
    ret

display_banner:
    mov si, banner_msg
    call print_string
    call newline
    ret

init_system:
    mov si, init_msg
    call print_string
    call newline
    
    ; Initialize filesystem
    call init_filesystem
    
    ; Setup default user
    mov si, default_user
    mov di, current_user
    call strcpy
    
    ret

command_loop:
    ; Display prompt
    call show_prompt
    
    ; Get user input
    call get_input
    
    ; Process command
    call process_command
    
    ; Loop
    jmp command_loop

show_prompt:
    mov si, current_user
    call print_string
    mov si, prompt_suffix
    call print_string
    ret

get_input:
    mov di, input_buffer
    mov cx, 0
    
.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13          ; Enter
    je .input_done
    
    cmp al, 8           ; Backspace
    je .handle_backspace
    
    cmp cx, 79          ; Max length
    jge .input_loop
    
    ; Store character
    mov [di], al
    inc di
    inc cx
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    jmp .input_loop

.handle_backspace:
    cmp cx, 0
    je .input_loop
    
    dec di
    dec cx
    mov byte [di], 0
    
    ; Move cursor back
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    
    jmp .input_loop

.input_done:
    mov byte [di], 0
    call newline
    ret

process_command:
    ; Check for empty command
    cmp byte [input_buffer], 0
    je .done
    
    ; Check help command
    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    cmp ax, 0
    je .show_help
    
    ; Check ls command
    mov si, input_buffer
    mov di, cmd_ls
    call strcmp
    cmp ax, 0
    je .list_files
    
    ; Check clear command
    mov si, input_buffer
    mov di, cmd_clear
    call strcmp
    cmp ax, 0
    je .clear_command
    
    ; Check version command
    mov si, input_buffer
    mov di, cmd_version
    call strcmp
    cmp ax, 0
    je .show_version
    
    ; Check exit command
    mov si, input_buffer
    mov di, cmd_exit
    call strcmp
    cmp ax, 0
    je .exit_system
    
    ; Unknown command
    mov si, unknown_msg
    call print_string
    call newline
    jmp .done

.show_help:
    mov si, help_text
    call print_string
    call newline
    jmp .done

.list_files:
    mov si, file_list_text
    call print_string
    call newline
    jmp .done

.clear_command:
    call clear_screen
    call display_banner
    jmp .done

.show_version:
    mov si, version_text
    call print_string
    call newline
    jmp .done

.exit_system:
    mov si, goodbye_text
    call print_string
    call newline
    cli
    hlt

.done:
    ret

; Utility functions
print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

newline:
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    ret

strcmp:
    push si
    push di
.compare_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
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

strcpy:
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

init_filesystem:
    ; Simple filesystem initialization
    mov byte [file_count], 4
    ret

; Data section
banner_msg db '╔══════════════════════════════════════════════════════════════╗', 13, 10
           db '║                        OmniOS 2.0                           ║', 13, 10
           db '║                  Enhanced Command Edition                   ║', 13, 10
           db '╚══════════════════════════════════════════════════════════════╝', 0

init_msg db 'OmniOS 2.0 - Enhanced Command Edition', 13, 10
         db 'Type "help" for available commands.', 0

default_user db 'OmniOS', 0
prompt_suffix db ':(User)> ', 0

help_text db 'OmniOS 2.0 Commands:', 13, 10
          db '  help    - Show this help message', 13, 10
          db '  ls      - List files and directories', 13, 10
          db '  clear   - Clear the screen', 13, 10
          db '  version - Show system version', 13, 10
          db '  exit    - Exit the system', 0

file_list_text db 'Files in root directory:', 13, 10
               db '  README.TXT    1024 bytes', 13, 10
               db '  SYSTEM.CFG     512 bytes', 13, 10
               db '  BOOT.LOG       256 bytes', 13, 10
               db '  USER.DAT       128 bytes', 0

version_text db 'OmniOS 2.0.0 Enhanced Command Edition', 13, 10
             db 'Build: 2025.01.23', 13, 10
             db 'Kernel: Enhanced Assembly Kernel', 0

unknown_msg db 'Unknown command. Type "help" for available commands.', 0
goodbye_text db 'Thank you for using OmniOS 2.0!', 0

; Command strings
cmd_help db 'help', 0
cmd_ls db 'ls', 0
cmd_clear db 'clear', 0
cmd_version db 'version', 0
cmd_exit db 'exit', 0

; Variables
input_buffer times 80 db 0
current_user times 32 db 0
file_count db 0

; Padding
times 4096-($-$$) db 0
