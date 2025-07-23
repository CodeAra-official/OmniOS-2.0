/*
 * OmniOS 2.0 Custom File System (OmniFS)
 * Optimized file system for OmniOS with .opi package support
 */

#include "omnios.h"
#include "fs/omnifs.h"

// OmniFS structures
typedef struct {
    uint32_t magic;           // 'OMNI'
    uint32_t version;         // File system version
    uint32_t block_size;      // Block size in bytes
    uint32_t total_blocks;    // Total number of blocks
    uint32_t free_blocks;     // Number of free blocks
    uint32_t inode_count;     // Total number of inodes
    uint32_t free_inodes;     // Number of free inodes
    uint32_t root_inode;      // Root directory inode
    uint32_t block_bitmap;    // Block bitmap location
    uint32_t inode_bitmap;    // Inode bitmap location
    uint32_t inode_table;     // Inode table location
    uint32_t data_blocks;     // First data block
    uint8_t reserved[468];    // Reserved space
} omnifs_superblock_t;

typedef struct {
    uint32_t mode;            // File type and permissions
    uint32_t uid;             // User ID
    uint32_t gid;             // Group ID
    uint32_t size;            // File size in bytes
    uint32_t atime;           // Access time
    uint32_t mtime;           // Modification time
    uint32_t ctime;           // Creation time
    uint32_t blocks;          // Number of blocks used
    uint32_t direct[12];      // Direct block pointers
    uint32_t indirect;        // Indirect block pointer
    uint32_t double_indirect; // Double indirect block pointer
    uint32_t triple_indirect; // Triple indirect block pointer
} omnifs_inode_t;

typedef struct {
    uint32_t inode;           // Inode number
    uint16_t rec_len;         // Record length
    uint8_t name_len;         // Name length
    uint8_t file_type;        // File type
    char name[];              // File name (variable length)
} omnifs_dirent_t;

// File system state
static omnifs_superblock_t* g_superblock = NULL;
static uint8_t* g_block_bitmap = NULL;
static uint8_t* g_inode_bitmap = NULL;
static omnifs_inode_t* g_inode_table = NULL;
static bool g_omnifs_mounted = false;

// Function prototypes
int omnifs_format(const char* device, uint32_t size);
int omnifs_mount(const char* device);
int omnifs_unmount(void);
int omnifs_create_file(const char* path, uint32_t mode);
int omnifs_delete_file(const char* path);
int omnifs_read_file(const char* path, void* buffer, uint32_t size, uint32_t offset);
int omnifs_write_file(const char* path, const void* buffer, uint32_t size, uint32_t offset);
int omnifs_list_directory(const char* path, omnifs_dirent_t* entries, int max_entries);

// Fixed 'ls' command implementation
int omnifs_list_directory_fixed(const char* path, omnifs_dirent_t* entries, int max_entries) {
    if (!g_omnifs_mounted) {
        return OMNIOS_ERROR_IO;
    }
    
    // Find directory inode
    uint32_t dir_inode = omnifs_find_inode(path);
    if (dir_inode == 0) {
        return OMNIOS_ERROR_NOT_FOUND;
    }
    
    // Get directory inode
    omnifs_inode_t* inode = &g_inode_table[dir_inode];
    if ((inode->mode & 0xF000) != 0x4000) { // Not a directory
        return OMNIOS_ERROR_GENERIC;
    }
    
    // Read directory entries
    int entry_count = 0;
    uint32_t offset = 0;
    
    while (offset < inode->size && entry_count < max_entries) {
        omnifs_dirent_t* dirent = (omnifs_dirent_t*)((uint8_t*)entries + offset);
        
        // Read directory entry from disk
        if (omnifs_read_inode_data(inode, dirent, sizeof(omnifs_dirent_t), offset) != OMNIOS_SUCCESS) {
            break;
        }
        
        // Validate entry
        if (dirent->rec_len == 0 || dirent->name_len == 0) {
            break;
        }
        
        // Read file name
        if (omnifs_read_inode_data(inode, dirent->name, dirent->name_len, 
                                   offset + sizeof(omnifs_dirent_t)) != OMNIOS_SUCCESS) {
            break;
        }
        
        dirent->name[dirent->name_len] = '\0'; // Null terminate
        
        entry_count++;
        offset += dirent->rec_len;
    }
    
    return entry_count;
}

