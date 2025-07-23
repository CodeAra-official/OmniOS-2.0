; OmniOS 2.0 Enhanced Kernel with Setup, Authentication, and Settings
; Complete operating system with professional features
[BITS 16]
[ORG 0x1000]

start:
    ; Initialize segments
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x8000
    sti
    
    ; Check first boot flag from bootloader
    mov al, [0x500]
    mov [first_boot], al
    
    ; Clear screen and set up display
    call clear_screen
    call setup_display
    
    ; Check if first boot
    cmp byte [first_boot], 1
    je run_setup
    
    ; Not first boot - show login screen
    call show_login_screen
    jmp main_loop

run_setup:
    ; First boot - run setup wizard
    call show_setup_wizard
    ; Mark setup as complete
    call mark_setup_complete
    ; Continue to login
    call show_login_screen

main_loop:
    ; Main system loop after authentication
    call show_desktop
    call show_prompt
    call get_command
    call process_command
    jmp main_loop

; Setup wizard for first boot
show_setup_wizard:
    pusha
    
    ; Setup header
    call clear_screen
    mov si, setup_header
    call print_color_line
    call newline
    
    ; Step 1: User account creation
    call setup_user_account
    
    ; Step 2: Network configuration
    call setup_network
    
    ; Step 3: Display settings
    call setup_display_settings
    
    ; Setup complete
    mov si, setup_complete_msg
    call print_success
    call wait_key
    
    popa
    ret

setup_user_account:
    pusha
    
    mov si, user_setup_msg
    call print_info
    call newline
    
    ; Get username
    mov si, username_prompt
    call print
    mov di, username_buffer
    call get_input
    
    ; Get password
    mov si, password_prompt
    call print
    mov di, password_buffer
    call get_password_input
    
    ; Confirm password
    mov si, confirm_password_prompt
    call print
    mov di, temp_buffer
    call get_password_input
    
    ; Validate passwords match
    mov si, password_buffer
    mov di, temp_buffer
    call compare_strings
    cmp ax, 1
    je .password_ok
    
    mov si, password_mismatch_msg
    call print_error
    jmp setup_user_account
    
.password_ok:
    mov si, user_created_msg
    call print_success
    call newline
    
    popa
    ret

setup_network:
    pusha
    
    mov si, network_setup_msg
    call print_info
    call newline
    
    ; Scan for networks
    mov si, scanning_networks_msg
    call print
    call simulate_network_scan
    
    ; Show available networks
    call show_network_list
    
    ; Get network selection
    mov si, select_network_prompt
    call print
    mov di, temp_buffer
    call get_input
    
    ; Get network password if needed
    mov si, network_password_prompt
    call print
    mov di, network_password_buffer
    call get_password_input
    
    ; Simulate connection
    mov si, connecting_msg
    call print
    call simulate_connection
    
    mov si, network_connected_msg
    call print_success
    call newline
    
    popa
    ret

setup_display_settings:
    pusha
    
    mov si, display_setup_msg
    call print_info
    call newline
    
    ; Color scheme selection
    mov si, color_scheme_prompt
    call print
    call show_color_options
    
    mov di, temp_buffer
    call get_input
    
    ; Apply color scheme
    call apply_color_scheme
    
    mov si, display_configured_msg
    call print_success
    call newline
    
    popa
    ret

; Login screen for subsequent boots
show_login_screen:
    pusha
    
    call clear_screen
    
    ; Login header
    mov si, login_header
    call print_color_line
    call newline
    call newline
    
.login_loop:
    ; Username prompt
    mov si, login_username_prompt
    call print
    mov di, input_username
    call get_input
    
    ; Password prompt
    mov si, login_password_prompt
    call print
    mov di, input_password
    call get_password_input
    
    ; Authenticate user
    call authenticate_user
    cmp ax, 1
    je .login_success
    
    ; Login failed
    mov si, login_failed_msg
    call print_error
    call newline
    jmp .login_loop
    
