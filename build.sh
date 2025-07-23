#!/bin/bash

# OmniOS 2.0 Enhanced Build System
# Professional build script with color-coded output and comprehensive features

# Color definitions for professional output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Build configuration
BUILD_DIR="build"
SRC_DIR="src"
KERNEL_SRC="$SRC_DIR/kernel/kernel.asm"
BOOTLOADER_SRC="$SRC_DIR/boot/bootloader.asm"
KERNEL_BIN="$BUILD_DIR/kernel.bin"
BOOTLOADER_BIN="$BUILD_DIR/bootloader.bin"
OS_IMAGE="$BUILD_DIR/omnios.img"

# Function to print colored output
print_header() {
    echo -e "${BOLD}${BLUE}================================${NC}"
    echo -e "${BOLD}${BLUE}    OmniOS 2.0 Build System    ${NC}"
    echo -e "${BOLD}${BLUE}    Professional Edition       ${NC}"
    echo -e "${BOLD}${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Function to check dependencies
check_dependencies() {
    print_step "Checking build dependencies..."
    
    local missing_deps=()
    
    # Check for NASM
    if ! command -v nasm &> /dev/null; then
        missing_deps+=("nasm")
    else
        print_success "Found NASM: $(nasm -v)"
    fi
    
    # Check for QEMU (optional)
    if ! command -v qemu-system-i386 &> /dev/null; then
        print_warning "QEMU not found - OS testing will not be available"
    else
        print_success "Found QEMU: $(qemu-system-i386 --version | head -n1)"
    fi
    
    # Check for dd
    if ! command -v dd &> /dev/null; then
        missing_deps+=("dd")
    else
        print_success "Found dd utility"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install missing dependencies and try again"
        exit 1
    fi
    
    print_success "All required dependencies found"
}

# Function to create build directory
create_build_dir() {
    print_step "Setting up build environment..."
    
    if [ -d "$BUILD_DIR" ]; then
        print_info "Cleaning existing build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    print_success "Build directory created: $BUILD_DIR"
}

# Function to verify source files
verify_sources() {
    print_step "Verifying source files..."
    
    local required_files=(
        "$BOOTLOADER_SRC"
        "$KERNEL_SRC"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Found: $file ($(wc -l < "$file") lines)"
        else
            print_error "Missing required file: $file"
            exit 1
        fi
    done
}

# Function to build bootloader
build_bootloader() {
    print_step "Building bootloader..."
    
    if nasm -f bin -o "$BOOTLOADER_BIN" "$BOOTLOADER_SRC"; then
        local size=$(stat -c%s "$BOOTLOADER_BIN")
        print_success "Bootloader built successfully ($size bytes)"
        
        # Verify bootloader size (should be exactly 512 bytes)
        if [ $size -eq 512 ]; then
            print_success "Bootloader size verification passed"
        else
            print_warning "Bootloader size is $size bytes (expected 512 bytes)"
        fi
    else
        print_error "Failed to build bootloader"
        exit 1
    fi
}

# Function to build kernel
build_kernel() {
    print_step "Building kernel..."
    
    if nasm -f bin -o "$KERNEL_BIN" "$KERNEL_SRC"; then
        local size=$(stat -c%s "$KERNEL_BIN")
        print_success "Kernel built successfully ($size bytes)"
        
        # Calculate sectors used
        local sectors=$((($size + 511) / 512))
        print_info "Kernel uses $sectors sectors"
    else
        print_error "Failed to build kernel"
        exit 1
    fi
}

# Function to create OS image
create_image() {
    print_step "Creating OS image..."
    
    # Create 1.44MB floppy disk image
    dd if=/dev/zero of="$OS_IMAGE" bs=512 count=2880 status=none
    
    # Write bootloader to first sector
    dd if="$BOOTLOADER_BIN" of="$OS_IMAGE" bs=512 count=1 conv=notrunc status=none
    
    # Write kernel starting from sector 2
    dd if="$KERNEL_BIN" of="$OS_IMAGE" bs=512 seek=1 conv=notrunc status=none
    
    local size=$(stat -c%s "$OS_IMAGE")
    print_success "OS image created: $OS_IMAGE ($size bytes)"
}

# Function to run OS in QEMU
run_os() {
    print_step "Starting OmniOS 2.0 in QEMU..."
    
    if [ ! -f "$OS_IMAGE" ]; then
        print_error "OS image not found. Build first with: $0"
        exit 1
    fi
    
    print_info "Starting QEMU with professional settings..."
    print_info "Press Ctrl+Alt+G to release mouse, Ctrl+Alt+Q to quit"
    
    # Try different display options based on environment
    if [ -n "$DISPLAY" ]; then
        # X11 available, try GTK first, fallback to SDL
        qemu-system-i386 \
            -drive format=raw,file="$OS_IMAGE",if=floppy \
            -boot a \
            -m 16M \
            -display gtk \
            -name "OmniOS 2.0 Professional Edition" \
            -rtc base=localtime \
            -no-reboot \
            -monitor stdio 2>/dev/null || \
        qemu-system-i386 \
            -drive format=raw,file="$OS_IMAGE",if=floppy \
            -boot a \
            -m 16M \
            -display sdl \
            -name "OmniOS 2.0 Professional Edition" \
            -rtc base=localtime \
            -no-reboot \
            -monitor stdio
    else
        # No display available, use VNC or curses
        print_info "No display detected, starting with VNC on port 5900"
        print_info "Connect with: vncviewer localhost:5900"
        qemu-system-i386 \
            -drive format=raw,file="$OS_IMAGE",if=floppy \
            -boot a \
            -m 16M \
            -display vnc=:0 \
            -name "OmniOS 2.0 Professional Edition" \
            -rtc base=localtime \
            -no-reboot \
            -monitor stdio
    fi
}

# Function to show build statistics
show_statistics() {
    print_step "Build Statistics:"
    
    if [ -f "$BOOTLOADER_BIN" ]; then
        local boot_size=$(stat -c%s "$BOOTLOADER_BIN")
        print_info "Bootloader: $boot_size bytes"
    fi
    
    if [ -f "$KERNEL_BIN" ]; then
        local kernel_size=$(stat -c%s "$KERNEL_BIN")
        local kernel_sectors=$((($kernel_size + 511) / 512))
        print_info "Kernel: $kernel_size bytes ($kernel_sectors sectors)"
    fi
    
    if [ -f "$OS_IMAGE" ]; then
        local image_size=$(stat -c%s "$OS_IMAGE")
        print_info "Total image: $image_size bytes"
    fi
    
    print_success "Build completed successfully!"
}

# Function to clean build artifacts
clean_build() {
    print_step "Cleaning build artifacts..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "Build directory cleaned"
    else
        print_info "Build directory already clean"
    fi
}

# Function to show help
show_help() {
    echo -e "${BOLD}OmniOS 2.0 Build System - Usage:${NC}"
    echo ""
    echo -e "${CYAN}$0${NC}                 - Build the complete OS"
    echo -e "${CYAN}$0 --run${NC}           - Build and run OS in QEMU"
    echo -e "${CYAN}$0 --clean${NC}         - Clean build artifacts"
    echo -e "${CYAN}$0 --help${NC}          - Show this help message"
    echo -e "${CYAN}$0 --bootloader${NC}    - Build only bootloader"
    echo -e "${CYAN}$0 --kernel${NC}        - Build only kernel"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  $0                    # Full build"
    echo -e "  $0 --run              # Build and test"
    echo -e "  $0 --clean            # Clean up"
    echo ""
}

# Main build function
main_build() {
    print_header
    check_dependencies
    create_build_dir
    verify_sources
    build_bootloader
    build_kernel
    create_image
    show_statistics
}

# Parse command line arguments
case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    --clean)
        clean_build
        exit 0
        ;;
    --run)
        main_build
        run_os
        exit 0
        ;;
    --bootloader)
        print_header
        check_dependencies
        create_build_dir
        verify_sources
        build_bootloader
        exit 0
        ;;
    --kernel)
        print_header
        check_dependencies
        create_build_dir
        verify_sources
        build_kernel
        exit 0
        ;;
    "")
        main_build
        exit 0
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
