; OmniOS 2.0 Professional Kernel
; Complete operating system with advanced features

[BITS 16]
[ORG 0x0000]

kernel_start:
    ; Initialize segments
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    
    ; Clear screen with black background
    mov ax, 0x0003
    int 0x10
    
    ; Check if first boot (flag stored at 0x500 by bootloader)
    push ds
    mov ax, 0x0000
    mov ds, ax
    mov al, [0x500]
    pop ds
    mov [first_boot], al
    
    ; Display professional header
    call display_header
    
    ; Check first boot status
    cmp byte [first_boot], 1
    je first_boot_setup
    
    ; Normal boot - show login
    call user_login
    jmp main_loop

first_boot_setup:
    call setup_system
    call create_user_account
    
    ; Mark setup as complete
    mov byte [first_boot], 0
    call save_setup_flag

main_loop:
    ; Display prompt
    mov si, prompt
    call print_string
    
    ; Get user input
    call get_input
    
    ; Process command
    call process_command
    
    jmp main_loop

; Display professional header
display_header:
    call clear_screen
    
    mov si, header_msg
    call print_string_color
    
    mov si, version_msg
    call print_string_color
    
    call newline
    ret

; First boot setup system
setup_system:
    mov si, setup_welcome
    call print_string_color
    
    mov si, setup_msg1
    call print_string
    
    ; Wait for key press
    mov ah, 0x00
    int 0x16
    
    call newline
    ret

; Create user account
create_user_account:
    mov si, create_user_msg
    call print_string
    
    ; Get username
    mov si, username_prompt
    call print_string
    mov di, username
    call get_string
    
    ; Get password
    mov si, password_prompt
    call print_string
    mov di, password
    call get_string_hidden
    
    ; Confirm account creation
    mov si, account_created_msg
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call newline
    ret

; User login system
user_login:
    mov si, login_header
    call print_string_color
    
.login_loop:
    ; Get username
    mov si, login_username
    call print_string
    mov di, input_username
    call get_string
    
    ; Get password
    mov si, login_password
    call print_string
    mov di, input_password
    call get_string_hidden
    
    ; Verify credentials
    call verify_login
    cmp al, 1
    je .login_success
    
    ; Login failed
    mov si, login_failed
    call print_string
    jmp .login_loop

.login_success:
    mov si, login_success_msg
    call print_string
    
    ; Small delay
    mov cx, 0x8000
.delay:
    nop
    loop .delay
    
    ret

; Verify login credentials
verify_login:
    ; Compare username
    mov si, input_username
    mov di, username
    call compare_strings
    cmp al, 1
    jne .login_fail
    
    ; Compare password
    mov si, input_password
    mov di, password
    call compare_strings
    cmp al, 1
    jne .login_fail
    
    mov al, 1  ; Success
    ret

.login_fail:
    mov al, 0  ; Failure
    ret

; Process user commands
process_command:
    ; Check for empty command
    cmp byte [input_buffer], 0
    je .done
    
    ; Check commands
    mov si, input_buffer
    mov di, cmd_help
    call compare_strings
    cmp al, 1
    je show_help
    
    mov si, input_buffer
    mov di, cmd_clear
    call compare_strings
    cmp al, 1
    je clear_screen
    
    mov si, input_buffer
    mov di, cmd_info
    call compare_strings
    cmp al, 1
    je show_system_info
    
    mov si, input_buffer
    mov di, cmd_settings
    call compare_strings
    cmp al, 1
    je show_settings
    
    mov si, input_buffer
    mov di, cmd_admin
    call compare_strings
    cmp al, 1
    je admin_mode
    
    mov si, input_buffer
    mov di, cmd_shutdown
    call compare_strings
    cmp al, 1
    je shutdown_system
    
    ; Unknown command
    mov si, unknown_cmd
    call print_string

.done:
    ret

; Show help system
show_help:
    call clear_screen
    mov si, help_header
    call print_string_color
    
    mov si, help_commands
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call clear_screen
    ret

; Show system information
show_system_info:
    call clear_screen
    mov si, info_header
    call print_string_color
    
    mov si, system_info
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call clear_screen
    ret

; Settings menu
show_settings:
    call clear_screen
    
.settings_loop:
    mov si, settings_header
    call print_string_color
    
    mov si, settings_menu
    call print_string
    
    ; Get choice
    mov ah, 0x00
    int 0x16
    
    cmp al, '1'
    je change_theme
    cmp al, '2'
    je change_password
    cmp al, '3'
    je factory_reset
    cmp al, '4'
    je .exit_settings
    
    jmp .settings_loop