.login_success:
    mov si, login_success_msg
    call print_success
    call wait_key
    
    ; Set current user
    mov si, input_username
    mov di, current_user
    call copy_string
    
    popa
    ret

; Desktop environment
show_desktop:
    call clear_screen
    
    ; Desktop header
    mov si, desktop_header
    call print_color_line
    call newline
    
    ; Welcome message
    mov si, welcome_msg
    call print
    mov si, current_user
    call print
    mov si, exclamation
    call print
    call newline
    
    ; System ready message
    mov si, system_ready_msg
    call print_info
    call newline
    
    ret

; Command processing
get_command:
    mov di, command_buffer
    call get_input
    ret

process_command:
    pusha
    
    ; Check for empty command
    cmp byte [command_buffer], 0
    je .done
    
    ; Convert to lowercase for comparison
    mov si, command_buffer
    call to_lowercase
    
    ; Check commands
    mov si, command_buffer
    
    ; Help command
    mov di, cmd_help
    call compare_strings
    cmp ax, 1
    je .cmd_help
    
    ; Settings command
    mov di, cmd_settings
    call compare_strings
    cmp ax, 1
    je .cmd_settings
    
    ; Admin command
    mov di, cmd_admin
    call compare_strings
    cmp ax, 1
    je .cmd_admin
    
    ; WiFi command
    mov di, cmd_wifi
    call compare_strings
    cmp ax, 1
    je .cmd_wifi
    
    ; Users command
    mov di, cmd_users
    call compare_strings
    cmp ax, 1
    je .cmd_users
    
    ; Apps command
    mov di, cmd_apps
    call compare_strings
    cmp ax, 1
    je .cmd_apps
    
    ; Factory command
    mov di, cmd_factory
    call compare_strings
    cmp ax, 1
    je .cmd_factory
    
    ; Clear command
    mov di, cmd_clear
    call compare_strings
    cmp ax, 1
    je .cmd_clear
    
    ; Version command
    mov di, cmd_version
    call compare_strings
    cmp ax, 1
    je .cmd_version
    
    ; Logout command
    mov di, cmd_logout
    call compare_strings
    cmp ax, 1
    je .cmd_logout
    
    ; Exit command
    mov di, cmd_exit
    call compare_strings
    cmp ax, 1
    je .cmd_exit
    
    ; Unknown command
    mov si, unknown_command_msg
    call print_error
    jmp .done
    
.cmd_help:
    call show_help
    jmp .done
    
.cmd_settings:
    call show_settings_menu
    jmp .done
    
.cmd_admin:
    call toggle_admin_mode
    jmp .done
    
.cmd_wifi:
    call wifi_configuration
    jmp .done
    
.cmd_users:
    call user_management
    jmp .done
    
.cmd_apps:
    call app_management
    jmp .done
    
.cmd_factory:
    call factory_reset
    jmp .done
    
.cmd_clear:
    call clear_screen
    call show_desktop
    jmp .done
    
.cmd_version:
    call show_version
    jmp .done
    
.cmd_logout:
    call logout_user
    jmp .done
    
.cmd_exit:
    call shutdown_system
    jmp .done
    
.done:
    popa
    ret

; Enhanced help system
show_help:
    pusha
    
    call newline
    mov si, help_header
    call print_color_line
    call newline
    
    ; Basic commands
    mov si, help_basic_header
    call print_info
    call newline
    
    mov si, help_basic_1
    call print
    call newline
    mov si, help_basic_2
    call print
    call newline
    mov si, help_basic_3
    call print
    call newline
    mov si, help_basic_4
    call print
    call newline
    mov si, help_basic_5
    call print
    call newline
    
    ; System commands
    call newline
    mov si, help_system_header
    call print_info
    call newline
    
    mov si, help_system_1
    call print
    call newline
    mov si, help_system_2
    call print
    call newline
    mov si, help_system_3
    call print
    call newline
    mov si, help_system_4
    call print
    call newline
    
    ; Network commands
    call newline
    mov si, help_network_header
    call print_info
    call newline
    
    mov si, help_network_1
    call print
    call newline
    
    ; Admin commands
    call newline
    mov si, help_admin_header
    call print_info
    call newline
    
    mov si, help_admin_1
    call print
    call newline
    mov si, help_admin_2
    call print
    call newline
    
    call newline
    mov si, help_footer
    call print_color_line
    call newline
    
    popa
    ret

