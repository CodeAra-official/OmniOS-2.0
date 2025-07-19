; OmniOS 2.0 Enhanced Notepad Application
[BITS 16]

notepad_application:
    call init_notepad
    call notepad_main_loop
    ret

init_notepad:
    call clear_screen_color
    call draw_notepad_window
    call draw_notepad_menu
    call init_text_buffer
    ret

draw_notepad_window:
    ; Main notepad window
    mov dh, 1   ; Top
    mov dl, 1   ; Left
    mov ch, 23  ; Height
    mov cl, 78  ; Width
    mov bl, [color_scheme]  ; Normal color
    call draw_window
    
    ; Title bar
    mov ah, 0x02
    mov bh, 0
    mov dh, 1
    mov dl, 30
    int 0x10
    
    mov si, notepad_title
    mov bl, [color_scheme+7]
    call print_colored
    
    ret

draw_notepad_menu:
    ; Menu bar
    mov ah, 0x06
    mov al, 0
    mov bh, [color_scheme+6]  ; Menu color
    mov ch, 2
    mov cl, 2
    mov dh, 2
    mov dl, 77
    int 0x10
    
    ; Menu items
    mov ah, 0x02
    mov bh, 0
    mov dh, 2
    mov dl, 3
    int 0x10
    
    mov si, notepad_menu
    mov bl, [color_scheme+6]
    call print_colored
    
    ret

init_text_buffer:
    ; Initialize text editing area
    mov di, notepad_buffer
    mov cx, 8192
    mov al, 0
    rep stosb
    
    ; Set cursor in text area
    mov ah, 0x02
    mov bh, 0
    mov dh, 4   ; Text starts at row 4
    mov dl, 3   ; Column 3
    int 0x10
    
    ; Show cursor
    mov ah, 0x01
    mov cx, 0x0607  ; Normal cursor
    int 0x10
    
    mov word [cursor_row], 4
    mov word [cursor_col], 3
    mov word [text_length], 0
    
    ret

notepad_main_loop:
    .main_loop:
        call handle_notepad_input
        call update_status_line
        
        ; Check for exit condition
        cmp byte [notepad_exit], 1
        jne .main_loop
    ret

handle_notepad_input:
    ; Check for keyboard input
    mov ah, 0x01
    int 0x16
    jz .no_input
    
    ; Get the key
    mov ah, 0x00
    int 0x16
    
    ; Check for special keys
    cmp al, 0
    je .extended_key
    
    ; Regular character input
    call process_character_input
    jmp .input_done
    
    .extended_key:
        call process_extended_key
    
    .input_done:
    .no_input:
        ret

process_character_input:
    ; AL contains the character
    cmp al, 27  ; ESC
    je .exit_notepad
    
    cmp al, 13  ; Enter
    je .handle_enter
    
    cmp al, 8   ; Backspace
    je .handle_backspace
    
    cmp al, 9   ; Tab
    je .handle_tab
    
    ; Regular printable character
    cmp al, 32
    jl .ignore_char
    cmp al, 126
    jg .ignore_char
    
    call insert_character
    jmp .char_done
    
    .handle_enter:
        call insert_newline
        jmp .char_done
    
    .handle_backspace:
        call delete_character
        jmp .char_done
    
    .handle_tab:
        ; Insert 4 spaces for tab
        mov al, ' '
        call insert_character
        call insert_character
        call insert_character
        call insert_character
        jmp .char_done
    
    .exit_notepad:
        call confirm_exit
        jmp .char_done
    
    .ignore_char:
    .char_done:
        ret

process_extended_key:
    ; AH contains scan code
    cmp ah, 0x48  ; Up arrow
    je .move_up
    
    cmp ah, 0x50  ; Down arrow
    je .move_down
    
    cmp ah, 0x4B  ; Left arrow
    je .move_left
    
    cmp ah, 0x4D  ; Right arrow
    je .move_right
    
    cmp ah, 0x47  ; Home
    je .move_home
    
    cmp ah, 0x4F  ; End
    je .move_end
    
    cmp ah, 0x3B  ; F1 - Save
    je .save_file
    
    cmp ah, 0x3C  ; F2 - Open
    je .open_file
    
    cmp ah, 0x3D  ; F3 - New
    je .new_file
    
    ret
    
    .move_up:
        call cursor_up
        ret
    
    .move_down:
        call cursor_down
        ret
    
    .move_left:
        call cursor_left
        ret
    
    .move_right:
        call cursor_right
        ret
    
    .move_home:
        call cursor_home
        ret
    
    .move_end:
        call cursor_end
        ret
    
    .save_file:
        call save_current_file
        ret
    
    .open_file:
        call open_file_dialog
        ret
    
    .new_file:
        call new_file_dialog
        ret

