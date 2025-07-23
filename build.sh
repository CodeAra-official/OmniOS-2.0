#!/bin/bash
# OmniOS 2.0 Enhanced Build Script with Update System

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    OmniOS 2.0 Build System                  ║"
echo "║                Enhanced Command Edition                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# GitHub repository
REPO_URL="https://github.com/CodeAra-official/OmniOS-2.0.git"
CURRENT_VERSION="2.0.0"

# Function to check for updates
check_updates() {
    echo -e "${BLUE}Checking for updates...${NC}"
    
    if command -v git &> /dev/null; then
        # Check if we're in a git repository
        if [ -d ".git" ]; then
            echo -e "${YELLOW}Fetching latest changes...${NC}"
            git fetch origin main 2>/dev/null
            
            # Check if there are updates
            LOCAL=$(git rev-parse HEAD)
            REMOTE=$(git rev-parse origin/main 2>/dev/null)
            
            if [ "$LOCAL" != "$REMOTE" ]; then
                echo -e "${GREEN}Updates available!${NC}"
                read -p "Do you want to update? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Updating OmniOS 2.0...${NC}"
                    git pull origin main
                    echo -e "${GREEN}Update completed!${NC}"
                    echo -e "${CYAN}Please run the build script again.${NC}"
                    exit 0
                fi
            else
                echo -e "${GREEN}You have the latest version!${NC}"
            fi
        else
            echo -e "${YELLOW}Not a git repository. Checking for manual updates...${NC}"
            echo -e "${CYAN}To get updates, clone from: ${REPO_URL}${NC}"
        fi
    else
        echo -e "${YELLOW}Git not found. Install git to enable automatic updates.${NC}"
        echo -e "${CYAN}Manual download: ${REPO_URL}${NC}"
    fi
}

# Function to download updates if not git repo
download_updates() {
    if [ ! -d ".git" ] && command -v curl &> /dev/null; then
        echo -e "${BLUE}Downloading latest version info...${NC}"
        
        # Try to get version info from GitHub API
        LATEST_VERSION=$(curl -s "https://api.github.com/repos/CodeAra-official/OmniOS-2.0/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' 2>/dev/null)
        
        if [ ! -z "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
            echo -e "${GREEN}New version available: ${LATEST_VERSION}${NC}"
            echo -e "${CYAN}Download from: ${REPO_URL}${NC}"
        fi
    fi
}

# Check dependencies
echo -e "${BLUE}Checking dependencies...${NC}"

MISSING_DEPS=()

if ! command -v nasm &> /dev/null; then
    MISSING_DEPS+=("nasm")
fi

if ! command -v mtools &> /dev/null; then
    MISSING_DEPS+=("mtools")
fi

if ! command -v qemu-system-i386 &> /dev/null; then
    echo -e "${YELLOW}Warning: QEMU not found${NC}"
    echo "Install with: sudo apt-get install qemu-system-x86"
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${RED}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo "Install with: sudo apt-get install ${MISSING_DEPS[*]}"
    exit 1
fi

echo -e "${GREEN}Dependencies OK${NC}"

# Check for updates if requested
if [ "$1" = "--check-updates" ] || [ "$1" = "-u" ]; then
    check_updates
    download_updates
fi

# Build system
echo -e "${BLUE}Building OmniOS 2.0 Enhanced Edition...${NC}"

# Create build directory
mkdir -p build
rm -rf build/*

# Build bootloader
echo -e "${YELLOW}Building bootloader...${NC}"
nasm -f bin -o build/bootloader.bin src/boot/bootloader.asm
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Bootloader built successfully${NC}"
    BOOTLOADER_SIZE=$(stat -c%s build/bootloader.bin)
    echo -e "${CYAN}Bootloader size: ${BOOTLOADER_SIZE} bytes${NC}"
    
    if [ $BOOTLOADER_SIZE -ne 512 ]; then
        echo -e "${YELLOW}Warning: Bootloader size is not 512 bytes${NC}"
    fi
else
    echo -e "${RED}Bootloader build failed${NC}"
    exit 1
fi

# Build enhanced kernel
echo -e "${YELLOW}Building enhanced kernel...${NC}"
nasm -f bin -o build/kernel.bin src/kernel/kernel.asm
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Enhanced kernel built successfully${NC}"
    KERNEL_SIZE=$(stat -c%s build/kernel.bin)
    echo -e "${CYAN}Kernel size: ${KERNEL_SIZE} bytes${NC}"
else
    echo -e "${RED}Kernel build failed${NC}"
    exit 1
fi

# Create floppy image
echo -e "${YELLOW}Creating disk image...${NC}"
dd if=/dev/zero of=build/omnios.img bs=512 count=2880 2>/dev/null
mkfs.fat -F 12 -n "OMNIOS20" build/omnios.img >/dev/null 2>&1

# Install bootloader
echo -e "${YELLOW}Installing bootloader...${NC}"
dd if=build/bootloader.bin of=build/omnios.img conv=notrunc 2>/dev/null

# Install kernel
echo -e "${YELLOW}Installing kernel...${NC}"
dd if=build/kernel.bin of=build/omnios.img bs=512 seek=1 conv=notrunc 2>/dev/null

echo -e "${GREEN}Disk image created successfully${NC}"

# Verify build
echo -e "${YELLOW}Verifying build...${NC}"
if [ -f "build/omnios.img" ]; then
    IMAGE_SIZE=$(stat -c%s build/omnios.img)
    if [ $IMAGE_SIZE -eq 1474560 ]; then
        echo -e "${GREEN}Build verification passed${NC}"
    else
        echo -e "${YELLOW}Warning: Image size unexpected (${IMAGE_SIZE} bytes)${NC}"
    fi
fi

# Show build summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                     BUILD SUCCESSFUL!                       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "${WHITE}Build Summary:${NC}"
echo -e "  Version: ${CURRENT_VERSION} Enhanced Command Edition"
echo -e "  Repository: ${REPO_URL}"
echo -e "  Bootloader: $(ls -lh build/bootloader.bin 2>/dev/null | awk '{print $5}' || echo 'N/A')"
echo -e "  Enhanced Kernel: $(ls -lh build/kernel.bin 2>/dev/null | awk '{print $5}' || echo 'N/A')"
echo -e "  Image: $(ls -lh build/omnios.img 2>/dev/null | awk '{print $5}' || echo 'N/A')"

echo ""
echo -e "${CYAN}Enhanced Command Set Available:${NC}"
echo -e "${WHITE}Basic Commands:${NC} help ls cd install open set admin exit off"
echo -e "${WHITE}File Operations:${NC} add delete move cut copy"
echo -e "${WHITE}Media/Network:${NC} play stop download go retry back"

echo ""
echo -e "${CYAN}To run OmniOS 2.0 Enhanced Edition:${NC}"
echo -e "  make run"
echo -e "  ./run-safe.sh"
echo -e "  qemu-system-i386 -drive format=raw,file=build/omnios.img,if=floppy -boot a"

echo ""
echo -e "${CYAN}Update Commands:${NC}"
echo -e "  ./build.sh --check-updates  # Check for updates"
echo -e "  ./build.sh -u              # Check for updates (short)"

# Auto-run if requested
if [ "$1" = "--run" ] || [ "$2" = "--run" ]; then
    echo ""
    echo -e "${CYAN}Starting OmniOS 2.0 Enhanced Edition...${NC}"
    if command -v qemu-system-i386 &> /dev/null; then
        qemu-system-i386 -drive format=raw,file=build/omnios.img,if=floppy -boot a -display curses
    else
        echo -e "${RED}QEMU not found. Please install qemu-system-x86${NC}"
    fi
fi
