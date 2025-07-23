; OmniOS 2.0 Kernel - Main System Kernel
[BITS 16]
[ORG 0x0000]

section .bss
    command_buffer resb 256
    buffer_len resb 1
    current_dir resb 256
    file_list resb 2048
    file_count resb 1

section .text

jmp Main

; Include system modules
%INCLUDE "src/kernel/print.asm"
%INCLUDE "src/kernel/commands.asm"
%INCLUDE "src/kernel/filesystem.asm"

Main:
    ; Set up segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Initialize system
    call init_system
    call show_welcome
    call init_filesystem
    
    ; Set root directory
    mov si, root_path
    mov di, current_dir
    call strcpy
    
    ; Main command loop
    call command_loop
    
    ; System halt
    jmp halt_system

init_system:
    ; Clear screen with blue background
    mov ah, 0x06
    mov al, 0
    mov bh, 0x1F        ; White text on blue background
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    
    ; Set cursor position
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 0x10
    
    ret

show_welcome:
    mov si, welcome_msg
    call print_colored
    call newline
    
    mov si, version_msg
    call print_colored
    call newline
    
    mov si, help_msg
    call print_colored
    call newline
    call newline
    
    ret

command_loop:
    ; Show prompt
    call show_prompt
    
    ; Get command input
    call get_command_input
    
    ; Process command
    call process_command
    
    ; Loop
    jmp command_loop

show_prompt:
    mov si, current_dir
    call print_colored
    
    mov si, prompt_symbol
    call print_colored
    
    ret

get_command_input:
    ; Clear command buffer
    mov di, command_buffer
    mov cx, 256
    mov al, 0
    rep stosb
    mov byte [buffer_len], 0
    
.input_loop:
    ; Get key
    mov ah, 0x00
    int 0x16
    
    ; Check for Enter
    cmp al, 13
    je .input_done
    
    ; Check for Backspace
    cmp al, 8
    je .handle_backspace
    
    ; Check for printable character
    cmp al, 32
    jl .input_loop
    cmp al, 126
    jg .input_loop
    
    ; Add character to buffer
    mov bx, [buffer_len]
    cmp bx, 255
    jge .input_loop
    
    mov [command_buffer + bx], al
    inc byte [buffer_len]
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    jmp .input_loop

.handle_backspace:
    cmp byte [buffer_len], 0
    je .input_loop
    
    dec byte [buffer_len]
    
    ; Move cursor back and erase
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    
    jmp .input_loop

.input_done:
    call newline
    ret

process_command:
    ; Check for empty command
    cmp byte [buffer_len], 0
    je .done
    
    ; Parse command
    mov si, command_buffer
    
    ; Check for 'help' command
    mov di, cmd_help
    mov cx, 4
    repe cmpsb
    je .cmd_help
    
    ; Check for 'ls' command
    mov si, command_buffer
    mov di, cmd_ls
    mov cx, 2
    repe cmpsb
    je .cmd_ls
    
    ; Check for 'cd' command
    mov si, command_buffer
    mov di, cmd_cd
    mov cx, 2
    repe cmpsb
    je .cmd_cd
    
    ; Check for 'open' command
    mov si, command_buffer
    mov di, cmd_open
    mov cx, 4
    repe cmpsb
    je .cmd_open
    
    ; Check for 'clear' command
    mov si, command_buffer
    mov di, cmd_clear
    mov cx, 5
    repe cmpsb
    je .cmd_clear
    
    ; Check for 'ver' command
    mov si, command_buffer
    mov di, cmd_ver
    mov cx, 3
    repe cmpsb
    je .cmd_ver
    
    ; Check for 'time' command
    mov si, command_buffer
    mov di, cmd_time
    mov cx, 4
    repe cmpsb
    je .cmd_time
    
    ; Check for 'shutdown' command
    mov si, command_buffer
    mov di, cmd_shutdown
    mov cx, 8
    repe cmpsb
    je .cmd_shutdown
    
    ; Check for 'reboot' command
    mov si, command_buffer
    mov di, cmd_reboot
    mov cx, 6
    repe cmpsb
    je .cmd_reboot
    
    ; Unknown command
    mov si, unknown_cmd_msg
    call print_error
    jmp .done

.cmd_help:
    call show_help
    jmp .done

.cmd_ls:
    call list_files
    jmp .done

.cmd_cd:
    call change_directory
    jmp .done

.cmd_open:
    call open_application
    jmp .done

.cmd_clear:
    call clear_screen
    jmp .done

.cmd_ver:
    call show_version
    jmp .done