; Settings menu
show_settings_menu:
    pusha
    
.menu_loop:
    call clear_screen
    
    ; Settings header
    mov si, settings_header
    call print_color_line
    call newline
    call newline
    
    ; Menu options
    mov si, settings_option_1
    call print
    call newline
    mov si, settings_option_2
    call print
    call newline
    mov si, settings_option_3
    call print
    call newline
    mov si, settings_option_4
    call print
    call newline
    mov si, settings_option_5
    call print
    call newline
    mov si, settings_option_0
    call print
    call newline
    call newline
    
    ; Get selection
    mov si, settings_prompt
    call print
    mov di, temp_buffer
    call get_input
    
    ; Process selection
    mov al, [temp_buffer]
    
    cmp al, '1'
    je .wifi_config
    cmp al, '2'
    je .user_mgmt
    cmp al, '3'
    je .app_mgmt
    cmp al, '4'
    je .admin_toggle
    cmp al, '5'
    je .factory_reset
    cmp al, '0'
    je .exit_settings
    
    ; Invalid selection
    mov si, invalid_selection_msg
    call print_error
    call wait_key
    jmp .menu_loop
    
.wifi_config:
    call wifi_configuration
    call wait_key
    jmp .menu_loop
    
.user_mgmt:
    call user_management
    call wait_key
    jmp .menu_loop
    
.app_mgmt:
    call app_management
    call wait_key
    jmp .menu_loop
    
.admin_toggle:
    call toggle_admin_mode
    call wait_key
    jmp .menu_loop
    
.factory_reset:
    call factory_reset
    call wait_key
    jmp .menu_loop
    
.exit_settings:
    popa
    ret

; WiFi configuration
wifi_configuration:
    pusha
    
    call newline
    mov si, wifi_config_header
    call print_color_line
    call newline
    
    ; Show current status
    mov si, wifi_status_msg
    call print
    mov si, wifi_current_network
    call print
    call newline
    
    ; Scan for networks
    mov si, wifi_scanning_msg
    call print
    call simulate_network_scan
    
    ; Show networks
    call show_network_list
    
    ; Connection options
    mov si, wifi_connect_prompt
    call print
    mov di, temp_buffer
    call get_input
    
    ; Process connection
    call process_wifi_connection
    
    popa
    ret

; User management
user_management:
    pusha
    
    call newline
    mov si, user_mgmt_header
    call print_color_line
    call newline
    
    ; Show current user
    mov si, current_user_msg
    call print
    mov si, current_user
    call print
    call newline
    
    ; User management options
    mov si, user_mgmt_options
    call print
    call newline
    
    ; Get selection
    mov di, temp_buffer
    call get_input
    
    ; Process user management
    call process_user_management
    
    popa
    ret

; Application management
app_management:
    pusha
    
    call newline
    mov si, app_mgmt_header
    call print_color_line
    call newline
    
    ; Show installed apps
    mov si, installed_apps_msg
    call print
    call newline
    call show_installed_apps
    
    ; App management options
    mov si, app_mgmt_options
    call print
    call newline
    
    ; Get selection
    mov di, temp_buffer
    call get_input
    
    ; Process app management
    call process_app_management
    
    popa
    ret

; Admin mode toggle
toggle_admin_mode:
    pusha
    
    ; Check current admin status
    cmp byte [admin_mode], 1
    je .disable_admin
    
    ; Enable admin mode
    call newline
    mov si, admin_enable_msg
    call print
    
    ; Verify admin password
    mov si, admin_password_prompt
    call print
    mov di, temp_buffer
    call get_password_input
    
    ; Check password (simplified - in real system would be hashed)
    mov si, temp_buffer
    mov di, admin_password
    call compare_strings
    cmp ax, 1
    je .admin_enabled
    
    mov si, admin_auth_failed_msg
    call print_error
    jmp .done
    
