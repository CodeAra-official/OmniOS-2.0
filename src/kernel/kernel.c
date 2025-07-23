/*
 * OmniOS 2.0 Kernel - Main Kernel Implementation
 * Modular kernel with resource management and driver interface
 */

#include "omnios.h"
#include "kernel/memory.h"
#include "kernel/process.h"
#include "kernel/drivers.h"
#include "kernel/syscalls.h"
#include "ui/ui_framework.h"
#include "security/security.h"

// Kernel signature (must match bootloader check)
const uint32_t kernel_signature __attribute__((section(".signature"))) = 0x4E524B4F; // "OKRN"

// Global system state
static system_state_t g_system_state;
static module_t g_loaded_modules[MAX_MODULES];
static int g_module_count = 0;

// Kernel initialization sequence
void kernel_main(void) {
    // Initialize kernel subsystems
    kernel_early_init();
    
    // Display kernel banner
    kernel_print_banner();
    
    // Initialize memory management
    if (memory_init() != OMNIOS_SUCCESS) {
        kernel_panic("Memory initialization failed");
    }
    
    // Initialize process management
    if (process_init() != OMNIOS_SUCCESS) {
        kernel_panic("Process initialization failed");
    }
    
    // Initialize driver subsystem
    if (driver_init() != OMNIOS_SUCCESS) {
        kernel_panic("Driver initialization failed");
    }
    
    // Initialize security subsystem
    if (security_init() != OMNIOS_SUCCESS) {
        kernel_panic("Security initialization failed");
    }
    
    // Initialize UI framework
    if (ui_framework_init() != OMNIOS_SUCCESS) {
        kernel_panic("UI framework initialization failed");
    }
    
    // Load essential drivers
    load_essential_drivers();
    
    // Initialize system calls
    syscall_init();
    
    // Start init process
    start_init_process();
    
    // Enable interrupts
    enable_interrupts();
    
    // Kernel main loop
    kernel_main_loop();
}

void kernel_early_init(void) {
    // Clear system state
    memset(&g_system_state, 0, sizeof(system_state_t));
    
    // Initialize basic console output
    console_init();
    
    // Set up interrupt handlers
    setup_interrupt_handlers();
    
    // Initialize timer
    timer_init();
}

void kernel_print_banner(void) {
    console_print("OmniOS 2.0 Kernel - Phoenix Edition\n");
    console_print("Version: %d.%d.%d Build %d\n", 
                  OMNIOS_VERSION_MAJOR, 
                  OMNIOS_VERSION_MINOR, 
                  OMNIOS_VERSION_PATCH, 
                  OMNIOS_VERSION_BUILD);
    console_print("Copyright (c) 2025 OmniOS Team\n\n");
}

void load_essential_drivers(void) {
    console_print("Loading essential drivers...\n");
    
    // Load keyboard driver
    if (load_module("keyboard_driver") != OMNIOS_SUCCESS) {
        console_print("Warning: Keyboard driver failed to load\n");
    }
    
    // Load display driver
    if (load_module("display_driver") != OMNIOS_SUCCESS) {
        console_print("Warning: Display driver failed to load\n");
    }
    
    // Load storage driver
    if (load_module("storage_driver") != OMNIOS_SUCCESS) {
        console_print("Warning: Storage driver failed to load\n");
    }
    
    // Load WiFi driver (optional)
    if (load_module("wifi_driver") != OMNIOS_SUCCESS) {
        console_print("Info: WiFi driver not available\n");
    }
    
    console_print("Driver loading completed\n");
}

void start_init_process(void) {
    console_print("Starting init process...\n");
    
    // Create init process
    process_t* init_proc = process_create("init", PROCESS_PRIORITY_HIGH);
    if (!init_proc) {
        kernel_panic("Failed to create init process");
    }
    
    // Load init program
    if (process_load_program(init_proc, "/system/init") != OMNIOS_SUCCESS) {
        kernel_panic("Failed to load init program");
    }
    
    // Start the process
    process_start(init_proc);
}