.cmd_time:
    call show_time
    jmp .done

.cmd_shutdown:
    call shutdown_system
    jmp .done

.cmd_reboot:
    call reboot_system
    jmp .done

.done:
    ret

show_help:
    mov si, help_title
    call print_colored
    call newline
    
    mov si, help_line1
    call print_colored
    call newline
    
    mov si, help_line2
    call print_colored
    call newline
    
    mov si, help_line3
    call print_colored
    call newline
    
    mov si, help_line4
    call print_colored
    call newline
    
    mov si, help_line5
    call print_colored
    call newline
    
    mov si, help_line6
    call print_colored
    call newline
    
    mov si, help_line7
    call print_colored
    call newline
    
    mov si, help_line8
    call print_colored
    call newline
    
    mov si, help_line9
    call print_colored
    call newline
    
    mov si, help_line10
    call print_colored
    call newline
    
    ret

list_files:
    mov si, listing_msg
    call print_colored
    call newline
    
    ; Initialize file system scan
    call scan_filesystem
    
    ; Display files
    mov cx, [file_count]
    cmp cx, 0
    je .no_files
    
    mov si, file_list
    
.display_loop:
    push cx
    
    ; Display file name
    call print_colored
    call newline
    
    ; Move to next file (32 bytes per entry)
    add si, 32
    
    pop cx
    loop .display_loop
    
    jmp .done

.no_files:
    mov si, no_files_msg
    call print_colored
    call newline

.done:
    ret

change_directory:
    ; Get directory name from command
    mov si, command_buffer
    add si, 3           ; Skip "cd "
    
    ; Check for ".." (parent directory)
    cmp word [si], '..'
    je .parent_dir
    
    ; Check for root directory
    cmp byte [si], '/'
    je .root_dir
    
    ; Try to change to specified directory
    mov di, current_dir
    call strcpy
    
    mov si, dir_changed_msg
    call print_colored
    call newline
    jmp .done

.parent_dir:
    ; Go to parent directory (simplified)
    mov si, root_path
    mov di, current_dir
    call strcpy
    
    mov si, dir_changed_msg
    call print_colored
    call newline
    jmp .done

.root_dir:
    mov si, root_path
    mov di, current_dir
    call strcpy
    
    mov si, dir_changed_msg
    call print_colored
    call newline
    jmp .done

.done:
    ret

open_application:
    ; Get application name
    mov si, command_buffer
    add si, 5           ; Skip "open "
    
    ; Check for specific applications
    mov di, app_notepad
    mov cx, 7
    repe cmpsb
    je .open_notepad
    
    mov si, command_buffer
    add si, 5
    mov di, app_settings
    mov cx, 8
    repe cmpsb
    je .open_settings
    
    mov si, command_buffer
    add si, 5
    mov di, app_files
    mov cx, 5
    repe cmpsb
    je .open_files
    
    ; Application not found
    mov si, app_not_found_msg
    call print_error
    jmp .done

.open_notepad:
    call run_notepad
    jmp .done

.open_settings:
    call run_settings
    jmp .done

.open_files:
    call run_file_manager
    jmp .done

.done:
    ret

clear_screen:
    call init_system
    ret

show_version:
    mov si, version_title
    call print_colored
    call newline
    
    mov si, version_info
    call print_colored
    call newline
    
    mov si, build_info
    call print_colored
    call newline
    
    ret

show_time:
    ; Get system time
    mov ah, 0x02
    int 0x1A
    
    ; Display time (simplified)
    mov si, time_msg
    call print_colored
    
    ; Convert and display hours
    mov al, ch
    call bcd_to_ascii
    mov ah, 0x0E
    int 0x10
    
    mov al, ':'
    int 0x10
    
    ; Convert and display minutes
    mov al, cl
    call bcd_to_ascii
    int 0x10
    
    call newline
    ret

shutdown_system:
    mov si, shutdown_msg
    call print_colored
    call newline
    
    ; ACPI shutdown
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    
    ; If ACPI fails, halt
    jmp halt_system

reboot_system:
    mov si, reboot_msg
    call print_colored
    call newline
    
    ; Keyboard controller reboot
    mov al, 0xFE
    out 0x64, al
    
    ; If that fails, triple fault
    int 0x19

halt_system:
    mov si, halt_msg
    call print_colored
    cli
    hlt
    jmp $

; Application runners
run_notepad:
    mov si, notepad_msg
    call print_colored
    call newline
    
    mov si, notepad_help
    call print_colored
    call newline
    
    ; Simple text editor loop
