#!/bin/bash

# OmniOS 2.0 Enhanced Build System with Color-Coded Output
# Professional build script with comprehensive error handling

# Color definitions for enhanced output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Build configuration
BUILD_DIR="build"
SRC_DIR="src"
OUTPUT_IMAGE="omnios.img"
BOOTLOADER="$SRC_DIR/boot/bootloader.asm"
KERNEL="$SRC_DIR/kernel/kernel.asm"

# Function to print colored messages
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

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Function to check if required tools are installed
check_dependencies() {
    print_header "CHECKING BUILD DEPENDENCIES"
    
    local missing_tools=()
    
    # Check for NASM
    if ! command -v nasm &> /dev/null; then
        missing_tools+=("nasm")
    else
        print_success "NASM assembler found: $(nasm -v)"
    fi
    
    # Check for QEMU (optional but recommended)
    if ! command -v qemu-system-i386 &> /dev/null; then
        print_warning "QEMU not found - you won't be able to test the OS directly"
    else
        print_success "QEMU emulator found: $(qemu-system-i386 --version | head -n1)"
    fi
    
    # Check for dd
    if ! command -v dd &> /dev/null; then
        missing_tools+=("dd")
    else
        print_success "dd utility found"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install missing dependencies:"
        print_status "  Ubuntu/Debian: sudo apt-get install nasm qemu-system-x86"
        print_status "  CentOS/RHEL: sudo yum install nasm qemu-kvm"
        print_status "  macOS: brew install nasm qemu"
        exit 1
    fi
    
    print_success "All required dependencies are installed"
}