int omnifs_format(const char* device, uint32_t size) {
    console_print("Formatting %s with OmniFS...\n", device);
    
    // Calculate file system parameters
    uint32_t block_size = 4096;
    uint32_t total_blocks = size / block_size;
    uint32_t inode_count = total_blocks / 4; // 1 inode per 4 blocks
    
    // Allocate superblock
    omnifs_superblock_t superblock;
    memset(&superblock, 0, sizeof(omnifs_superblock_t));
    
    superblock.magic = 0x494E4D4F; // 'OMNI'
    superblock.version = 1;
    superblock.block_size = block_size;
    superblock.total_blocks = total_blocks;
    superblock.free_blocks = total_blocks - 10; // Reserve first 10 blocks
    superblock.inode_count = inode_count;
    superblock.free_inodes = inode_count - 1; // Root inode used
    superblock.root_inode = 1;
    superblock.block_bitmap = 1;
    superblock.inode_bitmap = 2;
    superblock.inode_table = 3;
    superblock.data_blocks = 10;
    
    // Write superblock to device
    if (device_write(device, 0, &superblock, sizeof(omnifs_superblock_t)) != OMNIOS_SUCCESS) {
        return OMNIOS_ERROR_IO;
    }
    
    // Initialize block bitmap
    uint32_t bitmap_size = (total_blocks + 7) / 8;
    uint8_t* block_bitmap = memory_allocate(bitmap_size);
    memset(block_bitmap, 0, bitmap_size);
    
    // Mark reserved blocks as used
    for (int i = 0; i < 10; i++) {
        block_bitmap[i / 8] |= (1 << (i % 8));
    }
    
    device_write(device, block_size, block_bitmap, bitmap_size);
    memory_free(block_bitmap);
    
    // Initialize inode bitmap
    uint32_t inode_bitmap_size = (inode_count + 7) / 8;
    uint8_t* inode_bitmap = memory_allocate(inode_bitmap_size);
    memset(inode_bitmap, 0, inode_bitmap_size);
    
    // Mark root inode as used
    inode_bitmap[1 / 8] |= (1 << (1 % 8));
    
    device_write(device, block_size * 2, inode_bitmap, inode_bitmap_size);
    memory_free(inode_bitmap);
    
    // Initialize inode table
    uint32_t inode_table_size = inode_count * sizeof(omnifs_inode_t);
    omnifs_inode_t* inode_table = memory_allocate(inode_table_size);
    memset(inode_table, 0, inode_table_size);
    
    // Create root directory inode
    omnifs_inode_t* root_inode = &inode_table[1];
    root_inode->mode = 0x41ED; // Directory with 755 permissions
    root_inode->uid = 0;
    root_inode->gid = 0;
    root_inode->size = 0;
    root_inode->atime = root_inode->mtime = root_inode->ctime = get_current_time();
    root_inode->blocks = 0;
    
    device_write(device, block_size * 3, inode_table, inode_table_size);
    memory_free(inode_table);
    
    console_print("OmniFS formatting completed\n");
    return OMNIOS_SUCCESS;
}

int omnifs_mount(const char* device) {
    console_print("Mounting OmniFS from %s...\n", device);
    
    // Read superblock
    g_superblock = memory_allocate(sizeof(omnifs_superblock_t));
    if (device_read(device, 0, g_superblock, sizeof(omnifs_superblock_t)) != OMNIOS_SUCCESS) {
        memory_free(g_superblock);
        return OMNIOS_ERROR_IO;
    }
    
    // Verify magic number
    if (g_superblock->magic != 0x494E4D4F) {
        console_print("Invalid OmniFS magic number\n");
        memory_free(g_superblock);
        return OMNIOS_ERROR_GENERIC;
    }
    
    // Load block bitmap
    uint32_t bitmap_size = (g_superblock->total_blocks + 7) / 8;
    g_block_bitmap = memory_allocate(bitmap_size);
    device_read(device, g_superblock->block_size, g_block_bitmap, bitmap_size);
    
    // Load inode bitmap
    uint32_t inode_bitmap_size = (g_superblock->inode_count + 7) / 8;
    g_inode_bitmap = memory_allocate(inode_bitmap_size);
    device_read(device, g_superblock->block_size * 2, g_inode_bitmap, inode_bitmap_size);
    
    // Load inode table
    uint32_t inode_table_size = g_superblock->inode_count * sizeof(omnifs_inode_t);
    g_inode_table = memory_allocate(inode_table_size);
    device_read(device, g_superblock->block_size * 3, g_inode_table, inode_table_size);
    
    g_omnifs_mounted = true;
    console_print("OmniFS mounted successfully\n");
    return OMNIOS_SUCCESS;
}