.editor_loop:
    mov si, editor_prompt
    call print_colored
    
    ; Get input
    mov ah, 0x00
    int 0x16
    
    ; Check for ESC to exit
    cmp al, 27
    je .exit_editor
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    jmp .editor_loop

.exit_editor:
    call newline
    mov si, notepad_exit
    call print_colored
    call newline
    ret

run_settings:
    mov si, settings_msg
    call print_colored
    call newline
    
    mov si, settings_menu
    call print_colored
    call newline
    
    ; Settings menu loop
.settings_loop:
    mov si, settings_prompt
    call print_colored
    
    mov ah, 0x00
    int 0x16
    
    cmp al, '1'
    je .display_settings
    cmp al, '2'
    je .system_info
    cmp al, '0'
    je .exit_settings
    
    jmp .settings_loop

.display_settings:
    call newline
    mov si, display_info
    call print_colored
    call newline
    jmp .settings_loop

.system_info:
    call newline
    call show_version
    jmp .settings_loop

.exit_settings:
    call newline
    mov si, settings_exit
    call print_colored
    call newline
    ret

run_file_manager:
    mov si, files_msg
    call print_colored
    call newline
    
    ; Show current directory
    mov si, current_dir_msg
    call print_colored
    mov si, current_dir
    call print_colored
    call newline
    
    ; List files
    call list_files
    
    ret

; Utility functions
bcd_to_ascii:
    push ax
    
    ; Convert high nibble
    mov ah, al
    shr ah, 4
    add ah, '0'
    mov al, ah
    mov ah, 0x0E
    int 0x10
    
    ; Convert low nibble
    pop ax
    and al, 0x0F
    add al, '0'
    mov ah, 0x0E
    int 0x10
    
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

; Data section
welcome_msg     db 'Welcome to OmniOS 2.0 - Phoenix Edition', 0
version_msg     db 'Professional Operating System - Build 2025', 0
help_msg        db 'Type "help" for available commands', 0
prompt_symbol   db ' > ', 0
root_path       db '/', 0

; Command strings
cmd_help        db 'help', 0
cmd_ls          db 'ls', 0
cmd_cd          db 'cd', 0
cmd_open        db 'open', 0
cmd_clear       db 'clear', 0
cmd_ver         db 'ver', 0
cmd_time        db 'time', 0
cmd_shutdown    db 'shutdown', 0
cmd_reboot      db 'reboot', 0

; Application names
app_notepad     db 'notepad', 0
app_settings    db 'settings', 0
app_files       db 'files', 0

; Help messages
help_title      db '=== OmniOS 2.0 Command Reference ===', 0
help_line1      db 'help      - Show this help message', 0
help_line2      db 'ls        - List files and directories', 0
help_line3      db 'cd <dir>  - Change directory', 0
help_line4      db 'open <app>- Open application (notepad, settings, files)', 0
help_line5      db 'clear     - Clear screen', 0
help_line6      db 'ver       - Show system version', 0
help_line7      db 'time      - Show current time', 0
help_line8      db 'shutdown  - Shutdown system', 0
help_line9      db 'reboot    - Restart system', 0
help_line10     db '=====================================', 0

; Status messages
listing_msg     db 'Directory listing:', 0
no_files_msg    db 'No files found', 0
dir_changed_msg db 'Directory changed', 0
unknown_cmd_msg db 'Unknown command. Type "help" for available commands.', 0
app_not_found_msg db 'Application not found. Available: notepad, settings, files', 0

; Version information
version_title   db '=== System Information ===', 0
version_info    db 'OmniOS 2.0.0 Phoenix Edition', 0
build_info      db 'Build Date: January 2025', 0

; Time message
time_msg        db 'Current time: ', 0

; System messages
shutdown_msg    db 'Shutting down system...', 0
reboot_msg      db 'Restarting system...', 0
halt_msg        db 'System halted. You can safely turn off your computer.', 0

; Application messages
notepad_msg     db '=== OmniOS Notepad ===', 0
notepad_help    db 'Simple text editor. Press ESC to exit.', 0
editor_prompt   db 'Text: ', 0
notepad_exit    db 'Notepad closed.', 0

settings_msg    db '=== System Settings ===', 0
settings_menu   db '1. Display Settings  2. System Info  0. Exit', 0
settings_prompt db 'Select option: ', 0
display_info    db 'Display: 80x25 Text Mode, 16 Colors', 0
settings_exit   db 'Settings closed.', 0

files_msg       db '=== File Manager ===', 0
current_dir_msg db 'Current directory: ', 0
