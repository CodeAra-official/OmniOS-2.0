#!/bin/bash
# OmniOS 2.0 Debug Build Script

echo "Building OmniOS 2.0 (Debug Mode)..."

# Enable debug output
set -x

# Create build directory with debug info
mkdir -p build/debug

# Create enhanced test files for debugging
echo "Creating debug files..."
cat > build/test.txt << EOF
OmniOS 2.0 Debug Build
Build Date: $(date)
Build Host: $(hostname)
Build User: $(whoami)
Build Directory: $(pwd)

This file is used for testing file system operations.
EOF

mkdir -p build/system
cat > build/system/debug.txt << EOF
OmniOS 2.0 Debug Information
============================

Build Configuration:
- Debug Mode: Enabled
- Verbose Output: Enabled
- Symbol Information: Included

System Components:
- Bootloader: src/Boot/Boot.asm
- Kernel: src/kernel.asm
- File System: FAT12
- Memory Layout: 16-bit Real Mode

Debug Features:
- Extended error messages
- Memory dump capabilities
- Register state display
- Step-by-step execution
EOF

# Assemble with debug symbols
echo "Assembling bootloader (debug)..."
nasm -f bin -g -F dwarf -o build/boot.bin src/Boot/Boot.asm

echo "Assembling kernel (debug)..."
nasm -f bin -g -F dwarf -o build/kernel.bin src/kernel.asm

# Create debug symbols
echo "Generating debug information..."
objdump -D build/boot.bin > build/debug/boot.disasm 2>/dev/null || echo "objdump not available"
objdump -D build/kernel.bin > build/debug/kernel.disasm 2>/dev/null || echo "objdump not available"

# Create disk image
echo "Creating debug disk image..."
dd if=/dev/zero of=build/OmniOS-debug.img bs=512 count=2880
mkfs.fat -F 12 -n "OMNIOSDEBUG" build/OmniOS-debug.img

# Install bootloader
dd if=build/boot.bin of=build/OmniOS-debug.img conv=notrunc

# Copy files
mcopy -i build/OmniOS-debug.img build/kernel.bin "::kernel.bin"
mcopy -i build/OmniOS-debug.img build/test.txt "::test.txt"
mcopy -i build/OmniOS-debug.img build/system "::system"

# Create debug launch script
cat > launch-debug.sh << 'EOF'
#!/bin/bash
# OmniOS 2.0 Debug Launcher

echo "Starting OmniOS 2.0 in Debug Mode..."
echo "Debug features enabled:"
echo "  - Verbose QEMU output"
echo "  - CPU state logging"
echo "  - Memory access tracing"
echo ""

# Create debug log directory
mkdir -p logs

# Launch with debug options
qemu-system-i386 \
    -m 256M \
    -drive format=raw,file=build/OmniOS-debug.img,if=floppy \
    -boot a \
    -nographic \
    -d cpu,guest_errors,trace:* \
    -D logs/qemu-debug.log \
    -monitor stdio
EOF

chmod +x launch-debug.sh

echo "Debug build completed!"
echo "Files created:"
echo "  - build/OmniOS-debug.img (Debug disk image)"
echo "  - build/debug/ (Debug information)"
echo "  - launch-debug.sh (Debug launcher)"
echo ""
echo "To run debug version:"
echo "  ./launch-debug.sh"

# Disable debug output
set +x