// .opi package support functions
int omnifs_install_opi_package(const char* package_path) {
    console_print("Installing OPI package: %s\n", package_path);
    
    // Read package header
    opi_package_header_t header;
    if (omnifs_read_file(package_path, &header, sizeof(opi_package_header_t), 0) != OMNIOS_SUCCESS) {
        console_print("Failed to read package header\n");
        return OMNIOS_ERROR_IO;
    }
    
    // Verify package signature
    if (header.magic != OPI_MAGIC || header.version > OPI_VERSION) {
        console_print("Invalid or unsupported package format\n");
        return OMNIOS_ERROR_GENERIC;
    }
    
    // Check dependencies
    if (omnifs_check_dependencies(&header) != OMNIOS_SUCCESS) {
        console_print("Package dependencies not satisfied\n");
        return OMNIOS_ERROR_GENERIC;
    }
    
    // Create installation directory
    char install_path[256];
    snprintf(install_path, sizeof(install_path), "/apps/%s", header.package_name);
    
    if (omnifs_create_directory(install_path) != OMNIOS_SUCCESS) {
        console_print("Failed to create installation directory\n");
        return OMNIOS_ERROR_IO;
    }
    
    // Extract package files
    uint32_t offset = sizeof(opi_package_header_t);
    for (uint32_t i = 0; i < header.file_count; i++) {
        opi_file_entry_t file_entry;
        omnifs_read_file(package_path, &file_entry, sizeof(opi_file_entry_t), offset);
        offset += sizeof(opi_file_entry_t);
        
        // Create destination file path
        char dest_path[512];
        snprintf(dest_path, sizeof(dest_path), "%s/%s", install_path, file_entry.filename);
        
        // Extract file data
        void* file_data = memory_allocate(file_entry.size);
        omnifs_read_file(package_path, file_data, file_entry.size, offset);
        
        // Write file to destination
        omnifs_create_file(dest_path, file_entry.permissions);
        omnifs_write_file(dest_path, file_data, file_entry.size, 0);
        
        memory_free(file_data);
        offset += file_entry.size;
        
        console_print("Extracted: %s\n", file_entry.filename);
    }
    
    // Update package database
    omnifs_register_package(&header, install_path);
    
    console_print("Package installation completed successfully\n");
    return OMNIOS_SUCCESS;
}

int omnifs_check_dependencies(const opi_package_header_t* header) {
    // Parse dependency string
    char* deps = strdup(header->dependencies);
    char* token = strtok(deps, ",");
    
    while (token != NULL) {
        // Trim whitespace
        while (*token == ' ') token++;
        
        // Check if dependency is installed
        if (!omnifs_is_package_installed(token)) {
            console_print("Missing dependency: %s\n", token);
            free(deps);
            return OMNIOS_ERROR_GENERIC;
        }
        
        token = strtok(NULL, ",");
    }
    
    free(deps);
    return OMNIOS_SUCCESS;
}

bool omnifs_is_package_installed(const char* package_name) {
    char package_path[256];
    snprintf(package_path, sizeof(package_path), "/apps/%s", package_name);
    
    // Check if package directory exists
    uint32_t inode = omnifs_find_inode(package_path);
    return (inode != 0);
}

int omnifs_register_package(const opi_package_header_t* header, const char* install_path) {
    // Add entry to package database
    FILE* db_file = fopen("/system/packages.db", "a");
    if (!db_file) {
        return OMNIOS_ERROR_IO;
    }
    
    fprintf(db_file, "%s|%s|%s|%s|%u|%s\n",
            header->package_name,
            header->version,
            header->description,
            header->dependencies,
            header->total_size,
            install_path);
    
    fclose(db_file);
    return OMNIOS_SUCCESS;
}

uint32_t omnifs_find_inode(const char* path) {
    if (!g_omnifs_mounted) {
        return 0;
    }
    
    // Start from root inode
    uint32_t current_inode = g_superblock->root_inode;
    
    // Handle root path
    if (strcmp(path, "/") == 0) {
        return current_inode;
    }
    
    // Parse path components
    char* path_copy = strdup(path);
    char* token = strtok(path_copy + 1, "/"); // Skip leading slash
    
    while (token != NULL && current_inode != 0) {
        current_inode = omnifs_find_child_inode(current_inode, token);
        token = strtok(NULL, "/");
    }
    
    free(path_copy);
    return current_inode;
}

