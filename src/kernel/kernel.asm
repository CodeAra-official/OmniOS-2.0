; OmniOS 2.0 Enhanced Kernel with Complete Command Set
[BITS 16]
[ORG 0x0000]

section .bss
    command_buffer resb 256
    buffer_len resb 1
    current_dir resb 256
    clipboard resb 1024
    download_buffer resb 2048
    file_list resb 4096
    file_count resb 1
    admin_mode resb 1
    system_running resb 1

section .text

jmp Main

; Include system modules
%INCLUDE "src/kernel/print.asm"
%INCLUDE "src/kernel/filesystem.asm"
%INCLUDE "src/kernel/network.asm"

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
    
    ; Set initial state
    mov si, root_path
    mov di, current_dir
    call strcpy
    mov byte [admin_mode], 0
    mov byte [system_running], 1
    
    ; Main command loop
    call command_loop
    
    ; System halt
    jmp halt_system

init_system:
    ; Clear screen with professional theme
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
    
    mov si, help_hint
    call print_colored
    call newline
    call newline
    
    ret

command_loop:
    ; Check if system should continue running
    cmp byte [system_running], 0
    je halt_system
    
    ; Show prompt
    call show_prompt
    
    ; Get command input
    call get_command_input
    
    ; Process command
    call process_command
    
    ; Loop
    jmp command_loop

show_prompt:
    ; Show admin indicator if in admin mode
    cmp byte [admin_mode], 1
    jne .normal_prompt
    
    mov si, admin_indicator
    call print_error
    
.normal_prompt:
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
    
    ; Parse and execute commands
    mov si, command_buffer
    
    ; help command
    call check_command
    db 'help', 0
    jc .cmd_help
    
    ; ls command
    call check_command
    db 'ls', 0
    jc .cmd_ls
    
    ; cd command
    call check_command
    db 'cd', 0
    jc .cmd_cd
    
    ; install command
    call check_command
    db 'install', 0
    jc .cmd_install
    
    ; open command
    call check_command
    db 'open', 0
    jc .cmd_open
    
    ; set command
    call check_command
    db 'set', 0
    jc .cmd_set
    
    ; admin command
    call check_command
    db 'admin', 0
    jc .cmd_admin
    
    ; exit command
    call check_command
    db 'exit', 0
    jc .cmd_exit
    
    ; off command
    call check_command
    db 'off', 0
    jc .cmd_off
    
    ; retry command
    call check_command
    db 'retry', 0
    jc .cmd_retry
    
    ; back command
    call check_command
    db 'back', 0
    jc .cmd_back
    
    ; go command
    call check_command
    db 'go', 0
    jc .cmd_go
    
    ; download command
    call check_command
    db 'download', 0
    jc .cmd_download
    
    ; play command
    call check_command
    db 'play', 0
    jc .cmd_play
    
    ; stop command
    call check_command
    db 'stop', 0
    jc .cmd_stop
    
    ; add command
    call check_command
    db 'add', 0
    jc .cmd_add
    
    ; delete command
    call check_command
    db 'delete', 0
    jc .cmd_delete
    
    ; move command
    call check_command
    db 'move', 0
    jc .cmd_move
    
    ; cut command
    call check_command
    db 'cut', 0
    jc .cmd_cut
    
    ; copy command
    call check_command
    db 'copy', 0
    jc .cmd_copy
    
    ; Unknown command
    mov si, unknown_cmd_msg
    call print_error
    jmp .done

; Command implementations
.cmd_help:
    call show_help
    jmp .done

.cmd_ls:
    call list_files
    jmp .done

.cmd_cd:
    call change_directory
    jmp .done

.cmd_install:
    call install_package
    jmp .done

.cmd_open:
    call open_application
    jmp .done

.cmd_set:
    call set_configuration
    jmp .done

.cmd_admin:
    call admin_command
    jmp .done

.cmd_exit:
    call exit_application
    jmp .done

