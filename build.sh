#!/bin/bash
# OmniOS 2.0 Enhanced Build Script

echo "Building OmniOS 2.0..."

# Create build directory
mkdir -p build

# Create missing files and directories
echo "Creating required files..."
echo "This is a test file for OmniOS 2.0" > build/test.txt
mkdir -p build/system
echo "OmniOS System Files" > build/system/readme.txt

# Assemble bootloader and kernel
echo "Assembling bootloader..."
nasm -f bin -o build/boot.bin src/Boot/Boot.asm

echo "Assembling kernel..."
nasm -f bin -o build/kernel.bin src/kernel.asm

# Create disk image with proper format specification
echo "Creating disk image..."
dd if=/dev/zero of=build/OmniOS.img bs=512 count=2880
mkfs.fat -F 12 -n "OmniOS" build/OmniOS.img

# Install bootloader
echo "Installing bootloader..."
dd if=build/boot.bin of=build/OmniOS.img conv=notrunc

# Copy files to the image
echo "Copying files to disk image..."
mcopy -i build/OmniOS.img build/kernel.bin "::kernel.bin"
mcopy -i build/OmniOS.img build/test.txt "::test.txt"
mcopy -i build/OmniOS.img build/system "::system"

echo "Build completed successfully!"
echo "Disk image: build/OmniOS.img"

# Check if we're in a headless environment
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    echo "No display detected. Skipping QEMU GUI launch."
    echo "To run OmniOS, use: qemu-system-i386 -boot c -m 256 -fda build/OmniOS.img -nographic"
else
    echo "Starting OmniOS in QEMU..."
    # Run the system in QEMU with proper format specification
    qemu-system-i386 -boot c -m 256 -drive format=raw,file=build/OmniOS.img,if=floppy -display gtk
fi