.admin_enabled:
    mov byte [admin_mode], 1
    mov si, admin_enabled_msg
    call print_success
    jmp .done
    
.disable_admin:
    mov byte [admin_mode], 0
    mov si, admin_disabled_msg
    call print_info
    
.done:
    popa
    ret

; Factory reset
factory_reset:
    pusha
    
    ; Check admin mode
    cmp byte [admin_mode], 1
    jne .no_admin
    
    call newline
    mov si, factory_reset_warning
    call print_error
    call newline
    
    mov si, factory_reset_confirm
    call print
    mov di, temp_buffer
    call get_input
    
    ; Check confirmation
    mov al, [temp_buffer]
    cmp al, 'Y'
    je .perform_reset
    cmp al, 'y'
    je .perform_reset
    
    mov si, factory_reset_cancelled
    call print_info
    jmp .done
    
.perform_reset:
    mov si, factory_reset_progress
    call print
    call simulate_factory_reset
    
    mov si, factory_reset_complete
    call print_success
    call newline
    
    ; Reset system state
    call reset_system_state
    
    ; Restart setup
    mov byte [first_boot], 1
    jmp run_setup
    
.no_admin:
    mov si, admin_required_msg
    call print_error
    
.done:
    popa
    ret

; Utility functions
clear_screen:
    pusha
    mov ah, 0x06
    mov al, 0
    mov bh, 0x17        ; Blue background, white text
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    
    ; Set cursor to top
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 0x10
    popa
    ret

setup_display:
    pusha
    ; Set up color scheme and display mode
    popa
    ret

show_prompt:
    ; Show appropriate prompt based on admin mode
    cmp byte [admin_mode], 1
    je .admin_prompt
    
    ; Normal prompt
    mov si, current_user
    call print
    mov si, normal_prompt
    call print
    jmp .done
    
.admin_prompt:
    mov si, current_user
    call print
    mov si, admin_prompt_text
    call print_error  ; Red text for admin mode
    
.done:
    ret

print:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F        ; White text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

print_color_line:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x1F        ; Blue background, white text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

print_success:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0A        ; Green text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

print_error:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0C        ; Red text
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

print_info:
    pusha
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0E        ; Yellow text
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

get_input:
    pusha
    mov bx, di          ; Save buffer pointer
    mov cx, 0           ; Character count
    
.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x0D        ; Enter key
    je .input_done
    
    cmp al, 0x08        ; Backspace
    je .handle_backspace
    
    ; Regular character
    cmp cx, 63          ; Max input length
    jae .input_loop
    
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
    
    ; Erase character on screen
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    
    jmp .input_loop
    
.input_done:
    mov byte [di], 0    ; Null terminate
    call newline
    popa
    ret

get_password_input:
    pusha
    mov bx, di          ; Save buffer pointer
    mov cx, 0           ; Character count
    
.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x0D        ; Enter key
    je .input_done
    
    cmp al, 0x08        ; Backspace
    je .handle_backspace
    
    ; Regular character
    cmp cx, 63          ; Max input length
    jae .input_loop
    
    ; Store character
    mov [di], al
    inc di
    inc cx
    
    ; Echo asterisk
    mov ah, 0x0E
    mov al, '*'
    int 0x10
    
    jmp .input_loop
    
.handle_backspace:
    cmp cx, 0
    je .input_loop
    
    dec di
    dec cx
    mov byte [di], 0
    
    ; Erase asterisk on screen
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    
    jmp .input_loop
    
.input_done:
    mov byte [di], 0    ; Null terminate
    call newline
    popa
    ret

wait_key:
    pusha
    mov si, press_key_msg
    call print
    mov ah, 0x00
    int 0x16
    call newline
    popa
    ret

to_lowercase:
    pusha
