/*
 * OmniOS 2.0 Package Installer
 * Handles .opi (OmniOS Package Installer) files
 */

#include "version.h"
#include "colors.h"

// Package structure
typedef struct {
    char name[32];
    char version[16];
    char description[128];
    char author[64];
    char dependencies[256];
    unsigned int size;
    unsigned int install_path_offset;
    unsigned int file_count;
} opi_header_t;

typedef struct {
    char filename[64];
    unsigned int size;
    unsigned int offset;
    unsigned int permissions;
} opi_file_entry_t;

// Function prototypes
void package_installer_main(void);
int install_opi_package(const char* package_url);
int install_local_opi(const char* filename);
int verify_opi_package(const char* filename);
int extract_opi_package(const char* filename);
int download_package(const char* url, const char* local_file);
void show_package_info(const opi_header_t* header);

/*
 * Package installer main function
 */
void package_installer_main(void) {
    print_colored("OmniOS Package Installer v1.0", UI_TITLE);
    print_colored("Supports .opi package format", UI_TEXT);
    
    char input[256];
    char command[64];
    char argument[192];
    
    while (1) {
        print_colored("\nPackage> ", UI_HIGHLIGHT);
        
        // Get user input
        get_user_input(input, sizeof(input));
        
        // Parse command
        if (parse_command(input, command, argument) == 0) {
            continue;
        }
        
        // Handle commands
        if (strcmp(command, "install") == 0) {
            if (strlen(argument) == 0) {
                print_colored("Usage: install <package_url_or_file>", UI_WARNING);
                continue;
            }
            
            // Check if it's a URL or local file
            if (strstr(argument, "http://") || strstr(argument, "https://")) {
                install_opi_package(argument);
            } else {
                install_local_opi(argument);
            }
        }
        else if (strcmp(command, "list") == 0) {
            list_installed_packages();
        }
        else if (strcmp(command, "remove") == 0) {
            if (strlen(argument) == 0) {
                print_colored("Usage: remove <package_name>", UI_WARNING);
                continue;
            }
            remove_package(argument);
        }
        else if (strcmp(command, "info") == 0) {
            if (strlen(argument) == 0) {
                print_colored("Usage: info <package_name>", UI_WARNING);
                continue;
            }
            show_package_details(argument);
        }
        else if (strcmp(command, "update") == 0) {
            update_package_database();
        }
        else if (strcmp(command, "search") == 0) {
            if (strlen(argument) == 0) {
                print_colored("Usage: search <keyword>", UI_WARNING);
                continue;
            }
            search_packages(argument);
        }
        else if (strcmp(command, "help") == 0) {
            show_help();
        }
        else if (strcmp(command, "exit") == 0) {
            break;
        }
        else {
            print_colored("Unknown command. Type 'help' for available commands.", UI_ERROR);
        }
    }
}

/*
 * Install package from URL
 */
int install_opi_package(const char* package_url) {
    print_colored("Installing package from URL: ", UI_TEXT);
    print_colored(package_url, UI_HIGHLIGHT);
    
    // Generate local filename
    char local_file[64];
    generate_temp_filename(package_url, local_file);
    
    // Download package
    print_colored("Downloading package...", UI_TEXT);
    if (download_package(package_url, local_file) != 0) {
        print_colored("Failed to download package!", UI_ERROR);
        return -1;
    }
    
    // Install downloaded package
    int result = install_local_opi(local_file);
    
    // Clean up temporary file
    delete_file(local_file);
    
    return result;
}

/*
 * Install local .opi package
 */
int install_local_opi(const char* filename) {
    print_colored("Installing local package: ", UI_TEXT);
    print_colored(filename, UI_HIGHLIGHT);
    
    // Verify package integrity
    print_colored("Verifying package...", UI_TEXT);
    if (verify_opi_package(filename) != 0) {
        print_colored("Package verification failed!", UI_ERROR);
        return -1;
    }
    
    // Read package header
    opi_header_t header;
    if (read_opi_header(filename, &header) != 0) {
        print_colored("Failed to read package header!", UI_ERROR);
        return -1;
    }
    
    // Show package information
    show_package_info(&header);
    
    // Check dependencies
    print_colored("Checking dependencies...", UI_TEXT);
    if (check_dependencies(header.dependencies) != 0) {
        print_colored("Dependency check failed!", UI_ERROR);
        return -1;
    }
    
    // Check if package is already installed
    if (is_package_installed(header.name)) {
        print_colored("Package is already installed. Upgrade? (y/n): ", UI_WARNING);
        char response = get_char_input();
        if (response != 'y' && response != 'Y') {
            print_colored("Installation cancelled.", UI_TEXT);
            return 0;
        }
    }
    
    // Extract and install package
    print_colored("Extracting package...", UI_TEXT);
    if (extract_opi_package(filename) != 0) {
        print_colored("Package extraction failed!", UI_ERROR);
        return -1;
    }
    
    // Update package database
    print_colored("Updating package database...", UI_TEXT);
    if (register_package(&header) != 0) {
        print_colored("Failed to register package!", UI_ERROR);
        return -1;
    }
    
    print_colored("Package installed successfully!", UI_SUCCESS);
    return 0;
}

/*
 * Verify .opi package integrity
 */
