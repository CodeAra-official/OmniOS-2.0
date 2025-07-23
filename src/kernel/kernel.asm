; OmniOS 2.0 Enhanced Kernel with Complete Feature Set
; Fixed color scheme - Black background instead of blue
[BITS 16]
[ORG 0x1000]

; Kernel entry point
kernel_start:
    ; Initialize segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    
    ; Set up stack
    mov ax, 0x9000
    mov ss, ax
    mov sp, 0xFFFF
    
    ; Clear screen with black background
    call clear_screen_black
    
    ; Check first boot flag from bootloader
    mov al, [0x500]
    cmp al, 1
    je run_initial_setup
    
    ; Not first boot - show login screen
    call show_login_screen
    jmp main_loop

run_initial_setup:
    call show_setup_screen
    call mark_setup_complete
    ; After setup, continue to login
    call show_login_screen
    jmp main_loop

; Main system loop
main_loop:
    ; Show desktop
    call show_desktop
    
    ; Main command loop
command_loop:
    ; Show prompt
    call show_prompt
    
    ; Get command input
    call get_command_input
    
    ; Process command
    call process_command
    
    jmp command_loop

; Clear screen with black background (professional look)
clear_screen_black:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07        ; Light gray text on black background
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
    ret

; Alternative color schemes
clear_screen_dark:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x0F        ; White text on black background
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
    ret

clear_screen_green:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x02        ; Green text on black background
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
    ret

; Initial Setup Screen
show_setup_screen:
    call clear_screen_black
    
    ; Draw setup header with green accent
    mov dh, 2
    mov dl, 15
    call set_cursor
    mov si, setup_header
    call print_string_green
    
    ; Draw setup box
    mov dh, 4
    mov dl, 10
    mov ch, 16
    mov cl, 60
    call draw_box
    
    ; Step 1: User Account Creation
    mov dh, 6
    mov dl, 12
    call set_cursor
    mov si, setup_step1
    call print_string_cyan
    
    ; Get username
    mov dh, 8
    mov dl, 12
    call set_cursor
    mov si, username_prompt
    call print_string_white
    
    mov di, stored_username
    mov cx, 32
    call get_input_string
    
    ; Get password
    mov dh, 10
    mov dl, 12
    call set_cursor
    mov si, password_prompt
    call print_string_white
    
    mov di, stored_password
    mov cx, 32
    call get_password_input
    
    ; Step 2: Network Configuration
    mov dh, 12
    mov dl, 12
    call set_cursor
    mov si, setup_step2
    call print_string_cyan
    
    call show_network_setup
    
    ; Step 3: Color Scheme Selection
    mov dh, 16
    mov dl, 12
    call set_cursor
    mov si, setup_step3
    call print_string_cyan
    
    call show_color_scheme_setup
    
    ; Setup complete message
    mov dh, 18
    mov dl, 12
    call set_cursor
    mov si, setup_complete_msg
    call print_string_green
    
    ; Wait for key press
    mov ah, 0x00
    int 0x16
    
    ret

; Color scheme setup
show_color_scheme_setup:
    mov dh, 17
    mov dl, 12
    call set_cursor
    mov si, color_scheme_prompt
    call print_string_white
    
    ; Wait for selection
    mov ah, 0x00
    int 0x16
    
    ; Store color scheme choice
    cmp al, '1'
    je .scheme_default
    cmp al, '2'
    je .scheme_green
    cmp al, '3'
    je .scheme_high_contrast
    
    ; Default to scheme 1
.scheme_default:
    mov byte [color_scheme], 1
    ret
    
.scheme_green:
    mov byte [color_scheme], 2
    call clear_screen_green
    ret
    
.scheme_high_contrast:
    mov byte [color_scheme], 3
    call clear_screen_dark
    ret

; Network setup display
show_network_setup:
    mov dh, 14
    mov dl, 12
    call set_cursor
    mov si, network_scan_msg
    call print_string_white
    
    ; Simulate network scanning
    call simulate_network_scan
    
    ; Show available networks
    mov dh, 15
    mov dl, 14
    call set_cursor
    mov si, network_list
    call print_string_white
    
    ret

; Simulate network scanning
simulate_network_scan:
    ; Simple delay simulation with dots
    mov cx, 3
.scan_loop:
    mov ah, 0x0E
    mov al, '.'
    int 0x10
    
    ; Delay
    push cx
    mov cx, 0x8000
.delay_loop:
    nop
    loop .delay_loop
    pop cx
    
    loop .scan_loop
    
    ; New line
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    
    ret

; Login Screen
show_login_screen:
    ; Apply selected color scheme
    cmp byte [color_scheme], 2
    je .use_green
    cmp byte [color_scheme], 3
    je .use_high_contrast
    
    ; Default black scheme
    call clear_screen_black
    jmp .continue_login
    
.use_green:
    call clear_screen_green
    jmp .continue_login
    
.use_high_contrast:
    call clear_screen_dark
    