.loop:
    lodsb
    cmp al, 0
    je .done
    cmp al, 'A'
    jb .next
    cmp al, 'Z'
    ja .next
    add al, 32
    mov [si-1], al
.next:
    jmp .loop
.done:
    popa
    ret

compare_strings:
    pusha
    mov cx, 0
.loop:
    lodsb
    mov bl, [di]
    inc di
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    jmp .loop
.equal:
    mov ax, 1
    jmp .done
.not_equal:
    mov ax, 0
.done:
    mov [temp_compare_result], ax
    popa
    mov ax, [temp_compare_result]
    ret

copy_string:
    pusha
.loop:
    lodsb
    mov [di], al
    inc di
    cmp al, 0
    jne .loop
    popa
    ret

; Simulation functions
simulate_network_scan:
    pusha
    mov cx, 3
.scan_loop:
    mov al, '.'
    mov ah, 0x0E
    int 0x10
    
    ; Simple delay
    push cx
    mov cx, 0xFFFF
.delay:
    loop .delay
    pop cx
    
    loop .scan_loop
    
    call newline
    popa
    ret

show_network_list:
    pusha
    mov si, network_list_header
    call print_info
    call newline
    
    mov si, network_1
    call print
    call newline
    mov si, network_2
    call print
    call newline
    mov si, network_3
    call print
    call newline
    mov si, network_4
    call print
    call newline
    
    popa
    ret

simulate_connection:
    pusha
    mov cx, 5
.connect_loop:
    mov al, '.'
    mov ah, 0x0E
    int 0x10
    
    ; Simple delay
    push cx
    mov cx, 0xFFFF
.delay:
    loop .delay
    pop cx
    
    loop .connect_loop
    
    call newline
    popa
    ret

authenticate_user:
    pusha
    ; Simple authentication - compare with stored credentials
    mov si, input_username
    mov di, username_buffer
    call compare_strings
    cmp ax, 1
    jne .auth_failed
    
    mov si, input_password
    mov di, password_buffer
    call compare_strings
    cmp ax, 1
    jne .auth_failed
    
    mov ax, 1
    jmp .auth_done
    
.auth_failed:
    mov ax, 0
    
.auth_done:
    mov [auth_result], ax
    popa
    mov ax, [auth_result]
    ret

mark_setup_complete:
    pusha
    ; In a real system, this would write to disk
    ; For now, just set flag
    mov byte [setup_completed], 1
    popa
    ret

show_color_options:
    pusha
    mov si, color_option_1
    call print
    call newline
    mov si, color_option_2
    call print
    call newline
    mov si, color_option_3
    call print
    call newline
    popa
    ret

apply_color_scheme:
    pusha
    ; Apply selected color scheme
    ; Implementation would depend on selection
    popa
    ret

process_wifi_connection:
    pusha
    mov si, wifi_connecting_msg
    call print
    call simulate_connection
    mov si, wifi_connected_msg
    call print_success
    popa
    ret

process_user_management:
    pusha
    mov si, user_mgmt_processing
    call print_info
    popa
    ret

show_installed_apps:
    pusha
    mov si, app_list_header
    call print
    call newline
    mov si, app_1
    call print
    call newline
    mov si, app_2
    call print
    call newline
    mov si, app_3
    call print
    call newline
    popa
    ret

process_app_management:
    pusha
    mov si, app_mgmt_processing
    call print_info
    popa
    ret

simulate_factory_reset:
    pusha
    mov cx, 10
.reset_loop:
    mov al, '.'
    mov ah, 0x0E
    int 0x10
    
    ; Delay
    push cx
    mov cx, 0xFFFF
.delay:
    loop .delay
    pop cx
    
    loop .reset_loop
    
    call newline
    popa
    ret

reset_system_state:
    pusha
    ; Reset all system variables
    mov byte [admin_mode], 0
    mov byte [setup_completed], 0
    ; Clear user data
    mov di, username_buffer
    mov cx, 64
    mov al, 0
    rep stosb
    popa
    ret

