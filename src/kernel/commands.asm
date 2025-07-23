; OmniOS 2.0 Command Processing
; Enhanced command system with new commands

; Command processing is handled in main kernel file
; This file contains additional command utilities

parse_arguments:
    ; Parse command arguments
    ; SI = command buffer
    ; Returns: DI = first argument
    
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

get_argument:
    ; Get specific argument number
    ; AL = argument number (0-based)
    ; Returns: DI = argument pointer
    
    mov si, command_buffer
    mov cl, al
    
    ; Skip command name
.skip_command:
    lodsb
    cmp al, 0
    je .not_found
    cmp al, ' '
    jne .skip_command
    
    ; Skip arguments until we reach the desired one
.find_arg:
    cmp cl, 0
    je .found_arg
    
    ; Skip spaces
.skip_spaces:
    lodsb
    cmp al, 0
    je .not_found
    cmp al, ' '
    je .skip_spaces
    
    ; Skip current argument
.skip_arg:
    lodsb
    cmp al, 0
    je .not_found
    cmp al, ' '
    jne .skip_arg
    
    dec cl
    jmp .find_arg

.found_arg:
    ; Skip spaces before argument
.skip_spaces2:
    lodsb
    cmp al, 0
    je .not_found
    cmp al, ' '
    je .skip_spaces2
    
    dec si
    mov di, si
    ret

.not_found:
    mov di, 0
    ret
