#!/bin/bash

# OmniOS 2.0 Alternative Runner
# Multiple display options for compatibility

echo "OmniOS 2.0 Alternative Launcher"
echo "==============================="

if [ ! -f "build/omnios.img" ]; then
    echo "Error: Build the system first with ./build.sh"
    exit 1
fi

echo "Trying different QEMU display modes..."

# Method 1: Try curses (text-based)
echo "1. Trying curses display..."
timeout 5s qemu-system-i386 \
    -drive format=raw,file=build/omnios.img,if=floppy \
    -boot a \
    -display curses \
    -m 16 2>/dev/null && exit 0

# Method 2: Try SDL
echo "2. Trying SDL display..."
timeout 5s qemu-system-i386 \
    -drive format=raw,file=build/omnios.img,if=floppy \
    -boot a \
    -display sdl \
    -m 16 2>/dev/null && exit 0

# Method 3: Try VNC
echo "3. Starting VNC server on port 5900..."
qemu-system-i386 \
    -drive format=raw,file=build/omnios.img,if=floppy \
    -boot a \
    -display vnc=:0 \
    -m 16 &

QEMU_PID=$!
echo "QEMU started with PID: $QEMU_PID"
echo "Connect with VNC viewer to: localhost:5900"
echo "Press Enter to stop QEMU..."
read
kill $QEMU_PID 2>/dev/null