.continue_login:
    ; Draw login header
    mov dh, 8
    mov dl, 30
    call set_cursor
    mov si, login_header
    call print_string_green
    
    ; Draw login box
    mov dh, 10
    mov dl, 20
    mov ch, 8
    mov cl, 40
    call draw_box
    
.login_loop:
    ; Username prompt
    mov dh, 12
    mov dl, 22
    call set_cursor
    mov si, username_prompt
    call print_string_white
    
    mov di, input_username
    mov cx, 32
    call get_input_string
    
    ; Password prompt
    mov dh, 14
    mov dl, 22
    call set_cursor
    mov si, password_prompt
    call print_string_white
    
    mov di, input_password
    mov cx, 32
    call get_password_input
    
    ; Verify credentials
    call verify_login
    cmp al, 1
    je .login_success
    
    ; Login failed
    mov dh, 16
    mov dl, 22
    call set_cursor
    mov si, login_failed_msg
    call print_string_red
    
    ; Wait and try again
    mov ah, 0x00
    int 0x16
    
    ; Clear error message
    mov dh, 16
    mov dl, 22
    call set_cursor
    mov si, clear_line
    call print_string_white
    
    jmp .login_loop

.login_success:
    mov dh, 16
    mov dl, 22
    call set_cursor
    mov si, login_success_msg
    call print_string_green
    
    ; Brief pause
    mov cx, 0x0003
.success_delay:
    push cx
    mov cx, 0xFFFF
.inner_delay:
    nop
    loop .inner_delay
    pop cx
    loop .success_delay
    
    ret

; Verify login credentials
verify_login:
    ; Compare username
    mov si, input_username
    mov di, stored_username
    call compare_strings
    cmp al, 1
    jne .login_fail
    
    ; Compare password
    mov si, input_password
    mov di, stored_password
    call compare_strings
    cmp al, 1
    jne .login_fail
    
    mov al, 1  ; Success
    ret

.login_fail:
    mov al, 0  ; Failure
    ret

; Show desktop environment
show_desktop:
    ; Apply color scheme
    cmp byte [color_scheme], 2
    je .desktop_green
    cmp byte [color_scheme], 3
    je .desktop_high_contrast
    
    call clear_screen_black
    jmp .continue_desktop
    
.desktop_green:
    call clear_screen_green
    jmp .continue_desktop
    
.desktop_high_contrast:
    call clear_screen_dark
    
.continue_desktop:
    ; Desktop header with system info
    mov dh, 0
    mov dl, 0
    call set_cursor
    mov si, desktop_header
    call print_string_green
    
    ; Welcome message
    mov dh, 2
    mov dl, 2
    call set_cursor
    mov si, welcome_msg
    call print_string_white
    
    mov si, stored_username
    call print_string_cyan
    
    mov si, welcome_msg2
    call print_string_white
    
    ; System ready message
    mov dh, 4
    mov dl, 2
    call set_cursor
    mov si, system_ready_msg
    call print_string_green
    
    ; Show system status
    mov dh, 5
    mov dl, 2
    call set_cursor
    mov si, system_status
    call print_string_white
    
    ret

; Show command prompt
show_prompt:
    mov dh, 23
    mov dl, 0
    call set_cursor
    
    ; Show username
    mov si, stored_username
    call print_string_cyan
    
    ; Show admin indicator if in admin mode
    cmp byte [admin_mode], 1
    jne .normal_prompt
    
    mov si, admin_indicator
    call print_string_red
    
.normal_prompt:
    mov si, prompt_symbol
    call print_string_white
    ret

; Get command input
get_command_input:
    mov di, command_buffer
    mov cx, 255
    call get_input_string
    ret

; Process commands
process_command:
    ; Clear any previous output area
    call clear_output_area
    
    ; Check for empty command
    mov si, command_buffer
    cmp byte [si], 0
    je .end_process
    
    ; Convert to lowercase for comparison
    mov si, command_buffer
    call to_lowercase
    
    ; Check each command
    mov si, command_buffer
    
    ; Help command
    mov di, cmd_help
    call compare_strings
    cmp al, 1
    je .cmd_help
    
    ; Settings command
    mov di, cmd_settings
    call compare_strings
    cmp al, 1
    je .cmd_settings
    
    ; Admin command
    mov di, cmd_admin
    call compare_strings
    cmp al, 1
    je .cmd_admin
    
    ; WiFi command
    mov di, cmd_wifi
    call compare_strings
    cmp al, 1
    je .cmd_wifi
    
    ; Users command
    mov di, cmd_users
    call compare_strings
    cmp al, 1
    je .cmd_users
    
    ; Apps command
    mov di, cmd_apps
    call compare_strings
    cmp al, 1
    je .cmd_apps
    
    ; Factory command (admin only)
    mov di, cmd_factory
    call compare_strings
    cmp al, 1
    je .cmd_factory
    
    ; Clear command
    mov di, cmd_clear
    call compare_strings
    cmp al, 1
    je .cmd_clear
    
    ; Version command
    mov di, cmd_version
    call compare_strings
    cmp al, 1
    je .cmd_version
    
    ; Theme command
    mov di, cmd_theme
    call compare_strings
    cmp al, 1
    je .cmd_theme
    
    ; Logout command
    mov di, cmd_logout
    call compare_strings
    cmp al, 1
    je .cmd_logout
    
    ; Exit command
    mov di, cmd_exit
    call compare_strings
    cmp al, 1
    je .cmd_exit
    
    ; Unknown command
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, unknown_cmd_msg
    call print_string_red
    jmp .end_process

