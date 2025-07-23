#!/bin/bash
# OmniOS 2.0 Clean Script

echo "Cleaning OmniOS 2.0 build files..."

# Remove build directory
if [ -d "build" ]; then
    echo "Removing build directory..."
    rm -rf build
fi

# Remove generated scripts
echo "Removing generated scripts..."
rm -f launch-omnios.sh
rm -f launch-debug.sh

# Remove log files
if [ -d "logs" ]; then
    echo "Removing log files..."
    rm -rf logs
fi

# Remove temporary files
echo "Removing temporary files..."
find . -name "*.tmp" -delete
find . -name "*.bak" -delete
find . -name "*~" -delete

echo "Clean completed!"
echo ""
echo "To rebuild OmniOS 2.0:"
echo "  ./build.sh          (Standard build)"
echo "  ./build-termux.sh   (Termux build)"
echo "  ./build-debug.sh    (Debug build)"
