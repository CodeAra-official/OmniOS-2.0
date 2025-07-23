; OmniOS 2.0 Professional Kernel
; Complete operating system with enhanced features and professional design

[BITS 16]
[ORG 0x0000]

section .text

kernel_start:
    ; Initialize segments for kernel
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF

    ; Clear screen with professional black background
    call clear_screen
    
    ; Check if this is first boot
    call check_first_boot
    cmp byte [first_boot], 1
    je first_boot_setup
    
    ; Normal boot - show login
    jmp show_login

first_boot_setup:
    ; Display first boot setup screen
    call display_first_boot_screen
    call setup_initial_user
    
    ; Mark first boot as complete
    mov byte [first_boot], 0
    
    ; Continue to normal operation
    jmp show_login

show_login:
    ; Display login screen
    call display_login_screen
    call handle_login
    
    ; After successful login, show main interface
    jmp main_interface

main_interface:
    ; Clear screen and show main interface
    call clear_screen
    call display_header
    call display_welcome_message
    call command_loop

; ============================================================================
; SCREEN AND DISPLAY FUNCTIONS
; ============================================================================

clear_screen:
    mov ax, 0x0003      ; Set video mode 3 (80x25 color text)
    int 0x10
    
    ; Set background to black, text to bright green
    mov ah, 0x09
    mov al, ' '
    mov bh, 0
    mov bl, 0x0A        ; Bright green on black
    mov cx, 2000        ; Fill entire screen
    int 0x10
    
    ; Position cursor at top-left
    mov ah, 0x02
    mov bh, 0
    mov dx, 0x0000
    int 0x10
    ret

display_header:
    mov si, header_msg
    call print_string
    ret

display_welcome_message:
    mov si, welcome_msg
    call print_string
    
    ; Show current user
    mov si, current_user_msg
    call print_string
    mov si, username
    call print_string
    call print_newline
    call print_newline
    ret

display_first_boot_screen:
    call clear_screen
    mov si, first_boot_title
    call print_string
    mov si, first_boot_welcome
    call print_string
    ret

display_login_screen:
    call clear_screen
    mov si, login_title
    call print_string
    mov si, login_prompt
    call print_string
    ret

; ============================================================================
; FIRST BOOT AND SETUP FUNCTIONS
; ============================================================================

check_first_boot:
    ; For this implementation, we'll check a simple flag
    ; In a real system, this would check persistent storage
    mov al, [first_boot]
    ret

setup_initial_user:
    ; Get username
    mov si, setup_username_prompt
    call print_string
    mov di, username
    call get_input
    
    ; Get password
    mov si, setup_password_prompt
    call print_string
    mov di, password
    call get_input_hidden
    
    ; Confirm setup
    mov si, setup_complete_msg
    call print_string
    call wait_key
    ret

; ============================================================================
; LOGIN AND AUTHENTICATION
; ============================================================================

handle_login:
    mov si, username_prompt
    call print_string
    mov di, input_username
    call get_input
    
    mov si, password_prompt
    call print_string
    mov di, input_password
    call get_input_hidden
    
    ; Simple authentication check
    call authenticate_user
    cmp al, 1
    je login_success
    
    ; Login failed
    mov si, login_failed_msg
    call print_string
    call wait_key
    jmp show_login

login_success:
    mov si, login_success_msg
    call print_string
    call wait_key
    ret

authenticate_user:
    ; Simple string comparison for demo
    mov si, input_username
    mov di, username
    call compare_strings
    cmp al, 1
    jne auth_fail
    
    mov si, input_password
    mov di, password
    call compare_strings
    cmp al, 1
    jne auth_fail
    
    mov al, 1  ; Success
    ret

auth_fail:
    mov al, 0  ; Failure
    ret

; ============================================================================
; COMMAND PROCESSING
; ============================================================================

command_loop:
    ; Display prompt
    mov si, prompt
    call print_string
    
    ; Get command input
    mov di, command_buffer
    call get_input
    
    ; Process command
    call process_command
    
    ; Loop back
    jmp command_loop

process_command:
    ; Check for empty command
    mov si, command_buffer
    cmp byte [si], 0
    je command_loop
    
    ; Check for 'help' command
    mov si, command_buffer
    mov di, cmd_help_str
    call compare_strings
    cmp al, 1
    je show_help
    
    ; Check for 'clear' command
    mov si, command_buffer
    mov di, cmd_clear_str
    call compare_strings
    cmp al, 1
    je clear_command
    
    ; Check for 'settings' command
    mov si, command_buffer
    mov di, cmd_settings_str
    call compare_strings
    cmp al, 1
    je show_settings
    
    ; Check for 'admin' command
    mov si, command_buffer
    mov di, cmd_admin_str
    call compare_strings
    cmp al, 1
    je admin_mode
    
    ; Check for 'about' command
    mov si, command_buffer
    mov di, cmd_about_str
    call compare_strings
    cmp al, 1
    je show_about
    
    ; Check for 'logout' command
    mov si, command_buffer
    mov di, cmd_logout_str
    call compare_strings
    cmp al, 1
    je logout_user
    
    ; Check for 'shutdown' command
    mov si, command_buffer
    mov di, cmd_shutdown_str
    call compare_strings
    cmp al, 1
    je shutdown_system
    
    ; Unknown command
    mov si, unknown_command_msg
    call print_string
    ret

