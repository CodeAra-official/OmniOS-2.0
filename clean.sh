#!/bin/bash
# OmniOS 2.0 Clean Script

echo "Cleaning OmniOS 2.0 build files..."

# Remove build directory
if [ -d "build" ]; then
    rm -rf build
    echo "Build directory removed"
fi

# Remove any temporary files
find . -name "*.tmp" -delete 2>/dev/null
find . -name "*~" -delete 2>/dev/null

echo "Clean completed!"