.cmd_help:
    call show_help_menu
    jmp .end_process

.cmd_settings:
    call show_settings_menu
    jmp .end_process

.cmd_admin:
    call toggle_admin_mode
    jmp .end_process

.cmd_wifi:
    call show_wifi_menu
    jmp .end_process

.cmd_users:
    call show_users_menu
    jmp .end_process

.cmd_apps:
    call show_apps_menu
    jmp .end_process

.cmd_factory:
    call factory_reset
    jmp .end_process

.cmd_clear:
    call show_desktop
    jmp .end_process

.cmd_version:
    call show_version_info
    jmp .end_process

.cmd_theme:
    call change_theme
    jmp .end_process

.cmd_logout:
    call logout_user
    jmp .end_process

.cmd_exit:
    call shutdown_system
    jmp .end_process

.end_process:
    ret

; Show comprehensive help menu
show_help_menu:
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, help_header
    call print_string_cyan
    
    mov dh, 8
    mov dl, 2
    call set_cursor
    mov si, help_basic_header
    call print_string_yellow
    
    mov dh, 9
    mov dl, 4
    call set_cursor
    mov si, help_basic_commands
    call print_string_white
    
    mov dh, 11
    mov dl, 2
    call set_cursor
    mov si, help_system_header
    call print_string_yellow
    
    mov dh, 12
    mov dl, 4
    call set_cursor
    mov si, help_system_commands
    call print_string_white
    
    mov dh, 14
    mov dl, 2
    call set_cursor
    mov si, help_network_header
    call print_string_yellow
    
    mov dh, 15
    mov dl, 4
    call set_cursor
    mov si, help_network_commands
    call print_string_white
    
    mov dh, 17
    mov dl, 2
    call set_cursor
    mov si, help_admin_header
    call print_string_yellow
    
    mov dh, 18
    mov dl, 4
    call set_cursor
    mov si, help_admin_commands
    call print_string_white
    
    mov dh, 20
    mov dl, 2
    call set_cursor
    mov si, help_note
    call print_string_green
    
    ret

; Theme change command
change_theme:
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, theme_header
    call print_string_cyan
    
    mov dh, 8
    mov dl, 2
    call set_cursor
    mov si, theme_options
    call print_string_white
    
    mov dh, 12
    mov dl, 2
    call set_cursor
    mov si, theme_prompt
    call print_string_yellow
    
    ; Get theme selection
    mov ah, 0x00
    int 0x16
    
    cmp al, '1'
    je .theme_default
    cmp al, '2'
    je .theme_green
    cmp al, '3'
    je .theme_high_contrast
    
    ; Invalid selection
    mov dh, 14
    mov dl, 2
    call set_cursor
    mov si, invalid_theme_msg
    call print_string_red
    ret

.theme_default:
    mov byte [color_scheme], 1
    call show_desktop
    ret

.theme_green:
    mov byte [color_scheme], 2
    call show_desktop
    ret

.theme_high_contrast:
    mov byte [color_scheme], 3
    call show_desktop
    ret

; Show settings menu
show_settings_menu:
    ; Apply current color scheme
    cmp byte [color_scheme], 2
    je .settings_green
    cmp byte [color_scheme], 3
    je .settings_high_contrast
    
    call clear_screen_black
    jmp .continue_settings
    
.settings_green:
    call clear_screen_green
    jmp .continue_settings
    
.settings_high_contrast:
    call clear_screen_dark
    
.continue_settings:
    ; Settings header
    mov dh, 2
    mov dl, 25
    call set_cursor
    mov si, settings_header
    call print_string_green
    
    ; Draw settings box
    mov dh, 4
    mov dl, 15
    mov ch, 15
    mov cl, 50
    call draw_box
    
    ; Menu options
    mov dh, 6
    mov dl, 17
    call set_cursor
    mov si, settings_option1
    call print_string_white
    
    mov dh, 8
    mov dl, 17
    call set_cursor
    mov si, settings_option2
    call print_string_white
    
    mov dh, 10
    mov dl, 17
    call set_cursor
    mov si, settings_option3
    call print_string_white
    
    mov dh, 12
    mov dl, 17
    call set_cursor
    mov si, settings_option4
    call print_string_white
    
    mov dh, 14
    mov dl, 17
    call set_cursor
    mov si, settings_option5
    call print_string_white
    
    mov dh, 16
    mov dl, 17
    call set_cursor
    mov si, settings_option6
    call print_string_white
    
    mov dh, 17
    mov dl, 17
    call set_cursor
    mov si, settings_option0
    call print_string_yellow
    
    ; Get user choice
    mov dh, 18
    mov dl, 17
    call set_cursor
    mov si, choice_prompt
    call print_string_white
    
    ; Wait for key input
    mov ah, 0x00
    int 0x16
    
    ; Process choice
    cmp al, '1'
    je .wifi_config
    cmp al, '2'
    je .user_mgmt
    cmp al, '3'
    je .app_mgmt
    cmp al, '4'
    je .admin_toggle
    cmp al, '5'
    je .theme_change
    cmp al, '6'
    je .factory_reset
    cmp al, '0'
    je .back_to_desktop
    
    ; Invalid choice
    mov dh, 19
    mov dl, 17
    call set_cursor
    mov si, invalid_choice_msg
    call print_string_red
    
    ; Wait and return to settings
    mov ah, 0x00
    int 0x16
    call show_settings_menu
    ret