; ============================================================================
; COMMAND IMPLEMENTATIONS
; ============================================================================

show_help:
    mov si, help_msg
    call print_string
    ret

clear_command:
    call clear_screen
    call display_header
    ret

show_settings:
    call clear_screen
    mov si, settings_title
    call print_string
    mov si, settings_menu
    call print_string
    
    ; Get settings choice
    call get_key
    
    cmp al, '1'
    je change_theme
    cmp al, '2'
    je change_password
    cmp al, '3'
    je system_info
    cmp al, '4'
    je factory_reset
    
    ; Return to main
    call clear_screen
    call display_header
    ret

change_theme:
    mov si, theme_msg
    call print_string
    call wait_key
    call clear_screen
    call display_header
    ret

change_password:
    mov si, change_pass_msg
    call print_string
    mov di, password
    call get_input_hidden
    mov si, password_changed_msg
    call print_string
    call wait_key
    call clear_screen
    call display_header
    ret

system_info:
    mov si, system_info_msg
    call print_string
    call wait_key
    call clear_screen
    call display_header
    ret

factory_reset:
    mov si, factory_reset_msg
    call print_string
    call get_key
    cmp al, 'y'
    je do_factory_reset
    cmp al, 'Y'
    je do_factory_reset
    call clear_screen
    call display_header
    ret

do_factory_reset:
    mov si, factory_reset_confirm_msg
    call print_string
    mov byte [first_boot], 1
    call wait_key
    jmp first_boot_setup

admin_mode:
    mov si, admin_prompt_msg
    call print_string
    mov di, admin_password_input
    call get_input_hidden
    
    ; Check admin password (simple check)
    mov si, admin_password_input
    mov di, admin_password
    call compare_strings
    cmp al, 1
    je admin_access_granted
    
    mov si, admin_access_denied_msg
    call print_string
    call wait_key
    ret

admin_access_granted:
    mov si, admin_welcome_msg
    call print_string
    mov si, admin_menu_msg
    call print_string
    call wait_key
    ret

show_about:
    mov si, about_msg
    call print_string
    call wait_key
    ret

logout_user:
    mov si, logout_msg
    call print_string
    call wait_key
    jmp show_login

shutdown_system:
    mov si, shutdown_msg
    call print_string
    call wait_key
    
    ; Attempt ACPI shutdown
    mov ax, 0x2000
    mov dx, 0x604
    out dx, ax
    
    ; If ACPI fails, halt
    cli
    hlt

; ============================================================================
; UTILITY FUNCTIONS
; ============================================================================

print_string:
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

print_newline:
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    ret

get_input:
    push di
    mov cx, 0
.loop:
    call get_key
    cmp al, 13  ; Enter key
    je .done
    cmp al, 8   ; Backspace
    je .backspace
    cmp cx, 63  ; Max length
    jge .loop
    
    ; Store character
    stosb
    inc cx
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    jmp .loop

.backspace:
    cmp cx, 0
    je .loop
    dec di
    dec cx
    
    ; Move cursor back and clear character
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .loop

.done:
    mov al, 0
    stosb
    call print_newline
    pop di
    ret

get_input_hidden:
    push di
    mov cx, 0
.loop:
    call get_key
    cmp al, 13  ; Enter key
    je .done
    cmp al, 8   ; Backspace
    je .backspace
    cmp cx, 63  ; Max length
    jge .loop
    
    ; Store character
    stosb
    inc cx
    
    ; Echo asterisk
    mov ah, 0x0E
    mov al, '*'
    int 0x10
    jmp .loop

.backspace:
    cmp cx, 0
    je .loop
    dec di
    dec cx
    
    ; Move cursor back and clear character
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .loop

.done:
    mov al, 0
    stosb
    call print_newline
    pop di
    ret

get_key:
    mov ah, 0x00
    int 0x16
    ret

wait_key:
    mov si, press_key_msg
    call print_string
    call get_key
    call print_newline
    ret

compare_strings:
    push si
    push di
.loop:
    lodsb
    mov bl, al
    mov al, [di]
    inc di
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    jmp .loop
.not_equal:
    mov al, 0
    jmp .done
.equal:
    mov al, 1
.done:
    pop di
    pop si
    ret

; ============================================================================
; DATA SECTION
; ============================================================================

; System flags
first_boot db 1

; User data
username db 'admin', 0
times 60 db 0
password db 'admin', 0
times 60 db 0
admin_password db 'root', 0
times 60 db 0

; Input buffers
input_username times 64 db 0
input_password times 64 db 0
admin_password_input times 64 db 0
command_buffer times 128 db 0