# Function to create build directory
setup_build_environment() {
    print_header "SETTING UP BUILD ENVIRONMENT"
    
    if [ -d "$BUILD_
    print_header "SETTING UP BUILD ENVIRONMENT"
    
    if [ -d "$BUILD_DIR" ]; then
        print_status "Cleaning existing build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    print_success "Build directory created: $BUILD_DIR"
    
    # Create temporary directories for intermediate files
    mkdir -p "$BUILD_DIR/temp"
    print_success "Temporary directory created"
}

# Function to validate source files
validate_source_files() {
    print_header "VALIDATING SOURCE FILES"
    
    local required_files=("$BOOTLOADER" "$KERNEL")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        else
            print_success "Found: $file ($(wc -l < "$file") lines)"
        fi
    done
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        print_error "Missing required source files:"
        for file in "${missing_files[@]}"; do
            print_error "  - $file"
        done
        exit 1
    fi
    
    print_success "All source files validated"
}

# Function to assemble bootloader
build_bootloader() {
    print_header "BUILDING BOOTLOADER"
    
    print_status "Assembling bootloader from $BOOTLOADER..."
    
    if nasm -f bin "$BOOTLOADER" -o "$BUILD_DIR/bootloader.bin" 2>&1 | while IFS= read -r line; do
        if [[ $line == *"error"* ]]; then
            print_error "Bootloader assembly error: $line"
        elif [[ $line == *"warning"* ]]; then
            print_warning "Bootloader assembly warning: $line"
        else
            print_status "$line"
        fi
    done; then
        # Check if bootloader was actually created
        if [ -f "$BUILD_DIR/bootloader.bin" ]; then
            local size=$(stat -c%s "$BUILD_DIR/bootloader.bin" 2>/dev/null || stat -f%z "$BUILD_DIR/bootloader.bin" 2>/dev/null)
            print_success "Bootloader assembled successfully ($size bytes)"
            
            # Verify bootloader size (should be exactly 512 bytes)
            if [ "$size" -eq 512 ]; then
                print_success "Bootloader size is correct (512 bytes)"
            else
                print_warning "Bootloader size is $size bytes (expected 512 bytes)"
            fi
        else
            print_error "Bootloader assembly failed - output file not created"
            return 1
        fi
    else
        print_error "Bootloader assembly failed"
        return 1
    fi
}

# Function to assemble kernel
build_kernel() {
    print_header "BUILDING KERNEL"
    
    print_status "Assembling kernel from $KERNEL..."
    
    if nasm -f bin "$KERNEL" -o "$BUILD_DIR/kernel.bin" 2>&1 | while IFS= read -r line; do
        if [[ $line == *"error"* ]]; then
            print_error "Kernel assembly error: $line"
        elif [[ $line == *"warning"* ]]; then
            print_warning "Kernel assembly warning: $line"
        else
            print_status "$line"
        fi
    done; then
        # Check if kernel was actually created
        if [ -f "$BUILD_DIR/kernel.bin" ]; then
            local size=$(stat -c%s "$BUILD_DIR/kernel.bin" 2>/dev/null || stat -f%z "$BUILD_DIR/kernel.bin" 2>/dev/null)
            print_success "Kernel assembled successfully ($size bytes)"
            
            # Calculate sectors needed (512 bytes per sector)
            local sectors=$(( (size + 511) / 512 ))
            print_status "Kernel requires $sectors sectors"
        else
            print_error "Kernel assembly failed - output file not created"
            return 1
        fi
    else
        print_error "Kernel assembly failed"
        return 1
    fi
}

# Function to create disk image
create_disk_image() {
    print_header "CREATING DISK IMAGE"
    
    print_status "Creating 1.44MB floppy disk image..."
    
    # Create 1.44MB disk image (2880 sectors * 512 bytes)
    if dd if=/dev/zero of="$BUILD_DIR/$OUTPUT_IMAGE" bs=512 count=2880 2>/dev/null; then
        print_success "Blank disk image created (1.44MB)"
    else
        print_error "Failed to create disk image"
        return 1
    fi
    
    # Write bootloader to first sector
    print_status "Writing bootloader to disk image..."
    if dd if="$BUILD_DIR/bootloader.bin" of="$BUILD_DIR/$OUTPUT_IMAGE" bs=512 count=1 conv=notrunc 2>/dev/null; then
        print_success "Bootloader written to sector 0"
    else
        print_error "Failed to write bootloader to disk image"
        return 1
    fi
    
    # Write kernel starting from sector 1
    print_status "Writing kernel to disk image..."
    if dd if="$BUILD_DIR/kernel.bin" of="$BUILD_DIR/$OUTPUT_IMAGE" bs=512 seek=1 conv=notrunc 2>/dev/null; then
        print_success "Kernel written starting from sector 1"
    else
        print_error "Failed to write kernel to disk image"
        return 1
    fi
    
    # Copy final image to root directory
    if cp "$BUILD_DIR/$OUTPUT_IMAGE" "./omnios.img"; then
        print_success "Final image copied to ./omnios.img"
    else
        print_error "Failed to copy final image"
        return 1
    fi
}

# Function to verify the built image
verify_image() {
    print_header "VERIFYING BUILT IMAGE"
    
    if [ ! -f "./omnios.img" ]; then
        print_error "Output image not found: ./omnios.img"
        return 1
    fi
    
    local size=$(stat -c%s "./omnios.img" 2>/dev/null || stat -f%z "./omnios.img" 2>/dev/null)
    print_success "Image size: $size bytes ($(( size / 1024 ))KB)"
    
    # Check boot signature
    local boot_sig=$(xxd -s 510 -l 2 -p "./omnios.img" 2>/dev/null)
    if [ "$boot_sig" = "55aa" ]; then
        print_success "Boot signature verified (0x55AA)"
    else
        print_warning "Boot signature not found or incorrect: 0x$boot_sig"
    fi
    
    print_success "Image verification completed"
}

# Function to show build summary
show_build_summary() {
    print_header "BUILD SUMMARY"
    
    echo -e "${WHITE}Build Configuration:${NC}"
    echo -e "  Source Directory: ${CYAN}$SRC_DIR${NC}"
    echo -e "  Build Directory:  ${CYAN}$BUILD_DIR${NC}"
    echo -e "  Output Image:     ${CYAN}./omnios.img${NC}"
    echo ""
    
    if [ -f "./omnios.img" ]; then
        local size=$(stat -c%s "./omnios.img" 2>/dev/null || stat -f%z "./omnios.img" 2>/dev/null)
        echo -e "${WHITE}Output Details:${NC}"
        echo -e "  Image Size:       ${GREEN}$size bytes ($(( size / 1024 ))KB)${NC}"
        echo -e "  Image Type:       ${GREEN}1.44MB Floppy Disk${NC}"
        echo -e "  Architecture:     ${GREEN}x86 16-bit Real Mode${NC}"
        echo ""
        
        echo -e "${WHITE}Features Included:${NC}"
        echo -e "  ${GREEN}✓${NC} Initial Setup System"
        echo -e "  ${GREEN}✓${NC} User Authentication"
        echo -e "  ${GREEN}✓${NC} Enhanced Settings Menu"
        echo -e "  ${GREEN}✓${NC} Color Theme Support"
        echo -e "  ${GREEN}✓${NC} Administrative Features"
        echo -e "  ${GREEN}✓${NC} Factory Reset Capability"
        echo -e "  ${GREEN}✓${NC} Professional Color Scheme (Black Background)"
        echo ""
        
        echo -e "${WHITE}Usage Instructions:${NC}"
        echo -e "  Test with QEMU:   ${CYAN}./run.sh${NC}"
        echo -e "  Test (text mode): ${CYAN}./run-text.sh${NC}"
        echo -e "  Test (safe mode): ${CYAN}./run-safe.sh${NC}"
        echo -e "  Flash to device:  ${CYAN}sudo dd if=omnios.img of=/dev/sdX bs=512${NC}"
        echo ""
        
        print_success "BUILD COMPLETED SUCCESSFULLY!"
        echo -e "${GREEN}Your OmniOS 2.0 image is ready: ./omnios.img${NC}"
    else
        print_error "BUILD FAILED - No output image generated"
        return 1
    fi
}

# Function to clean up temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    if [ -d "$BUILD_DIR/temp" ]; then
        rm -rf "$BUILD_DIR/temp"
        print_success "Temporary files cleaned"
    fi
}

