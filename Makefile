# OmniOS 2.0 Enhanced Build System
# Complete build system for enhanced kernel

# Build configuration
NASM = nasm
DD = dd
MKFS = mkfs.fat
MCOPY = mcopy
QEMU = qemu-system-i386

# Directories
SRC_DIR = src
BUILD_DIR = build
BOOT_DIR = $(SRC_DIR)/boot
KERNEL_DIR = $(SRC_DIR)/kernel

# Color definitions
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
CYAN = \033[0;36m
WHITE = \033[1;37m
NC = \033[0m

# Default target
.PHONY: all
all: banner clean setup bootloader kernel floppy

# Print build banner
.PHONY: banner
banner:
	@echo -e "$(CYAN)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo -e "$(CYAN)║                    OmniOS 2.0 Build System                  ║$(NC)"
	@echo -e "$(CYAN)║                Enhanced Command Edition                      ║$(NC)"
	@echo -e "$(CYAN)╚══════════════════════════════════════════════════════════════╝$(NC)"

# Create directories
.PHONY: setup
setup:
	@echo -e "$(BLUE)Setting up build environment...$(NC)"
	@mkdir -p $(BUILD_DIR)

# Bootloader
.PHONY: bootloader
bootloader: setup
	@echo -e "$(YELLOW)Building bootloader...$(NC)"
	$(NASM) -f bin -o $(BUILD_DIR)/bootloader.bin $(BOOT_DIR)/bootloader.asm
	@echo -e "$(GREEN)Bootloader built successfully$(NC)"

# Kernel
.PHONY: kernel
kernel: setup
	@echo -e "$(YELLOW)Building enhanced kernel...$(NC)"
	$(NASM) -f bin -o $(BUILD_DIR)/kernel.bin $(KERNEL_DIR)/kernel.asm
	@echo -e "$(GREEN)Enhanced kernel built successfully$(NC)"

# Create OmniOS disk image
.PHONY: floppy
floppy: bootloader kernel
	@echo -e "$(YELLOW)Creating OmniOS disk image...$(NC)"
	
	# Create 1.44MB floppy image
	$(DD) if=/dev/zero of=$(BUILD_DIR)/omnios.img bs=512 count=2880 2>/dev/null
	
	# Format with FAT12
	$(MKFS) -F 12 -n "OMNIOS20" $(BUILD_DIR)/omnios.img >/dev/null 2>&1
	
	# Install bootloader
	$(DD) if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/omnios.img conv=notrunc 2>/dev/null
	
	# Install kernel (starting at sector 2)
	$(DD) if=$(BUILD_DIR)/kernel.bin of=$(BUILD_DIR)/omnios.img bs=512 seek=1 conv=notrunc 2>/dev/null
	
	@echo -e "$(GREEN)OmniOS Enhanced Edition created: $(BUILD_DIR)/omnios.img$(NC)"

# Clean build artifacts
.PHONY: clean
clean:
	@echo -e "$(RED)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@echo -e "$(GREEN)Clean completed$(NC)"

# Install dependencies
.PHONY: install-deps
install-deps:
	@echo -e "$(BLUE)Installing build dependencies...$(NC)"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y nasm mtools qemu-system-x86; \
	elif command -v pkg >/dev/null 2>&1; then \
		pkg install nasm mtools qemu-system-i386; \
	else \
		echo -e "$(RED)Unknown package manager. Please install dependencies manually.$(NC)"; \
	fi
	@echo -e "$(GREEN)Dependencies installed$(NC)"

# Run in QEMU
.PHONY: run
run: all
	@echo -e "$(CYAN)Starting OmniOS 2.0 Enhanced Edition...$(NC)"
	@echo -e "$(WHITE)Available commands: help ls cd install open set admin exit off$(NC)"
	@echo -e "$(WHITE)File operations: add delete move cut copy$(NC)"
	@echo -e "$(WHITE)Media/Network: play stop download go retry back$(NC)"
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/omnios.img,if=floppy -boot a -display curses

# Run without graphics
.PHONY: run-nographic
run-nographic: all
	@echo -e "$(CYAN)Starting OmniOS 2.0 (text mode)...$(NC)"
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/omnios.img,if=floppy -boot a -nographic -serial mon:stdio

# Generate build report
.PHONY: report
report: all
	@echo -e "$(BLUE)Generating build report...$(NC)"
	@echo "OmniOS 2.0 Enhanced Edition Build Report" > $(BUILD_DIR)/build-report.txt
	@echo "=========================================" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Version: 2.0.0 Enhanced Command Edition" >> $(BUILD_DIR)/build-report.txt
	@echo "Build Date: $(shell date)" >> $(BUILD_DIR)/build-report.txt
	@echo "Build Host: $(shell hostname)" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Components:" >> $(BUILD_DIR)/build-report.txt
	@echo "- Bootloader: $(shell ls -lh $(BUILD_DIR)/bootloader.bin 2>/dev/null | awk '{print $$5}' || echo 'N/A')" >> $(BUILD_DIR)/build-report.txt
	@echo "- Enhanced Kernel: $(shell ls -lh $(BUILD_DIR)/kernel.bin 2>/dev/null | awk '{print $$5}' || echo 'N/A')" >> $(BUILD_DIR)/build-report.txt
	@echo "- Disk Image: $(shell ls -lh $(BUILD_DIR)/omnios.img 2>/dev/null | awk '{print $$5}' || echo 'N/A')" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Enhanced Features:" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Complete command set (20+ commands)" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ File operations (add, delete, move, cut, copy)" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Media player commands (play, stop)" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Network operations (download)" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Admin mode with privileges" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Professional color scheme" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Built-in applications (notepad, settings, files, terminal)" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ Enhanced file system with directory support" >> $(BUILD_DIR)/build-report.txt
	@echo "✓ System configuration management" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Available Commands:" >> $(BUILD_DIR)/build-report.txt
	@echo "- help: Show command reference" >> $(BUILD_DIR)/build-report.txt
	@echo "- ls: List files and directories" >> $(BUILD_DIR)/build-report.txt
	@echo "- cd: Change directory" >> $(BUILD_DIR)/build-report.txt
	@echo "- install: Install packages" >> $(BUILD_DIR)/build-report.txt
	@echo "- open: Open applications" >> $(BUILD_DIR)/build-report.txt
	@echo "- set: Configure system settings" >> $(BUILD_DIR)/build-report.txt
	@echo "- admin: Toggle admin mode" >> $(BUILD_DIR)/build-report.txt
	@echo "- exit: Exit applications" >> $(BUILD_DIR)/build-report.txt
	@echo "- off: Shutdown system" >> $(BUILD_DIR)/build-report.txt
	@echo "- retry: Retry last command" >> $(BUILD_DIR)/build-report.txt
	@echo "- back: Go back/parent directory" >> $(BUILD_DIR)/build-report.txt
	@echo "- go: Navigate to location" >> $(BUILD_DIR)/build-report.txt
	@echo "- download: Download files from URL" >> $(BUILD_DIR)/build-report.txt
	@echo "- play: Play media files" >> $(BUILD_DIR)/build-report.txt
	@echo "- stop: Stop media playback" >> $(BUILD_DIR)/build-report.txt
	@echo "- add: Add files/folders" >> $(BUILD_DIR)/build-report.txt
	@echo "- delete: Delete files/folders" >> $(BUILD_DIR)/build-report.txt
	@echo "- move: Move files/folders" >> $(BUILD_DIR)/build-report.txt
	@echo "- cut: Cut files to clipboard" >> $(BUILD_DIR)/build-report.txt
	@echo "- copy: Copy files to clipboard" >> $(BUILD_DIR)/build-report.txt
	@echo "" >> $(BUILD_DIR)/build-report.txt
	@echo "Build completed successfully!" >> $(BUILD_DIR)/build-report.txt
	@echo -e "$(GREEN)Build report generated: $(BUILD_DIR)/build-report.txt$(NC)"

# Help target
.PHONY: help
help:
	@echo -e "$(CYAN)OmniOS 2.0 Enhanced Build System Help$(NC)"
	@echo -e "$(CYAN)=====================================$(NC)"
	@echo ""
	@echo -e "$(WHITE)Main Targets:$(NC)"
	@echo -e "  $(YELLOW)all$(NC)           - Build complete OmniOS Enhanced Edition"
	@echo -e "  $(YELLOW)bootloader$(NC)    - Build bootloader only"
	@echo -e "  $(YELLOW)kernel$(NC)        - Build enhanced kernel only"
	@echo -e "  $(YELLOW)floppy$(NC)        - Create bootable disk image"
	@echo ""
	@echo -e "$(WHITE)Utility Targets:$(NC)"
	@echo -e "  $(YELLOW)clean$(NC)         - Clean build artifacts"
	@echo -e "  $(YELLOW)install-deps$(NC)  - Install build dependencies"
	@echo -e "  $(YELLOW)run$(NC)           - Run OmniOS in QEMU"
	@echo -e "  $(YELLOW)run-nographic$(NC) - Run OmniOS in text mode"
	@echo -e "  $(YELLOW)report$(NC)        - Generate detailed build report"
	@echo -e "  $(YELLOW)help$(NC)          - Show this help"
	@echo ""
	@echo -e "$(WHITE)Enhanced Commands Available in OmniOS:$(NC)"
	@echo -e "  $(GREEN)Basic:$(NC) help ls cd open exit off"
	@echo -e "  $(GREEN)Files:$(NC) add delete move cut copy"
	@echo -e "  $(GREEN)System:$(NC) set admin install retry back"
	@echo -e "  $(GREEN)Media:$(NC) play stop"
	@echo -e "  $(GREEN)Network:$(NC) download go"
