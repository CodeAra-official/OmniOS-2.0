#!/bin/bash
# OmniOS 2.0 Enhanced Build Script

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    OmniOS 2.0 Build System                  ║"
echo "║                   Professional Edition                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check dependencies
echo -e "${BLUE}Checking dependencies...${NC}"

if ! command -v nasm &> /dev/null; then
    echo -e "${RED}Error: NASM not found${NC}"
    echo "Install with: sudo apt-get install nasm"
    exit 1
fi

if ! command -v qemu-system-i386 &> /dev/null; then
    echo -e "${YELLOW}Warning: QEMU not found${NC}"
    echo "Install with: sudo apt-get install qemu-system-x86"
fi

if ! command -v mtools &> /dev/null; then
    echo -e "${RED}Error: mtools not found${NC}"
    echo "Install with: sudo apt-get install mtools"
    exit 1
fi

echo -e "${GREEN}Dependencies OK${NC}"

# Build system
echo -e "${BLUE}Building OmniOS 2.0...${NC}"

# Create build directory
mkdir -p build

# Create missing files and directories
echo "Creating required files..."
echo "This is a test file for OmniOS 2.0" > build/test.txt
mkdir -p build/system
echo "OmniOS System Files" > build/system/readme.txt

# Build bootloader
echo -e "${YELLOW}Building bootloader...${NC}"
nasm -f bin -o build/bootloader.bin src/boot/bootloader.asm
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Bootloader built successfully${NC}"
else
    echo -e "${RED}Bootloader build failed${NC}"
    exit 1
fi

# Build kernel
echo -e "${YELLOW}Building kernel...${NC}"
nasm -f bin -o build/kernel.bin src/kernel/kernel.asm
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Kernel built successfully${NC}"
else
    echo -e "${RED}Kernel build failed${NC}"
    exit 1
fi

# Create floppy image
echo -e "${YELLOW}Creating disk image...${NC}"
dd if=/dev/zero of=build/omnios.img bs=512 count=2880 2>/dev/null
mkfs.fat -F 12 -n "OMNIOS20" build/omnios.img >/dev/null 2>&1

# Install bootloader
dd if=build/bootloader.bin of=build/omnios.img conv=notrunc 2>/dev/null

# Install kernel
dd if=build/kernel.bin of=build/omnios.img bs=512 seek=1 conv=notrunc 2>/dev/null

echo -e "${GREEN}Disk image created successfully${NC}"

# Show build summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                     BUILD SUCCESSFUL!                       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "${WHITE}Build Summary:${NC}"
echo -e "  Version: 2.0.0"
echo -e "  Bootloader: $(ls -lh build/bootloader.bin 2>/dev/null | awk '{print $5}' || echo 'N/A')"
echo -e "  Kernel: $(ls -lh build/kernel.bin 2>/dev/null | awk '{print $5}' || echo 'N/A')"
echo -e "  Image: $(ls -lh build/omnios.img 2>/dev/null | awk '{print $5}' || echo 'N/A')"

echo ""
echo -e "${CYAN}To run OmniOS 2.0:${NC}"
echo -e "  make run"
echo -e "  or"
echo -e "  qemu-system-i386 -fda build/omnios.img -boot a"

# Auto-run if requested
if [ "$1" = "--run" ]; then
    echo ""
    echo -e "${CYAN}Starting OmniOS 2.0...${NC}"
    qemu-system-i386 -fda build/omnios.img -boot a
fi
