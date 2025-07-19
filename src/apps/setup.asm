; OmniOS 2.0 Setup Application
[BITS 16]

setup_application:
    call clear_screen_color
    call draw_setup_window
    call setup_wizard
    ret

draw_setup_window:
    ; Main setup window
    mov dh, 2   ; Top
    mov dl, 5   ; Left
    mov ch, 20  ; Height
    mov cl, 70  ; Width
    mov bl, [color_scheme+1]  ; Setup window color
    call draw_window
    
    ; Title
    mov ah, 0x02
    mov bh, 0
    mov dh, 3
    mov dl, 30
    int 0x10
    
    mov si, setup_title
    mov bl, [color_scheme+7]
    call print_colored
    
    ret

setup_wizard:
    call setup_step_welcome
    call setup_step_hardware
    call setup_step_user_account
    call setup_step_network
    call setup_step_timezone
    call setup_step_finish
    ret

setup_step_welcome:
    ; Clear content area
    mov ah, 0x06
    mov al, 0
    mov bh, [color_scheme+1]
    mov ch, 5
    mov cl, 7
    mov dh, 20
    mov dl, 73
    int 0x10
    
    ; Welcome message
    mov ah, 0x02
    mov bh, 0
    mov dh, 7
    mov dl, 10
    int 0x10
    
    mov si, welcome_msg
    mov bl, [color_scheme+1]
    call print_colored
    
    ; Instructions
    mov dh, 10
    mov dl, 10
    mov ah, 0x02
    int 0x10
    
    mov si, setup_instructions
    call print_colored
    
    ; Wait for Enter
    call wait_for_enter
    ret

setup_step_hardware:
    ; Hardware detection step
    mov ah, 0x02
    mov dh, 7
    mov dl, 10
    int 0x10
    
    mov si, hardware_detect_msg
    call print_colored
    
    ; Simulate hardware detection
    call detect_hardware
    call display_hardware_info
    call wait_for_enter
    ret

setup_step_user_account:
    ; User account creation
    mov ah, 0x02
    mov dh, 7
    mov dl, 10
    int 0x10
    
    mov si, user_account_msg
    call print_colored
    
    ; Username input
    mov dh, 10
    mov dl, 10
    mov ah, 0x02
    int 0x10
    
    mov si, username_prompt
    call print_colored
    
    call input_username
    
    ; Password input (optional in this demo)
    mov dh, 12
    mov dl, 10
    mov ah, 0x02
    int 0x10
    
    mov si, password_prompt
    call print_colored
    
    call input_password
    ret

setup_step_network:
    ; Network configuration
    mov ah, 0x02
    mov dh, 7
    mov dl, 10
    int 0x10
    
    mov si, network_config_msg
    call print_colored
    
    ; WiFi scanning simulation
    mov dh, 10
    mov dl, 10
    mov ah, 0x02
    int 0x10
    
    mov si, wifi_scan_msg
    call print_colored
    
    call simulate_wifi_scan
    call wait_for_enter
    ret

setup_step_timezone:
    ; Timezone selection
    mov ah, 0x02
    mov dh, 7
    mov dl, 10
    int 0x10
    
    mov si, timezone_msg
    call print_colored
    
    ; Show timezone options
    call display_timezone_options
    call select_timezone
    ret

setup_step_finish:
    ; Setup completion
    mov ah, 0x02
    mov dh, 7
    mov dl, 10
    int 0x10
    
    mov si, setup_complete_msg
    call print_colored
    
    ; Configuration summary
    call display_setup_summary
    call wait_for_enter
    
    ; Save configuration
    call save_setup_config
    ret

detect_hardware:
    ; Simulate hardware detection
    mov cx, 3  ; Number of detection steps
    mov dh, 9
    
    .detect_loop:
        mov ah, 0x02
        mov bh, 0
        mov dl, 12
        int 0x10
        
        mov si, detecting_text
        call print_colored
        
        ; Progress indicator
        mov ah, 0x09
        mov al, '.'
        mov bh, 0
        mov bl, [color_scheme+2]
        push cx
        mov cx, 1
        int 0x10
        pop cx
        
        ; Small delay
        push cx
        push dx
        mov cx, 0
        mov dx, 30000
        mov ah, 0x86
        int 0x15
        pop dx
        pop cx
        
        inc dh
        loop .detect_loop
    
    ret

display_hardware_info:
    mov dh, 13
    mov dl, 10
    mov ah, 0x02
    int 0x10
    
    mov si, hardware_info
    call print_colored
    ret

input_username:
    ; Simple username input
    mov di, username
    mov cx, 0
    
    .input_loop:
        mov ah, 0x00
        int 0x16
        
        cmp al, 13  ; Enter
        je .input_done
        
        cmp al, 8   ; Backspace
        je .handle_backspace
        
        ; Store character
        stosb
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
        
        ; Erase character
        mov ah, 0x0E
        mov al, 8
        int 0x10
        mov al, ' '
        int 0x10
        mov al, 8
        int 0x10
        
        jmp .input_loop
    
    .input_done:
        mov al, 0
        stosb  ; Null terminate
        ret

