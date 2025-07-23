#!/bin/bash

# OmniOS 2.0 Build Verification Script
# Verifies that the build completed successfully

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}OmniOS 2.0 Build Verification${NC}"
echo "============================="

# Check if build directory exists
if [ ! -d "build" ]; then
    echo -e "${RED}Build directory not found!${NC}"
    echo "Please run 'make all' first."
    exit 1
fi

# Check bootloader
if [ ! -f "build/bootloader.bin" ]; then
    echo -e "${RED}Bootloader not found!${NC}"
    exit 1
else
    BOOTLOADER_SIZE=$(stat -c%s "build/bootloader.bin")
    if [ "$BOOTLOADER_SIZE" -eq 512 ]; then
        echo -e "${GREEN}✓ Bootloader: OK (512 bytes)${NC}"
    else
        echo -e "${YELLOW}⚠ Bootloader: Size is $BOOTLOADER_SIZE bytes (expected 512)${NC}"
    fi
fi

# Check kernel
if [ ! -f "build/kernel.bin" ]; then
    echo -e "${RED}Kernel not found!${NC}"
    exit 1
else
    KERNEL_SIZE=$(stat -c%s "build/kernel.bin")
    echo -e "${GREEN}✓ Kernel: OK ($KERNEL_SIZE bytes)${NC}"
fi

# Check disk image
if [ ! -f "build/omnios.img" ]; then
    echo -e "${RED}Disk image not found!${NC}"
    exit 1
else
    IMAGE_SIZE=$(stat -c%s "build/omnios.img")
    if [ "$IMAGE_SIZE" -eq 1474560 ]; then
        echo -e "${GREEN}✓ Disk Image: OK (1.44MB floppy)${NC}"
    else
        echo -e "${YELLOW}⚠ Disk Image: Size is $IMAGE_SIZE bytes${NC}"
    fi
fi

# Verify bootloader signature
echo -e "${BLUE}Verifying bootloader signature...${NC}"
SIGNATURE=$(xxd -s 510 -l 2 -p build/bootloader.bin)
if [ "$SIGNATURE" = "55aa" ]; then
    echo -e "${GREEN}✓ Boot signature: Valid (0x55AA)${NC}"
else
    echo -e "${RED}✗ Boot signature: Invalid ($SIGNATURE)${NC}"
    exit 1
fi

# Check if image has bootloader installed
echo -e "${BLUE}Verifying disk image...${NC}"
IMG_SIGNATURE=$(xxd -s 510 -l 2 -p build/omnios.img)
if [ "$IMG_SIGNATURE" = "55aa" ]; then
    echo -e "${GREEN}✓ Disk image bootable: Yes${NC}"
else
    echo -e "${RED}✗ Disk image bootable: No${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}All verification checks passed!${NC}"
echo -e "${BLUE}OmniOS 2.0 is ready to run.${NC}"

echo ""
echo -e "${YELLOW}To run OmniOS 2.0:${NC}"
echo "  make run-safe    # Safe mode with fallback"
echo "  make run         # Standard mode"
echo "  ./run-text.sh    # Text mode only"
