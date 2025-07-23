#!/bin/bash

# OmniOS 2.0 Professional Build System
# Enhanced build script with comprehensive error handling and professional output

# Color codes for professional output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Professional header
print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}    OmniOS 2.0 Build System${NC}"
    echo -e "${WHITE}    Professional Edition${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Status messages
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
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
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_step "Checking build dependencies..."
    
    # Check for NASM
    if command -v nasm &> /dev/null; then
        NASM_VERSION=$(nasm -v)
        print_success "Found NASM: $NASM_VERSION"
    else
        print_error "NASM assembler not found. Please install nasm."
        exit 1
    fi
    
    # Check for QEMU (if --run flag is used)
    if [[ "$1" == "--run" ]]; then
        if command -v qemu-system-i386 &> /dev/null; then
            QEMU_VERSION=$(qemu-system-i386 --version | head -n1)
            print_success "Found QEMU: $QEMU_VERSION"
        else
            print_error "QEMU not found. Please install qemu-system-x86."
            exit 1
        fi
    fi
    
    # Check for dd utility
    if command -v dd &> /dev/null; then
        print_success "Found dd utility"
    else
        print_error "dd utility not found."
        exit 1
    fi
    
    print_success "All required dependencies found"
}

# Setup build environment
setup_build_env() {
    print_step "Setting up build environment..."
    
    # Clean and create build directory
    if [ -d "build" ]; then
        print_info "Cleaning existing build directory..."
        rm -rf build/*
    else
        mkdir -p build
    fi
    
    print_success "Build directory created: build"
}

# Verify source files exist
verify_sources() {
    print_step "Verifying source files..."
    
    # Check bootloader
    if [ -f "src/boot/bootloader.asm" ]; then
        LINES=$(wc -l < src/boot/bootloader.asm)
        print_success "Found: src/boot/bootloader.asm ($LINES lines)"
    else
        print_error "Bootloader source not found: src/boot/bootloader.asm"
        exit 1
    fi
    
    # Check kernel
    if [ -f "src/kernel/kernel.asm" ]; then
        LINES=$(wc -l < src/kernel/kernel.asm)
        print_success "Found: src/kernel/kernel.asm ($LINES lines)"
    else
        print_error "Kernel source not found: src/kernel/kernel.asm"
        exit 1
    fi
}

# Build bootloader
build_bootloader() {
    print_step "Building bootloader..."
    
    nasm -f bin -o build/bootloader.bin src/boot/bootloader.asm
    
    if [ $? -eq 0 ]; then
        BOOTLOADER_SIZE=$(stat -c%s build/bootloader.bin)
        print_success "Bootloader built successfully ($BOOTLOADER_SIZE bytes)"
        
        # Verify bootloader size (must be exactly 512 bytes)
        if [ $BOOTLOADER_SIZE -eq 512 ]; then
            print_success "Bootloader size verification passed"
        else
            print_error "Bootloader size is $BOOTLOADER_SIZE bytes, must be 512 bytes"
            exit 1
        fi
    else
        print_error "Failed to build bootloader"
        exit 1
    fi
}

# Build kernel
build_kernel() {
    print_step "Building kernel..."
    
    nasm -f bin -o build/kernel.bin src/kernel/kernel.asm
    
    if [ $? -eq 0 ]; then
        KERNEL_SIZE=$(stat -c%s build/kernel.bin)
        print_success "Kernel built successfully ($KERNEL_SIZE bytes)"
        
        # Calculate sectors used (512 bytes per sector)
        SECTORS=$((($KERNEL_SIZE + 511) / 512))
        print_info "Kernel uses $SECTORS sectors"
    else
        print_error "Failed to build kernel"
        exit 1
    fi
}

# Create OS image
create_image() {
    print_step "Creating OS image..."
    
    # Create 1.44MB floppy disk image
    dd if=/dev/zero of=build/omnios.img bs=1024 count=1440 &> /dev/null
    
    # Write bootloader to first sector
    dd if=build/bootloader.bin of=build/omnios.img bs=512 count=1 conv=notrunc &> /dev/null
    
    # Write kernel starting from sector 2
    dd if=build/kernel.bin of=build/omnios.img bs=512 seek=1 conv=notrunc &> /dev/null
    
    if [ $? -eq 0 ]; then
        IMAGE_SIZE=$(stat -c%s build/omnios.img)
        print_success "OS image created: build/omnios.img ($IMAGE_SIZE bytes)"
    else
        print_error "Failed to create OS image"
        exit 1
    fi
}

# Display build statistics
show_statistics() {
    print_step "Build Statistics:"
    
    BOOTLOADER_SIZE=$(stat -c%s build/bootloader.bin)
    KERNEL_SIZE=$(stat -c%s build/kernel.bin)
    IMAGE_SIZE=$(stat -c%s build/omnios.img)
    
    print_info "Bootloader: $BOOTLOADER_SIZE bytes"
    print_info "Kernel: $KERNEL_SIZE bytes ($(((KERNEL_SIZE + 511) / 512)) sectors)"
    print_info "Total image: $IMAGE_SIZE bytes"
    
    print_success "Build completed successfully!"
}

# Run OS in QEMU
run_os() {
    print_step "Starting OmniOS 2.0 in QEMU..."
    print_info "Starting QEMU with professional settings..."
    print_info "Press Ctrl+Alt+G to release mouse, Ctrl+Alt+Q to quit"
    
    # Try different display options for compatibility
    if command -v qemu-system-i386 &> /dev/null; then
        # Try SDL first, then VNC if that fails
        qemu-system-i386 -drive format=raw,file=build/omnios.img,index=0,if=floppy -m 16 -display sdl 2>/dev/null || \
        qemu-system-i386 -drive format=raw,file=build/omnios.img,index=0,if=floppy -m 16 -display vnc=:0 &
        
        if [ $? -ne 0 ]; then
            print_info "QEMU started with VNC display on localhost:5900"
            print_info "Connect with: vncviewer localhost:5900"
        fi
    else
        print_error "QEMU not available"
        exit 1
    fi
}

# Clean build artifacts
clean_build() {
    print_step "Cleaning build artifacts..."
    
    if [ -d "build" ]; then
        rm -rf build
        print_success "Build directory cleaned"
    else
        print_info "Build directory already clean"
    fi
}

# Main build function
main() {
    print_header
    
    case "$1" in
        "--clean")
            clean_build
            ;;
        "--run")
            check_dependencies "--run"
            setup_build_env
            verify_sources
            build_bootloader
            build_kernel
            create_image
            show_statistics
            run_os
            ;;
        "--help")
            echo "OmniOS 2.0 Build System Usage:"
            echo "  ./build.sh          - Build OS image"
            echo "  ./build.sh --run    - Build and run in QEMU"
            echo "  ./build.sh --clean  - Clean build artifacts"
            echo "  ./build.sh --help   - Show this help"
            ;;
        *)
            check_dependencies
            setup_build_env
            verify_sources
            build_bootloader
            build_kernel
            create_image
            show_statistics
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
