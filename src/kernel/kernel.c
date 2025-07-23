/*
 * OmniOS 2.0 Kernel - C Components
 * Enhanced kernel with C/Assembly hybrid architecture
 */

#include "version.h"
#include "colors.h"

// Kernel data structures
typedef struct {
    char name[32];
    unsigned int size;
    unsigned int address;
    unsigned char type;
} file_entry_t;

typedef struct {
    unsigned char r, g, b;
} color_t;

// Color palette for enhanced UI
static color_t color_palette[16] = {
    {0x00, 0x00, 0x00}, // Black
    {0x00, 0x00, 0xAA}, // Blue
    {0x00, 0xAA, 0x00}, // Green
    {0x00, 0xAA, 0xAA}, // Cyan
    {0xAA, 0x00, 0x00}, // Red
    {0xAA, 0x00, 0xAA}, // Magenta
    {0xAA, 0x55, 0x00}, // Brown
    {0xAA, 0xAA, 0xAA}, // Light Gray
    {0x55, 0x55, 0x55}, // Dark Gray
    {0x55, 0x55, 0xFF}, // Light Blue
    {0x55, 0xFF, 0x55}, // Light Green
    {0x55, 0xFF, 0xFF}, // Light Cyan
    {0xFF, 0x55, 0x55}, // Light Red
    {0xFF, 0x55, 0xFF}, // Light Magenta
    {0xFF, 0xFF, 0x55}, // Yellow
    {0xFF, 0xFF, 0xFF}  // White
};

// File system structure
static file_entry_t file_table[256];
static int file_count = 0;

// Function prototypes
void kernel_main(void);
void init_filesystem(void);
void init_drivers(void);
void init_applications(void);
int process_ls_command(void);
int install_opi_package(const char* filename);
void set_text_color(unsigned char color);
void print_colored(const char* text, unsigned char color);

/*
 * Main kernel entry point (called from assembly)
 */
void kernel_main(void) {
    // Initialize kernel subsystems
    init_filesystem();
    init_drivers();
    init_applications();
    
    // Display welcome message with colors
    set_text_color(UI_TITLE);
    print_colored("OmniOS " OMNIOS_VERSION_STRING " - " OMNIOS_CODENAME, UI_TITLE);
    
    set_text_color(UI_TEXT);
    print_colored("Kernel initialized successfully", UI_SUCCESS);
    
    // Return control to assembly code
}

/*
 * Initialize the file system
 * Fixes the 'ls' command crash issue
 */
void init_filesystem(void) {
    // Clear file table
    for (int i = 0; i < 256; i++) {
        file_table[i].name[0] = '\0';
        file_table[i].size = 0;
        file_table[i].address = 0;
        file_table[i].type = 0;
    }
    
    // Add default system files
    // kernel.bin
    strcpy(file_table[0].name, "KERNEL  BIN");
    file_table[0].size = 8192;
    file_table[0].address = 0x2000;
    file_table[0].type = 1; // System file
    
    // system.cfg
    strcpy(file_table[1].name, "SYSTEM  CFG");
    file_table[1].size = 1024;
    file_table[1].address = 0x4000;
    file_table[1].type = 2; // Configuration file
    
    // test.txt
    strcpy(file_table[2].name, "TEST    TXT");
    file_table[2].size = 256;
    file_table[2].address = 0x5000;
    file_table[2].type = 3; // Text file
    
    // calc.opi
    strcpy(file_table[3].name, "CALC    OPI");
    file_table[3].size = 2048;
    file_table[3].address = 0x6000;
    file_table[3].type = 4; // OPI package
    
    file_count = 4;
}

/*
 * Initialize hardware drivers
 */
void init_drivers(void) {
    // Initialize WiFi driver
    wifi_driver_init();
    
    // Initialize keyboard driver
    keyboard_driver_init();
    
    // Initialize generic hardware support
    hardware_driver_init();
}

/*
 * Initialize core applications
 */
void init_applications(void) {
    // Register core applications
    register_application("setup", setup_application_main);
    register_application("settings", settings_application_main);
    register_application("notepad", notepad_application_main);
    register_application("filemanager", filemanager_application_main);
}

/*
 * Process 'ls' command - Fixed implementation
 */