.wifi_config:
    call show_wifi_menu
    ret

.user_mgmt:
    call show_users_menu
    ret

.app_mgmt:
    call show_apps_menu
    ret

.admin_toggle:
    call toggle_admin_mode
    ret

.theme_change:
    call change_theme
    ret

.factory_reset:
    call factory_reset
    ret

.back_to_desktop:
    call show_desktop
    ret

; WiFi configuration menu
show_wifi_menu:
    ; Apply current color scheme
    cmp byte [color_scheme], 2
    je .wifi_green
    cmp byte [color_scheme], 3
    je .wifi_high_contrast
    
    call clear_screen_black
    jmp .continue_wifi
    
.wifi_green:
    call clear_screen_green
    jmp .continue_wifi
    
.wifi_high_contrast:
    call clear_screen_dark
    
.continue_wifi:
    mov dh, 2
    mov dl, 25
    call set_cursor
    mov si, wifi_header
    call print_string_green
    
    ; Show current status
    mov dh, 5
    mov dl, 10
    call set_cursor
    mov si, wifi_status_msg
    call print_string_white
    
    mov si, wifi_current_status
    call print_string_cyan
    
    ; Show scanning message
    mov dh, 7
    mov dl, 10
    call set_cursor
    mov si, wifi_scanning_msg
    call print_string_yellow
    
    ; Simulate scanning
    call simulate_network_scan
    
    ; Show networks
    mov dh, 9
    mov dl, 10
    call set_cursor
    mov si, wifi_networks_header
    call print_string_white
    
    mov dh, 11
    mov dl, 12
    call set_cursor
    mov si, wifi_network_1
    call print_string_white
    
    mov dh, 12
    mov dl, 12
    call set_cursor
    mov si, wifi_network_2
    call print_string_white
    
    mov dh, 13
    mov dl, 12
    call set_cursor
    mov si, wifi_network_3
    call print_string_white
    
    mov dh, 15
    mov dl, 10
    call set_cursor
    mov si, wifi_connect_prompt
    call print_string_yellow
    
    ; Wait for user input
    mov ah, 0x00
    int 0x16
    
    call show_desktop
    ret

; User management menu
show_users_menu:
    ; Apply current color scheme
    cmp byte [color_scheme], 2
    je .users_green
    cmp byte [color_scheme], 3
    je .users_high_contrast
    
    call clear_screen_black
    jmp .continue_users
    
.users_green:
    call clear_screen_green
    jmp .continue_users
    
.users_high_contrast:
    call clear_screen_dark
    
.continue_users:
    mov dh, 2
    mov dl, 25
    call set_cursor
    mov si, users_header
    call print_string_green
    
    mov dh, 6
    mov dl, 10
    call set_cursor
    mov si, users_current
    call print_string_white
    
    mov si, stored_username
    call print_string_cyan
    
    mov dh, 8
    mov dl, 10
    call set_cursor
    mov si, users_admin_status
    call print_string_white
    
    cmp byte [admin_mode], 1
    je .show_admin_yes
    
    mov si, admin_status_no
    call print_string_red
    jmp .continue_user_menu
    
.show_admin_yes:
    mov si, admin_status_yes
    call print_string_green
    
.continue_user_menu:
    mov dh, 10
    mov dl, 10
    call set_cursor
    mov si, users_options
    call print_string_white
    
    ; Wait for user input
    mov ah, 0x00
    int 0x16
    
    call show_desktop
    ret

; Application management menu
show_apps_menu:
    ; Apply current color scheme
    cmp byte [color_scheme], 2
    je .apps_green
    cmp byte [color_scheme], 3
    je .apps_high_contrast
    
    call clear_screen_black
    jmp .continue_apps
    
.apps_green:
    call clear_screen_green
    jmp .continue_apps
    
.apps_high_contrast:
    call clear_screen_dark
    