insert_character:
    ; Insert character at current cursor position
    push ax
    push bx
    push cx
    push di
    push si
    
    ; Check if buffer is full
    cmp word [text_length], 8190
    jae .buffer_full
    
    ; Calculate insertion point
    call get_cursor_buffer_position
    mov di, bx
    
    ; Shift text right to make space
    mov si, notepad_buffer
    add si, [text_length]
    mov cx, [text_length]
    sub cx, bx
    inc cx
    
    std  ; Set direction flag for backward copy
    add di, cx
    .shift_loop:
        movsb
        loop .shift_loop
    cld  ; Clear direction flag
    
    ; Insert the character
    mov [bx], al
    inc word [text_length]
    
    ; Display the character
    mov ah, 0x0E
    int 0x10
    
    ; Update cursor position
    call advance_cursor
    
    .buffer_full:
        pop si
        pop di
        pop cx
        pop bx
        pop ax
        ret

insert_newline:
    ; Insert newline and move cursor
    mov al, 13
    call insert_character
    mov al, 10
    call insert_character
    
    ; Move cursor to beginning of next line
    mov ah, 0x02
    mov bh, 0
    inc word [cursor_row]
    mov word [cursor_col], 3
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    
    ret

delete_character:
    ; Delete character before cursor
    cmp word [text_length], 0
    je .nothing_to_delete
    
    ; Get current position
    call get_cursor_buffer_position
    cmp bx, 0
    je .nothing_to_delete
    
    ; Shift text left
    mov si, bx
    mov di, bx
    dec di
    mov cx, [text_length]
    sub cx, bx
    rep movsb
    
    dec word [text_length]
    
    ; Move cursor back
    call retreat_cursor
    
    ; Redraw line
    call redraw_current_line
    
    .nothing_to_delete:
        ret

cursor_up:
    cmp word [cursor_row], 4
    jle .at_top
    
    dec word [cursor_row]
    mov ah, 0x02
    mov bh, 0
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    
    .at_top:
        ret

cursor_down:
    cmp word [cursor_row], 22
    jge .at_bottom
    
    inc word [cursor_row]
    mov ah, 0x02
    mov bh, 0
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    
    .at_bottom:
        ret

cursor_left:
    cmp word [cursor_col], 3
    jle .at_left_edge
    
    dec word [cursor_col]
    mov ah, 0x02
    mov bh, 0
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    
    .at_left_edge:
        ret

cursor_right:
    cmp word [cursor_col], 76
    jge .at_right_edge
    
    inc word [cursor_col]
    mov ah, 0x02
    mov bh, 0
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    
    .at_right_edge:
        ret

cursor_home:
    mov word [cursor_col], 3
    mov ah, 0x02
    mov bh, 0
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    ret

cursor_end:
    ; Find end of current line
    call find_line_end
    mov ah, 0x02
    mov bh, 0
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    ret

advance_cursor:
    inc word [cursor_col]
    cmp word [cursor_col], 77
    jl .cursor_ok
    
    ; Wrap to next line
    mov word [cursor_col], 3
    inc word [cursor_row]
    cmp word [cursor_row], 23
    jl .cursor_ok
    
    ; Scroll up
    call scroll_text_up
    dec word [cursor_row]
    
    .cursor_ok:
        ret

retreat_cursor:
    dec word [cursor_col]
    cmp word [cursor_col], 2
    jg .cursor_ok
    
    ; Wrap to previous line end
    cmp word [cursor_row], 4
    jle .at_top
    
    dec word [cursor_row]
    mov word [cursor_col], 76
    
    .at_top:
    .cursor_ok:
        ret

get_cursor_buffer_position:
    ; Calculate buffer position from cursor position
    ; Returns position in BX
    mov bx, 0
    ; (Implementation would calculate actual buffer position)
    ret

find_line_end:
    ; Find the end of the current line
    ; Updates cursor_col to line end position
    ; (Implementation would scan for newline or end of text)
    ret

