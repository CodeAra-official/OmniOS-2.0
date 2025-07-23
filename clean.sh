#!/bin/bash
# OmniOS 2.0 Enhanced Edition Clean Script

echo "Cleaning OmniOS 2.0 Enhanced Edition build files..."

# Remove build directory
if [ -d "build" ]; then
    rm -rf build
    echo "Build directory removed"
fi

# Remove any temporary files
find . -name "*.tmp" -delete 2>/dev/null
find . -name "*~" -delete 2>/dev/null

echo "Clean completed!"
echo "Run './build.sh' to rebuild the enhanced system."
