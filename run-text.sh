#!/bin/bash

# OmniOS 2.0 Text Mode Runner
# Runs system in text-only mode

echo "Starting OmniOS 2.0 (Text Mode)..."

# Check if image exists
if [ ! -f "build/omnios.img" ]; then
    echo "Error: OmniOS image not found. Please build first with 'make all'"
    exit 1
fi

# Kill any existing QEMU processes using the image
pkill -f "omnios.img" 2>/dev/null

# Wait a moment for processes to terminate
sleep 1

# Run in text mode
echo "Starting system..."
qemu-system-i386 \
    -drive format=raw,file=build/omnios.img,if=floppy \
    -boot a \
    -nographic \
    -serial mon:stdio \
    -no-reboot \
    -no-shutdown

echo "OmniOS 2.0 session ended."
