/*
 * OmniOS 2.0 Memory Management
 * Physical and virtual memory management with paging
 */

#include "omnios.h"
#include "kernel/memory.h"

// Memory management structures
typedef struct memory_block {
    uint32_t address;
    uint32_t size;
    bool allocated;
    struct memory_block* next;
} memory_block_t;

typedef struct {
    uint32_t total_memory;
    uint32_t free_memory;
    uint32_t used_memory;
    memory_block_t* free_list;
    memory_block_t* used_list;
} memory_manager_t;

static memory_manager_t g_memory_manager;
static uint32_t g_kernel_heap_start;
static uint32_t g_kernel_heap_end;

// Page directory and tables for virtual memory
static uint32_t* page_directory;
static uint32_t* page_tables[1024];

int memory_init(void) {
    console_print("Initializing memory management...\n");
    
    // Detect available memory
    uint32_t total_memory = detect_memory();
    console_print("Total memory: %d MB\n", total_memory / (1024 * 1024));
    
    // Initialize memory manager
    g_memory_manager.total_memory = total_memory;
    g_memory_manager.free_memory = total_memory - 0x100000; // Reserve first 1MB
    g_memory_manager.used_memory = 0x100000;
    g_memory_manager.free_list = NULL;
    g_memory_manager.used_list = NULL;
    
    // Set up kernel heap (1MB - 16MB)
    g_kernel_heap_start = 0x100000;
    g_kernel_heap_end = 0x1000000;
    
    // Initialize free list with kernel heap
    memory_block_t* initial_block = (memory_block_t*)g_kernel_heap_start;
    initial_block->address = g_kernel_heap_start + sizeof(memory_block_t);
    initial_block->size = g_kernel_heap_end - g_kernel_heap_start - sizeof(memory_block_t);
    initial_block->allocated = false;
    initial_block->next = NULL;
    g_memory_manager.free_list = initial_block;
    
    // Initialize paging
    if (init_paging() != OMNIOS_SUCCESS) {
        return OMNIOS_ERROR_GENERIC;
    }
    
    console_print("Memory management initialized\n");
    return OMNIOS_SUCCESS;
}

uint32_t detect_memory(void) {
    // Use BIOS memory map (simplified)
    // In real implementation, this would parse the memory map from bootloader
    return 64 * 1024 * 1024; // Assume 64MB for now
}

int init_paging(void) {
    console_print("Setting up paging...\n");
    
    // Allocate page directory
    page_directory = (uint32_t*)memory_allocate_aligned(PAGE_SIZE, PAGE_SIZE);
    if (!page_directory) {
        return OMNIOS_ERROR_MEMORY;
    }
    
    // Clear page directory
    memset(page_directory, 0, PAGE_SIZE);
    
    // Identity map first 4MB (kernel space)
    for (int i = 0; i < 1024; i++) {
        // Allocate page table
        page_tables[0] = (uint32_t*)memory_allocate_aligned(PAGE_SIZE, PAGE_SIZE);
        if (!page_tables[0]) {
            return OMNIOS_ERROR_MEMORY;
        }
        
        // Map pages
        for (int j = 0; j < 1024; j++) {
            uint32_t address = (i * 1024 + j) * PAGE_SIZE;
            page_tables[0][j] = address | 0x003; // Present, writable
        }
        
        // Add page table to directory
        page_directory[i] = (uint32_t)page_tables[0] | 0x003;
        
        // Only map first 4MB for now
        if (i == 0) break;
    }
    
    // Enable paging
    enable_paging((uint32_t)page_directory);
    
    console_print("Paging enabled\n");
    return OMNIOS_SUCCESS;
}

void* memory_allocate(uint32_t size) {
    if (size == 0) {
        return NULL;
    }
    
    // Align size to 4-byte boundary
    size = (size + 3) & ~3;
    
    // Find suitable free block
    memory_block_t* current = g_memory_manager.free_list;
    memory_block_t* prev = NULL;
    
    while (current) {
        if (current->size >= size) {
            // Found suitable block
            void* allocated_ptr = (void*)current->address;
            
            // If block is larger than needed, split it
            if (current->size > size + sizeof(memory_block_t)) {
                memory_block_t* new_block = (memory_block_t*)(current->address + size);
                new_block->address = current->address + size + sizeof(memory_block_t);
                new_block->size = current->size - size - sizeof(memory_block_t);
                new_block->allocated = false;
                new_block->next = current->next;
                
                current->size = size;
                current->next = new_block;
            }
            
            // Remove from free list
            if (prev) {
                prev->next = current->next;
            } else {
                g_memory_manager.free_list = current->next;
            }
            
            // Add to used list
            current->allocated = true;
            current->next = g_memory_manager.used_list;
            g_memory_manager.used_list = current;
            
            // Update statistics
            g_memory_manager.free_memory -= size;
            g_memory_manager.used_memory += size;
            
            return allocated_ptr;
        }
        
        prev = current;
        current = current->next;
    }
    
    return NULL; // No suitable block found
}

void memory_free(void* ptr) {
    if (!ptr) {
        return;
    }
    
    // Find block in used list
    memory_block_t* current = g_memory_manager.used_list;
    memory_block_t* prev = NULL;
    
    while (current) {
        if ((void*)current->address == ptr) {
            // Remove from used list
            if (prev) {
                prev->next = current->next;
            } else {
                g_memory_manager.used_list = current->next;
            }
            
            // Add to free list
            current->allocated = false;
            current->next = g_memory_manager.free_list;
            g_memory_manager.free_list = current;
            
            // Update statistics
            g_memory_manager.free_memory += current->size;
            g_memory_manager.used_memory -= current->size;
            
            // Coalesce adjacent free blocks
            coalesce_free_blocks();
            
            return;
        }
        
        prev = current;
        current = current->next;
    }
}

void* memory_allocate_aligned(uint32_t size, uint32_t alignment) {
    if (alignment == 0 || (alignment & (alignment - 1)) != 0) {
        return NULL; // Alignment must be power of 2
    }
    
    // Allocate extra space for alignment
    uint32_t total_size = size + alignment - 1;
    void* ptr = memory_allocate(total_size);
    if (!ptr) {
        return NULL;
    }
    
    // Calculate aligned address
    uint32_t aligned_addr = ((uint32_t)ptr + alignment - 1) & ~(alignment - 1);
    
    return (void*)aligned_addr;
}

void coalesce_free_blocks(void) {
    memory_block_t* current = g_memory_manager.free_list;
    
    while (current && current->next) {
        // Check if current block is adjacent to next block
        if (current->address + current->size == (uint32_t)current->next) {
            // Merge blocks
            memory_block_t* next_block = current->next;
            current->size += next_block->size + sizeof(memory_block_t);
            current->next = next_block->next;
        } else {
            current = current->next;
        }
    }
}

uint32_t memory_get_total(void) {
    return g_memory_manager.total_memory;
}

uint32_t memory_get_free(void) {
    return g_memory_manager.free_memory;
}

uint32_t memory_get_used(void) {
    return g_memory_manager.used_memory;
}

// Assembly function to enable paging
extern void enable_paging(uint32_t page_directory_address);