uint32_t omnifs_find_child_inode(uint32_t parent_inode, const char* name) {
    omnifs_inode_t* inode = &g_inode_table[parent_inode];
    
    // Ensure it's a directory
    if ((inode->mode & 0xF000) != 0x4000) {
        return 0;
    }
    
    // Search directory entries
    uint32_t offset = 0;
    while (offset < inode->size) {
        omnifs_dirent_t dirent;
        
        if (omnifs_read_inode_data(inode, &dirent, sizeof(omnifs_dirent_t), offset) != OMNIOS_SUCCESS) {
            break;
        }
        
        if (dirent.rec_len == 0) {
            break;
        }
        
        // Read entry name
        char entry_name[256];
        omnifs_read_inode_data(inode, entry_name, dirent.name_len, 
                               offset + sizeof(omnifs_dirent_t));
        entry_name[dirent.name_len] = '\0';
        
        if (strcmp(entry_name, name) == 0) {
            return dirent.inode;
        }
        
        offset += dirent.rec_len;
    }
    
    return 0; // Not found
}

int omnifs_read_inode_data(omnifs_inode_t* inode, void* buffer, uint32_t size, uint32_t offset) {
    if (offset >= inode->size) {
        return OMNIOS_ERROR_GENERIC;
    }
    
    uint32_t bytes_to_read = (offset + size > inode->size) ? (inode->size - offset) : size;
    uint32_t bytes_read = 0;
    
    while (bytes_read < bytes_to_read) {
        uint32_t block_index = (offset + bytes_read) / g_superblock->block_size;
        uint32_t block_offset = (offset + bytes_read) % g_superblock->block_size;
        uint32_t block_bytes = g_superblock->block_size - block_offset;
        
        if (block_bytes > bytes_to_read - bytes_read) {
            block_bytes = bytes_to_read - bytes_read;
        }
        
        // Get physical block number
        uint32_t physical_block = omnifs_get_block_number(inode, block_index);
        if (physical_block == 0) {
            break;
        }
        
        // Read from block
        uint8_t* block_data = memory_allocate(g_superblock->block_size);
        device_read("storage", physical_block * g_superblock->block_size, 
                    block_data, g_superblock->block_size);
        
        memcpy((uint8_t*)buffer + bytes_read, block_data + block_offset, block_bytes);
        memory_free(block_data);
        
        bytes_read += block_bytes;
    }
    
    return OMNIOS_SUCCESS;
}

uint32_t omnifs_get_block_number(omnifs_inode_t* inode, uint32_t block_index) {
    // Direct blocks
    if (block_index < 12) {
        return inode->direct[block_index];
    }
    
    // Indirect blocks
    block_index -= 12;
    uint32_t pointers_per_block = g_superblock->block_size / sizeof(uint32_t);
    
    if (block_index < pointers_per_block) {
        // Single indirect
        if (inode->indirect == 0) {
            return 0;
        }
        
        uint32_t* indirect_block = memory_allocate(g_superblock->block_size);
        device_read("storage", inode->indirect * g_superblock->block_size,
                    indirect_block, g_superblock->block_size);
        
        uint32_t block_num = indirect_block[block_index];
        memory_free(indirect_block);
        return block_num;
    }
    
    // Double indirect (simplified implementation)
    // ... additional indirect block handling would go here
    
    return 0;
}

int omnifs_create_directory(const char* path) {
    // Find parent directory
    char* parent_path = strdup(path);
    char* last_slash = strrchr(parent_path, '/');
    if (!last_slash) {
        free(parent_path);
        return OMNIOS_ERROR_GENERIC;
    }
    
    *last_slash = '\0';
    char* dir_name = last_slash + 1;
    
    uint32_t parent_inode = omnifs_find_inode(parent_path);
    if (parent_inode == 0) {
        free(parent_path);
        return OMNIOS_ERROR_NOT_FOUND;
    }
    
    // Allocate new inode
    uint32_t new_inode = omnifs_allocate_inode();
    if (new_inode == 0) {
        free(parent_path);
        return OMNIOS_ERROR_MEMORY;
    }
    
    // Initialize directory inode
    omnifs_inode_t* inode = &g_inode_table[new_inode];
    inode->mode = 0x41ED; // Directory with 755 permissions
    inode->uid = 0; // Current user ID
    inode->gid = 0; // Current group ID
    inode->size = 0;
    inode->atime = inode->mtime = inode->ctime = get_current_time();
    inode->blocks = 0;
    
    // Add directory entry to parent
    omnifs_add_directory_entry(parent_inode, dir_name, new_inode, OMNIFS_FILE_TYPE_DIR);
    
    free(parent_path);
    return OMNIOS_SUCCESS;
}