.cmd_off:
    call shutdown_system
    jmp .done

.cmd_retry:
    call retry_last_command
    jmp .done

.cmd_back:
    call go_back
    jmp .done

.cmd_go:
    call go_to_location
    jmp .done

.cmd_download:
    call download_file
    jmp .done

.cmd_play:
    call play_media
    jmp .done

.cmd_stop:
    call stop_media
    jmp .done

.cmd_add:
    call add_file_folder
    jmp .done

.cmd_delete:
    call delete_file_folder
    jmp .done

.cmd_move:
    call move_file_folder
    jmp .done

.cmd_cut:
    call cut_file_folder
    jmp .done

.cmd_copy:
    call copy_file_folder
    jmp .done

.done:
    ret

; Command function implementations
show_help:
    mov si, help_title
    call print_success
    call newline
    
    mov si, help_basic
    call print_colored
    call newline
    
    mov si, help_file
    call print_colored
    call newline
    
    mov si, help_system
    call print_colored
    call newline
    
    mov si, help_media
    call print_colored
    call newline
    
    mov si, help_network
    call print_colored
    call newline
    
    mov si, help_admin
    call print_colored
    call newline
    
    ret

list_files:
    mov si, listing_msg
    call print_colored
    call newline
    
    ; Scan current directory
    call scan_filesystem
    
    ; Display files
    mov cx, [file_count]
    cmp cx, 0
    je .no_files
    
    mov si, file_list
    
.display_loop:
    push cx
    
    ; Display file name with type indicator
    mov al, [si]
    cmp al, 'D'         ; Directory
    je .show_dir
    
    ; Regular file
    mov al, ' '
    call print_char
    mov al, '-'
    call print_char
    mov al, ' '
    call print_char
    
    add si, 1
    call print_colored
    call newline
    jmp .next_file

.show_dir:
    mov al, ' '
    call print_char
    mov al, 'd'
    call print_char
    mov al, ' '
    call print_char
    
    add si, 1
    call print_success
    call newline

.next_file:
    ; Move to next file (64 bytes per entry)
    add si, 63
    
    pop cx
    loop .display_loop
    
    jmp .done

.no_files:
    mov si, no_files_msg
    call print_error
    call newline

.done:
    ret

change_directory:
    ; Get directory name from command
    call get_first_argument
    cmp di, 0
    je .show_current
    
    ; Check for special directories
    mov si, di
    mov bx, parent_dir
    call strcmp
    cmp ax, 0
    je .parent_dir
    
    mov si, di
    mov bx, root_dir
    call strcmp
    cmp ax, 0
    je .root_dir
    
    ; Try to change to specified directory
    ; (Simplified - in real implementation would check if directory exists)
    mov si, di
    mov di, current_dir
    call strcpy
    
    mov si, dir_changed_msg
    call print_success
    call newline
    jmp .done

.show_current:
    mov si, current_dir_msg
    call print_colored
    mov si, current_dir
    call print_success
    call newline
    jmp .done

.parent_dir:
    ; Go to parent directory
    mov si, root_path
    mov di, current_dir
    call strcpy
    
    mov si, dir_changed_msg
    call print_success
    call newline
    jmp .done

.root_dir:
    mov si, root_path
    mov di, current_dir
    call strcpy
    
    mov si, dir_changed_msg
    call print_success
    call newline
    jmp .done

.done:
    ret

install_package:
    call get_first_argument
    cmp di, 0
    je .no_package
    
    mov si, installing_msg
    call print_colored
    mov si, di
    call print_success
    call newline
    
    ; Simulate installation process
    mov si, install_progress1
    call print_colored
    call newline
    call delay
    
    mov si, install_progress2
    call print_colored
    call newline
    call delay
    
    mov si, install_complete
    call print_success
    call newline
    
    jmp .done

.no_package:
    mov si, install_usage
    call print_error
    call newline

.done:
    ret