input_password:
    ; Password input (masked)
    mov di, password
    mov cx, 0
    
    .pass_loop:
        mov ah, 0x00
        int 0x16
        
        cmp al, 13
        je .pass_done
        
        cmp al, 8
        je .pass_backspace
        
        stosb
        inc cx
        
        ; Show asterisk
        mov ah, 0x0E
        mov al, '*'
        int 0x10
        
        jmp .pass_loop
    
    .pass_backspace:
        cmp cx, 0
        je .pass_loop
        
        dec di
        dec cx
        
        mov ah, 0x0E
        mov al, 8
        int 0x10
        mov al, ' '
        int 0x10
        mov al, 8
        int 0x10
        
        jmp .pass_loop
    
    .pass_done:
        mov al, 0
        stosb
        ret

simulate_wifi_scan:
    ; Show scanning progress
    mov cx, 5
    mov dh, 11
    
    .scan_loop:
        mov ah, 0x02
        mov bh, 0
        mov dl, 12
        int 0x10
        
        mov si, scanning_text
        call print_colored
        
        ; Add progress dots
        mov ah, 0x09
        mov al, '.'
        mov bh, 0
        mov bl, [color_scheme+2]
        push cx
        mov cx, 1
        int 0x10
        pop cx
        
        ; Delay
        push cx
        push dx
        mov cx, 0
        mov dx, 20000
        mov ah, 0x86
        int 0x15
        pop dx
        pop cx
        
        inc dh
        loop .scan_loop
    
    ; Show found networks
    mov dh, 17
    mov dl, 12
    mov ah, 0x02
    int 0x10
    
    mov si, networks_found
    call print_colored
    ret

display_timezone_options:
    mov dh, 10
    mov dl, 12
    
    mov si, timezone_options
    mov cx, 5  ; Number of timezone options
    
    .tz_loop:
        mov ah, 0x02
        mov bh, 0
        int 0x10
        
        call print_colored
        
        ; Skip to next string
        .skip_tz:
            lodsb
            cmp al, 0
            jne .skip_tz
        
        inc dh
        loop .tz_loop
    
    ret

select_timezone:
    ; Simple timezone selection
    mov ah, 0x00
    int 0x16
    
    ; Store selected timezone
    mov [selected_timezone], al
    ret

display_setup_summary:
    mov dh, 10
    mov dl, 10
    mov ah, 0x02
    int 0x10
    
    mov si, summary_header
    call print_colored
    
    ; Show username
    mov dh, 12
    mov dl, 12
    mov ah, 0x02
    int 0x10
    
    mov si, summary_username
    call print_colored
    
    mov si, username
    call print_colored
    
    ; Show other settings
    mov dh, 13
    mov dl, 12
    mov ah, 0x02
    int 0x10
    
    mov si, summary_complete
    call print_colored
    
    ret

save_setup_config:
    ; Save configuration to file
    ; (File operations would go here)
    ret

wait_for_enter:
    .wait_loop:
        mov ah, 0x00
        int 0x16
        cmp al, 13
        jne .wait_loop
    ret

; Setup Application Data
setup_title db 'OmniOS 2.0 Initial Setup', 0
welcome_msg db 'Welcome to OmniOS 2.0! This wizard will help you configure your system.', 0
setup_instructions db 'Press Enter to continue through each step.', 0
hardware_detect_msg db 'Step 1: Hardware Detection', 0
detecting_text db 'Detecting hardware', 0
hardware_info db 'Hardware detection complete. CPU: 486+, RAM: 256MB+', 0
user_account_msg db 'Step 2: User Account Setup', 0
username_prompt db 'Enter username: ', 0
password_prompt db 'Enter password: ', 0
network_config_msg db 'Step 3: Network Configuration', 0
wifi_scan_msg db 'Scanning for WiFi networks...', 0
scanning_text db 'Scanning', 0
networks_found db 'Found networks: OmniNet, TestWiFi, HomeNetwork', 0
timezone_msg db 'Step 4: Timezone Selection', 0
timezone_options:
    db '1. UTC (GMT+0)', 0
    db '2. EST (GMT-5)', 0
    db '3. PST (GMT-8)', 0
    db '4. CET (GMT+1)', 0
    db '5. JST (GMT+9)', 0
setup_complete_msg db 'Step 5: Setup Complete!', 0
summary_header db 'Configuration Summary:', 0
summary_username db 'Username: ', 0
summary_complete db 'Setup completed successfully!', 0

; Setup variables
username resb 32
password resb 32
selected_timezone db 0