redraw_current_line:
    ; Redraw the current line after deletion
    ; (Implementation would redraw the line from buffer)
    ret

scroll_text_up:
    ; Scroll text area up one line
    mov ah, 0x06
    mov al, 1
    mov bh, [color_scheme]
    mov ch, 4   ; Text area top
    mov cl, 3   ; Text area left
    mov dh, 22  ; Text area bottom
    mov dl, 76  ; Text area right
    int 0x10
    ret

save_current_file:
    ; Save file dialog and save operation
    call show_save_dialog
    ; (File save implementation would go here)
    ret

open_file_dialog:
    ; Open file dialog
    call show_open_dialog
    ; (File open implementation would go here)
    ret

new_file_dialog:
    ; New file - clear current buffer
    call confirm_new_file
    ; (Clear buffer implementation would go here)
    ret

show_save_dialog:
    ; Simple save dialog
    mov dh, 10
    mov dl, 20
    mov ch, 5
    mov cl, 40
    mov bl, [color_scheme+6]
    call draw_window
    
    mov ah, 0x02
    mov bh, 0
    mov dh, 11
    mov dl, 25
    int 0x10
    
    mov si, save_dialog_msg
    call print_colored
    
    ; Get filename input
    call get_filename_input
    ret

show_open_dialog:
    ; Simple open dialog
    mov dh, 10
    mov dl, 20
    mov ch, 5
    mov cl, 40
    mov bl, [color_scheme+6]
    call draw_window
    
    mov ah, 0x02
    mov bh, 0
    mov dh, 11
    mov dl, 25
    int 0x10
    
    mov si, open_dialog_msg
    call print_colored
    
    call get_filename_input
    ret

get_filename_input:
    ; Simple filename input
    mov di, filename_buffer
    mov cx, 0
    
    .input_loop:
        mov ah, 0x00
        int 0x16
        
        cmp al, 13
        je .input_done
        
        cmp al, 27
        je .input_cancel
        
        cmp al, 8
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
        stosb
        ret
    
    .input_cancel:
        ret

confirm_exit:
    ; Exit confirmation dialog
    mov si, exit_confirm_msg
    call show_confirmation
    cmp al, 'y'
    je .do_exit
    cmp al, 'Y'
    je .do_exit
    ret
    
    .do_exit:
        mov byte [notepad_exit], 1
        ret

confirm_new_file:
    ; New file confirmation
    mov si, new_confirm_msg
    call show_confirmation
    cmp al, 'y'
    je .do_new
    cmp al, 'Y'
    je .do_new
    ret
    
    .do_new:
        call init_text_buffer
        ret

show_confirmation:
    ; Show confirmation dialog
    ; SI = message
    mov dh, 12
    mov dl, 25
    mov ch, 3
    mov cl, 30
    mov bl, [color_scheme+4]  ; Warning color
    call draw_window
    
    mov ah, 0x02
    mov bh, 0
    mov dh, 13
    mov dl, 27
    int 0x10
    
    call print_colored
    
    ; Wait for y/n response
    mov ah, 0x00
    int 0x16
    ret

update_status_line:
    ; Update status line with cursor position and file info
    mov ah, 0x06
    mov al, 0
    mov bh, [color_scheme+5]
    mov ch, 23
    mov cl, 2
    mov dh, 23
    mov dl, 77
    int 0x10
    
    ; Show cursor position
    mov ah, 0x02
    mov bh, 0
    mov dh, 23
    mov dl, 3
    int 0x10
    
    mov si, status_line_text
    mov bl, [color_scheme+5]
    call print_colored
    
    ret

; Notepad Data
notepad_title db 'OmniOS Notepad - Enhanced Text Editor', 0
notepad_menu db 'F1:Save F2:Open F3:New F4:Help ESC:Exit', 0
save_dialog_msg db 'Enter filename to save:', 0
open_dialog_msg db 'Enter filename to open:', 0
exit_confirm_msg db 'Exit without saving? (y/n)', 0
new_confirm_msg db 'Create new file? (y/n)', 0
status_line_text db 'Row:   Col:   Chars:     F1:Help', 0

; Notepad Variables
cursor_row dw 4
cursor_col dw 3
text_length dw 0
notepad_exit db 0
filename_buffer resb 32
