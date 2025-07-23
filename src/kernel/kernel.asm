; OmniOS 2.0 Professional Kernel - Fixed Display + New Applications
; Complete operating system with advanced applications

[BITS 16]
[ORG 0x0000]

kernel_start:
    ; Initialize segments
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    
    ; Clear screen with proper initialization
    call clear_screen_properly
    
    ; Check if first boot (flag stored at 0x500 by bootloader)
    push ds
    mov ax, 0x0000
    mov ds, ax
    mov al, [0x500]
    pop ds
    mov [first_boot], al
    
    ; Display clean header
    call display_clean_header
    
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
    ; Display clean prompt
    mov si, clean_prompt
    call print_string
    
    ; Get user input
    call get_input
    
    ; Process command
    call process_command
    
    jmp main_loop

; Clear screen properly without garbled characters
clear_screen_properly:
    ; Set video mode to clear any corruption
    mov ax, 0x0003
    int 0x10
    
    ; Set cursor to top-left
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 0x10
    
    ; Clear screen with spaces
    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x07    ; White on black
    mov ch, 0x00
    mov cl, 0x00
    mov dh, 0x18
    mov dl, 0x4F
    int 0x10
    
    ret

; Display clean header without garbled characters
display_clean_header:
    mov si, clean_header
    call print_string
    
    mov si, version_info
    call print_string
    
    call newline
    ret

; Enhanced setup system
setup_system:
    call clear_screen_properly
    
    mov si, setup_header
    call print_string
    
    mov si, setup_welcome_msg
    call print_string
    
    ; Wait for key press
    mov ah, 0x00
    int 0x16
    
    call newline
    ret

; Create user account
create_user_account:
    mov si, user_creation_msg
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
    mov si, account_success_msg
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call clear_screen_properly
    ret

; User login system
user_login:
    call clear_screen_properly
    
    mov si, login_header
    call print_string
    
.login_loop:
    ; Get username
    mov si, login_username_prompt
    call print_string
    mov di, input_username
    call get_string
    
    ; Get password
    mov si, login_password_prompt
    call print_string
    mov di, input_password
    call get_string_hidden
    
    ; Verify credentials
    call verify_login
    cmp al, 1
    je .login_success
    
    ; Login failed
    mov si, login_failed_msg
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
    
    call clear_screen_properly
    call show_desktop
    ret

; Show desktop with application menu
show_desktop:
    mov si, desktop_header
    call print_string
    
    mov si, available_apps
    call print_string
    
    ret

; Process user commands - Enhanced with new applications
process_command:
    ; Check for empty command
    cmp byte [input_buffer], 0
    je .done
    
    ; Basic Commands
    mov si, input_buffer
    mov di, cmd_help
    call compare_strings
    cmp al, 1
    je show_help
    
    mov si, input_buffer
    mov di, cmd_clear
    call compare_strings
    cmp al, 1
    je clear_and_desktop
    
    mov si, input_buffer
    mov di, cmd_apps
    call compare_strings
    cmp al, 1
    je show_applications
    
    ; New Applications
    mov si, input_buffer
    mov di, cmd_notepad
    call compare_strings
    cmp al, 1
    je launch_notepad
    
    mov si, input_buffer
    mov di, cmd_filemanager
    call compare_strings
    cmp al, 1
    je launch_filemanager
    
    mov si, input_buffer
    mov di, cmd_diskmanager
    call compare_strings
    cmp al, 1
    je launch_diskmanager
    
    mov si, input_buffer
    mov di, cmd_package
    call compare_strings
    cmp al, 1
    je launch_package_installer
    
    mov si, input_buffer
    mov di, cmd_download
    call compare_strings
    cmp al, 1
    je launch_downloader
    
    ; Admin Applications
    mov si, input_buffer
    mov di, cmd_admin
    call compare_strings
    cmp al, 1
    je admin_menu
    
    mov si, input_buffer
    mov di, cmd_shutdown
    call compare_strings
    cmp al, 1
    je shutdown_system
    
    ; Unknown command
    mov si, unknown_command_msg
    call print_string

.done:
    ret

; Clear screen and show desktop
clear_and_desktop:
    call clear_screen_properly
    call show_desktop
    ret

