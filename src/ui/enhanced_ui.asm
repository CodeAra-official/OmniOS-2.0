; Enhanced UI System for OmniOS 2.0
[BITS 16]

; Color definitions
COLOR_BLACK     equ 0x00
COLOR_BLUE      equ 0x01
COLOR_GREEN     equ 0x02
COLOR_CYAN      equ 0x03
COLOR_RED       equ 0x04
COLOR_MAGENTA   equ 0x05
COLOR_BROWN     equ 0x06
COLOR_LGRAY     equ 0x07
COLOR_DGRAY     equ 0x08
COLOR_LBLUE     equ 0x09
COLOR_LGREEN    equ 0x0A
COLOR_LCYAN     equ 0x0B
COLOR_LRED      equ 0x0C
COLOR_LMAGENTA  equ 0x0D
COLOR_YELLOW    equ 0x0E
COLOR_WHITE     equ 0x0F

init_ui:
    ; Set 80x25 color text mode
    mov ax, 0x0003
    int 0x10
    
    ; Hide cursor initially
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10
    
    ret

clear_screen_color:
    ; Clear screen with current color scheme
    mov ah, 0x06
    mov al, 0        ; Clear entire screen
    mov bh, [color_scheme]  ; Background color
    mov ch, 0        ; Top row
    mov cl, 0        ; Left column
    mov dh, 24       ; Bottom row
    mov dl, 79       ; Right column
    int 0x10
    ret

print_colored:
    ; Print string with color
    ; SI = string pointer, BL = color attribute
    push ax
    push bx
    push cx
    push dx
    
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
        pop dx
        pop cx
        pop bx
        pop ax
        ret

draw_window:
    ; Draw a window with border
    ; DH=top, DL=left, CH=height, CL=width, BL=color
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Save window parameters
    mov [window_top], dh
    mov [window_left], dl
    mov [window_height], ch
    mov [window_width], cl
    mov [window_color], bl
    
    ; Draw top border
    call draw_top_border
    
    ; Draw side borders and fill
    call draw_window_body
    
    ; Draw bottom border
    call draw_bottom_border
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_top_border:
    ; Position cursor at top-left
    mov ah, 0x02
    mov bh, 0
    mov dh, [window_top]
    mov dl, [window_left]
    int 0x10
    
    ; Draw top-left corner
    mov ah, 0x09
    mov al, 0xDA  ; ┌
    mov bh, 0
    mov bl, [window_color]
    mov cx, 1
    int 0x10
    
    ; Draw top horizontal line
    mov cl, [window_width]
    sub cl, 2
    .top_line:
        ; Move cursor right
        mov ah, 0x03
        int 0x10
        inc dl
        mov ah, 0x02
        int 0x10
        
        ; Draw horizontal line
        mov ah, 0x09
        mov al, 0xC4  ; ─
        mov cx, 1
        int 0x10
        
        dec cl
        jnz .top_line
    
    ; Draw top-right corner
    mov ah, 0x03
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    
    mov ah, 0x09
    mov al, 0xBF  ; ┐
    mov cx, 1
    int 0x10
    
    ret

draw_window_body:
    mov ch, [window_height]
    sub ch, 2
    mov dh, [window_top]
    inc dh
    
    .body_loop:
        ; Position at left edge
        mov ah, 0x02
        mov bh, 0
        mov dl, [window_left]
        int 0x10
        
        ; Draw left border
        mov ah, 0x09
        mov al, 0xB3  ; │
        mov bh, 0
        mov bl, [window_color]
        mov cx, 1
        int 0x10
        
        ; Fill interior
        mov cl, [window_width]
        sub cl, 2
        .fill_line:
            mov ah, 0x03
            int 0x10
            inc dl
            mov ah, 0x02
            int 0x10
            
            mov ah, 0x09
            mov al, ' '
            mov cx, 1
            int 0x10
            
            dec cl
            jnz .fill_line
        
        ; Draw right border
        mov ah, 0x03
        int 0x10
        inc dl
        mov ah, 0x02
        int 0x10
        
        mov ah, 0x09
        mov al, 0xB3  ; │
        mov cx, 1
        int 0x10
        
        inc dh
        dec ch
        jnz .body_loop
    
    ret

draw_bottom_border:
    ; Position cursor at bottom-left
    mov ah, 0x02
    mov bh, 0
    mov dh, [window_top]
    add dh, [window_height]
    dec dh
    mov dl, [window_left]
    int 0x10
    
    ; Draw bottom-left corner
    mov ah, 0x09
    mov al, 0xC0  ; └
    mov bh, 0
    mov bl, [window_color]
    mov cx, 1
    int 0x10
    
    ; Draw bottom horizontal line
    mov cl, [window_width]
    sub cl, 2
    .bottom_line:
        mov ah, 0x03
        int 0x10
        inc dl
        mov ah, 0x02
        int 0x10
        
        mov ah, 0x09
        mov al, 0xC4  ; ─
        mov cx, 1
        int 0x10
        
        dec cl
        jnz .bottom_line
    
    ; Draw bottom-right corner
    mov ah, 0x03
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    
    mov ah, 0x09
    mov al, 0xD9  ; ┘
    mov cx, 1
    int 0x10
    
    ret

draw_desktop:
    ; Draw desktop background with pattern
    call clear_screen_color
    
    ; Draw desktop title bar
    mov ah, 0x06
    mov al, 0
    mov bh, [color_scheme+1]  ; Title bar color
    mov ch, 0
    mov cl, 0
    mov dh, 0
    mov dl, 79
    int 0x10
    
    ; Desktop title
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 2
    int 0x10
    
    mov si, desktop_title
    mov bl, [color_scheme+1]
    call print_colored
    
    ; Clock area
    mov ah, 0x02
    mov dh, 0
    mov dl, 65
    int 0x10
    
    mov si, clock_display
    call print_colored
    
    ret

