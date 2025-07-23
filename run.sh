#!/bin/bash
# OmniOS 2.0 Run Script

if [ ! -f "build/omnios.img" ]; then
    echo "OmniOS image not found. Building..."
    ./build.sh
fi

echo "Starting OmniOS 2.0..."
qemu-system-i386 -fda build/omnios.img -boot a