# Main build process
main() {
    # Print build header
    echo -e "${CYAN}"
    echo "  ██████╗ ███╗   ███╗███╗   ██╗██╗ ██████╗ ███████╗    ██████╗    ██████╗ "
    echo " ██╔═══██╗████╗ ████║████╗  ██║██║██╔═══██╗██╔════╝    ╚════██╗  ██╔═████╗"
    echo " ██║   ██║██╔████╔██║██╔██╗ ██║██║██║   ██║███████╗     █████╔╝  ██║██╔██║"
    echo " ██║   ██║██║╚██╔╝██║██║╚██╗██║██║██║   ██║╚════██║    ██╔═══╝   ████╔╝██║"
    echo " ╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║╚██████╔╝███████║    ███████╗  ╚██████╔╝"
    echo "  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚══════╝    ╚══════╝   ╚═════╝ "
    echo -e "${NC}"
    echo -e "${WHITE}Enhanced Professional Build System${NC}"
    echo -e "${WHITE}Build Date: $(date)${NC}"
    echo ""
    
    # Execute build steps
    check_dependencies || exit 1
    setup_build_environment || exit 1
    validate_source_files || exit 1
    build_bootloader || exit 1
    build_kernel || exit 1
    create_disk_image || exit 1
    verify_image || exit 1
    cleanup
    show_build_summary || exit 1
    
    echo ""
    print_success "Build process completed successfully!"
    echo -e "${YELLOW}Note: The system now uses a professional black background.${NC}"
    echo -e "${YELLOW}First boot will show the setup screen for initial configuration.${NC}"
    echo -e "${YELLOW}The kernel entry point has been fixed for proper startup.${NC}"
}

# Handle script interruption
trap 'print_error "Build interrupted by user"; cleanup; exit 1' INT TERM

# Run main function
main "$@"