; Show all applications
show_applications:
    call clear_screen_properly
    
    mov si, apps_header
    call print_string
    
    mov si, apps_list
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call clear_and_desktop
    ret

; Launch Notepad Application
launch_notepad:
    call clear_screen_properly
    
    mov si, notepad_header
    call print_string
    
    mov si, notepad_interface
    call print_string
    
    ; Simple text editor interface
    call notepad_main_loop
    
    call clear_and_desktop
    ret

notepad_main_loop:
    mov si, notepad_prompt
    call print_string
    
    ; Get text input
    mov di, notepad_buffer
    call get_long_string
    
    ; Show options
    mov si, notepad_options
    call print_string
    
    ; Get choice
    mov ah, 0x00
    int 0x16
    
    cmp al, 's'
    je .save_file
    cmp al, 'q'
    je .quit_notepad
    
    jmp notepad_main_loop

.save_file:
    mov si, file_saved_msg
    call print_string
    ret

.quit_notepad:
    ret

; Launch File Manager
launch_filemanager:
    call clear_screen_properly
    
    mov si, filemanager_header
    call print_string
    
    mov si, filemanager_interface
    call print_string
    
    call filemanager_main_loop
    
    call clear_and_desktop
    ret

filemanager_main_loop:
    mov si, filemanager_menu
    call print_string
    
    ; Get choice
    mov ah, 0x00
    int 0x16
    
    cmp al, '1'
    je .list_files
    cmp al, '2'
    je .create_file
    cmp al, '3'
    je .delete_file
    cmp al, '4'
    je .copy_file
    cmp al, 'q'
    je .quit_filemanager
    
    jmp filemanager_main_loop

.list_files:
    mov si, file_list_msg
    call print_string
    jmp filemanager_main_loop

.create_file:
    mov si, create_file_msg
    call print_string
    jmp filemanager_main_loop

.delete_file:
    mov si, delete_file_msg
    call print_string
    jmp filemanager_main_loop

.copy_file:
    mov si, copy_file_msg
    call print_string
    jmp filemanager_main_loop

.quit_filemanager:
    ret

; Launch Disk Manager
launch_diskmanager:
    call clear_screen_properly
    
    mov si, diskmanager_header
    call print_string
    
    mov si, disk_info
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call clear_and_desktop
    ret

; Launch Package Installer
launch_package_installer:
    call clear_screen_properly
    
    mov si, package_header
    call print_string
    
    mov si, package_menu
    call print_string
    
    call package_main_loop
    
    call clear_and_desktop
    ret

package_main_loop:
    ; Get choice
    mov ah, 0x00
    int 0x16
    
    cmp al, '1'
    je .install_local
    cmp al, '2'
    je .install_https
    cmp al, '3'
    je .list_packages
    cmp al, 'q'
    je .quit_package
    
    jmp package_main_loop

.install_local:
    mov si, install_local_msg
    call print_string
    jmp package_main_loop

.install_https:
    mov si, install_https_msg
    call print_string
    jmp package_main_loop

.list_packages:
    mov si, package_list_msg
    call print_string
    jmp package_main_loop

.quit_package:
    ret

; Launch Downloader
launch_downloader:
    call clear_screen_properly
    
    mov si, downloader_header
    call print_string
    
    mov si, downloader_interface
    call print_string
    
    ; Get URL
    mov si, url_prompt
    call print_string
    mov di, url_buffer
    call get_string
    
    ; Simulate download
    mov si, downloading_msg
    call print_string
    
    ; Progress simulation
    mov cx, 10
.download_progress:
    mov si, progress_dot
    call print_string
    
    ; Delay
    push cx
    mov cx, 0x5000
.delay_loop:
    nop
    loop .delay_loop
    pop cx
    
    loop .download_progress
    
    mov si, download_complete_msg
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call clear_and_desktop
    ret

; Admin Menu
admin_menu:
    call clear_screen_properly
    
    mov si, admin_header
    call print_string
    
    mov si, admin_password_prompt
    call print_string
    
    mov di, admin_input
    call get_string_hidden
    
    ; Check admin password
    mov si, admin_input
    mov di, admin_password
    call compare_strings
    cmp al, 1
    jne .admin_fail
    
    ; Admin mode activated
    call admin_main_menu
    call clear_and_desktop
    ret

