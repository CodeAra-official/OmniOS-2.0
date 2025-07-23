#!/bin/bash

# OmniOS 2.0 Professional Build System
# Enhanced build script with comprehensive features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Build configuration
BUILD_DIR="build"
BOOTLOADER_SRC="src/boot/bootloader.asm"
KERNEL_SRC="src/kernel/kernel.asm"
BOOTLOADER_BIN="$BUILD_DIR/bootloader.bin"
KERNEL_BIN="$BUILD_DIR/kernel.bin"
OS_IMAGE="$BUILD_DIR/omnios.img"

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display header
show_header() {
    echo -e "${WHITE}================================${NC}"
    echo -e "${WHITE}    OmniOS 2.0 Build System    ${NC}"
    echo -e "${WHITE}    Professional Edition${NC}"
    echo -e "${WHITE}================================${NC}"
}

# Function to check dependencies
check_dependencies() {
    print_step "Checking build dependencies..."
    
    # Check for NASM
    if command -v nasm >/dev/null 2>&1; then
        NASM_VERSION=$(nasm -v)
        print_success "Found NASM: $NASM_VERSION"
    else
        print_error "NASM assembler not found. Please install NASM."
        exit 1
    fi
    
    # Check for QEMU (if running)
    if [[ "$1" == "--run" ]]; then
        if command -v qemu-system-i386 >/dev/null 2>&1; then
            QEMU_VERSION=$(qemu-system-i386 --version | head -n1)
            print_success "Found QEMU: $QEMU_VERSION"
        else
            print_error "QEMU not found. Please install qemu-system-x86."
            exit 1
        fi
    fi
    
    # Check for dd
    if command -v dd >/dev/null 2>&1; then
        print_success "Found dd utility"
    else
        print_error "dd utility not found."
        exit 1
    fi
    
    print_success "All required dependencies found"
}

# Function to setup build environment
setup_build_env() {
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
    
    if [ ! -f "$BOOTLOADER_SRC" ]; then
        print_error "Bootloader source not found: $BOOTLOADER_SRC"
        exit 1
    fi
    
    if [ ! -f "$KERNEL_SRC" ]; then
        print_error "Kernel source not found: $KERNEL_SRC"
        exit 1
    fi
    
    # Count lines in source files
    BOOTLOADER_LINES=$(wc -l < "$BOOTLOADER_SRC")
    KERNEL_LINES=$(wc -l < "$KERNEL_SRC")
    
    print_success "Found: $BOOTLOADER_SRC ($BOOTLOADER_LINES lines)"
    print_success "Found: $KERNEL_SRC ($KERNEL_LINES lines)"
}

# Function to build bootloader
build_bootloader() {
    print_step "Building bootloader..."
    
    if nasm -f bin -o "$BOOTLOADER_BIN" "$BOOTLOADER_SRC"; then
        print_success "Bootloader built successfully ($(stat -c%s "$BOOTLOADER_BIN") bytes)"
        
        # Verify bootloader size (must be exactly 512 bytes)
        BOOTLOADER_SIZE=$(stat -c%s "$BOOTLOADER_BIN")
        if [ "$BOOTLOADER_SIZE" -eq 512 ]; then
            print_success "Bootloader size verification passed"
        else
            print_error "Bootloader size is $BOOTLOADER_SIZE bytes, must be exactly 512 bytes"
            exit 1
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
        KERNEL_SIZE=$(stat -c%s "$KERNEL_BIN")
        KERNEL_SECTORS=$((($KERNEL_SIZE + 511) / 512))
        print_success "Kernel built successfully ($KERNEL_SIZE bytes)"
        print_info "Kernel uses $KERNEL_SECTORS sectors"
    else
        print_error "Failed to build kernel"
        exit 1
    fi
}

# Function to create OS image
create_image() {
    print_step "Creating OS image..."
    
    # Create 1.44MB floppy disk image
    dd if=/dev/zero of="$OS_IMAGE" bs=1024 count=1440 2>/dev/null
    
    # Write bootloader to first sector
    dd if="$BOOTLOADER_BIN" of="$OS_IMAGE" bs=512 count=1 conv=notrunc 2>/dev/null
    
    # Write kernel starting from sector 2
    dd if="$KERNEL_BIN" of="$OS_IMAGE" bs=512 seek=1 conv=notrunc 2>/dev/null
    
    IMAGE_SIZE=$(stat -c%s "$OS_IMAGE")
    print_success "OS image created: $OS_IMAGE ($IMAGE_SIZE bytes)"
}

# Function to show build statistics
show_statistics() {
    print_step "Build Statistics:"
    
    BOOTLOADER_SIZE=$(stat -c%s "$BOOTLOADER_BIN")
    KERNEL_SIZE=$(stat -c%s "$KERNEL_BIN")
    IMAGE_SIZE=$(stat -c%s "$OS_IMAGE")
    
    print_info "Bootloader: $BOOTLOADER_SIZE bytes"
    print_info "Kernel: $KERNEL_SIZE bytes ($((($KERNEL_SIZE + 511) / 512)) sectors)"
    print_info "Total image: $IMAGE_SIZE bytes"
}

# Function to run in QEMU
run_qemu() {
    print_step "Starting OmniOS 2.0 in QEMU..."
    print_info "Starting QEMU with professional settings..."
    print_info "Press Ctrl+Alt+G to release mouse, Ctrl+Alt+Q to quit"
    
    # Try different display options for compatibility
    if command -v qemu-system-i386 >/dev/null 2>&1; then
        # Try GTK first, fall back to SDL, then VNC
        qemu-system-i386 \
            -drive format=raw,file="$OS_IMAGE" \
            -m 16 \
            -display gtk \
            -name "OmniOS 2.0 Professional" \
            -boot a 2>/dev/null || \
        qemu-system-i386 \
            -drive format=raw,file="$OS_IMAGE" \
            -m 16 \
            -display sdl \
            -name "OmniOS 2.0 Professional" \
            -boot a 2>/dev/null || \
        {
            print_warning "GUI display failed, starting with VNC on port 5900"
            qemu-system-i386 \
                -drive format=raw,file="$OS_IMAGE" \
                -m 16 \
                -display vnc=:0 \
                -name "OmniOS 2.0 Professional" \
                -boot a &
            print_info "Connect with VNC viewer to localhost:5900"
            wait
        }
    else
        print_error "QEMU not available"
        exit 1
    fi
}

# Function to clean build
clean_build() {
    print_step "Cleaning build artifacts..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "Build directory cleaned"
    else
        print_info "Build directory already clean"
    fi
}

# Main build function
main_build() {
    show_header
    check_dependencies "$1"
    setup_build_env
    verify_sources
    build_bootloader
    build_kernel
    create_image
    show_statistics
    print_success "Build completed successfully!"
}

# Main script logic
case "$1" in
    --run)
        main_build "$1"
        run_qemu
        ;;
    --clean)
        clean_build
        ;;
    --help)
        echo "OmniOS 2.0 Build System"
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)  Build OmniOS 2.0"
        echo "  --run      Build and run in QEMU"
        echo "  --clean    Clean build artifacts"
        echo "  --help     Show this help"
        ;;
    "")
        main_build
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
