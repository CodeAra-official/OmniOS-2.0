#!/bin/bash
# OmniOS 2.0 Dependency Installation Script

echo "Installing OmniOS 2.0 dependencies..."

# Detect the environment
if [ -d "/data/data/com.termux" ]; then
    ENVIRONMENT="termux"
elif command -v apt-get &> /dev/null; then
    ENVIRONMENT="debian"
elif command -v yum &> /dev/null; then
    ENVIRONMENT="redhat"
elif command -v pacman &> /dev/null; then
    ENVIRONMENT="arch"
else
    ENVIRONMENT="unknown"
fi

echo "Detected environment: $ENVIRONMENT"

install_termux() {
    echo "Installing packages for Termux..."
    pkg update
    pkg install -y nasm qemu-system-i386 mtools git wget curl unzip
    
    # Create OmniOS data directory
    mkdir -p ~/omnios-data/{documents,downloads,system}
    
    echo "Termux setup completed!"
}

install_debian() {
    echo "Installing packages for Debian/Ubuntu..."
    sudo apt-get update
    sudo apt-get install -y nasm qemu-system-x86 mtools build-essential git wget curl
    
    echo "Debian/Ubuntu setup completed!"
}

install_redhat() {
    echo "Installing packages for Red Hat/CentOS/Fedora..."
    sudo yum install -y nasm qemu-system-x86 mtools gcc git wget curl
    
    echo "Red Hat setup completed!"
}

install_arch() {
    echo "Installing packages for Arch Linux..."
    sudo pacman -S --noconfirm nasm qemu mtools base-devel git wget curl
    
    echo "Arch Linux setup completed!"
}

case $ENVIRONMENT in
    "termux")
        install_termux
        ;;
    "debian")
        install_debian
        ;;
    "redhat")
        install_redhat
        ;;
    "arch")
        install_arch
        ;;
    *)
        echo "Unknown environment. Please install manually:"
        echo "  - nasm (assembler)"
        echo "  - qemu-system-i386 (emulator)"
        echo "  - mtools (FAT filesystem tools)"
        echo "  - git (version control)"
        exit 1
        ;;
esac

# Verify installations
echo ""
echo "Verifying installations..."

check_command() {
    if command -v $1 &> /dev/null; then
        echo "✓ $1 is installed"
        return 0
    else
        echo "✗ $1 is NOT installed"
        return 1
    fi
}

MISSING=0
check_command nasm || MISSING=1
check_command qemu-system-i386 || MISSING=1
check_command mcopy || MISSING=1
check_command git || MISSING=1

if [ $MISSING -eq 0 ]; then
    echo ""
    echo "All dependencies installed successfully!"
    echo "You can now run: ./build.sh"
else
    echo ""
    echo "Some dependencies are missing. Please install them manually."
    exit 1
fi