int verify_opi_package(const char* filename) {
    // Check file exists
    if (!file_exists(filename)) {
        return -1;
    }
    
    // Check file extension
    if (!has_extension(filename, ".opi")) {
        print_colored("Invalid package format. Expected .opi file.", UI_ERROR);
        return -1;
    }
    
    // Read and verify header
    opi_header_t header;
    if (read_opi_header(filename, &header) != 0) {
        return -1;
    }
    
    // Verify magic number
    if (header.size == 0 || header.file_count == 0) {
        print_colored("Invalid package header.", UI_ERROR);
        return -1;
    }
    
    // Verify checksum (simplified)
    unsigned int calculated_checksum = calculate_file_checksum(filename);
    unsigned int stored_checksum = get_stored_checksum(filename);
    
    if (calculated_checksum != stored_checksum) {
        print_colored("Package checksum verification failed!", UI_ERROR);
        return -1;
    }
    
    return 0;
}

/*
 * Extract .opi package
 */
int extract_opi_package(const char* filename) {
    opi_header_t header;
    opi_file_entry_t file_entry;
    
    // Read header
    if (read_opi_header(filename, &header) != 0) {
        return -1;
    }
    
    // Create installation directory
    char install_path[128];
    sprintf(install_path, "/apps/%s", header.name);
    create_directory(install_path);
    
    // Extract each file
    for (unsigned int i = 0; i < header.file_count; i++) {
        // Read file entry
        if (read_file_entry(filename, i, &file_entry) != 0) {
            print_colored("Failed to read file entry!", UI_ERROR);
            return -1;
        }
        
        // Extract file
        char dest_path[256];
        sprintf(dest_path, "%s/%s", install_path, file_entry.filename);
        
        if (extract_file_from_package(filename, &file_entry, dest_path) != 0) {
            print_colored("Failed to extract file: ", UI_ERROR);
            print_colored(file_entry.filename, UI_ERROR);
            return -1;
        }
        
        // Set file permissions
        set_file_permissions(dest_path, file_entry.permissions);
        
        print_colored("Extracted: ", UI_TEXT);
        print_colored(file_entry.filename, UI_SUCCESS);
    }
    
    return 0;
}

/*
 * Download package from URL
 */
int download_package(const char* url, const char* local_file) {
    // Simplified HTTP download implementation
    print_colored("Connecting to server...", UI_TEXT);
    
    // Parse URL
    char hostname[128];
    char path[256];
    int port = 80;
    
    if (parse_url(url, hostname, &port, path) != 0) {
        print_colored("Invalid URL format!", UI_ERROR);
        return -1;
    }
    
    // Connect to server (simulated)
    print_colored("Downloading...", UI_TEXT);
    
    // Show progress
    for (int i = 0; i <= 100; i += 10) {
        show_progress_bar(i);
        delay(100); // Simulate download time
    }
    
    print_colored("Download completed!", UI_SUCCESS);
    return 0;
}

/*
 * Show package information
 */
void show_package_info(const opi_header_t* header) {
    print_colored("\n=== Package Information ===", UI_TITLE);
    
    print_colored("Name: ", UI_TEXT);
    print_colored(header->name, UI_HIGHLIGHT);
    
    print_colored("Version: ", UI_TEXT);
    print_colored(header->version, UI_TEXT);
    
    print_colored("Author: ", UI_TEXT);
    print_colored(header->author, UI_TEXT);
    
    print_colored("Description: ", UI_TEXT);
    print_colored(header->description, UI_TEXT);
    
    char size_str[32];
    format_file_size(header->size, size_str);
    print_colored("Size: ", UI_TEXT);
    print_colored(size_str, UI_TEXT);
    
    if (strlen(header->dependencies) > 0) {
        print_colored("Dependencies: ", UI_TEXT);
        print_colored(header->dependencies, UI_WARNING);
    }
    
    print_colored("Files: ", UI_TEXT);
    char file_count_str[16];
    sprintf(file_count_str, "%u", header->file_count);
    print_colored(file_count_str, UI_TEXT);
    
    print_colored("===========================\n", UI_TITLE);
}

// Additional utility functions
void show_help(void) {
    print_colored("\nOmniOS Package Installer Commands:", UI_TITLE);
    print_colored("  install <url|file>  - Install package from URL or local file", UI_TEXT);
    print_colored("  list               - List installed packages", UI_TEXT);
    print_colored("  remove <name>      - Remove installed package", UI_TEXT);
    print_colored("  info <name>        - Show package information", UI_TEXT);
    print_colored("  update             - Update package database", UI_TEXT);
    print_colored("  search <keyword>   - Search for packages", UI_TEXT);
    print_colored("  help               - Show this help", UI_TEXT);
    print_colored("  exit               - Exit package installer", UI_TEXT);
}

void show_progress_bar(int percentage) {
    char bar[52]; // 50 chars + brackets
    int filled = percentage / 2; // 50 chars max
    
    bar[0] = '[';
    for (int i = 1; i <= 50; i++) {
        bar[i] = (i <= filled) ? '=' : ' ';
    }
    bar[51] = ']';
    bar[52] = '\0';
    
    print_colored("\r", UI_TEXT);
    print_colored(bar, UI_SUCCESS);
    
    char percent_str[8];
    sprintf(percent_str, " %d%%", percentage);
    print_colored(percent_str, UI_TEXT);
}

// Stub implementations for utility functions
int parse_command(const char* input, char* command, char* argument) {
    // Parse input into command and argument
    return 1; // Success
}

void get_user_input(char* buffer, int max_size) {
    // Get user input from keyboard
}

char get_char_input(void) {
    // Get single character input
    return 'n';
}

int file_exists(const char* filename) {
    // Check if file exists
    return 1; // Assume exists for demo
}

int has_extension(const char* filename, const char* ext) {
    // Check file extension
    return 1; // Assume correct for demo
}

// Additional stub functions would be implemented here...