; Messages
header_msg db '================================================================================', 13, 10
           db '                           OmniOS 2.0 Professional Edition                    ', 13, 10
           db '                              Enhanced Operating System                        ', 13, 10
           db '================================================================================', 13, 10, 13, 10, 0

welcome_msg db 'Welcome to OmniOS 2.0 Professional Edition!', 13, 10
            db 'Type "help" for available commands.', 13, 10, 13, 10, 0

current_user_msg db 'Current user: ', 0

first_boot_title db '================================================================================', 13, 10
                 db '                        OmniOS 2.0 - First Boot Setup                         ', 13, 10
                 db '================================================================================', 13, 10, 13, 10, 0

first_boot_welcome db 'Welcome to OmniOS 2.0! This appears to be your first boot.', 13, 10
                   db 'Let''s set up your system with initial configuration.', 13, 10, 13, 10, 0

setup_username_prompt db 'Enter your username: ', 0
setup_password_prompt db 'Enter your password: ', 0
setup_complete_msg db 13, 10, 'Setup complete! Press any key to continue...', 13, 10, 0

login_title db '================================================================================', 13, 10
            db '                            OmniOS 2.0 - User Login                           ', 13, 10
            db '================================================================================', 13, 10, 13, 10, 0

login_prompt db 'Please log in to continue.', 13, 10, 13, 10, 0
username_prompt db 'Username: ', 0
password_prompt db 'Password: ', 0
login_success_msg db 13, 10, 'Login successful! Press any key to continue...', 13, 10, 0
login_failed_msg db 13, 10, 'Login failed! Press any key to try again...', 13, 10, 0

prompt db 'OmniOS> ', 0

; Command strings
cmd_help_str db 'help', 0
cmd_clear_str db 'clear', 0
cmd_settings_str db 'settings', 0
cmd_admin_str db 'admin', 0
cmd_about_str db 'about', 0
cmd_logout_str db 'logout', 0
cmd_shutdown_str db 'shutdown', 0

help_msg db 'Available commands:', 13, 10
         db '  help      - Show this help message', 13, 10
         db '  clear     - Clear the screen', 13, 10
         db '  settings  - Open settings menu', 13, 10
         db '  admin     - Enter administrator mode', 13, 10
         db '  about     - Show system information', 13, 10
         db '  logout    - Log out current user', 13, 10
         db '  shutdown  - Shutdown the system', 13, 10, 13, 10, 0

unknown_command_msg db 'Unknown command. Type "help" for available commands.', 13, 10, 0

settings_title db '================================================================================', 13, 10
               db '                              Settings Menu                                    ', 13, 10
               db '================================================================================', 13, 10, 13, 10, 0

settings_menu db '1. Change Theme', 13, 10
              db '2. Change Password', 13, 10
              db '3. System Information', 13, 10
              db '4. Factory Reset', 13, 10
              db '5. Return to Main Menu', 13, 10, 13, 10
              db 'Select option (1-5): ', 0

theme_msg db 13, 10, 'Theme changed to Professional Black! Press any key...', 13, 10, 0
change_pass_msg db 13, 10, 'Enter new password: ', 0
password_changed_msg db 13, 10, 'Password changed successfully! Press any key...', 13, 10, 0

system_info_msg db 13, 10, 'System Information:', 13, 10
                db '  OS: OmniOS 2.0 Professional Edition', 13, 10
                db '  Version: 2.0.0', 13, 10
                db '  Architecture: x86 16-bit', 13, 10
                db '  Memory: 16MB', 13, 10
                db '  Features: Enhanced UI, Authentication, Settings', 13, 10
                db 13, 10, 'Press any key...', 13, 10, 0

factory_reset_msg db 13, 10, 'WARNING: This will reset all settings!', 13, 10
                  db 'Continue? (y/N): ', 0

factory_reset_confirm_msg db 13, 10, 'Factory reset complete! Press any key to restart setup...', 13, 10, 0

admin_prompt_msg db 13, 10, 'Enter administrator password: ', 0
admin_access_denied_msg db 13, 10, 'Access denied! Press any key...', 13, 10, 0
admin_welcome_msg db 13, 10, 'Administrator access granted!', 13, 10, 0
admin_menu_msg db 'Administrator features available.', 13, 10
               db 'Press any key to continue...', 13, 10, 0

about_msg db 13, 10, 'OmniOS 2.0 Professional Edition', 13, 10
          db 'Enhanced Operating System', 13, 10
          db 'Built with professional design and features', 13, 10
          db 'Copyright 2024 OmniOS Development Team', 13, 10
          db 13, 10, 'Press any key...', 13, 10, 0

logout_msg db 13, 10, 'Logging out... Press any key...', 13, 10, 0

shutdown_msg db 13, 10, 'Shutting down OmniOS 2.0...', 13, 10
             db 'Thank you for using OmniOS!', 13, 10
             db 'Press any key...', 13, 10, 0

press_key_msg db 'Press any key...', 0

; Pad to ensure proper size
times 4096-($-$$) db 0