draw_taskbar:
    ; Draw taskbar at bottom
    mov ah, 0x06
    mov al, 0
    mov bh, [color_scheme+5]  ; Taskbar color
    mov ch, 24
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    
    ; Start button
    mov ah, 0x02
    mov bh, 0
    mov dh, 24
    mov dl, 2
    int 0x10
    
    mov si, start_button_text
    mov bl, [color_scheme+7]
    call print_colored
    
    ret

draw_menu_bar:
    ; Application shortcuts
    mov ah, 0x02
    mov bh, 0
    mov dh, 24
    mov dl, 15
    int 0x10
    
    mov si, quick_apps_text
    mov bl, [color_scheme+5]
    call print_colored
    
    ret

show_loading_progress:
    ; Progress bar at bottom of splash
    mov ah, 0x02
    mov bh, 0
    mov dh, 20
    mov dl, 25
    int 0x10
    
    mov si, loading_text
    call print_colored
    
    ; Animated progress bar
    mov cx, 30  ; Progress bar width
    mov dl, 25
    inc dh
    
    .progress_loop:
        mov ah, 0x02
        mov bh, 0
        int 0x10
        
        mov ah, 0x09
        mov al, 0xDB  ; █
        mov bh, 0
        mov bl, [color_scheme+2]  ; Green
        push cx
        mov cx, 1
        int 0x10
        pop cx
        
        inc dl
        
        ; Small delay
        push ax
        push cx
        push dx
        mov cx, 0
        mov dx, 5000
        mov ah, 0x86
        int 0x15
        pop dx
        pop cx
        pop ax
        
        loop .progress_loop
    
    ret

handle_input:
    ; Check for keyboard input
    mov ah, 0x01
    int 0x16
    jz .no_input
    
    ; Get the key
    mov ah, 0x00
    int 0x16
    
    ; Process key
    call process_keyboard_input
    
    .no_input:
        ret

process_keyboard_input:
    ; AL = ASCII code, AH = scan code
    cmp al, 27  ; ESC key
    je show_main_menu
    
    cmp ah, 0x3B  ; F1
    je .f1_pressed
    
    cmp ah, 0x3C  ; F2
    je .f2_pressed
    
    ; Add more key handlers
    ret
    
    .f1_pressed:
        mov al, 1  ; Setup app
        call launch_application
        ret
    
    .f2_pressed:
        mov al, 2  ; Notepad app
        call launch_application
        ret

show_main_menu:
    ; Draw application menu
    mov dh, 5   ; Top
    mov dl, 20  ; Left
    mov ch, 15  ; Height
    mov cl, 35  ; Width
    mov bl, [color_scheme+6]  ; Menu color
    call draw_window
    
    ; Menu title
    mov ah, 0x02
    mov bh, 0
    mov dh, 6
    mov dl, 32
    int 0x10
    
    mov si, main_menu_title
    mov bl, [color_scheme+7]
    call print_colored
    
    ; Menu items
    call draw_menu_items
    
    ret

draw_menu_items:
    mov si, app_menu_items
    mov dh, 8  ; Start row
    mov dl, 22 ; Start column
    mov cl, 1  ; Item counter
    
    .menu_loop:
        lodsb
        cmp al, 0
        je .menu_done
        
        ; Position cursor
        mov ah, 0x02
        mov bh, 0
        int 0x10
        
        ; Print item number
        mov ah, 0x09
        mov al, cl
        add al, '0'
        mov bh, 0
        mov bl, [color_scheme+7]
        push cx
        mov cx, 1
        int 0x10
        pop cx
        
        ; Print ". "
        mov ah, 0x03
        int 0x10
        inc dl
        mov ah, 0x02
        int 0x10
        
        mov ah, 0x09
        mov al, '.'
        push cx
        mov cx, 1
        int 0x10
        pop cx
        
        mov ah, 0x03
        int 0x10
        inc dl
        mov ah, 0x02
        int 0x10
        
        mov ah, 0x09
        mov al, ' '
        push cx
        mov cx, 1
        int 0x10
        pop cx
        
        ; Print menu item
        dec si  ; Back up to start of string
        push cx
        push dx
        mov bl, [color_scheme]
        call print_colored
        pop dx
        pop cx
        
        ; Skip to next string
        .skip_string:
            lodsb
            cmp al, 0
            jne .skip_string
        
        inc dh  ; Next row
        inc cl  ; Next item number
        jmp .menu_loop
    
    .menu_done:
        ret

update_display:
    ; Update clock
    call update_clock_display
    
    ; Update any active windows
    ; (Window update logic would go here)
    
    ret

update_clock_display:
    ; Get system time
    mov ah, 0x02
    int 0x1A
    
    ; Format and display time
    ; (Time formatting logic would go here)
    
    ret

process_timers:
    ; Handle any system timers
    ; (Timer processing logic would go here)
    ret

file_exists:
    ; Check if file exists
    ; SI = filename
    ; Returns: AL = 1 if exists, 0 if not
    
    ; Simplified file existence check
    mov al, 0  ; Assume file doesn't exist for now
    ret

save_configuration:
    ; Save current system configuration
    ret

; UI Data
window_top db 0
window_left db 0
window_height db 0
window_width db 0
window_color db 0

desktop_title db 'OmniOS 2.0 Desktop', 0
clock_display db '12:00:00', 0
start_button_text db 'Start', 0
quick_apps_text db 'F1:Setup F2:Notepad F3:Files F4:Settings', 0
loading_text db 'Loading OmniOS 2.0...', 0
main_menu_title db 'Applications', 0