open_application:
    call get_first_argument
    cmp di, 0
    je .no_app
    
    ; Check for specific applications
    mov si, di
    mov bx, app_notepad
    call strcmp
    cmp ax, 0
    je .open_notepad
    
    mov si, di
    mov bx, app_settings
    call strcmp
    cmp ax, 0
    je .open_settings
    
    mov si, di
    mov bx, app_files
    call strcmp
    cmp ax, 0
    je .open_files
    
    mov si, di
    mov bx, app_terminal
    call strcmp
    cmp ax, 0
    je .open_terminal
    
    ; Application not found
    mov si, app_not_found_msg
    call print_error
    call newline
    jmp .done

.no_app:
    mov si, open_usage
    call print_error
    call newline
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

.open_terminal:
    call run_terminal
    jmp .done

.done:
    ret

set_configuration:
    call get_first_argument
    cmp di, 0
    je .show_settings
    
    ; Check setting type
    mov si, di
    mov bx, set_color
    call strcmp
    cmp ax, 0
    je .set_color_scheme
    
    mov si, di
    mov bx, set_time
    call strcmp
    cmp ax, 0
    je .set_system_time
    
    mov si, di
    mov bx, set_lang
    call strcmp
    cmp ax, 0
    je .set_language
    
    ; Unknown setting
    mov si, set_unknown
    call print_error
    call newline
    jmp .done

.show_settings:
    mov si, set_current
    call print_colored
    call newline
    jmp .done

.set_color_scheme:
    mov si, set_color_msg
    call print_success
    call newline
    jmp .done

.set_system_time:
    mov si, set_time_msg
    call print_success
    call newline
    jmp .done

.set_language:
    mov si, set_lang_msg
    call print_success
    call newline
    jmp .done

.done:
    ret

admin_command:
    ; Check if already in admin mode
    cmp byte [admin_mode], 1
    je .already_admin
    
    ; Request admin password (simplified)
    mov si, admin_prompt
    call print_colored
    
    ; Get password (simplified - just press Enter)
    mov ah, 0x00
    int 0x16
    
    ; Enable admin mode
    mov byte [admin_mode], 1
    
    mov si, admin_enabled
    call print_success
    call newline
    jmp .done

.already_admin:
    ; Disable admin mode
    mov byte [admin_mode], 0
    
    mov si, admin_disabled
    call print_colored
    call newline

.done:
    ret

exit_application:
    mov si, exit_msg
    call print_colored
    call newline
    
    ; Return to command prompt (no action needed)
    ret

shutdown_system:
    mov si, shutdown_msg
    call print_colored
    call newline
    
    ; Set system to stop running
    mov byte [system_running], 0
    
    ; ACPI shutdown attempt
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    
    ; If ACPI fails, halt
    jmp halt_system

retry_last_command:
    mov si, retry_msg
    call print_colored
    call newline
    
    ; Re-execute last command (simplified)
    call process_command
    ret

go_back:
    ; Go to parent directory
    mov si, root_path
    mov di, current_dir
    call strcpy
    
    mov si, back_msg
    call print_success
    call newline
    ret

go_to_location:
    call get_first_argument
    cmp di, 0
    je .no_location
    
    mov si, goto_msg
    call print_colored
    mov si, di
    call print_success
    call newline
    
    ; Change to specified location
    mov si, di
    mov di, current_dir
    call strcpy
    
    jmp .done

.no_location:
    mov si, goto_usage
    call print_error
    call newline

.done:
    ret

download_file:
    call get_first_argument
    cmp di, 0
    je .no_url
    
    mov si, download_msg
    call print_colored
    mov si, di
    call print_success
    call newline
    
    ; Simulate download process
    mov si, download_progress1
    call print_colored
    call newline
    call delay
    
    mov si, download_progress2
    call print_colored
    call newline
    call delay
    
    mov si, download_complete
    call print_success
    call newline
    
    jmp .done

.no_url:
    mov si, download_usage
    call print_error
    call newline

.done:
    ret

