#!/bin/bash

# OmniOS 2.0 Text-Only Runner
# Guaranteed to work in any terminal

echo "Starting OmniOS 2.0 in text mode..."

if [ ! -f "build/omnios.img" ]; then
    echo "Error: Build first with ./build.sh"
    exit 1
fi

# Force text mode with serial console
qemu-system-i386 \
    -drive format=raw,file=build/omnios.img,if=floppy \
    -boot a \
    -nographic \
    -serial mon:stdio \
    -m 16

echo "OmniOS 2.0 session ended."
