#!/bin/bash

# OmniOS 2.0 Text Mode Runner

echo "Starting OmniOS 2.0 (Text Mode)..."

if [ ! -f "build/omnios.img" ]; then
    echo "Error: OmniOS image not found. Please build first with 'make all'"
    exit 1
fi

echo "Use Ctrl+A then X to exit QEMU"
qemu-system-i386 -drive format=raw,file=build/omnios.img,if=floppy -boot a -nographic