play_media:
    call get_first_argument
    cmp di, 0
    je .no_file
    
    mov si, play_msg
    call print_colored
    mov si, di
    call print_success
    call newline
    
    mov si, play_status
    call print_colored
    call newline
    
    jmp .done

.no_file:
    mov si, play_usage
    call print_error
    call newline

.done:
    ret

stop_media:
    mov si, stop_msg
    call print_colored
    call newline
    ret

add_file_folder:
    call get_first_argument
    cmp di, 0
    je .no_name
    
    mov si, add_msg
    call print_colored
    mov si, di
    call print_success
    call newline
    
    ; Add to file system (simplified)
    mov si, add_complete
    call print_success
    call newline
    
    jmp .done

.no_name:
    mov si, add_usage
    call print_error
    call newline

.done:
    ret

delete_file_folder:
    call get_first_argument
    cmp di, 0
    je .no_name
    
    mov si, delete_msg
    call print_colored
    mov si, di
    call print_error
    call newline
    
    ; Confirm deletion
    mov si, delete_confirm
    call print_colored
    
    mov ah, 0x00
    int 0x16
    
    cmp al, 'y'
    je .confirm_delete
    cmp al, 'Y'
    je .confirm_delete
    
    mov si, delete_cancelled
    call print_colored
    call newline
    jmp .done

.confirm_delete:
    mov si, delete_complete
    call print_success
    call newline
    jmp .done

.no_name:
    mov si, delete_usage
    call print_error
    call newline

.done:
    ret

move_file_folder:
    call get_first_argument
    cmp di, 0
    je .no_source
    
    ; Get destination (simplified)
    mov si, move_msg
    call print_colored
    mov si, di
    call print_success
    call newline
    
    mov si, move_complete
    call print_success
    call newline
    
    jmp .done

.no_source:
    mov si, move_usage
    call print_error
    call newline

.done:
    ret

cut_file_folder:
    call get_first_argument
    cmp di, 0
    je .no_file
    
    ; Copy to clipboard for cutting
    mov si, di
    mov di, clipboard
    call strcpy
    
    mov si, cut_msg
    call print_colored
    mov si, clipboard
    call print_success
    call newline
    
    jmp .done

.no_file:
    mov si, cut_usage
    call print_error
    call newline

.done:
    ret

copy_file_folder:
    call get_first_argument
    cmp di, 0
    je .no_file
    
    ; Copy to clipboard
    mov si, di
    mov di, clipboard
    call strcpy
    
    mov si, copy_msg
    call print_colored
    mov si, clipboard
    call print_success
    call newline
    
    jmp .done

.no_file:
    mov si, copy_usage
    call print_error
    call newline

.done:
    ret

; Application runners
run_notepad:
    mov si, notepad_title
    call print_success
    call newline
    
    mov si, notepad_help
    call print_colored
    call newline
    
    ; Simple text editor
.editor_loop:
    mov si, editor_prompt
    call print_colored
    
    mov ah, 0x00
    int 0x16
    
    cmp al, 27      ; ESC to exit
    je .exit_editor
    
    cmp al, 13      ; Enter
    je .new_line
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    jmp .editor_loop

.new_line:
    call newline
    jmp .editor_loop

.exit_editor:
    call newline
    mov si, notepad_exit
    call print_colored
    call newline
    ret

run_settings:
    mov si, settings_title
    call print_success
    call newline
    
    mov si, settings_menu
    call print_colored
    call newline
    
.settings_loop:
    mov si, settings_prompt
    call print_colored
    
    mov ah, 0x00
    int 0x16
    
    cmp al, '1'
    je .display_settings
    cmp al, '2'
    je .system_info
    cmp al, '3'
    je .network_settings
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
    mov si, system_info
    call print_colored
    call newline
    jmp .settings_loop

.network_settings:
    call newline
    mov si, network_info
    call print_colored
    call newline
    jmp .settings_loop

.exit_settings:
    call newline
    mov si, settings_exit
    call print_colored
    call newline
    ret

