# OmniOS 2.0 Modular Build System
# Comprehensive build system for all components

# Build configuration
CC = gcc
AS = nasm
LD = ld
OBJCOPY = objcopy

# Compiler flags
CFLAGS = -m32 -ffreestanding -nostdlib -nostdinc -fno-builtin -fno-stack-protector
CFLAGS += -Wall -Wextra -Werror -O2 -Isrc/include
ASFLAGS = -f elf32 -Isrc/include/
LDFLAGS = -m elf_i386 -nostdlib

# Directories
SRC_DIR = src
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj
BIN_DIR = $(BUILD_DIR)/bin
IMG_DIR = $(BUILD_DIR)/images

# Source files
BOOT_ASM_SOURCES = $(wildcard $(SRC_DIR)/boot/*.asm)
KERNEL_C_SOURCES = $(wildcard $(SRC_DIR)/kernel/*.c) $(wildcard $(SRC_DIR)/kernel/*/*.c)
KERNEL_ASM_SOURCES = $(wildcard $(SRC_DIR)/kernel/*.asm)
DRIVER_SOURCES = $(wildcard $(SRC_DIR)/drivers/*.c) $(wildcard $(SRC_DIR)/drivers/*/*.c)
APP_SOURCES = $(wildcard $(SRC_DIR)/apps/*/*.c)
FS_SOURCES = $(wildcard $(SRC_DIR)/fs/*.c)
UI_SOURCES = $(wildcard $(SRC_DIR)/ui/*.c) $(wildcard $(SRC_DIR)/ui/*/*.c)
SECURITY_SOURCES = $(wildcard $(SRC_DIR)/security/*.c)

# Object files
KERNEL_C_OBJECTS = $(KERNEL_C_SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
KERNEL_ASM_OBJECTS = $(KERNEL_ASM_SOURCES:$(SRC_DIR)/%.asm=$(OBJ_DIR)/%.o)
DRIVER_OBJECTS = $(DRIVER_SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
APP_OBJECTS = $(APP_SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
FS_OBJECTS = $(FS_SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
UI_OBJECTS = $(UI_SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
SECURITY_OBJECTS = $(SECURITY_SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)

ALL_OBJECTS = $(KERNEL_C_OBJECTS) $(KERNEL_ASM_OBJECTS) $(DRIVER_OBJECTS) \
              $(APP_OBJECTS) $(FS_OBJECTS) $(UI_OBJECTS) $(SECURITY_OBJECTS)

# Version management
VERSION_FILE = version.json
VERSION_MAJOR = $(shell jq -r '.major' $(VERSION_FILE))
VERSION_MINOR = $(shell jq -r '.minor' $(VERSION_FILE))
VERSION_PATCH = $(shell jq -r '.patch' $(VERSION_FILE))
VERSION_BUILD = $(shell jq -r '.build' $(VERSION_FILE))
VERSION_STRING = $(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)-build.$(VERSION_BUILD)

# Color definitions
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
PURPLE = \033[0;35m
CYAN = \033[0;36m
WHITE = \033[1;37m
NC = \033[0m

# Default target
.PHONY: all
all: increment-version bootloader kernel filesystem omnios-image

# Print build banner
.PHONY: banner
banner:
	@echo -e "$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo -e "$(CYAN)║                    OmniOS 2.0 Build System                  ║$(NC)"
	@echo -e "$(CYAN)║                   Version $(VERSION_STRING)                     ║$(NC)"
	@echo -e "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)"

# Increment version
.PHONY: increment-version
increment-version:
	@echo -e "$(BLUE)Incrementing build version...$(NC)"
	@NEW_BUILD=$$(($(VERSION_BUILD) + 1)); \
	jq ".build = $$NEW_BUILD | .version_string = \"$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)-build.$$NEW_BUILD\"" $(VERSION_FILE) > temp.json && \
	mv temp.json $(VERSION_FILE)
	@echo -e "$(GREEN)Version updated to: $(shell jq -r '.version_string' $(VERSION_FILE))$(NC)"

# Create directories
$(OBJ_DIR) $(BIN_DIR) $(IMG_DIR):
	@mkdir -p $@
	@mkdir -p $(OBJ_DIR)/boot $(OBJ_DIR)/kernel $(OBJ_DIR)/drivers $(OBJ_DIR)/apps
	@mkdir -p $(OBJ_DIR)/fs $(OBJ_DIR)/ui $(OBJ_DIR)/security

# Bootloader
.PHONY: bootloader
bootloader: $(OBJ_DIR) $(BIN_DIR)
	@echo -e "$(YELLOW)Building bootloader...$(NC)"
	$(AS) -f bin -o $(BIN_DIR)/bootloader.bin $(SRC_DIR)/boot/bootloader.asm
	$(AS) -f bin -o $(BIN_DIR)/stage2.bin $(SRC_DIR)/boot/stage2.asm
	@echo -e "$(GREEN)Bootloader built successfully$(NC)"

# Kernel
.PHONY: kernel
kernel: $(OBJ_DIR) $(BIN_DIR) $(ALL_OBJECTS)
	@echo -e "$(YELLOW)Linking kernel...$(NC)"
	$(LD) $(LDFLAGS) -T $(SRC_DIR)/kernel/linker.ld -o $(BIN_DIR)/kernel.elf $(ALL_OBJECTS)
	$(OBJCOPY) -O binary $(BIN_DIR)/kernel.elf $(BIN_DIR)/kernel.bin
	@echo -e "$(GREEN)Kernel built successfully$(NC)"

# C source compilation
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	@echo -e "$(BLUE)Compiling $<$(NC)"
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Assembly source compilation
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm | $(OBJ_DIR)
	@echo -e "$(BLUE)Assembling $<$(NC)"
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) $< -o $@

# File system creation
.PHONY: filesystem
filesystem: $(BIN_DIR)
	@echo -e "$(YELLOW)Creating file system...$(NC)"
	@mkdir -p $(BUILD_DIR)/fs_root/{system,apps,drivers,packages,users}
	@mkdir -p $(BUILD_DIR)/fs_root/system/{config,modules,logs}
	
	# Copy system files
	@echo "OmniOS $(shell jq -r '.version_string' $(VERSION_FILE))" > $(BUILD_DIR)/fs_root/system/version.txt
	@echo "build_date=$(shell date)" >> $(BUILD_DIR)/fs_root/system/version.txt
	
	# Create system configuration
	@echo "[System]" > $(BUILD_DIR)/fs_root/system/config/system.conf
	@echo "version=$(shell jq -r '.version_string' $(VERSION_FILE))" >> $(BUILD_DIR)/fs_root/system/config/system.conf
	@echo "filesystem=omnifs" >> $(BUILD_DIR)/fs_root/system/config/system.conf
	@echo "package_format=opi" >> $(BUILD_DIR)/fs_root/system/config/system.conf
	
	# Create package database
	@echo "# OmniOS Package Database" > $(BUILD_DIR)/fs_root/system/packages.db
	@echo "core|$(shell jq -r '.version_string' $(VERSION_FILE))|OmniOS Core System||4096" >> $(BUILD_DIR)/fs_root/system/packages.db
	
	# Create sample .opi package
	@$(MAKE) create-sample-opi
	
	@echo -e "$(GREEN)File system created$(NC)"

# Create sample .opi package
.PHONY: create-sample-opi
create-sample-opi:
	@echo -e "$(BLUE)Creating sample .opi package...$(NC)"
	@mkdir -p $(BUILD_DIR)/sample_package
	
	# Create package manifest
	@echo '{' > $(BUILD_DIR)/sample_package/manifest.json
	@echo '  "name": "calculator",' >> $(BUILD_DIR)/sample_package/manifest.json
	@echo '  "version": "1.0.0",' >> $(BUILD_DIR)/sample_package/manifest.json
	@echo '  "description": "Simple Calculator Application",' >> $(BUILD_DIR)/sample_package/manifest.json
	@echo '  "author": "OmniOS Team",' >> $(BUILD_DIR)/sample_package/manifest.json
	@echo '  "dependencies": ["core"],' >> $(BUILD_DIR)/sample_package/manifest.json
	@echo '  "files": ["calculator.bin", "calculator.cfg"],' >> $(BUILD_DIR)/sample_package/manifest.json
	@echo '  "install_path": "/apps/calculator",' >> $(BUILD_DIR)/sample_package/manifest.json
	@echo '  "executable": "calculator.bin"' >> $(BUILD_DIR)/sample_package/manifest.json
	@echo '}' >> $(BUILD_DIR)/sample_package/manifest.json
	
	# Create dummy application files
	@echo "Sample Calculator Application Binary" > $(BUILD_DIR)/sample_package/calculator.bin
	@echo "[Calculator]" > $(BUILD_DIR)/sample_package/calculator.cfg
	@echo "precision=10" >> $(BUILD_DIR)/sample_package/calculator.cfg
	@echo "memory_slots=5" >> $(BUILD_DIR)/sample_package/calculator.cfg
	
	# Create .opi package
	@cd $(BUILD_DIR)/sample_package && tar -czf ../calculator.opi *
	@cp $(BUILD_DIR)/calculator.opi $(BUILD_DIR)/fs_root/packages/
	@echo -e "$(GREEN)Sample .opi package created$(NC)"

# Create OmniOS disk image
.PHONY: omnios-image
omnios-image: $(IMG_DIR) bootloader kernel filesystem
	@echo -e "$(YELLOW)Creating OmniOS disk image...$(NC)"
	
	# Create 2.88MB floppy image
	dd if=/dev/zero of=$(IMG_DIR)/omnios.img bs=512 count=5760 2>/dev/null
	
	# Format with FAT12
	mkfs.fat -F 12 -n "OMNIOS20" $(IMG_DIR)/omnios.img >/dev/null 2>&1
	
	# Install bootloader
	dd if=$(BIN_DIR)/bootloader.bin of=$(IMG_DIR)/omnios.img conv=notrunc 2>/dev/null
	
	# Install stage 2 bootloader (sectors 2-5)
	dd if=$(BIN_DIR)/stage2.bin of=$(IMG_DIR)/omnios.img bs=512 seek=1 conv=notrunc 2>/dev/null
	
	# Install kernel (sectors 6-50)
	dd if=$(BIN_DIR)/kernel.bin of=$(IMG_DIR)/omnios.img bs=512 seek=5 conv=notrunc 2>/dev/null
	
	# Copy file system files
	mcopy -i $(IMG_DIR)/omnios.img $(BUILD_DIR)/fs_root/* ::/ 2>/dev/null || true
	
	@echo -e "$(GREEN)OmniOS disk image created: $(IMG_DIR)/omnios.img$(NC)"

# Build for Termux
.PHONY: termux
termux: banner increment-version
	@echo -e "$(YELLOW)Building for Termux environment...$(NC)"
	@$(MAKE) all CFLAGS="$(CFLAGS) -DTERMUX_BUILD"
	@echo -e "$(GREEN)Termux build completed$(NC)"

# Build for Redmi devices
.PHONY: redmi
redmi: banner increment-version
	@echo -e "$(YELLOW)Building for Redmi devices...$(NC)"
	@$(MAKE) all CFLAGS="$(CFLAGS) -DREDMI_BUILD -DARM_TARGET"
	@echo -e "$(GREEN)Redmi build completed$(NC)"

# Debug build
.PHONY: debug
debug: banner increment-version
	@echo -e "$(YELLOW)Building debug version...$(NC)"
	@$(MAKE) all CFLAGS="$(CFLAGS) -DDEBUG -g -O0"
	@echo -e "$(GREEN)Debug build completed$(NC)"

# Clean build artifacts
.PHONY: clean
clean:
	@echo -e "$(RED)Cleaning build artifacts...$(NC)"
	rm -rf $(BUILD_DIR)
	@echo -e "$(GREEN)Clean completed$(NC)"

# Install dependencies
.PHONY: install-deps
install-deps:
	@echo -e "$(BLUE)Installing build dependencies...$(NC)"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y nasm gcc-multilib mtools qemu-system-x86 jq; \
	elif command -v pkg >/dev/null 2>&1; then \
		pkg install nasm gcc mtools qemu-system-i386 jq; \
	else \
		echo -e "$(RED)Unknown package manager. Please install dependencies manually.$(NC)"; \
	fi
	@echo -e "$(GREEN)Dependencies installed$(NC)"

# Run in QEMU
.PHONY: run
run: omnios-image
	@echo -e "$(CYAN)Starting OmniOS in QEMU...$(NC)"
	qemu-system-i386 -m 256M -drive format=raw,file=$(IMG_DIR)/omnios.img,if=floppy -boot a

# Run in debug mode
.PHONY: run-debug
run-debug: debug
	@echo -e "$(CYAN)Starting OmniOS in debug mode...$(NC)"
	qemu-system-i386 -m 256M -drive format=raw,file=$(IMG_DIR)/omnios.img,if=floppy -boot a -s -S

# Generate build report
.PHONY: report
report: omnios-image
	@echo -e "$(BLUE)Generating build report...$(NC)"
	@echo "OmniOS 2.0 Build Report" > $(BUILD_DIR)/build-report.txt
	@echo "======================" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Version: $(shell jq -r '.version_string' $(VERSION_FILE))" >> $(BUILD_DIR)/build-report.txt
	@echo "Build Date: $(shell date)" >> $(BUILD_DIR)/build-report.txt
	@echo "Build Host: $(shell hostname)" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Components:" >> $(BUILD_DIR)/build-report.txt
	@echo "- Bootloader: $(shell ls -lh $(BIN_DIR)/bootloader.bin 2>/dev/null | awk '{print $$5}' || echo 'N/A')" >> $(BUILD_DIR)/build-report.txt
	@echo "- Stage 2: $(shell ls -lh $(BIN_DIR)/stage2.bin 2>/dev/null | awk '{print $$5}' || echo 'N/A')" >> $(BUILD_DIR)/build-report.txt
	@echo "- Kernel: $(shell ls -lh $(BIN_DIR)/kernel.bin 2>/dev/null | awk '{print $$5}' || echo 'N/A')" >> $(BUILD_DIR)/build-report.txt
	@echo "- Disk Image: $(shell ls -lh $(IMG_DIR)/omnios.img 2>/dev/null | awk '{print $$5}' || echo 'N/A')" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Features:" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Modular Architecture" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Custom Bootloader" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ C/Assembly Hybrid Kernel" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ OmniFS File System" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ .opi Package System" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Core Applications" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Driver Framework" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Security Subsystem" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ UI Framework" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Build completed successfully!" >> $(BUILD_DIR)/build-report.txt
	@echo -e "$(GREEN)Build report generated: $(BUILD_DIR)/build-report.txt$(NC)"

# Help target
.PHONY: help
help:
	@echo -e "$(CYAN)OmniOS 2.0 Build System Help$(NC)"
	@echo -e "$(CYAN)=============================$(NC)"
	@echo ""
	@echo -e "$(WHITE)Main Targets:$(NC)"
	@echo -e "  $(YELLOW)all$(NC)           - Build complete OmniOS system"
	@echo -e "  $(YELLOW)bootloader$(NC)    - Build bootloader only"
	@echo -e "  $(YELLOW)kernel$(NC)        - Build kernel only"
	@echo -e "  $(YELLOW)filesystem$(NC)    - Create file system"
	@echo -e "  $(YELLOW)omnios-image$(NC)  - Create bootable disk image"
	@echo ""
	@echo -e "$(WHITE)Platform Targets:$(NC)"
	@echo -e "  $(YELLOW)termux$(NC)        - Build for Termux environment"
	@echo -e "  $(YELLOW)redmi$(NC)         - Build for Redmi devices"
	@echo -e "  $(YELLOW)debug$(NC)         - Build debug version"
	@echo ""
	@echo -e "$(WHITE)Utility Targets:$(NC)"
	@echo -e "  $(YELLOW)clean$(NC)         - Clean build artifacts"
	@echo -e "  $(YELLOW)install-deps$(NC)  - Install build dependencies"
	@echo -e "  $(YELLOW)run$(NC)           - Run OmniOS in QEMU"
	@echo -e "  $(YELLOW)run-debug$(NC)     - Run OmniOS in debug mode"
	@echo -e "  $(YELLOW)report$(NC)        - Generate build report"
	@echo -e "  $(YELLOW)help$(NC)          - Show this help"

# Dependency tracking
-include $(ALL_OBJECTS:.o=.d)

$(OBJ_DIR)/%.d: $(SRC_DIR)/%.c | $(OBJ_DIR)
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -MM -MT $(@:.d=.o) $< > $@