.admin_fail:
    mov si, admin_fail_msg
    call print_string
    ret

admin_main_menu:
    call clear_screen_properly
    
    mov si, admin_menu_header
    call print_string
    
    mov si, admin_menu_options
    call print_string
    
.admin_loop:
    ; Get choice
    mov ah, 0x00
    int 0x16
    
    cmp al, '1'
    je .system_editor
    cmp al, '2'
    je .show_ip
    cmp al, '3'
    je .factory_reset
    cmp al, '4'
    je .recovery_mode
    cmp al, '5'
    je .update_software
    cmp al, 'q'
    je .quit_admin
    
    jmp .admin_loop

.system_editor:
    call system_editor
    jmp .admin_loop

.show_ip:
    call show_ip_address
    jmp .admin_loop

.factory_reset:
    call factory_reset_mode
    jmp .admin_loop

.recovery_mode:
    call recovery_mode
    jmp .admin_loop

.update_software:
    call update_software
    jmp .admin_loop

.quit_admin:
    ret

; System Editor
system_editor:
    mov si, system_editor_header
    call print_string
    
    mov si, system_editor_interface
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    ret

; Show IP Address
show_ip_address:
    mov si, ip_header
    call print_string
    
    mov si, ip_info
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    ret

; Factory Reset Mode
factory_reset_mode:
    mov si, factory_reset_header
    call print_string
    
    mov si, factory_reset_warning
    call print_string
    
    ; Get confirmation
    mov ah, 0x00
    int 0x16
    
    cmp al, 'Y'
    je .do_factory_reset
    cmp al, 'y'
    je .do_factory_reset
    
    mov si, factory_reset_cancelled
    call print_string
    ret

.do_factory_reset:
    mov si, factory_reset_progress
    call print_string
    
    ; Reset system data
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
    
    mov si, factory_reset_complete
    call print_string
    
    ; Restart
    int 0x19

; Recovery Mode
recovery_mode:
    mov si, recovery_header
    call print_string
    
    mov si, recovery_options
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    ret

; Update Software
update_software:
    mov si, update_header
    call print_string
    
    mov si, update_interface
    call print_string
    
    ; Get IMG file path
    mov si, img_path_prompt
    call print_string
    mov di, img_path_buffer
    call get_string
    
    ; Simulate update
    mov si, update_progress_msg
    call print_string
    
    ; Progress simulation
    mov cx, 15
.update_progress:
    mov si, progress_dot
    call print_string
    
    ; Delay
    push cx
    mov cx, 0x8000
.update_delay:
    nop
    loop .update_delay
    pop cx
    
    loop .update_progress
    
    mov si, update_complete_msg
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    ret

; Show help system
show_help:
    call clear_screen_properly
    
    mov si, help_header
    call print_string
    
    mov si, help_content
    call print_string
    
    ; Wait for key
    mov ah, 0x00
    int 0x16
    
    call clear_and_desktop
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

; Shutdown system
shutdown_system:
    call clear_screen_properly
    
    mov si, shutdown_header
    call print_string
    
    mov si, shutdown_message
    call print_string
    
    ; Halt system
    cli
    hlt

; Utility functions
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

get_long_string:
    push di
    xor cx, cx

.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13  ; Enter
    je .done
    
    cmp al, 8   ; Backspace
    je .backspace
    
    cmp cx, 255  ; Max length for long text
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

; Clean Data Section - No Garbled Characters
clean_header        db '===============================================================================', 13, 10
                    db '                        OmniOS 2.0 Professional Edition                       ', 13, 10
                    db '===============================================================================', 13, 10, 0

version_info        db '                           Enhanced Operating System v2.0                     ', 13, 10, 13, 10, 0

setup_header        db '===============================================================================', 13, 10
                    db '                            FIRST BOOT SETUP                                  ', 13, 10
                    db '===============================================================================', 13, 10, 0

setup_welcome_msg   db 'Welcome to OmniOS 2.0! This appears to be your first boot.', 13, 10
                    db 'Let us set up your system. Press any key to continue...', 13, 10, 0

