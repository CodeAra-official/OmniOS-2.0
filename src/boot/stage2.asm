; OmniOS 2.0 Stage 2 Bootloader
; Loads and initializes the kernel
; Sets up protected mode and memory management

[BITS 16]
[ORG 0x0000]

; Stage 2 signature
dw 0x5432

stage2_start:
    ; Set up segments
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    
    ; Display stage 2 message
    mov si, stage2_message
    call print_string
    
    ; Enable A20 line
    call enable_a20
    
    ; Load kernel from disk
    call load_kernel
    
    ; Set up GDT (Global Descriptor Table)
    call setup_gdt
    
    ; Switch to protected mode
    call enter_protected_mode
    
    ; Jump to kernel (never returns)
    jmp 0x08:kernel_entry_point

; Print string function (16-bit mode)
print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

; Enable A20 line for access to extended memory
enable_a20:
    pusha
    
    ; Method 1: BIOS interrupt
    mov ax, 0x2401
    int 0x15
    jnc .a20_enabled
    
    ; Method 2: Keyboard controller
    call wait_8042
    mov al, 0xAD
    out 0x64, al        ; Disable keyboard
    
    call wait_8042
    mov al, 0xD0
    out 0x64, al        ; Read output port
    
    call wait_8042_data
    in al, 0x60
    push ax
    
    call wait_8042
    mov al, 0xD1
    out 0x64, al        ; Write output port
    
    call wait_8042
    pop ax
    or al, 2            ; Set A20 bit
    out 0x60, al
    
    call wait_8042
    mov al, 0xAE
    out 0x64, al        ; Enable keyboard
    
.a20_enabled:
    popa
    ret

wait_8042:
    in al, 0x64
    test al, 2
    jnz wait_8042
    ret

wait_8042_data:
    in al, 0x64
    test al, 1
    jz wait_8042_data
    ret

; Load kernel from disk
load_kernel:
    pusha
    
    mov si, kernel_loading_message
    call print_string
    
    ; Load kernel (sectors 6-50, ~22KB)
    mov ah, 0x02           ; Read sectors
    mov al, 45             ; Number of sectors
    mov ch, 0              ; Cylinder 0
    mov cl, 6              ; Start sector
    mov dh, 0              ; Head 0
    mov dl, [0x7C00 + boot_drive_offset]  ; Boot drive
    mov bx, 0x2000         ; Load to 0x2000:0x0000
    mov es, bx
    mov bx, 0x0000
    int 0x13
    jc kernel_load_error
    
    ; Verify kernel signature
    mov ax, 0x2000
    mov es, ax
    cmp dword [es:0x0000], 0x4E524B4F  ; "OKRN" signature
    jne kernel_signature_error
    
    popa
    ret

kernel_load_error:
    mov si, kernel_error_message
    call print_string
    jmp halt

kernel_signature_error:
    mov si, kernel_sig_error_message
    call print_string
    jmp halt

; Set up Global Descriptor Table
setup_gdt:
    lgdt [gdt_descriptor]
    ret

; Enter protected mode
enter_protected_mode:
    cli                    ; Disable interrupts
    mov eax, cr0
    or eax, 1              ; Set PE bit
    mov cr0, eax
    
    ; Far jump to flush pipeline and load CS
    jmp 0x08:protected_mode_start

[BITS 32]
protected_mode_start:
    ; Set up data segments
    mov ax, 0x10           ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack
    mov esp, 0x90000
    
    ; Jump to kernel
    mov eax, 0x20000       ; Kernel load address
    jmp eax

[BITS 16]
halt:
    cli
    hlt
    jmp $

; Global Descriptor Table
gdt_start:
    ; Null descriptor
    dd 0x00000000
    dd 0x00000000
    
    ; Code segment descriptor
    dw 0xFFFF              ; Limit (low)
    dw 0x0000              ; Base (low)
    db 0x00                ; Base (middle)
    db 10011010b           ; Access byte
    db 11001111b           ; Granularity
    db 0x00                ; Base (high)
    
    ; Data segment descriptor
    dw 0xFFFF              ; Limit (low)
    dw 0x0000              ; Base (low)
    db 0x00                ; Base (middle)
    db 10010010b           ; Access byte
    db 11001111b           ; Granularity
    db 0x00                ; Base (high)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size
    dd gdt_start                ; Offset

; Data section
stage2_message          db 'Stage 2 Bootloader Loaded', 0x0D, 0x0A, 0
kernel_loading_message  db 'Loading Kernel...', 0x0D, 0x0A, 0
kernel_error_message    db 'Kernel Load Error!', 0x0D, 0x0A, 0
kernel_sig_error_message db 'Invalid Kernel Signature!', 0x0D, 0x0A, 0

boot_drive_offset       equ 0x1BE  ; Offset to boot drive in MBR

kernel_entry_point      equ 0x20000

; Pad stage 2 to exactly 2KB
times 2048-($-$$) db 0
