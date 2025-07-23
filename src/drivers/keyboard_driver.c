/*
 * OmniOS 2.0 Keyboard Driver
 * Enhanced keyboard input handling
 */

#include "version.h"
#include "colors.h"

// Keyboard state
typedef struct {
    unsigned char shift_pressed;
    unsigned char ctrl_pressed;
    unsigned char alt_pressed;
    unsigned char caps_lock;
    unsigned char num_lock;
    unsigned char scroll_lock;
} keyboard_state_t;

static keyboard_state_t kbd_state;

// Key mapping tables
static char normal_keys[128] = {
    0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
    0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`',
    0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0,
    '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '0', '.'
};

static char shift_keys[128] = {
    0, 27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
    '\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n',
    0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~',
    0, '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0,
    '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    '7', '8', '9', '-', '4', '5', '6', '+', '1', '2', '3', '0', '.'
};

// Function prototypes
void keyboard_driver_init(void);
unsigned char keyboard_get_scancode(void);
char keyboard_scancode_to_ascii(unsigned char scancode);
int keyboard_handle_special_keys(unsigned char scancode);
void keyboard_update_leds(void);

/*
 * Initialize keyboard driver
 */
void keyboard_driver_init(void) {
    // Clear keyboard state
    kbd_state.shift_pressed = 0;
    kbd_state.ctrl_pressed = 0;
    kbd_state.alt_pressed = 0;
    kbd_state.caps_lock = 0;
    kbd_state.num_lock = 1; // Num lock on by default
    kbd_state.scroll_lock = 0;
    
    // Update keyboard LEDs
    keyboard_update_leds();
    
    print_colored("Keyboard driver initialized", UI_SUCCESS);
}

/*
 * Get raw scancode from keyboard
 */
unsigned char keyboard_get_scancode(void) {
    unsigned char scancode;
    
    // Wait for keyboard input
    __asm__ volatile (
        "mov $0x00, %%ah\n\t"
        "int $0x16\n\t"
        "mov %%ah, %0"
        : "=r" (scancode)
        :
        : "ax"
    );
    
    return scancode;
}

/*
 * Convert scancode to ASCII character
 */
char keyboard_scancode_to_ascii(unsigned char scancode) {
    // Handle key release (bit 7 set)
    if (scancode & 0x80) {
        scancode &= 0x7F; // Clear release bit
        
        // Handle modifier key releases
        switch (scancode) {
            case 0x2A: // Left Shift
            case 0x36: // Right Shift
                kbd_state.shift_pressed = 0;
                break;
            case 0x1D: // Ctrl
                kbd_state.ctrl_pressed = 0;
                break;
            case 0x38: // Alt
                kbd_state.alt_pressed = 0;
                break;
        }
        return 0; // No ASCII for key release
    }
    
    // Handle special keys
    if (keyboard_handle_special_keys(scancode)) {
        return 0; // Special key handled
    }
    
    // Convert to ASCII
    if (scancode < 128) {
        char ascii;
        
        if (kbd_state.shift_pressed || kbd_state.caps_lock) {
            ascii = shift_keys[scancode];
        } else {
            ascii = normal_keys[scancode];
        }
        
        // Handle Caps Lock for letters only
        if (kbd_state.caps_lock && ascii >= 'a' && ascii <= 'z') {
            ascii = ascii - 'a' + 'A';
        } else if (kbd_state.caps_lock && ascii >= 'A' && ascii <= 'Z') {
            ascii = ascii - 'A' + 'a';
        }
        
        return ascii;
    }
    
    return 0; // Unknown scancode
}

/*
 * Handle special keys (modifiers, function keys, etc.)
 */
int keyboard_handle_special_keys(unsigned char scancode) {
    switch (scancode) {
        case 0x2A: // Left Shift
        case 0x36: // Right Shift
            kbd_state.shift_pressed = 1;
            return 1;
            
        case 0x1D: // Ctrl
            kbd_state.ctrl_pressed = 1;
            return 1;
            
        case 0x38: // Alt
            kbd_state.alt_pressed = 1;
            return 1;
            
        case 0x3A: // Caps Lock
            kbd_state.caps_lock = !kbd_state.caps_lock;
            keyboard_update_leds();
            return 1;
            
        case 0x45: // Num Lock
            kbd_state.num_lock = !kbd_state.num_lock;
            keyboard_update_leds();
            return 1;
            
        case 0x46: // Scroll Lock
            kbd_state.scroll_lock = !kbd_state.scroll_lock;
            keyboard_update_leds();
            return 1;
            
        // Function keys (F1-F12)
        case 0x3B: // F1
            print_colored("F1 pressed - Help", UI_HIGHLIGHT);
            return 1;
        case 0x3C: // F2
            print_colored("F2 pressed - Settings", UI_HIGHLIGHT);
            return 1;
        case 0x3D: // F3
            print_colored("F3 pressed - Search", UI_HIGHLIGHT);
            return 1;
        case 0x3E: // F4
            print_colored("F4 pressed - Applications", UI_HIGHLIGHT);
            return 1;
            
        // Arrow keys
        case 0x48: // Up arrow
            print_colored("Up arrow", UI_TEXT);
            return 1;
        case 0x50: // Down arrow
            print_colored("Down arrow", UI_TEXT);
            return 1;
        case 0x4B: // Left arrow
            print_colored("Left arrow", UI_TEXT);
            return 1;
        case 0x4D: // Right arrow
            print_colored("Right arrow", UI_TEXT);
            return 1;
    }
    
    return 0; // Not a special key
}

/*
 * Update keyboard LEDs
 */
void keyboard_update_leds(void) {
    unsigned char led_state = 0;
    
    if (kbd_state.scroll_lock) led_state |= 0x01;
    if (kbd_state.num_lock) led_state |= 0x02;
    if (kbd_state.caps_lock) led_state |= 0x04;
    
    // Send LED command to keyboard controller
    __asm__ volatile (
        "mov $0xED, %%al\n\t"  // Set LEDs command
        "out %%al, $0x60\n\t"  // Send to keyboard
        "mov %0, %%al\n\t"     // LED state
        "out %%al, $0x60"      // Send LED state
        :
        : "r" (led_state)
        : "al"
    );
}
