#!/bin/bash

# OmniOS 2.0 Safe Run Script
# Tries different QEMU display modes

echo "Starting OmniOS 2.0 (Safe Mode)..."

# Check if image exists
if [ ! -f "build/omnios.img" ]; then
    echo "Error: OmniOS image not found. Please build first with 'make all'"
    exit 1
fi

# Try different display modes
echo "Trying curses display..."
qemu-system-i386 -drive format=raw,file=build/omnios.img,if=floppy -boot a -display curses 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Curses failed, trying text mode..."
    qemu-system-i386 -drive format=raw,file=build/omnios.img,if=floppy -boot a -nographic
fi