.exit_settings:
    call clear_screen
    ret

; Change theme
change_theme:
    mov si, theme_msg
    call print_string
    
    ; Toggle theme (simple implementation)
    xor byte [current_theme], 1
    
    mov si, theme_changed
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    ret

; Change password
change_password:
    mov si, new_password_msg
    call print_string
    
    mov di, password
    call get_string_hidden
    
    mov si, password_changed
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    ret

; Factory reset
factory_reset:
    mov si, reset_warning
    call print_string
    
    ; Get confirmation
    mov ah, 0x00
    int 0x16
    
    cmp al, 'Y'
    je .do_reset
    cmp al, 'y'
    je .do_reset
    
    mov si, reset_cancelled
    call print_string
    ret

.do_reset:
    ; Clear user data
    mov di, username
    mov cx, 32
    xor al, al
    rep stosb
    
    mov di, password
    mov cx, 32
    xor al, al
    rep stosb
    
    ; Set first boot flag
    mov byte [first_boot], 1
    
    mov si, reset_complete
    call print_string
    
    ; Restart system
    int 0x19

; Administrator mode
admin_mode:
    mov si, admin_password_prompt
    call print_string
    
    mov di, admin_input
    call get_string_hidden
    
    ; Check admin password (simple: "admin")
    mov si, admin_input
    mov di, admin_pass
    call compare_strings
    cmp al, 1
    jne .admin_fail
    
    ; Admin mode activated
    call clear_screen
    mov si, admin_welcome
    call print_string_color
    
    mov si, admin_commands
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call clear_screen
    ret

.admin_fail:
    mov si, admin_fail_msg
    call print_string
    ret

; Shutdown system
shutdown_system:
    mov si, shutdown_msg
    call print_string
    
    ; Halt system
    cli
    hlt

; Utility functions
clear_screen:
    mov ax, 0x0003
    int 0x10
    ret

newline:
    mov si, newline_str
    call print_string
    ret

print_string:
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
    ret

print_string_color:
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0A  ; Bright green
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

get_input:
    mov di, input_buffer
    xor cx, cx

.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13  ; Enter key
    je .done
    
    cmp al, 8   ; Backspace
    je .backspace
    
    ; Regular character
    cmp cx, 79  ; Max input length
    jae .input_loop
    
    ; Store character
    mov [di], al
    inc di
    inc cx
    
    ; Echo character
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F
    int 0x10
    
    jmp .input_loop

.backspace:
    cmp cx, 0
    je .input_loop
    
    dec di
    dec cx
    mov byte [di], 0
    
    ; Move cursor back and clear character
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    
    jmp .input_loop

.done:
    mov byte [di], 0
    call newline
    ret

get_string:
    push di
    xor cx, cx

.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13  ; Enter
    je .done
    
    cmp al, 8   ; Backspace
    je .backspace
    
    cmp cx, 31  ; Max length
    jae .input_loop
    
    mov [di], al
    inc di
    inc cx
    
    ; Echo
    mov ah, 0x0E
    int 0x10
    
    jmp .input_loop

.backspace:
    cmp cx, 0
    je .input_loop
    
    dec di
    dec cx
    mov byte [di], 0
    
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    
    jmp .input_loop

.done:
    mov byte [di], 0
    call newline
    pop di
    ret

get_string_hidden:
    push di
    xor cx, cx

.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13  ; Enter
    je .done
    
    cmp al, 8   ; Backspace
    je .backspace
    
    cmp cx, 31  ; Max length
    jae .input_loop
    
    mov [di], al
    inc di
    inc cx
    
    ; Echo asterisk
    mov ah, 0x0E
    mov al, '*'
    int 0x10
    
    jmp .input_loop

.backspace:
    cmp cx, 0
    je .input_loop
    
    dec di
    dec cx
    mov byte [di], 0
    
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    
    jmp .input_loop

.done:
    mov byte [di], 0
    call newline
    pop di
    ret

compare_strings:
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
    pop di
    pop si
    mov al, 1
    ret

.not_equal:
    pop di
    pop si
    mov al, 0
    ret

save_setup_flag:
    ; This would write to disk in a real implementation
    ret

; Data section
header_msg          db 13, 10
                    db '  ╔══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                    db '  ║                        OmniOS 2.0 Professional Edition                      ║', 13, 10
                    db '  ╚══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 0

version_msg         db '                           Enhanced Operating System v2.0', 13, 10, 13, 10, 0

setup_welcome       db '╔═══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                    db '║                            FIRST BOOT SETUP                                  ║', 13, 10
                    db '╚═══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 0