show_version:
    pusha
    call newline
    mov si, version_header
    call print_color_line
    call newline
    mov si, version_info
    call print
    call newline
    mov si, build_info
    call print
    call newline
    mov si, features_info
    call print
    call newline
    popa
    ret

logout_user:
    pusha
    mov si, logout_msg
    call print_info
    call wait_key
    ; Return to login screen
    popa
    jmp show_login_screen

shutdown_system:
    pusha
    mov si, shutdown_msg
    call print_info
    call wait_key
    
    ; Shutdown sequence
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    
    ; If APM shutdown fails, halt
    cli
    hlt
    popa
    ret

; Data section
first_boot          db 1
admin_mode          db 0
setup_completed     db 0
auth_result         dw 0
temp_compare_result dw 0

; User data
current_user        times 64 db 0
username_buffer     times 64 db 0
password_buffer     times 64 db 0
input_username      times 64 db 0
input_password      times 64 db 0
network_password_buffer times 64 db 0
command_buffer      times 128 db 0
temp_buffer         times 128 db 0

; Admin credentials (in real system would be hashed)
admin_password      db 'admin123', 0

; Network data
wifi_current_network db 'Not connected', 0

; Commands
cmd_help            db 'help', 0
cmd_settings        db 'settings', 0
cmd_admin           db 'admin', 0
cmd_wifi            db 'wifi', 0
cmd_users           db 'users', 0
cmd_apps            db 'apps', 0
cmd_factory         db 'factory', 0
cmd_clear           db 'clear', 0
cmd_version         db 'version', 0
cmd_logout          db 'logout', 0
cmd_exit            db 'exit', 0

; Messages
setup_header        db '                     INITIAL SETUP                           ', 0
user_setup_msg      db 'Step 1: Create User Account', 0
network_setup_msg   db 'Step 2: Network Configuration', 0
display_setup_msg   db 'Step 3: Display Settings', 0
setup_complete_msg  db 'Setup Complete! Welcome to OmniOS 2.0', 0

username_prompt     db 'Enter username: ', 0
password_prompt     db 'Enter password: ', 0
confirm_password_prompt db 'Confirm password: ', 0
password_mismatch_msg db 'Passwords do not match. Please try again.', 0
user_created_msg    db 'User account created successfully!', 0

scanning_networks_msg db 'Scanning for networks', 0
network_password_prompt db 'Enter network password: ', 0
connecting_msg      db 'Connecting', 0
network_connected_msg db 'Network connected successfully!', 0

color_scheme_prompt db 'Select color scheme (1-3): ', 0
color_option_1      db '1. Default (Blue)', 0
color_option_2      db '2. Dark Theme', 0
color_option_3      db '3. High Contrast', 0
display_configured_msg db 'Display settings configured!', 0

login_header        db '                        LOGIN                                ', 0
login_username_prompt db 'Username: ', 0
login_password_prompt db 'Password: ', 0
login_failed_msg    db 'Login failed. Please try again.', 0
login_success_msg   db 'Login successful!', 0

desktop_header      db '                    OmniOS 2.0 Desktop Environment                    ', 0
welcome_msg         db 'Welcome back, ', 0
exclamation         db '!', 0
system_ready_msg    db 'System ready. Type "help" for available commands.', 0

normal_prompt       db '> ', 0
admin_prompt_text   db ' [ADMIN]> ', 0

unknown_command_msg db 'Command not found. Type "help" for available commands.', 0

; Help messages
help_header         db '                       HELP SYSTEM                         ', 0
help_basic_header   db 'Basic Commands:', 0
help_basic_1        db '  help        - Show this help menu', 0
help_basic_2        db '  clear       - Clear screen and refresh desktop', 0
help_basic_3        db '  version     - Show system version information', 0
help_basic_4        db '  logout      - Logout current user', 0
help_basic_5        db '  exit        - Shutdown system', 0

