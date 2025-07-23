#!/bin/bash
# OmniOS 2.0 Build Verification Script

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                OmniOS 2.0 Build Verification                ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if build directory exists
if [ ! -d "build" ]; then
    echo -e "${RED}Build directory not found!${NC}"
    echo "Run './build.sh' first"
    exit 1
fi

echo -e "${BLUE}Checking build components...${NC}"

# Check bootloader
if [ -f "build/bootloader.bin" ]; then
    BOOTLOADER_SIZE=$(stat -c%s "build/bootloader.bin")
    if [ $BOOTLOADER_SIZE -eq 512 ]; then
        echo -e "${GREEN}✓ Bootloader: $BOOTLOADER_SIZE bytes (correct size)${NC}"
    else
        echo -e "${YELLOW}⚠ Bootloader: $BOOTLOADER_SIZE bytes (expected 512)${NC}"
    fi
else
    echo -e "${RED}✗ Bootloader not found!${NC}"
    exit 1
fi

# Check kernel
if [ -f "build/kernel.bin" ]; then
    KERNEL_SIZE=$(stat -c%s "build/kernel.bin")
    echo -e "${GREEN}✓ Kernel: $KERNEL_SIZE bytes${NC}"
    
    # Check if kernel is not empty
    if [ $KERNEL_SIZE -gt 0 ]; then
        echo -e "${GREEN}✓ Kernel has content${NC}"
    else
        echo -e "${RED}✗ Kernel is empty!${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Kernel not found!${NC}"
    exit 1
fi

# Check disk image
if [ -f "build/omnios.img" ]; then
    IMAGE_SIZE=$(stat -c%s "build/omnios.img")
    EXPECTED_SIZE=$((2880 * 512))  # 1.44MB
    
    if [ $IMAGE_SIZE -eq $EXPECTED_SIZE ]; then
        echo -e "${GREEN}✓ Disk image: $IMAGE_SIZE bytes (1.44MB floppy)${NC}"
    else
        echo -e "${YELLOW}⚠ Disk image: $IMAGE_SIZE bytes (expected $EXPECTED_SIZE)${NC}"
    fi
    
    # Check boot signature
    BOOT_SIG=$(xxd -s 510 -l 2 -p build/omnios.img)
    if [ "$BOOT_SIG" = "55aa" ]; then
        echo -e "${GREEN}✓ Boot signature present${NC}"
    else
        echo -e "${RED}✗ Invalid boot signature: $BOOT_SIG${NC}"
    fi
else
    echo -e "${RED}✗ Disk image not found!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Build verification completed successfully!${NC}"
echo ""
echo -e "${BLUE}To run OmniOS 2.0:${NC}"
echo -e "  ./run-safe.sh    (recommended)"
echo -e "  ./run-text.sh    (text mode only)"
echo -e "  make run         (standard)"