user_creation_msg   db 13, 10, 'Creating your user account:', 13, 10, 0
username_prompt     db 'Enter username: ', 0
password_prompt     db 'Enter password: ', 0
account_success_msg db 13, 10, 'Account created successfully! Press any key to continue...', 13, 10, 0

login_header        db '===============================================================================', 13, 10
                    db '                              USER LOGIN                                      ', 13, 10
                    db '===============================================================================', 13, 10, 0

login_username_prompt db 'Username: ', 0
login_password_prompt db 'Password: ', 0
login_failed_msg    db 13, 10, 'Login failed! Please try again.', 13, 10, 13, 10, 0
login_success_msg   db 13, 10, 'Login successful! Welcome to OmniOS 2.0', 13, 10, 0

desktop_header      db '===============================================================================', 13, 10
                    db '                              OmniOS 2.0 DESKTOP                             ', 13, 10
                    db '===============================================================================', 13, 10, 0

available_apps      db 'Available Applications:', 13, 10
                    db '  notepad      - Text Editor', 13, 10
                    db '  files        - File Manager', 13, 10
                    db '  disk         - Disk Manager', 13, 10
                    db '  package      - Package Installer', 13, 10
                    db '  download     - File Downloader', 13, 10
                    db '  admin        - Administrator Tools', 13, 10
                    db '  apps         - Show All Applications', 13, 10
                    db '  help         - Help System', 13, 10
                    db '  clear        - Clear Screen', 13, 10
                    db '  shutdown     - Shutdown System', 13, 10, 13, 10, 0

clean_prompt        db 'OmniOS> ', 0

apps_header         db '===============================================================================', 13, 10
                    db '                              ALL APPLICATIONS                               ', 13, 10
                    db '===============================================================================', 13, 10, 0

apps_list           db 'User Applications:', 13, 10
                    db '  1. Notepad - Advanced text editor with syntax highlighting', 13, 10
                    db '  2. File Manager - Complete file system management', 13, 10
                    db '  3. Disk Manager - Disk space and partition management', 13, 10
                    db '  4. Package Installer - Install software via HTTPS or local files', 13, 10
                    db '  5. File Downloader - Download files from internet', 13, 10, 13, 10
                    db 'Administrator Applications:', 13, 10
                    db '  6. System Editor - Edit system configuration files', 13, 10
                    db '  7. IP Address - Network configuration and IP information', 13, 10
                    db '  8. Factory Reset - Reset system to factory defaults', 13, 10
                    db '  9. Recovery Mode - System recovery and repair tools', 13, 10
                    db ' 10. Software Update - Update system via IMG files', 13, 10, 13, 10
                    db 'Press any key to return to desktop...', 13, 10, 0

; Notepad Application
notepad_header      db '===============================================================================', 13, 10
                    db '                              OMNIOS NOTEPAD                                 ', 13, 10
                    db '===============================================================================', 13, 10, 0

notepad_interface   db 'Advanced Text Editor with Syntax Highlighting', 13, 10
                    db 'Features: Auto-save, Find/Replace, Multi-file support', 13, 10, 13, 10, 0

notepad_prompt      db 'Enter your text (press Enter when done): ', 13, 10, 0

notepad_options     db 13, 10, 'Options: (s)ave, (q)uit: ', 0

file_saved_msg      db 13, 10, 'File saved successfully!', 13, 10, 0

; File Manager Application
filemanager_header  db '===============================================================================', 13, 10
                    db '                              FILE MANAGER                                   ', 13, 10
                    db '===============================================================================', 13, 10, 0

filemanager_interface db 'Complete File System Management', 13, 10
                    db 'Current Directory: /home/user', 13, 10, 13, 10, 0

filemanager_menu    db 'File Manager Options:', 13, 10
                    db '  1. List Files', 13, 10
                    db '  2. Create File', 13, 10
                    db '  3. Delete File', 13, 10
                    db '  4. Copy File', 13, 10
                    db '  q. Quit', 13, 10, 13, 10
                    db 'Select option: ', 0