.continue_apps:
    mov dh, 2
    mov dl, 25
    call set_cursor
    mov si, apps_header
    call print_string_green
    
    mov dh, 6
    mov dl, 10
    call set_cursor
    mov si, apps_installed
    call print_string_white
    
    mov dh, 8
    mov dl, 12
    call set_cursor
    mov si, app_system_tools
    call print_string_white
    
    mov dh, 9
    mov dl, 12
    call set_cursor
    mov si, app_network_manager
    call print_string_white
    
    mov dh, 10
    mov dl, 12
    call set_cursor
    mov si, app_text_editor
    call print_string_white
    
    mov dh, 11
    mov dl, 12
    call set_cursor
    mov si, app_settings
    call print_string_white
    
    mov dh, 13
    mov dl, 10
    call set_cursor
    mov si, apps_management_options
    call print_string_yellow
    
    ; Wait for user input
    mov ah, 0x00
    int 0x16
    
    call show_desktop
    ret

; Toggle admin mode
toggle_admin_mode:
    cmp byte [admin_mode], 1
    je .disable_admin
    
    ; Enable admin mode - require password
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, admin_password_prompt
    call print_string_yellow
    
    mov di, temp_password
    mov cx, 32
    call get_password_input
    
    ; Verify admin password (same as user password for simplicity)
    mov si, temp_password
    mov di, stored_password
    call compare_strings
    cmp al, 1
    jne .admin_fail
    
    ; Enable admin mode
    mov byte [admin_mode], 1
    mov dh, 8
    mov dl, 2
    call set_cursor
    mov si, admin_enabled_msg
    call print_string_green
    ret

.disable_admin:
    ; Disable admin mode
    mov byte [admin_mode], 0
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, admin_disabled_msg
    call print_string_green
    ret

.admin_fail:
    mov dh, 8
    mov dl, 2
    call set_cursor
    mov si, admin_fail_msg
    call print_string_red
    ret

; Factory reset function
factory_reset:
    ; Check if admin mode is enabled
    cmp byte [admin_mode], 1
    jne .not_admin
    
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, factory_warning
    call print_string_red
    
    mov dh, 8
    mov dl, 2
    call set_cursor
    mov si, factory_confirm
    call print_string_yellow
    
    ; Get confirmation
    mov ah, 0x00
    int 0x16
    
    cmp al, 'Y'
    je .do_reset
    cmp al, 'y'
    je .do_reset
    
    mov dh, 10
    mov dl, 2
    call set_cursor
    mov si, factory_cancelled
    call print_string_green
    ret

.do_reset:
    mov dh, 10
    mov dl, 2
    call set_cursor
    mov si, factory_resetting
    call print_string_red
    
    ; Show progress
    call show_reset_progress
    
    ; Clear setup flag to force setup on next boot
    call clear_setup_flag
    
    ; Reset system variables
    call reset_system_variables
    
    mov dh, 15
    mov dl, 2
    call set_cursor
    mov si, factory_complete
    call print_string_green
    
    ; Wait and reboot
    mov cx, 0x0005
.reset_delay:
    push cx
    mov cx, 0xFFFF
.inner_delay:
    nop
    loop .inner_delay
    pop cx
    loop .reset_delay
    
    ; Reboot system
    db 0x0EA
    dw 0x0000
    dw 0xFFFF

.not_admin:
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, admin_required_msg
    call print_string_red
    ret

; Show factory reset progress
show_reset_progress:
    mov dh, 12
    mov dl, 2
    call set_cursor
    mov si, reset_progress_msg
    call print_string_white
    
    ; Show progress bar
    mov cx, 20
    mov dl, 2
    inc dh
    
.progress_loop:
    call set_cursor
    mov ah, 0x0E
    mov al, 0xDB  ; Block character
    int 0x10
    
    ; Delay
    push cx
    mov cx, 0x8000
.progress_delay:
    nop
    loop .progress_delay
    pop cx
    
    inc dl
    loop .progress_loop
    
    ret

; Reset system variables
reset_system_variables:
    ; Clear stored credentials
    mov di, stored_username
    mov cx, 33
    mov al, 0
    rep stosb
    
    mov di, stored_password
    mov cx, 33
    mov al, 0
    rep stosb
    
    ; Reset admin mode
    mov byte [admin_mode], 0
    
    ; Reset color scheme
    mov byte [color_scheme], 1
    
    ret

; Show version information
show_version_info:
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, version_header
    call print_string_cyan
    
    mov dh, 8
    mov dl, 2
    call set_cursor
    mov si, version_info
    call print_string_white
    
    mov dh, 9
    mov dl, 2
    call set_cursor
    mov si, version_build
    call print_string_white
    
    mov dh, 10
    mov dl, 2
    call set_cursor
    mov si, version_features
    call print_string_green
    
    mov dh, 12
    mov dl, 2
    call set_cursor
    mov si, version_color_scheme
    call print_string_white
    
    ; Show current color scheme
    cmp byte [color_scheme], 1
    je .show_scheme_default
    cmp byte [color_scheme], 2
    je .show_scheme_green
    cmp byte [color_scheme], 3
    je .show_scheme_high_contrast
    
.show_scheme_default:
    mov si, scheme_name_default
    call print_string_cyan
    ret
    
.show_scheme_green:
    mov si, scheme_name_green
    call print_string_green
    ret
    
.show_scheme_high_contrast:
    mov si, scheme_name_high_contrast
    call print_string_white
    ret