run_file_manager:
    mov si, files_title
    call print_success
    call newline
    
    ; Show current directory
    mov si, current_dir_msg
    call print_colored
    mov si, current_dir
    call print_success
    call newline
    
    ; List files
    call list_files
    
    ret

run_terminal:
    mov si, terminal_title
    call print_success
    call newline
    
    mov si, terminal_help
    call print_colored
    call newline
    
    ; Return to main command loop
    ret

; Utility functions
check_command:
    ; Compare command with string after call
    push si
    push di
    push cx
    
    pop di          ; Get return address (points to string)
    mov si, command_buffer
    
.compare_loop:
    mov al, [si]
    mov ah, [di]
    
    cmp ah, 0       ; End of command string
    je .check_end
    
    cmp al, ah
    jne .not_match
    
    inc si
    inc di
    jmp .compare_loop

.check_end:
    ; Check if we're at end of input or space
    cmp al, 0
    je .match
    cmp al, ' '
    je .match
    
.not_match:
    ; Skip past the string
.skip_string:
    cmp byte [di], 0
    je .skip_done
    inc di
    jmp .skip_string
    
.skip_done:
    inc di          ; Skip null terminator
    
    pop cx
    pop di
    pop si
    
    push di         ; Restore return address
    clc             ; Clear carry (no match)
    ret

.match:
    ; Skip past the string
.skip_string2:
    cmp byte [di], 0
    je .skip_done2
    inc di
    jmp .skip_string2
    
.skip_done2:
    inc di          ; Skip null terminator
    
    pop cx
    pop di
    pop si
    
    push di         ; Restore return address
    stc             ; Set carry (match)
    ret

get_first_argument:
    ; Get first argument after command
    mov si, command_buffer
    
    ; Skip command name
.skip_command:
    lodsb
    cmp al, 0
    je .no_args
    cmp al, ' '
    jne .skip_command
    
    ; Skip spaces
.skip_spaces:
    lodsb
    cmp al, 0
    je .no_args
    cmp al, ' '
    je .skip_spaces
    
    ; Found argument
    dec si
    mov di, si
    ret

.no_args:
    mov di, 0
    ret

strcmp:
    ; Compare strings SI and BX
    push si
    push bx
    
.compare_loop:
    mov al, [si]
    mov ah, [bx]
    
    cmp al, ah
    jne .not_equal
    
    cmp al, 0
    je .equal
    
    inc si
    inc bx
    jmp .compare_loop

.equal:
    mov ax, 0
    jmp .done

.not_equal:
    mov ax, 1

.done:
    pop bx
    pop si
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

delay:
    ; Simple delay
    push cx
    push dx
    
    mov cx, 0x0001
    mov dx, 0x0000
    
.delay_loop:
    dec dx
    jnz .delay_loop
    dec cx
    jnz .delay_loop
    
    pop dx
    pop cx
    ret

halt_system:
    mov si, halt_msg
    call print_colored
    call newline
    
    cli
    hlt
    jmp $

; Data section
welcome_msg         db 'OmniOS 2.0 Professional - Enhanced Command System', 0
version_msg         db 'Version 2.0.0 - Phoenix Edition | Build 2025', 0
help_hint           db 'Type "help" to see all available commands', 0
prompt_symbol       db ' > ', 0
admin_indicator     db '[ADMIN] ', 0
root_path           db '/', 0
parent_dir          db '..', 0
root_dir            db '/', 0

; Command strings for applications
app_notepad         db 'notepad', 0
app_settings        db 'settings', 0
app_files           db 'files', 0
app_terminal        db 'terminal', 0

; Setting types
set_color           db 'color', 0
set_time            db 'time', 0
set_lang            db 'language', 0