uint32_t omnifs_allocate_inode(void) {
    for (uint32_t i = 1; i < g_superblock->inode_count; i++) {
        uint32_t byte_index = i / 8;
        uint32_t bit_index = i % 8;
        
        if (!(g_inode_bitmap[byte_index] & (1 << bit_index))) {
            // Mark inode as used
            g_inode_bitmap[byte_index] |= (1 << bit_index);
            g_superblock->free_inodes--;
            return i;
        }
    }
    
    return 0; // No free inodes
}

int omnifs_add_directory_entry(uint32_t parent_inode, const char* name, 
                               uint32_t child_inode, uint8_t file_type) {
    omnifs_inode_t* parent = &g_inode_table[parent_inode];
    
    // Calculate entry size
    uint16_t name_len = strlen(name);
    uint16_t rec_len = sizeof(omnifs_dirent_t) + name_len;
    rec_len = (rec_len + 3) & ~3; // Align to 4 bytes
    
    // Create directory entry
    omnifs_dirent_t* entry = memory_allocate(rec_len);
    entry->inode = child_inode;
    entry->rec_len = rec_len;
    entry->name_len = name_len;
    entry->file_type = file_type;
    memcpy(entry->name, name, name_len);
    
    // Append to directory
    omnifs_write_inode_data(parent, entry, rec_len, parent->size);
    parent->size += rec_len;
    
    memory_free(entry);
    return OMNIOS_SUCCESS;
}

int omnifs_write_inode_data(omnifs_inode_t* inode, const void* buffer, 
                            uint32_t size, uint32_t offset) {
    // Simplified write implementation
    // In a full implementation, this would handle block allocation,
    // indirect blocks, and proper data writing
    
    uint32_t bytes_written = 0;
    
    while (bytes_written < size) {
        uint32_t block_index = (offset + bytes_written) / g_superblock->block_size;
        uint32_t block_offset = (offset + bytes_written) % g_superblock->block_size;
        uint32_t block_bytes = g_superblock->block_size - block_offset;
        
        if (block_bytes > size - bytes_written) {
            block_bytes = size - bytes_written;
        }
        
        // Allocate block if needed
        if (block_index < 12 && inode->direct[block_index] == 0) {
            inode->direct[block_index] = omnifs_allocate_block();
            if (inode->direct[block_index] == 0) {
                return OMNIOS_ERROR_MEMORY;
            }
            inode->blocks++;
        }
        
        uint32_t physical_block = omnifs_get_block_number(inode, block_index);
        if (physical_block == 0) {
            return OMNIOS_ERROR_IO;
        }
        
        // Read-modify-write block
        uint8_t* block_data = memory_allocate(g_superblock->block_size);
        device_read("storage", physical_block * g_superblock->block_size,
                    block_data, g_superblock->block_size);
        
        memcpy(block_data + block_offset, (uint8_t*)buffer + bytes_written, block_bytes);
        
        device_write("storage", physical_block * g_superblock->block_size,
                     block_data, g_superblock->block_size);
        
        memory_free(block_data);
        bytes_written += block_bytes;
    }
    
    return OMNIOS_SUCCESS;
}

uint32_t omnifs_allocate_block(void) {
    for (uint32_t i = g_superblock->data_blocks; i < g_superblock->total_blocks; i++) {
        uint32_t byte_index = i / 8;
        uint32_t bit_index = i % 8;
        
        if (!(g_block_bitmap[byte_index] & (1 << bit_index))) {
            // Mark block as used
            g_block_bitmap[byte_index] |= (1 << bit_index);
            g_superblock->free_blocks--;
            return i;
        }
    }
    
    return 0; // No free blocks
}

// External device I/O functions (implemented by storage driver)
extern int device_read(const char* device, uint32_t offset, void* buffer, uint32_t size);
extern int device_write(const char* device, uint32_t offset, const void* buffer, uint32_t size);
extern uint32_t get_current_time(void);
