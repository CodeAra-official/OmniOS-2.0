# OmniOS 2.0 Enhanced Makefile
# Professional Operating System Build System

# Build configuration
ASM = nasm
ASMFLAGS = -f bin
BUILD_DIR = build
SRC_DIR = src

# Source files
BOOTLOADER_SRC = $(SRC_DIR)/boot/bootloader.asm
KERNEL_SRC = $(SRC_DIR)/kernel/kernel.asm

# Output files
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
OS_IMAGE = $(BUILD_DIR)/omnios.img

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
RED = \033[0;31m
NC = \033[0m

.PHONY: all clean run run-nographic run-text run-safe help install-deps check-updates

# Default target
all: $(OS_IMAGE)
	@echo -e "$(GREEN)OmniOS 2.0 build complete!$(NC)"

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Build bootloader
$(BOOTLOADER_BIN): $(BOOTLOADER_SRC) | $(BUILD_DIR)
	@echo -e "$(YELLOW)Building bootloader...$(NC)"
	$(ASM) $(ASMFLAGS) -o $@ $<
	@echo -e "$(GREEN)Bootloader built successfully$(NC)"

# Build kernel
$(KERNEL_BIN): $(KERNEL_SRC) | $(BUILD_DIR)
	@echo -e "$(YELLOW)Building kernel...$(NC)"
	$(ASM) $(ASMFLAGS) -o $@ $<
	@echo -e "$(GREEN)Kernel built successfully$(NC)"

# Create OS image
$(OS_IMAGE): $(BOOTLOADER_BIN) $(KERNEL_BIN)
	@echo -e "$(YELLOW)Creating OS image...$(NC)"
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	mkfs.fat -F 12 -n "OMNIOS20" $@ >/dev/null 2>&1
	dd if=$(BOOTLOADER_BIN) of=$@ conv=notrunc 2>/dev/null
	dd if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo -e "$(GREEN)OS image created successfully$(NC)"

# Run with GUI (default)
run: $(OS_IMAGE)
	@echo -e "$(BLUE)Starting OmniOS 2.0...$(NC)"
	qemu-system-i386 -drive format=raw,file=$(OS_IMAGE),if=floppy -boot a

# Run without graphics (curses interface)
run-nographic: $(OS_IMAGE)
	@echo -e "$(BLUE)Starting OmniOS 2.0 (text mode)...$(NC)"
	qemu-system-i386 -drive format=raw,file=$(OS_IMAGE),if=floppy -boot a -display curses

# Run in text mode
run-text: $(OS_IMAGE)
	@echo -e "$(BLUE)Starting OmniOS 2.0 (text only)...$(NC)"
	qemu-system-i386 -drive format=raw,file=$(OS_IMAGE),if=floppy -boot a -nographic

# Safe run (tries different display modes)
run-safe: $(OS_IMAGE)
	@echo -e "$(BLUE)Starting OmniOS 2.0 (safe mode)...$(NC)"
	@if command -v qemu-system-i386 >/dev/null 2>&1; then \
		qemu-system-i386 -drive format=raw,file=$(OS_IMAGE),if=floppy -boot a -display curses 2>/dev/null || \
		qemu-system-i386 -drive format=raw,file=$(OS_IMAGE),if=floppy -boot a -nographic; \
	else \
		echo -e "$(RED)QEMU not found. Please install qemu-system-x86$(NC)"; \
	fi

# Clean build files
clean:
	@echo -e "$(YELLOW)Cleaning build files...$(NC)"
	rm -rf $(BUILD_DIR)
	@echo -e "$(GREEN)Clean complete$(NC)"

# Install dependencies
install-deps:
	@echo -e "$(YELLOW)Installing dependencies...$(NC)"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y nasm mtools qemu-system-x86; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y nasm mtools qemu-system-x86; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S nasm mtools qemu; \
	else \
		echo -e "$(RED)Package manager not supported. Please install manually:$(NC)"; \
		echo "  - nasm (assembler)"; \
		echo "  - mtools (FAT filesystem tools)"; \
		echo "  - qemu-system-x86 (emulator)"; \
	fi

# Check for updates
check-updates:
	@echo -e "$(BLUE)Checking for updates...$(NC)"
	@./build.sh --check-updates

# Help
help:
	@echo -e "$(GREEN)OmniOS 2.0 Build System$(NC)"
	@echo ""
	@echo -e "$(YELLOW)Available targets:$(NC)"
	@echo "  all           - Build complete OS (default)"
	@echo "  clean         - Clean build files"
	@echo "  run           - Run OS with GUI"
	@echo "  run-nographic - Run OS with curses interface"
	@echo "  run-text      - Run OS in text mode"
	@echo "  run-safe      - Run OS (tries different display modes)"
	@echo "  install-deps  - Install build dependencies"
	@echo "  check-updates - Check for updates from GitHub"
	@echo "  help          - Show this help"
	@echo ""
	@echo -e "$(YELLOW)Examples:$(NC)"
	@echo "  make all && make run-safe"
	@echo "  make clean && make all"
	@echo "  make check-updates"
