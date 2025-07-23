#!/bin/bash

# OmniOS 2.0 Safe Run Script
# Tries different QEMU display modes

echo "Starting OmniOS 2.0 (Safe Mode)..."

# Check if image exists
if [ ! -f "build/omnios.img" ]; then
    echo "Error: OmniOS image not found. Please build first with 'make all'"
    exit 1
fi

# Kill any existing QEMU processes using the image
echo "Checking for running processes..."
pkill -f "omnios.img" 2>/dev/null

# Wait for processes to terminate
sleep 2

# Remove any lock files
rm -f build/omnios.img.lock 2>/dev/null

echo "No display detected. Using text mode..."
qemu-system-i386 \
    -drive format=raw,file=build/omnios.img,if=floppy \
    -boot a \
    -nographic \
    -serial mon:stdio \
    -no-reboot

echo "OmniOS 2.0 session ended."