help_system_header  db 'System Commands:', 0
help_system_1       db '  settings    - Open comprehensive settings menu', 0
help_system_2       db '  admin       - Toggle administrator mode', 0
help_system_3       db '  users       - User management interface', 0
help_system_4       db '  apps        - Application management system', 0

help_network_header db 'Network Commands:', 0
help_network_1      db '  wifi        - WiFi configuration and management', 0

help_admin_header   db 'Administrative Commands (Admin Mode Required):', 0
help_admin_1        db '  factory     - Factory reset system', 0
help_admin_2        db '  sysconfig   - Advanced system configuration', 0

help_footer         db '                    End of Help                           ', 0

; Settings menu
settings_header     db '                       SETTINGS                            ', 0
settings_option_1   db '1. WiFi Configuration', 0
settings_option_2   db '2. User Management', 0
settings_option_3   db '3. Application Management', 0
settings_option_4   db '4. Admin Mode Toggle', 0
settings_option_5   db '5. Factory Reset', 0
settings_option_0   db '0. Back to main menu', 0
settings_prompt     db 'Select option (0-5): ', 0
invalid_selection_msg db 'Invalid selection. Please try again.', 0

; WiFi configuration
wifi_config_header  db '                   WIFI CONFIGURATION                     ', 0
wifi_status_msg     db 'Current network: ', 0
wifi_scanning_msg   db 'Scanning for networks', 0
wifi_connect_prompt db 'Enter network number to connect (or 0 to cancel): ', 0
wifi_connecting_msg db 'Connecting to network', 0
wifi_connected_msg  db 'Successfully connected to network!', 0

network_list_header db 'Available networks:', 0
network_1           db '1. OmniNet-5G (Secured)', 0
network_2           db '2. HomeWiFi (Secured)', 0
network_3           db '3. PublicNet (Open)', 0
network_4           db '4. Skip network setup', 0

; User management
user_mgmt_header    db '                   USER MANAGEMENT                        ', 0
current_user_msg    db 'Current user: ', 0
user_mgmt_options   db 'User management options available here.', 0
user_mgmt_processing db 'Processing user management request...', 0

; Application management
app_mgmt_header     db '                APPLICATION MANAGEMENT                    ', 0
installed_apps_msg  db 'Installed applications:', 0
app_list_header     db 'Applications:', 0
app_1               db '  - Notepad (Text Editor)', 0
app_2               db '  - Settings (System Configuration)', 0
app_3               db '  - Terminal (Command Interface)', 0
app_mgmt_options    db 'Application management options available here.', 0
app_mgmt_processing db 'Processing application management request...', 0

; Admin mode
admin_enable_msg    db 'Enabling administrator mode...', 0
admin_password_prompt db 'Enter admin password: ', 0
admin_auth_failed_msg db 'Authentication failed. Access denied.', 0
admin_enabled_msg   db 'Administrator mode ENABLED', 0
admin_disabled_msg  db 'Administrator mode disabled', 0
admin_required_msg  db 'Administrator privileges required for this command.', 0

; Factory reset
factory_reset_warning db 'WARNING: This will erase ALL data and reset to factory defaults!', 0
factory_reset_confirm db 'Type Y to confirm factory reset: ', 0
factory_reset_cancelled db 'Factory reset cancelled.', 0
factory_reset_progress db 'Performing factory reset', 0
factory_reset_complete db 'Factory reset complete. System will restart.', 0

; Version information
version_header      db '                    VERSION INFORMATION                    ', 0
version_info        db 'OmniOS 2.0 Enhanced Professional Edition', 0
build_info          db 'Build: 2025-01-23 | Architecture: x86 16-bit', 0
features_info       db 'Features: Setup, Authentication, Settings, Admin Mode', 0

; System messages
press_key_msg       db 'Press any key to continue...', 0
logout_msg          db 'Logging out...', 0
shutdown_msg        db 'Shutting down system...', 0

; Network selection prompt
select_network_prompt db 'Select network (1-4): ', 0

; Padding to ensure proper size
times 8192-($-$$) db 0
