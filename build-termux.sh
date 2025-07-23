#!/bin/bash
# OmniOS 2.0 Build Script for Termux Environment

echo "Building OmniOS 2.0 for Termux..."

# Check if we're in Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "Warning: This script is optimized for Termux environment"
fi

# Install required packages if not present
check_and_install() {
    if ! command -v $1 &> /dev/null; then
        echo "Installing $1..."
        pkg install $1 -y
    fi
}

echo "Checking dependencies..."
check_and_install nasm
check_and_install qemu-system-i386
check_and_install mtools

# Create build directory
mkdir -p build

# Create required files
echo "Creating system files..."
echo "OmniOS 2.0 Test File - Built on $(date)" > build/test.txt
mkdir -p build/system
echo "OmniOS 2.0 System Directory" > build/system/readme.txt
echo "version=2.0.0" > build/system/version.txt

# Create configuration file for Termux
cat > build/system/termux.conf << EOF
# OmniOS 2.0 Termux Configuration
display_mode=text
memory_limit=256M
enable_networking=true
storage_path=/data/data/com.termux/files/home/omnios-data
EOF

# Assemble bootloader
echo "Assembling bootloader..."
if ! nasm -f bin -o build/boot.bin src/Boot/Boot.asm; then
    echo "Error: Failed to assemble bootloader"
    exit 1
fi

# Assemble kernel
echo "Assembling kernel..."
if ! nasm -f bin -o build/kernel.bin src/kernel.asm; then
    echo "Error: Failed to assemble kernel"
    exit 1
fi

# Create disk image
echo "Creating disk image..."
dd if=/dev/zero of=build/OmniOS.img bs=512 count=2880 2>/dev/null
mkfs.fat -F 12 -n "OmniOS20" build/OmniOS.img >/dev/null 2>&1

# Install bootloader
echo "Installing bootloader..."
dd if=build/boot.bin of=build/OmniOS.img conv=notrunc 2>/dev/null

# Copy files to image
echo "Installing system files..."
mcopy -i build/OmniOS.img build/kernel.bin "::kernel.bin" 2>/dev/null
mcopy -i build/OmniOS.img build/test.txt "::test.txt" 2>/dev/null
mcopy -i build/OmniOS.img build/system "::system" 2>/dev/null

echo "Build completed successfully!"
echo "Image location: $(pwd)/build/OmniOS.img"
echo "Image size: $(ls -lh build/OmniOS.img | awk '{print $5}')"

# Create launch script
cat > launch-omnios.sh << 'EOF'
#!/bin/bash
# OmniOS 2.0 Launcher for Termux

OMNIOS_IMG="build/OmniOS.img"
MEMORY="256M"

if [ ! -f "$OMNIOS_IMG" ]; then
    echo "Error: OmniOS image not found. Run ./build-termux.sh first."
    exit 1
fi

echo "Starting OmniOS 2.0..."
echo "Memory: $MEMORY"
echo "Image: $OMNIOS_IMG"
echo ""
echo "Press Ctrl+A then X to exit QEMU"
echo "Starting in 3 seconds..."
sleep 3

# Launch with text mode for Termux compatibility
qemu-system-i386 \
    -m $MEMORY \
    -drive format=raw,file=$OMNIOS_IMG,if=floppy \
    -boot a \
    -nographic \
    -serial mon:stdio
EOF

chmod +x launch-omnios.sh

echo ""
echo "To run OmniOS 2.0:"
echo "  ./launch-omnios.sh"
echo ""
echo "To run with GUI (if X11 available):"
echo "  qemu-system-i386 -m 256M -drive format=raw,file=build/OmniOS.img,if=floppy -boot a"
