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

ERRORS=0

# Check if build directory exists
if [ ! -d "build" ]; then
    echo -e "${RED}❌ Build directory not found${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ Build directory exists${NC}"
fi

echo -e "${BLUE}Checking build components...${NC}"

# Check bootloader
if [ ! -f "build/bootloader.bin" ]; then
    echo -e "${RED}❌ Bootloader binary not found${NC}"
    ERRORS=$((ERRORS + 1))
else
    BOOTLOADER_SIZE=$(stat -c%s build/bootloader.bin)
    if [ $BOOTLOADER_SIZE -eq 512 ]; then
        echo -e "${GREEN}✅ Bootloader size correct (512 bytes)${NC}"
    else
        echo -e "${YELLOW}⚠️  Bootloader size: ${BOOTLOADER_SIZE} bytes (expected 512)${NC}"
    fi
    
    # Check boot signature
    SIGNATURE=$(xxd -s 510 -l 2 -p build/bootloader.bin)
    if [ "$SIGNATURE" = "55aa" ]; then
        echo -e "${GREEN}✅ Boot signature correct${NC}"
    else
        echo -e "${RED}❌ Invalid boot signature: $SIGNATURE${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check kernel
if [ ! -f "build/kernel.bin" ]; then
    echo -e "${RED}❌ Kernel binary not found${NC}"
    ERRORS=$((ERRORS + 1))
else
    KERNEL_SIZE=$(stat -c%s build/kernel.bin)
    echo -e "${GREEN}✅ Kernel binary exists (${KERNEL_SIZE} bytes)${NC}"
    
    if [ $KERNEL_SIZE -gt 0 ]; then
        echo -e "${GREEN}✅ Kernel has content${NC}"
    else
        echo -e "${RED}❌ Kernel is empty${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check OS image
if [ ! -f "build/omnios.img" ]; then
    echo -e "${RED}❌ OS image not found${NC}"
    ERRORS=$((ERRORS + 1))
else
    IMAGE_SIZE=$(stat -c%s build/omnios.img)
    if [ $IMAGE_SIZE -eq 1474560 ]; then
        echo -e "${GREEN}✅ OS image size correct (1.44MB)${NC}"
    else
        echo -e "${YELLOW}⚠️  OS image size: ${IMAGE_SIZE} bytes (expected 1474560)${NC}"
    fi
fi

# Check dependencies
echo -e "${BLUE}Checking runtime dependencies...${NC}"

if command -v qemu-system-i386 &> /dev/null; then
    echo -e "${GREEN}✅ QEMU available${NC}"
else
    echo -e "${YELLOW}⚠️  QEMU not found (install qemu-system-x86)${NC}"
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  BUILD VERIFICATION PASSED                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}✅ All checks passed! OmniOS 2.0 is ready to run.${NC}"
    echo ""
    echo -e "${BLUE}To run OmniOS 2.0:${NC}"
    echo "  make run-safe"
    echo "  ./run-safe.sh"
    exit 0
else
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                  BUILD VERIFICATION FAILED                  ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${RED}❌ Found ${ERRORS} error(s). Please rebuild.${NC}"
    echo ""
    echo -e "${BLUE}To rebuild:${NC}"
    echo "  make clean"
    echo "  make all"
    exit 1
fi
