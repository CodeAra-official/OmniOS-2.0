#!/bin/bash

# OmniOS 2.0 Debug Boot
# Shows detailed boot process

echo "OmniOS 2.0 Debug Boot"
echo "====================="

if [ ! -f "build/omnios.img" ]; then
    echo "Error: Build first with ./build.sh"
    exit 1
fi

echo "Starting with debug output..."

qemu-system-i386 \
    -drive format=raw,file=build/omnios.img,if=floppy \
    -boot a \
    -nographic \
    -serial mon:stdio \
    -d cpu_reset,guest_errors \
    -m 16