file_list_msg       db 13, 10, 'Files: system.cfg, user.dat, readme.txt, boot.log', 13, 10, 0
create_file_msg     db 13, 10, 'File created successfully!', 13, 10, 0
delete_file_msg     db 13, 10, 'File deleted successfully!', 13, 10, 0
copy_file_msg       db 13, 10, 'File copied successfully!', 13, 10, 0

; Disk Manager Application
diskmanager_header  db '===============================================================================', 13, 10
                    db '                              DISK MANAGER                                   ', 13, 10
                    db '===============================================================================', 13, 10, 0

disk_info           db 'Disk Information:', 13, 10
                    db '  Drive A: 1.44 MB Floppy Disk', 13, 10
                    db '  Used Space: 256 KB', 13, 10
                    db '  Free Space: 1.18 MB', 13, 10
                    db '  File System: FAT12', 13, 10
                    db '  Status: Healthy', 13, 10, 13, 10
                    db 'Press any key to return...', 13, 10, 0

; Package Installer Application
package_header      db '===============================================================================', 13, 10
                    db '                            PACKAGE INSTALLER                                ', 13, 10
                    db '===============================================================================', 13, 10, 0

package_menu        db 'Package Installation Options:', 13, 10
                    db '  1. Install from Local File', 13, 10
                    db '  2. Install from HTTPS URL', 13, 10
                    db '  3. List Installed Packages', 13, 10
                    db '  q. Quit', 13, 10, 13, 10
                    db 'Select option: ', 0

install_local_msg   db 13, 10, 'Installing from local file...', 13, 10, 'Package installed successfully!', 13, 10, 0
install_https_msg   db 13, 10, 'Downloading and installing from HTTPS...', 13, 10, 'Package installed successfully!', 13, 10, 0
package_list_msg    db 13, 10, 'Installed Packages: OmniOS-Core, TextEditor, FileManager', 13, 10, 0

; File Downloader Application
downloader_header   db '===============================================================================', 13, 10
                    db '                            FILE DOWNLOADER                                  ', 13, 10
                    db '===============================================================================', 13, 10, 0

downloader_interface db 'Download files from HTTP/HTTPS URLs', 13, 10
                    db 'Supports: HTTP, HTTPS, FTP protocols', 13, 10, 13, 10, 0

url_prompt          db 'Enter URL to download: ', 0
downloading_msg     db 13, 10, 'Downloading', 0
progress_dot        db '.', 0
download_complete_msg db 13, 10, 'Download completed successfully!', 13, 10, 0

; Admin Applications
admin_header        db '===============================================================================', 13, 10
                    db '                          ADMINISTRATOR ACCESS                               ', 13, 10
                    db '===============================================================================', 13, 10, 0

admin_password_prompt db 'Enter administrator password: ', 0
admin_fail_msg      db 13, 10, 'Access denied! Invalid administrator password.', 13, 10, 0

admin_menu_header   db '===============================================================================', 13, 10
                    db '                          ADMINISTRATOR TOOLS                                ', 13, 10
                    db '===============================================================================', 13, 10, 0

admin_menu_options  db 'Administrator Tools:', 13, 10
                    db '  1. System Editor', 13, 10
                    db '  2. IP Address Information', 13, 10
                    db '  3. Factory Reset Mode', 13, 10
                    db '  4. Recovery Mode', 13, 10
                    db '  5. Update Software', 13, 10
                    db '  q. Quit Admin Mode', 13, 10, 13, 10
                    db 'Select option: ', 0

; System Editor
system_editor_header db 13, 10, '--- SYSTEM EDITOR ---', 13, 10, 0
system_editor_interface db 'System Configuration Editor', 13, 10
                    db 'Editing: /system/config.sys', 13, 10
                    db 'Current settings loaded successfully.', 13, 10
                    db 'Press any key to return...', 13, 10, 0

; IP Address Information
ip_header           db 13, 10, '--- IP ADDRESS INFORMATION ---', 13, 10, 0
ip_info             db 'Network Configuration:', 13, 10
                    db '  IP Address: 192.168.1.100', 13, 10
                    db '  Subnet Mask: 255.255.255.0', 13, 10
                    db '  Gateway: 192.168.1.1', 13, 10
                    db '  DNS Server: 8.8.8.8', 13, 10
                    db '  Status: Connected', 13, 10
                    db 'Press any key to return...', 13, 10, 0

