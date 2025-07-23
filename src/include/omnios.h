/*
 * OmniOS 2.0 - Main System Header
 * Modular Architecture Definitions
 */

#ifndef OMNIOS_H
#define OMNIOS_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// System version and build information
#define OMNIOS_VERSION_MAJOR    2
#define OMNIOS_VERSION_MINOR    0
#define OMNIOS_VERSION_PATCH    0
#define OMNIOS_VERSION_BUILD    1
#define OMNIOS_CODENAME         "Phoenix"

// System limits and constants
#define MAX_PROCESSES           64
#define MAX_OPEN_FILES          256
#define MAX_DRIVERS             32
#define MAX_MODULES             16
#define PAGE_SIZE               4096
#define KERNEL_STACK_SIZE       8192

// Module types
typedef enum {
    MODULE_BOOTLOADER = 0,
    MODULE_KERNEL,
    MODULE_DRIVER,
    MODULE_FILESYSTEM,
    MODULE_APPLICATION,
    MODULE_UI_FRAMEWORK,
    MODULE_SECURITY
} module_type_t;

// Module structure
typedef struct {
    char name[32];
    module_type_t type;
    uint32_t version;
    uint32_t base_address;
    uint32_t size;
    void (*init)(void);
    void (*cleanup)(void);
    bool loaded;
} module_t;

// System state
typedef struct {
    uint32_t total_memory;
    uint32_t free_memory;
    uint32_t active_processes;
    uint32_t uptime;
    bool gui_enabled;
    char current_user[32];
} system_state_t;

// Function prototypes for core system functions
int omnios_init(void);
int omnios_shutdown(void);
int load_module(const char* module_name);
int unload_module(const char* module_name);
system_state_t* get_system_state(void);

// Error codes
#define OMNIOS_SUCCESS          0
#define OMNIOS_ERROR_GENERIC    -1
#define OMNIOS_ERROR_MEMORY     -2
#define OMNIOS_ERROR_IO         -3
#define OMNIOS_ERROR_PERMISSION -4
#define OMNIOS_ERROR_NOT_FOUND  -5

#endif /* OMNIOS_H */