void kernel_main_loop(void) {
    console_print("Kernel initialization complete\n");
    console_print("System ready\n\n");
    
    // Update system state
    g_system_state.total_memory = memory_get_total();
    g_system_state.free_memory = memory_get_free();
    g_system_state.active_processes = process_get_count();
    g_system_state.uptime = 0;
    g_system_state.gui_enabled = true;
    strcpy(g_system_state.current_user, "system");
    
    // Main kernel loop
    while (1) {
        // Process scheduler
        process_schedule();
        
        // Handle interrupts
        handle_pending_interrupts();
        
        // Update system statistics
        update_system_stats();
        
        // Power management
        if (should_idle()) {
            cpu_idle();
        }
    }
}

// Module management functions
int load_module(const char* module_name) {
    if (g_module_count >= MAX_MODULES) {
        return OMNIOS_ERROR_MEMORY;
    }
    
    // Find module in filesystem
    char module_path[256];
    snprintf(module_path, sizeof(module_path), "/system/modules/%s.mod", module_name);
    
    // Load module file
    void* module_data = load_file(module_path);
    if (!module_data) {
        return OMNIOS_ERROR_NOT_FOUND;
    }
    
    // Parse module header
    module_header_t* header = (module_header_t*)module_data;
    if (header->magic != MODULE_MAGIC) {
        free(module_data);
        return OMNIOS_ERROR_GENERIC;
    }
    
    // Allocate memory for module
    void* module_base = memory_allocate(header->size);
    if (!module_base) {
        free(module_data);
        return OMNIOS_ERROR_MEMORY;
    }
    
    // Copy module to allocated memory
    memcpy(module_base, module_data, header->size);
    free(module_data);
    
    // Initialize module structure
    module_t* module = &g_loaded_modules[g_module_count];
    strncpy(module->name, module_name, sizeof(module->name) - 1);
    module->type = header->type;
    module->version = header->version;
    module->base_address = (uint32_t)module_base;
    module->size = header->size;
    module->init = (void(*)(void))(module_base + header->init_offset);
    module->cleanup = (void(*)(void))(module_base + header->cleanup_offset);
    module->loaded = true;
    
    // Call module initialization
    if (module->init) {
        module->init();
    }
    
    g_module_count++;
    
    console_print("Module '%s' loaded successfully\n", module_name);
    return OMNIOS_SUCCESS;
}

int unload_module(const char* module_name) {
    // Find module
    for (int i = 0; i < g_module_count; i++) {
        if (strcmp(g_loaded_modules[i].name, module_name) == 0) {
            module_t* module = &g_loaded_modules[i];
            
            // Call cleanup function
            if (module->cleanup) {
                module->cleanup();
            }
            
            // Free module memory
            memory_free((void*)module->base_address);
            
            // Remove from array
            memmove(&g_loaded_modules[i], &g_loaded_modules[i + 1], 
                    (g_module_count - i - 1) * sizeof(module_t));
            g_module_count--;
            
            console_print("Module '%s' unloaded\n", module_name);
            return OMNIOS_SUCCESS;
        }
    }
    
    return OMNIOS_ERROR_NOT_FOUND;
}

system_state_t* get_system_state(void) {
    return &g_system_state;
}

void update_system_stats(void) {
    static uint32_t last_update = 0;
    uint32_t current_time = timer_get_ticks();
    
    // Update every second
    if (current_time - last_update >= 1000) {
        g_system_state.free_memory = memory_get_free();
        g_system_state.active_processes = process_get_count();
        g_system_state.uptime = current_time / 1000;
        last_update = current_time;
    }
}

bool should_idle(void) {
    // Check if all processes are waiting
    return process_all_waiting();
}

void kernel_panic(const char* message) {
    // Disable interrupts
    disable_interrupts();
    
    // Clear screen and display panic message
    console_clear();
    console_set_color(CONSOLE_COLOR_RED, CONSOLE_COLOR_BLACK);
    console_print("\n*** KERNEL PANIC ***\n");
    console_print("Error: %s\n", message);
    console_print("System halted.\n");
    
    // Halt the system
    while (1) {
        cpu_halt();
    }
}

// Assembly functions (implemented in kernel_asm.s)
extern void enable_interrupts(void);
extern void disable_interrupts(void);
extern void cpu_halt(void);
extern void cpu_idle(void);
extern void setup_interrupt_handlers(void);
extern void handle_pending_interrupts(void);
