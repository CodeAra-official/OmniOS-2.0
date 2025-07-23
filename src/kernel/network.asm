; OmniOS 2.0 Network Functions
; Basic network operations

network_init:
    ; Initialize network subsystem
    push ax
    push si
    
    mov si, network_init_msg
    call print_string
    
    pop si
    pop ax
    ret

network_send:
    ; Send network packet
    ; SI = data to send
    push ax
    push si
    
    mov si, network_send_msg
    call print_string
    
    pop si
    pop ax
    ret

; Network data
network_init_msg db 'Network initialized.', 13, 10, 0
network_send_msg db 'Network packet sent.', 13, 10, 0
