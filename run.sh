#!/bin/bash
# OmniOS 2.0 Enhanced Edition Run Script

if [ ! -f "build/omnios.img" ]; then
    echo "OmniOS Enhanced Edition image not found. Building..."
    ./build.sh
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Starting OmniOS 2.0 Enhanced Edition           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Enhanced Command Set Available:"
echo "• Basic: help ls cd install open set admin exit off"
echo "• Files: add delete move cut copy"
echo "• Media: play stop"
echo "• Network: download go retry back"
echo ""
echo "Starting system..."

if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    echo "No display detected. Using text mode..."
    qemu-system-i386 -drive format=raw,file=build/omnios.img,if=floppy -boot a -nographic -serial mon:stdio
else
    echo "Starting with display..."
    qemu-system-i386 -drive format=raw,file=build/omnios.img,if=floppy -boot a -display curses
fi