setup_msg1          db 'Welcome to OmniOS 2.0! This appears to be your first boot.', 13, 10
                    db 'Let us set up your system. Press any key to continue...', 13, 10, 0

create_user_msg     db 13, 10, 'Creating your user account:', 13, 10, 0
username_prompt     db 'Enter username: ', 0
password_prompt     db 'Enter password: ', 0
account_created_msg db 13, 10, 'Account created successfully! Press any key to continue...', 13, 10, 0

login_header        db '╔═══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                    db '║                              USER LOGIN                                      ║', 13, 10
                    db '╚═══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 0

login_username      db 'Username: ', 0
login_password      db 'Password: ', 0
login_failed        db 13, 10, 'Login failed! Please try again.', 13, 10, 13, 10, 0
login_success_msg   db 13, 10, 'Login successful! Welcome to OmniOS 2.0', 13, 10, 0

prompt              db 13, 10, 'OmniOS> ', 0

help_header         db '╔═══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                    db '║                              HELP SYSTEM                                     ║', 13, 10
                    db '╚═══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 0

help_commands       db 'Available Commands:', 13, 10
                    db '  help      - Show this help system', 13, 10
                    db '  clear     - Clear the screen', 13, 10
                    db '  info      - Show system information', 13, 10
                    db '  settings  - Open settings menu', 13, 10
                    db '  admin     - Enter administrator mode', 13, 10
                    db '  shutdown  - Shutdown the system', 13, 10, 13, 10
                    db 'Press any key to continue...', 13, 10, 0

info_header         db '╔═══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                    db '║                           SYSTEM INFORMATION                                 ║', 13, 10
                    db '╚═══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 0

system_info         db 'OmniOS 2.0 Professional Edition', 13, 10
                    db 'Version: 2.0.0', 13, 10
                    db 'Architecture: x86 (16-bit)', 13, 10
                    db 'Memory: 16MB', 13, 10
                    db 'Features: User Authentication, Settings, Admin Mode', 13, 10, 13, 10
                    db 'Press any key to continue...', 13, 10, 0

settings_header     db '╔═══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                    db '║                              SETTINGS MENU                                   ║', 13, 10
                    db '╚═══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 0

settings_menu       db '1. Change Theme', 13, 10
                    db '2. Change Password', 13, 10
                    db '3. Factory Reset', 13, 10
                    db '4. Exit Settings', 13, 10, 13, 10
                    db 'Select option (1-4): ', 0

theme_msg           db 13, 10, 'Changing theme...', 13, 10, 0
theme_changed       db 'Theme changed successfully! Press any key...', 13, 10, 0

new_password_msg    db 13, 10, 'Enter new password: ', 0
password_changed    db 13, 10, 'Password changed successfully! Press any key...', 13, 10, 0

reset_warning       db 13, 10, 'WARNING: This will erase all user data!', 13, 10
                    db 'Are you sure? (Y/N): ', 0
reset_cancelled     db 13, 10, 'Factory reset cancelled.', 13, 10, 0
reset_complete      db 13, 10, 'Factory reset complete. Restarting...', 13, 10, 0

admin_password_prompt db 13, 10, 'Enter administrator password: ', 0
admin_welcome       db '╔═══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                    db '║                          ADMINISTRATOR MODE                                  ║', 13, 10
                    db '╚═══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 0

admin_commands      db 'Administrator commands available:', 13, 10
                    db '  - System diagnostics', 13, 10
                    db '  - User management', 13, 10
                    db '  - System configuration', 13, 10, 13, 10
                    db 'Press any key to exit admin mode...', 13, 10, 0

admin_fail_msg      db 13, 10, 'Access denied! Invalid administrator password.', 13, 10, 0

shutdown_msg        db 13, 10, 'Shutting down OmniOS 2.0...', 13, 10
                    db 'It is now safe to turn off your computer.', 13, 10, 0

unknown_cmd         db 'Unknown command. Type "help" for available commands.', 13, 10, 0
newline_str         db 13, 10, 0

; Command strings
cmd_help            db 'help', 0
cmd_clear           db 'clear', 0
cmd_info            db 'info', 0
cmd_settings        db 'settings', 0
cmd_admin           db 'admin', 0
cmd_shutdown        db 'shutdown', 0

; Admin password
admin_pass          db 'admin', 0

; Variables
first_boot          db 1
current_theme       db 0
username            times 32 db 0
password            times 32 db 0
input_username      times 32 db 0
input_password      times 32 db 0
admin_input         times 32 db 0
input_buffer        times 80 db 0

; Pad kernel to exact size
times 9216-($-$$) db 0