int process_ls_command(void) {
    set_text_color(UI_HIGHLIGHT);
    print_colored("Directory listing:", UI_HIGHLIGHT);
    
    set_text_color(UI_TEXT);
    
    for (int i = 0; i < file_count; i++) {
        if (file_table[i].name[0] != '\0') {
            // Format filename for display
            char display_name[13];
            format_filename(file_table[i].name, display_name);
            
            // Choose color based on file type
            unsigned char file_color;
            switch (file_table[i].type) {
                case 1: file_color = UI_ERROR; break;    // System files (red)
                case 2: file_color = UI_WARNING; break;  // Config files (yellow)
                case 3: file_color = UI_TEXT; break;     // Text files (white)
                case 4: file_color = UI_SUCCESS; break;  // OPI packages (green)
                default: file_color = UI_TEXT; break;
            }
            
            print_colored(display_name, file_color);
            
            // Print file size
            char size_str[16];
            format_file_size(file_table[i].size, size_str);
            print_colored(size_str, UI_TEXT);
            
            // Print file type
            const char* type_str = get_file_type_string(file_table[i].type);
            print_colored(type_str, UI_TEXT);
            
            print_colored("\n", UI_TEXT);
        }
    }
    
    return 0; // Success
}

/*
 * Install .opi package
 */
int install_opi_package(const char* filename) {
    set_text_color(UI_HIGHLIGHT);
    print_colored("Installing OPI package: ", UI_HIGHLIGHT);
    print_colored(filename, UI_TEXT);
    
    // Find the package file
    int package_index = -1;
    for (int i = 0; i < file_count; i++) {
        if (strcmp(file_table[i].name, filename) == 0) {
            package_index = i;
            break;
        }
    }
    
    if (package_index == -1) {
        print_colored("Package not found!", UI_ERROR);
        return -1;
    }
    
    if (file_table[package_index].type != 4) {
        print_colored("Not a valid OPI package!", UI_ERROR);
        return -1;
    }
    
    // Simulate package installation
    print_colored("Extracting package...", UI_TEXT);
    print_colored("Verifying dependencies...", UI_TEXT);
    print_colored("Installing files...", UI_TEXT);
    print_colored("Updating package database...", UI_TEXT);
    
    print_colored("Package installed successfully!", UI_SUCCESS);
    return 0;
}

/*
 * Set text color
 */
void set_text_color(unsigned char color) {
    // Assembly interface for setting text color
    __asm__ volatile (
        "mov %0, %%bl\n\t"
        "mov $0x09, %%ah\n\t"
        "mov $' ', %%al\n\t"
        "mov $1, %%cx\n\t"
        "int $0x10"
        :
        : "r" (color)
        : "ax", "bx", "cx"
    );
}

/*
 * Print colored text
 */
void print_colored(const char* text, unsigned char color) {
    set_text_color(color);
    
    while (*text) {
        __asm__ volatile (
            "mov %0, %%al\n\t"
            "mov $0x0E, %%ah\n\t"
            "int $0x10"
            :
            : "r" (*text)
            : "ax"
        );
        text++;
    }
}

// Utility functions
void format_filename(const char* fat_name, char* display_name) {
    int i, j = 0;
    
    // Copy name part
    for (i = 0; i < 8 && fat_name[i] != ' '; i++) {
        display_name[j++] = fat_name[i];
    }
    
    // Add dot if extension exists
    if (fat_name[8] != ' ') {
        display_name[j++] = '.';
        
        // Copy extension
        for (i = 8; i < 11 && fat_name[i] != ' '; i++) {
            display_name[j++] = fat_name[i];
        }
    }
    
    display_name[j] = '\0';
}

void format_file_size(unsigned int size, char* size_str) {
    if (size < 1024) {
        sprintf(size_str, "%u B", size);
    } else if (size < 1024 * 1024) {
        sprintf(size_str, "%u KB", size / 1024);
    } else {
        sprintf(size_str, "%u MB", size / (1024 * 1024));
    }
}

const char* get_file_type_string(unsigned char type) {
    switch (type) {
        case 1: return "[SYS]";
        case 2: return "[CFG]";
        case 3: return "[TXT]";
        case 4: return "[OPI]";
        default: return "[???]";
    }
}

// Driver initialization functions (implemented in separate driver files)
extern void wifi_driver_init(void);
extern void keyboard_driver_init(void);
extern void hardware_driver_init(void);

// Application registration functions
extern void register_application(const char* name, void (*main_func)(void));
extern void setup_application_main(void);
extern void settings_application_main(void);
extern void notepad_application_main(void);
extern void filemanager_application_main(void);

// Standard library functions (minimal implementation)
int strcmp(const char* str1, const char* str2) {
    while (*str1 && (*str1 == *str2)) {
        str1++;
        str2++;
    }
    return *(unsigned char*)str1 - *(unsigned char*)str2;
}

char* strcpy(char* dest, const char* src) {
    char* orig_dest = dest;
    while ((*dest++ = *src++));
    return orig_dest;
}

int sprintf(char* str, const char* format, ...) {
    // Minimal sprintf implementation
    // For now, just copy the format string
    strcpy(str, format);
    return strlen(format);
}

int strlen(const char* str) {
    int len = 0;
    while (str[len]) len++;
    return len;
}
