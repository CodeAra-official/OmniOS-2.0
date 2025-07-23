# OmniOS 2.0 Enhanced Build System
# Fixed Makefile with proper assembly and disk creation

ASM = nasm
ASMFLAGS = -f bin
BUILD_DIR = build
SRC_DIR = src

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
RED = \033[0;31m
NC = \033[0m

.PHONY: all clean run run-safe help

all: $(BUILD_DIR)/omnios.img
	@echo -e "$(GREEN)OmniOS 2.0 build complete!$(NC)"

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/bootloader.bin: $(SRC_DIR)/boot/bootloader.asm | $(BUILD_DIR)
	@echo -e "$(YELLOW)Building bootloader...$(NC)"
	$(ASM) $(ASMFLAGS) -o $@ $<
	@echo -e "$(GREEN)Bootloader built successfully$(NC)"

$(BUILD_DIR)/kernel.bin: $(SRC_DIR)/kernel/kernel.asm | $(BUILD_DIR)
	@echo -e "$(YELLOW)Building kernel...$(NC)"
	$(ASM) $(ASMFLAGS) -o $@ $<
	@echo -e "$(GREEN)Kernel built successfully$(NC)"

$(BUILD_DIR)/omnios.img: $(BUILD_DIR)/bootloader.bin $(BUILD_DIR)/kernel.bin
	@echo -e "$(YELLOW)Creating disk image...$(NC)"
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=$(BUILD_DIR)/bootloader.bin of=$@ conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/kernel.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo -e "$(GREEN)Disk image created: $@$(NC)"

clean:
	@echo -e "$(YELLOW)Cleaning build files...$(NC)"
	rm -rf $(BUILD_DIR)
	@echo -e "$(GREEN)Clean complete$(NC)"

run: $(BUILD_DIR)/omnios.img
	@echo -e "$(BLUE)Starting OmniOS 2.0...$(NC)"
	qemu-system-i386 -drive format=raw,file=$<,if=floppy -boot a

run-safe: $(BUILD_DIR)/omnios.img
	@echo -e "$(BLUE)Starting OmniOS 2.0 (safe mode)...$(NC)"
	qemu-system-i386 -drive format=raw,file=$<,if=floppy -boot a -display curses 2>/dev/null || \
	qemu-system-i386 -drive format=raw,file=$<,if=floppy -boot a -nographic

help:
	@echo -e "$(GREEN)OmniOS 2.0 Build System$(NC)"
	@echo ""
	@echo -e "$(YELLOW)Available targets:$(NC)"
	@echo "  all      - Build complete OS"
	@echo "  clean    - Clean build files"
	@echo "  run      - Run OS in QEMU"
	@echo "  run-safe - Run OS (fallback modes)"
	@echo "  help     - Show this help"
