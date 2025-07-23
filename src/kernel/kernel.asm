; OmniOS 2.0 Enhanced Kernel with Complete Command Set
[BITS 16]
[ORG 0x1000]

%INCLUDE "src/utils/print.asm"
%INCLUDE "src/utils/command.asm"
%INCLUDE "src/utils/setup.asm"

; Kernel entry point - this is where bootloader jumps
kernel_start:
    ; Set up segments properly
    mov ax, 0x1000      ; We're loaded at 0x1000:0x0000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF      ; Set stack at top of segment
    
    ; Clear screen with black background
    call cls
    
    ; Display welcome message
    mov si, welcome_msg
    call print
    call newln
    
    ; Display OmniOS banner
    mov si, omnios_banner
    call print_string
    
    ; Display system info
    mov si, system_info
    call print
    call newln
    
    ; Initialize system
    call init_system
    
    ; Setup user
    call setup_user
    
    ; Start command loop
    jmp start_shell

start_shell:
    ; Display prompt
    mov si, uname
    call print
    mov si, prompt_symb
    call print
    
    ; Start command processor
    jmp command_loop

clear_screen_black:
    ; Clear screen with BLACK background
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07        ; Light gray on BLACK
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    
    ; Reset cursor
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 0x10
    ret

print_string:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F        ; White text on black
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

print_colored:
    pusha
    mov ah, 0x0E
    mov bh, 0
    ; BL already set by caller
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

newline:
    pusha
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    popa
    ret

init_system:
    ; Display system info
    mov si, system_info
    call print_string
    call newline
    
    ; Show available commands
    mov si, help_msg
    call print_string
    call newline
    ret

setup_user:
    ; Setup user name and length
    mov si, uname
    mov di, uname_len
    call calculate_length
    ret

calculate_length:
    pusha
    mov cx, 0
.loop:
    lodsb
    cmp al, 0
    je .done
    inc cx
    jmp .loop
.done:
    mov [di], cl
    popa
    ret

command_loop:
    ; Display prompt
    mov si, prompt
    call print_string
    
    ; Get user input
    call get_input
    
    ; Process command
    call process_command
    
    ; Repeat
    jmp command_loop

get_input:
    pusha
    mov di, buffer
    mov cx, 0
    
.input_loop:
    ; Get character
    mov ah, 0x00
    int 0x16
    
    ; Check for Enter
    cmp al, 0x0D
    je .input_done
    
    ; Check for Backspace
    cmp al, 0x08
    je .backspace
    
    ; Check buffer limit
    cmp cx, 254
    jge .input_loop
    
    ; Store character
    mov [di], al
    inc di
    inc cx
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    jmp .input_loop

.backspace:
    cmp cx, 0
    je .input_loop
    
    dec di
    dec cx
    mov byte [di], 0
    
    ; Move cursor back
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    
    jmp .input_loop

.input_done:
    mov byte [di], 0
    call newline
    popa
    ret

process_command:
    pusha
    
    ; Check for help command
    mov si, buffer
    mov di, cmd_help
    call compare_strings
    cmp ax, 1
    je .show_help
    
    ; Check for ls command
    mov si, buffer
    mov di, cmd_ls
    call compare_strings
    cmp ax, 1
    je .list_files
    
    ; Check for clear command
    mov si, buffer
    mov di, cmd_clear
    call compare_strings
    cmp ax, 1
    je .clear_screen
    
    ; Check for exit command
    mov si, buffer
    mov di, cmd_exit
    call compare_strings
    cmp ax, 1
    je .exit_system
    
    ; Check for version command
    mov si, buffer
    mov di, cmd_version
    call compare_strings
    cmp ax, 1
    je .show_version
    
    ; Unknown command
    mov si, unknown_cmd
    call print_string
    call newline
    jmp .done

.show_help:
    mov si, help_text
    call print_string
    call newline
    jmp .done

.list_files:
    mov si, root_files
    call print_string
    call newline
    jmp .done

.clear_screen:
    call clear_screen_black
    mov si, omnios_banner
    call print_string
    jmp .done

.show_version:
    mov si, version_info
    call print_string
    call newline
    jmp .done

.exit_system:
    mov si, goodbye_msg
    call print_string
    call newline
    cli
    hlt

.done:
    popa
    ret

compare_strings:
    pusha
    mov ax, 1
.compare_loop:
    mov bl, [si]
    mov bh, [di]
    
    cmp bl, bh
    jne .not_equal
    
    cmp bl, 0
    je .equal
    
    inc si
    inc di
    jmp .compare_loop

.not_equal:
    mov ax, 0
.equal:
    mov [temp_result], ax
    popa
    mov ax, [temp_result]
    ret

; Data section
welcome_msg db 'Welcome to OmniOS 2.0!', 0
omnios_banner    db '╔══════════════════════════════════════════════════════════════╗', 0x0D, 0x0A
                 db '║                        OmniOS 2.0                           ║', 0x0D, 0x0A
                 db '║                  Enhanced Command Edition                   ║', 0x0D, 0x0A
                 db '╚══════════════════════════════════════════════════════════════╝', 0x0D, 0x0A, 0x0A, 0

system_info      db 'OmniOS 2.0 - Enhanced Command Edition', 0x0D, 0x0A
                 db 'Type "help" for available commands.', 0x0D, 0x0A, 0

prompt           db 'OmniOS> ', 0
prompt_symb      db ':(User)> ', 0

help_msg         db 'Available commands: help, ls, clear, version, exit', 0

help_text        db 'OmniOS 2.0 Commands:', 0x0D, 0x0A
                 db '  help    - Show this help message', 0x0D, 0x0A
                 db '  ls      - List files and directories', 0x0D, 0x0A
                 db '  clear   - Clear the screen', 0x0D, 0x0A
                 db '  version - Show system version', 0x0D, 0x0A
                 db '  exit    - Exit the system', 0x0D, 0x0A, 0

root_files       db 'README.TXT', 0x0D, 0x0A
                 db 'SYSTEM.CFG', 0x0D, 0x0A
                 db 'BOOT.LOG', 0x0D, 0x0A
                 db 'USER.DAT', 0x0D, 0x0A, 0

unknown_cmd      db 'Unknown command. Type "help" for available commands.', 0

goodbye_msg      db 'Thank you for using OmniOS 2.0!', 0

; Command strings
cmd_help         db 'help', 0
cmd_ls           db 'ls', 0
cmd_clear        db 'clear', 0
cmd_exit         db 'exit', 0
cmd_version      db 'version', 0

; Variables
buffer           times 255 db 0
buffer_len       db 0
orig_case        times 255 db 0
uname            db 'OmniOS', 0
uname_len        db 0
temp_result      dw 0
temp_buffer      times 12 db 0

; Padding
times 4096-($-$$) db 0