; Logout user
logout_user:
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, logout_msg
    call print_string_yellow
    
    ; Brief delay
    mov cx, 0x0002
.logout_delay:
    push cx
    mov cx, 0xFFFF
.inner_delay:
    nop
    loop .inner_delay
    pop cx
    loop .logout_delay
    
    ; Reset admin mode on logout
    mov byte [admin_mode], 0
    
    ; Return to login screen
    call show_login_screen
    jmp main_loop

; Shutdown system
shutdown_system:
    mov dh, 6
    mov dl, 2
    call set_cursor
    mov si, shutdown_msg
    call print_string_yellow
    
    ; Show shutdown progress
    mov dh, 8
    mov dl, 2
    call set_cursor
    mov si, shutdown_progress
    call print_string_white
    
    ; Brief delay
    mov cx, 0x0003
.shutdown_delay:
    push cx
    mov cx, 0xFFFF
.inner_delay:
    nop
    loop .inner_delay
    pop cx
    loop .shutdown_delay
    
    ; Shutdown
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    
    ; If shutdown fails, halt
    cli
    hlt

; Mark setup as complete
mark_setup_complete:
    ; Write setup completion flag to disk sector 20
    mov ah, 0x03        ; Write sectors
    mov al, 1           ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 20          ; Sector 20
    mov dh, 0           ; Head 0
    mov dl, [0x7C00 + 510 - 1]  ; Boot drive
    
    ; Prepare setup flag data
    mov bx, 0x600
    mov es, bx
    mov bx, 0x0000
    mov word [es:0x0000], 0x4F53  ; "SO" signature
    
    int 0x13
    ret

; Clear setup flag for factory reset
clear_setup_flag:
    ; Clear sector 20
    mov ah, 0x03        ; Write sectors
    mov al, 1           ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 20          ; Sector 20
    mov dh, 0           ; Head 0
    mov dl, [0x7C00 + 510 - 1]  ; Boot drive
    
    ; Clear data
    mov bx, 0x600
    mov es, bx
    mov bx, 0x0000
    mov word [es:0x0000], 0x0000  ; Clear signature
    
    int 0x13
    ret

; Utility functions
set_cursor:
    mov ah, 0x02
    mov bh, 0
    int 0x10
    ret

print_string_white:
    mov bl, 0x0F
    jmp print_string_colored

print_string_red:
    mov bl, 0x0C
    jmp print_string_colored

print_string_green:
    mov bl, 0x0A
    jmp print_string_colored

print_string_yellow:
    mov bl, 0x0E
    jmp print_string_colored

print_string_cyan:
    mov bl, 0x0B
    jmp print_string_colored

print_string_colored:
    push ax
    push bx
    push cx
    
.print_loop:
    lodsb
    cmp al, 0
    je .done
    
    mov ah, 0x09
    mov bh, 0
    mov cx, 1
    int 0x10
    
    ; Move cursor forward
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    
    jmp .print_loop

.done:
    pop cx
    pop bx
    pop ax
    ret

; Draw a box
draw_box:
    ; DH=top, DL=left, CH=height, CL=width
    push ax
    push bx
    push cx
    push dx
    
    ; Save parameters
    mov [box_top], dh
    mov [box_left], dl
    mov [box_height], ch
    mov [box_width], cl
    
    ; Draw top border
    call set_cursor
    mov al, 0xDA  ; Top-left corner
    mov bl, 0x0F
    mov ah, 0x09
    mov bh, 0
    mov cx, 1
    int 0x10
    
    ; Draw top line
    mov cl, [box_width]
    sub cl, 2
.top_line:
    mov ah, 0x03
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    
    mov al, 0xC4  ; Horizontal line
    mov ah, 0x09
    mov cx, 1
    int 0x10
    
    dec cl
    jnz .top_line
    
    ; Top-right corner
    mov ah, 0x03
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    
    mov al, 0xBF  ; Top-right corner
    mov ah, 0x09
    mov cx, 1
    int 0x10
    
    ; Draw sides
    mov ch, [box_height]
    sub ch, 2
    mov dh, [box_top]
    inc dh
    
.side_loop:
    ; Left side
    mov dl, [box_left]
    call set_cursor
    mov al, 0xB3  ; Vertical line
    mov ah, 0x09
    mov cx, 1
    int 0x10
    
    ; Right side
    mov dl, [box_left]
    add dl, [box_width]
    dec dl
    call set_cursor
    mov al, 0xB3  ; Vertical line
    mov ah, 0x09
    mov cx, 1
    int 0x10
    
    inc dh
    dec ch
    jnz .side_loop
    
    ; Bottom border
    mov dh, [box_top]
    add dh, [box_height]
    dec dh
    mov dl, [box_left]
    call set_cursor
    
    mov al, 0xC0  ; Bottom-left corner
    mov ah, 0x09
    mov cx, 1
    int 0x10
    
    ; Bottom line
    mov cl, [box_width]
    sub cl, 2