; Help messages
help_title          db '=== OmniOS 2.0 Complete Command Reference ===', 0
help_basic          db 'BASIC: help ls cd open exit off', 0
help_file           db 'FILES: add delete move cut copy', 0
help_system         db 'SYSTEM: set admin install retry back', 0
help_media          db 'MEDIA: play stop', 0
help_network        db 'NETWORK: download go', 0
help_admin          db 'ADMIN: Advanced system commands (requires admin mode)', 0

; Status messages
listing_msg         db 'Directory listing:', 0
no_files_msg        db 'Directory is empty', 0
dir_changed_msg     db 'Directory changed successfully', 0
current_dir_msg     db 'Current directory: ', 0
unknown_cmd_msg     db 'Unknown command. Type "help" for available commands.', 0

; Application messages
notepad_title       db '=== OmniOS Notepad ===', 0
notepad_help        db 'Text Editor - Type text, ESC to exit', 0
editor_prompt       db 'Text: ', 0
notepad_exit        db 'Notepad closed', 0

settings_title      db '=== System Settings ===', 0
settings_menu       db '1.Display 2.System 3.Network 0.Exit', 0
settings_prompt     db 'Select: ', 0
display_info        db 'Display: 80x25 Text Mode, Professional Theme', 0
system_info         db 'System: OmniOS 2.0, 16-bit Kernel, FAT12 FS', 0
network_info        db 'Network: Ethernet Ready, WiFi Available', 0
settings_exit       db 'Settings closed', 0

files_title         db '=== File Manager ===', 0
terminal_title      db '=== Terminal ===', 0
terminal_help       db 'Advanced terminal mode - All commands available', 0

; Command-specific messages
install_usage       db 'Usage: install <package_name>', 0
installing_msg      db 'Installing package: ', 0
install_progress1   db 'Downloading package...', 0
install_progress2   db 'Installing files...', 0
install_complete    db 'Package installed successfully!', 0

open_usage          db 'Usage: open <application>', 0
app_not_found_msg   db 'Application not found. Available: notepad, settings, files, terminal', 0

set_current         db 'Current settings: Color=Professional, Language=English', 0
set_color_msg       db 'Color scheme updated', 0
set_time_msg        db 'System time updated', 0
set_lang_msg        db 'Language updated', 0
set_unknown         db 'Unknown setting. Available: color, time, language', 0

admin_prompt        db 'Enter admin password (press Enter): ', 0
admin_enabled       db 'Admin mode ENABLED', 0
admin_disabled      db 'Admin mode disabled', 0

exit_msg            db 'Exiting current application...', 0
shutdown_msg        db 'Shutting down OmniOS 2.0...', 0
retry_msg           db 'Retrying last command...', 0
back_msg            db 'Going back...', 0

goto_msg            db 'Going to: ', 0
goto_usage          db 'Usage: go <location>', 0

download_msg        db 'Downloading: ', 0
download_usage      db 'Usage: download <url>', 0
download_progress1  db 'Connecting to server...', 0
download_progress2  db 'Downloading file...', 0
download_complete   db 'Download completed!', 0

play_msg            db 'Playing: ', 0
play_usage          db 'Usage: play <filename>', 0
play_status         db 'Media player started', 0
stop_msg            db 'Media playback stopped', 0

add_msg             db 'Adding: ', 0
add_usage           db 'Usage: add <filename>', 0
add_complete        db 'File/folder added successfully', 0

delete_msg          db 'Deleting: ', 0
delete_usage        db 'Usage: delete <filename>', 0
delete_confirm      db 'Are you sure? (y/n): ', 0
delete_cancelled    db 'Deletion cancelled', 0
delete_complete     db 'File/folder deleted successfully', 0

move_msg            db 'Moving: ', 0
move_usage          db 'Usage: move <source> <destination>', 0
move_complete       db 'File/folder moved successfully', 0

cut_msg             db 'Cut to clipboard: ', 0
cut_usage           db 'Usage: cut <filename>', 0

copy_msg            db 'Copied to clipboard: ', 0
copy_usage          db 'Usage: copy <filename>', 0

halt_msg            db 'System halted. Safe to power off.', 0
