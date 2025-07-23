#!/bin/bash

# OmniOS 2.0 Enhanced Build System with GitHub Integration
# Includes automatic updates from official repository

REPO_URL="https://github.com/CodeAra-official/OmniOS-2.0.git"
VERSION_FILE="version.json"
BUILD_DIR="build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display banner
display_banner() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    OmniOS 2.0 Build System                  ║"
    echo "║                Enhanced Command Edition                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Function to check for updates
check_updates() {
    print_status "Checking for updates from GitHub..."
    
    if [ ! -d ".git" ]; then
        print_warning "Not a git repository. Initializing..."
        git init
        git remote add origin $REPO_URL
    fi
    
    # Fetch latest changes
    git fetch origin main 2>/dev/null
    
    if [ $? -eq 0 ]; then
        LOCAL_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "none")
        REMOTE_COMMIT=$(git rev-parse origin/main 2>/dev/null || echo "none")
        
        if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
            print_warning "Updates available!"
            echo "Local:  $LOCAL_COMMIT"
            echo "Remote: $REMOTE_COMMIT"
            echo ""
            read -p "Do you want to update? (y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_status "Updating from GitHub..."
                git pull origin main
                print_success "Update completed!"
                return 0
            fi
        else
            print_success "Already up to date!"
        fi
    else
        print_warning "Could not check for updates (network/repo issue)"
    fi
    
    return 1
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check for required tools
    MISSING_DEPS=""
    
    if ! command -v nasm &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS nasm"
    fi
    
    if ! command -v qemu-system-i386 &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS qemu-system-i386"
    fi
    
    if ! command -v dd &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS dd"
    fi
    
    if [ -n "$MISSING_DEPS" ]; then
        print_error "Missing dependencies:$MISSING_DEPS"
        print_status "Please install missing dependencies and try again."
        exit 1
    fi
    
    print_success "Dependencies OK"
}

# Function to build the system
build_system() {
    print_status "Building OmniOS 2.0 Enhanced Edition..."
    
    # Create build directory
    mkdir -p $BUILD_DIR
    
    # Build bootloader
    print_status "Building bootloader..."
    nasm -f bin src/boot/bootloader.asm -o $BUILD_DIR/bootloader.bin
    if [ $? -ne 0 ]; then
        print_error "Bootloader build failed"
        exit 1
    fi
    print_success "Bootloader built successfully"
    
    # Build kernel
    print_status "Building kernel..."
    nasm -f bin src/kernel/kernel.asm -o $BUILD_DIR/kernel.bin
    if [ $? -ne 0 ]; then
        print_error "Kernel build failed"
        exit 1
    fi
    print_success "Kernel built successfully"
    
    # Create disk image
    print_status "Creating disk image..."
    dd if=/dev/zero of=$BUILD_DIR/omnios.img bs=1024 count=1440 2>/dev/null
    dd if=$BUILD_DIR/bootloader.bin of=$BUILD_DIR/omnios.img bs=512 count=1 conv=notrunc 2>/dev/null
    dd if=$BUILD_DIR/kernel.bin of=$BUILD_DIR/omnios.img bs=512 seek=1 conv=notrunc 2>/dev/null
    
    print_success "Disk image created: $BUILD_DIR/omnios.img"
}

# Function to run the system
run_system() {
    if [ ! -f "$BUILD_DIR/omnios.img" ]; then
        print_error "Disk image not found. Please build first."
        exit 1
    fi
    
    print_status "Starting OmniOS 2.0..."
    print_status "Use Ctrl+Alt+G to release mouse, Ctrl+Alt+Q to quit"
    
    qemu-system-i386 -drive format=raw,file=$BUILD_DIR/omnios.img -m 64M -display curses 2>/dev/null || \
    qemu-system-i386 -drive format=raw,file=$BUILD_DIR/omnios.img -m 64M -nographic
}

# Function to clean build files
clean_build() {
    print_status "Cleaning build files..."
    rm -rf $BUILD_DIR
    print_success "Build files cleaned"
}

# Main script logic
display_banner

case "$1" in
    --check-updates)
        check_updates
        ;;
    --clean)
        clean_build
        ;;
    --run)
        run_system
        ;;
    --build)
        check_dependencies
        build_system
        ;;
    *)
        # Default: check updates, then build
        if [ "$1" != "--no-update" ]; then
            check_updates
        fi
        
        check_dependencies
        build_system
        
        if [ "$1" == "--run" ] || [ -z "$1" ]; then
            echo ""
            read -p "Do you want to run OmniOS now? (y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                run_system
            fi
        fi
        ;;
esac

print_success "Build process completed!"