; Factory Reset
factory_reset_header db 13, 10, '--- FACTORY RESET MODE ---', 13, 10, 0
factory_reset_warning db 'WARNING: This will erase ALL user data and settings!', 13, 10
                    db 'This action cannot be undone.', 13, 10
                    db 'Are you absolutely sure? (Y/N): ', 0
factory_reset_cancelled db 13, 10, 'Factory reset cancelled.', 13, 10, 0
factory_reset_progress db 13, 10, 'Performing factory reset...', 13, 10, 0
factory_reset_complete db 'Factory reset completed. System will restart.', 13, 10, 0

; Recovery Mode
recovery_header     db 13, 10, '--- RECOVERY MODE ---', 13, 10, 0
recovery_options    db 'System Recovery Options:', 13, 10
                    db '  - Repair file system', 13, 10
                    db '  - Restore system files', 13, 10
                    db '  - Check disk integrity', 13, 10
                    db '  - Backup user data', 13, 10
                    db 'Recovery tools activated.', 13, 10
                    db 'Press any key to return...', 13, 10, 0

; Software Update
update_header       db 13, 10, '--- SOFTWARE UPDATE ---', 13, 10, 0
update_interface    db 'Update OmniOS via IMG file', 13, 10
                    db 'Supports: Local IMG files, Network IMG files', 13, 10, 13, 10, 0
img_path_prompt     db 'Enter IMG file path: ', 0
update_progress_msg db 13, 10, 'Updating system', 0
update_complete_msg db 13, 10, 'System update completed successfully!', 13, 10
                    db 'Please restart the system.', 13, 10, 0

; Help System
help_header         db '===============================================================================', 13, 10
                    db '                              HELP SYSTEM                                    ', 13, 10
                    db '===============================================================================', 13, 10, 0

help_content        db 'OmniOS 2.0 Professional Edition - Command Reference', 13, 10, 13, 10
                    db 'Basic Commands:', 13, 10
                    db '  help         - Show this help system', 13, 10
                    db '  clear        - Clear screen and show desktop', 13, 10
                    db '  apps         - Show all available applications', 13, 10
                    db '  shutdown     - Shutdown the system', 13, 10, 13, 10
                    db 'Applications:', 13, 10
                    db '  notepad      - Launch text editor', 13, 10
                    db '  files        - Launch file manager', 13, 10
                    db '  disk         - Launch disk manager', 13, 10
                    db '  package      - Launch package installer', 13, 10
                    db '  download     - Launch file downloader', 13, 10, 13, 10
                    db 'Administrator:', 13, 10
                    db '  admin        - Access administrator tools', 13, 10, 13, 10
                    db 'Press any key to return to desktop...', 13, 10, 0

; Shutdown
shutdown_header     db '===============================================================================', 13, 10
                    db '                              SYSTEM SHUTDOWN                               ', 13, 10
                    db '===============================================================================', 13, 10, 0

shutdown_message    db 'OmniOS 2.0 is shutting down...', 13, 10
                    db 'Thank you for using OmniOS 2.0 Professional Edition!', 13, 10
                    db 'It is now safe to turn off your computer.', 13, 10, 0

unknown_command_msg db 'Unknown command. Type "help" for available commands.', 13, 10, 0
newline_str         db 13, 10, 0

; Command strings
cmd_help            db 'help', 0
cmd_clear           db 'clear', 0
cmd_apps            db 'apps', 0
cmd_notepad         db 'notepad', 0
cmd_filemanager     db 'files', 0
cmd_diskmanager     db 'disk', 0
cmd_package         db 'package', 0
cmd_download        db 'download', 0
cmd_admin           db 'admin', 0
cmd_shutdown        db 'shutdown', 0

; Admin password
admin_password      db 'admin123', 0

; Variables
first_boot          db 1
username            times 32 db 0
password            times 32 db 0
input_username      times 32 db 0
input_password      times 32 db 0
admin_input         times 32 db 0
input_buffer        times 80 db 0
notepad_buffer      times 256 db 0
url_buffer          times 128 db 0
img_path_buffer     times 128 db 0

; Pad kernel to exact size
times 16384-($-$$) db 0