.bottom_line:
    mov ah, 0x03
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    
    mov al, 0xC4  ; Horizontal line
    mov ah, 0x09
    mov cx, 1
    int 0x10
    
    dec cl
    jnz .bottom_line
    
    ; Bottom-right corner
    mov ah, 0x03
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    
    mov al, 0xD9  ; Bottom-right corner
    mov ah, 0x09
    mov cx, 1
    int 0x10
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Get input string
get_input_string:
    ; DI = buffer, CX = max length
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 0  ; Character count
    
.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13  ; Enter key
    je .input_done
    
    cmp al, 8   ; Backspace
    je .handle_backspace
    
    cmp al, 32  ; Space or printable character
    jl .input_loop
    
    cmp bx, cx  ; Check max length
    jge .input_loop
    
    ; Store character
    mov [di + bx], al
    inc bx
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    jmp .input_loop

.handle_backspace:
    cmp bx, 0
    je .input_loop
    
    dec bx
    mov byte [di + bx], 0
    
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
    mov byte [di + bx], 0  ; Null terminate
    
    ; Move to next line
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Get password input (masked)
get_password_input:
    ; DI = buffer, CX = max length
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 0  ; Character count
    
.password_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13  ; Enter key
    je .password_done
    
    cmp al, 8   ; Backspace
    je .handle_password_backspace
    
    cmp al, 32  ; Space or printable character
    jl .password_loop
    
    cmp bx, cx  ; Check max length
    jge .password_loop
    
    ; Store character
    mov [di + bx], al
    inc bx
    
    ; Echo asterisk
    mov ah, 0x0E
    mov al, '*'
    int 0x10
    
    jmp .password_loop

.handle_password_backspace:
    cmp bx, 0
    je .password_loop
    
    dec bx
    mov byte [di + bx], 0
    
    ; Move cursor back and erase
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    
    jmp .password_loop

.password_done:
    mov byte [di + bx], 0  ; Null terminate
    
    ; Move to next line
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Compare strings
compare_strings:
    ; SI = string1, DI = string2
    ; Returns AL = 1 if equal, 0 if not
    push bx
    push cx
    
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
    mov al, 1
    jmp .compare_done

.not_equal:
    mov al, 0

.compare_done:
    pop cx
    pop bx
    ret

; Convert string to lowercase
to_lowercase:
    ; SI = string
    push ax
    push si
    
.lower_loop:
    mov al, [si]
    cmp al, 0
    je .lower_done
    
    cmp al, 'A'
    jl .next_char
    cmp al, 'Z'
    jg .next_char
    
    add al, 32  ; Convert to lowercase
    mov [si], al

.next_char:
    inc si
    jmp .lower_loop

.lower_done:
    pop si
    pop ax
    ret

; Clear output area
clear_output_area:
    ; Clear lines 6-22 for command output
    mov dh, 6
    mov dl, 0
    mov ch, 17
    
.clear_loop:
    call set_cursor
    
    ; Clear line
    mov cx, 80
.clear_line:
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    loop .clear_line
    
    inc dh
    dec ch
    jnz .clear_loop
    
    ret

; Data section
; Setup messages
setup_header        db '                    OMNIOS 2.0 INITIAL SETUP                    ', 0
setup_step1         db 'Step 1: Create User Account', 0
setup_step2         db 'Step 2: Network Configuration', 0
setup_step3         db 'Step 3: Color Scheme Selection', 0
setup_complete_msg  db 'Setup Complete! Press any key to continue...', 0
network_scan_msg    db 'Scanning for available networks', 0
network_list        db '1. OmniNet-5G (Secured)  2. HomeWiFi (Secured)  3. Skip', 0
color_scheme_prompt db 'Select color scheme: 1=Default 2=Green 3=High Contrast', 0

; Login messages
login_header        db '                        OMNIOS 2.0 LOGIN                        ', 0
login_failed_msg    db 'Login failed! Press any key to try again...', 0
login_success_msg   db 'Login successful! Welcome to OmniOS 2.0', 0

; Desktop messages
desktop_header      db '                    OMNIOS 2.0 DESKTOP ENVIRONMENT                    ', 0
welcome_msg         db 'Welcome back, ', 0
welcome_msg2        db '!', 0
system_ready_msg    db 'System ready. Type "help" for available commands.', 0
system_status       db 'Status: All systems operational | Memory: 640KB | Color: Professional', 0

; Prompt
prompt_symbol       db '> ', 0
admin_indicator     db ' [ADMIN]', 0

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
cmd_theme           db 'theme', 0
cmd_logout          db 'logout', 0
cmd_exit            db 'exit', 0

; Help messages
help_header         db 'OMNIOS 2.0 ENHANCED COMMAND REFERENCE:', 0
help_basic_header   db 'Basic Commands:', 0
help_basic_commands db 'help, clear, version, theme, logout, exit', 0
help_system_header  db 'System Commands:', 0
help_system_commands db 'settings, admin, users, apps', 0
help_network_header db 'Network Commands:', 0
help_network_commands db 'wifi', 0
help_admin_header   db 'Admin Commands (requires admin mode):', 0
help_admin_commands db 'factory', 0
help_note           db 'Use "settings" for comprehensive configuration menu', 0

; Theme messages
theme_header        db 'COLOR SCHEME SELECTION:', 0
theme_options       db '1. Default (Black/White) - Professional look', 13, 10, '2. Matrix (Black/Green) - Retro terminal style', 13, 10, '3. High Contrast (Black/White) - Maximum readability', 0
theme_prompt        db 'Select theme (1-3): ', 0
invalid_theme_msg   db 'Invalid selection! Please choose 1, 2, or 3.', 0

; Settings messages
settings_header     db '                       SYSTEM SETTINGS                       ', 0
settings_option1    db '1. WiFi Configuration', 0
settings_option2    db '2. User Management', 0
settings_option3    db '3. Application Management', 0
settings_option4    db '4. Admin Mode Toggle', 0
settings_option5    db '5. Color Theme Selection', 0
settings_option6    db '6. Factory Reset', 0
settings_option0    db '0. Back to Desktop', 0
choice_prompt       db 'Select option (0-6): ', 0
invalid_choice_msg  db 'Invalid choice! Press any key...', 0

; WiFi messages
wifi_header         db '                   WIFI CONFIGURATION                   ', 0
wifi_status_msg     db 'Current status: ', 0
wifi_current_status db 'Not connected', 0
wifi_scanning_msg   db 'Scanning for networks', 0
wifi_networks_header db 'Available networks:', 0
wifi_network_1      db '1. OmniNet-5G (Signal: 90%) [Secured]', 0
wifi_network_2      db '2. HomeWiFi (Signal: 75%) [Secured]', 0
wifi_network_3      db '3. PublicNet (Signal: 45%) [Open]', 0
wifi_connect_prompt db 'Select network to connect (1-3) or press any key to exit: ', 0

; User management messages
users_header        db '                   USER MANAGEMENT                   ', 0
users_current       db 'Current user: ', 0
users_admin_status  db 'Admin status: ', 0
admin_status_yes    db 'ENABLED', 0
admin_status_no     db 'DISABLED', 0
users_options       db 'Options: Change password, User settings, Account management', 0

; Application management messages
apps_header         db '                APPLICATION MANAGEMENT                ', 0
apps_installed      db 'Installed applications:', 0
app_system_tools    db '- System Tools (Settings, Admin, Network)', 0
app_network_manager db '- Network Manager (WiFi, Connections)', 0
app_text_editor     db '- Text Editor (Basic text editing)', 0
app_settings        db '- Settings Manager (System configuration)', 0
apps_management_options db 'Management: Install, Remove, Configure applications', 0

; Admin messages
admin_password_prompt db 'Enter admin password: ', 0
admin_enabled_msg   db 'Administrator mode ENABLED - Full system access granted', 0
admin_disabled_msg  db 'Administrator mode DISABLED - Standard user access', 0
admin_fail_msg      db 'Incorrect password! Access denied.', 0
admin_required_msg  db 'Administrator privileges required for this operation!', 0

; Factory reset messages
factory_warning     db 'WARNING: This will erase ALL data and reset to factory defaults!', 0
factory_confirm     db 'Type Y to confirm factory reset (any other key cancels): ', 0
factory_cancelled   db 'Factory reset cancelled - No changes made.', 0
factory_resetting   db 'Performing factory reset - DO NOT POWER OFF!', 0
reset_progress_msg  db 'Progress: ', 0
factory_complete    db 'Factory reset complete. System will restart in 3 seconds.', 0

; Version messages
version_header      db 'OMNIOS 2.0 ENHANCED PROFESSIONAL EDITION', 0
version_info        db 'Version: 2.0.0 Professional', 0
version_build       db 'Build: 2025.01.23 | Architecture: x86 16-bit Real Mode', 0
version_features    db 'Features: Setup, Authentication, Settings, Admin, Themes, Factory Reset', 0
version_color_scheme db 'Current color scheme: ', 0
scheme_name_default db 'Default (Professional Black)', 0
scheme_name_green   db 'Matrix (Terminal Green)', 0
scheme_name_high_contrast db 'High Contrast (Maximum Readability)', 0

; System messages
logout_msg          db 'Logging out... Returning to login screen.', 0
shutdown_msg        db 'Shutting down system... Please wait.', 0
shutdown_progress   db 'Saving system state and powering down...', 0
unknown_cmd_msg     db 'Unknown command. Type "help" for available commands.', 0
clear_line          db '                                                                                ', 0

; Input prompts
username_prompt     db 'Username: ', 0
password_prompt     db 'Password: ', 0

; Storage variables
stored_username     times 33 db 0
stored_password     times 33 db 0
input_username      times 33 db 0
input_password      times 33 db 0
temp_password       times 33 db 0
command_buffer      times 256 db 0
admin_mode          db 0
color_scheme        db 1  ; 1=Default, 2=Green, 3=High Contrast

; Box drawing variables
box_top             db 0
box_left            db 0
box_height          db 0
box_width           db 0

; Pad kernel to fill sectors
times 12288-($-$$) db 0  ; 24 sectors * 512 bytes = 12288 bytes
