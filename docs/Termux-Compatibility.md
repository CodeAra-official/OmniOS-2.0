# OmniOS 2.0 Termux Compatibility Guide

## Overview

OmniOS 2.0 has been specifically optimized for the Termux environment, providing a seamless operating system experience on Android devices. This guide covers installation, configuration, and optimization for running OmniOS within Termux.

## System Requirements

### Minimum Requirements
- **Android Version**: 7.0 (API level 24) or higher
- **RAM**: 3GB (4GB+ recommended)
- **Storage**: 2GB free space for installation
- **Architecture**: ARM64, ARM, x86_64, or x86
- **Termux Version**: 0.118 or newer

### Recommended Requirements
- **Android Version**: 10.0 or higher
- **RAM**: 6GB or more
- **Storage**: 4GB+ free space
- **CPU**: Octa-core 2.0GHz+
- **Root Access**: For advanced features

## Installation Process

### Step 1: Termux Setup
\`\`\`bash
# Update package repositories
pkg update && pkg upgrade -y

# Install essential packages
pkg install git wget curl unzip tar gzip

# Install build tools
pkg install nasm make gcc clang

# Install emulation tools
pkg install qemu-system-i386 qemu-system-x86_64

# Install file system tools
pkg install mtools dosfstools
\`\`\`

### Step 2: Download OmniOS 2.0
\`\`\`bash
# Create installation directory
mkdir -p ~/omnios-2.0
cd ~/omnios-2.0

# Download OmniOS 2.0 Termux package
wget https://github.com/omnios/releases/download/v2.0.0/omnios-2.0-termux.tar.gz

# Extract package
tar -xzf omnios-2.0-termux.tar.gz
\`\`\`

### Step 3: Configure for Termux
\`\`\`bash
# Run Termux-specific configuration
./configure-termux.sh

# Set environment variables
echo 'export OMNIOS_HOME="$HOME/omnios-2.0"' >> ~/.bashrc
echo 'export PATH="$OMNIOS_HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
\`\`\`

### Step 4: Build OmniOS
\`\`\`bash
# Build for current architecture
chmod +x build-termux.sh
./build-termux.sh --target-arch=$(uname -m)

# Create disk image
./create-disk-image.sh --size=100M
\`\`\`

### Step 5: First Launch
\`\`\`bash
# Launch OmniOS
./launch-omnios-termux.sh

# Or use the wrapper script
omnios-start
\`\`\`

## Architecture-Specific Configuration

### ARM64 Devices (Most Modern Android)
\`\`\`bash
# Optimized configuration for ARM64
export QEMU_CPU="cortex-a72"
export QEMU_MACHINE="virt"
export QEMU_ACCEL="tcg,thread=multi"
export OMNIOS_ARCH="arm64"
\`\`\`

### x86_64 Devices (Intel/AMD Android)
\`\`\`bash
# Configuration for x86_64
export QEMU_CPU="qemu64"
export QEMU_MACHINE="pc"
export QEMU_ACCEL="tcg"
export OMNIOS_ARCH="x86_64"
\`\`\`

### ARM32 Devices (Older Android)
\`\`\`bash
# Configuration for ARM32
export QEMU_CPU="cortex-a15"
export QEMU_MACHINE="virt"
export QEMU_ACCEL="tcg"
export OMNIOS_ARCH="arm"
\`\`\`

## Performance Optimization

### Memory Management
\`\`\`bash
# Configure memory usage
cat > ~/.omnios-config &lt;&lt; EOF
# Memory configuration
QEMU_MEMORY="512M"          # Default memory
QEMU_MEMORY_MAX="1G"        # Maximum memory
ENABLE_MEMORY_BALLOONING=true
MEMORY_OVERCOMMIT=true
EOF
\`\`\`

### CPU Optimization
\`\`\`bash
# CPU configuration
cat >> ~/.omnios-config &lt;&lt; EOF
# CPU configuration  
QEMU_SMP="2"                # Number of CPU cores
CPU_AFFINITY=true           # Enable CPU affinity
ENABLE_THREADING=true       # Enable threading
EOF
\`\`\`

### Storage Optimization
\`\`\`bash
# Storage configuration
cat >> ~/.omnios-config &lt;&lt; EOF
# Storage configuration
DISK_CACHE="writeback"      # Disk cache mode
ENABLE_COMPRESSION=true     # Enable disk compression
TRIM_SUPPORT=true          # Enable TRIM support
EOF
\`\`\`

### Network Configuration
\`\`\`bash
# Network setup
cat >> ~/.omnios-config &lt;&lt; EOF
# Network configuration
ENABLE_NETWORK=true
NETWORK_MODE="user"         # User mode networking
ENABLE_PORT_FORWARD=true
HTTP_PROXY_PORT=8080
EOF
\`\`\`

## Feature Integration

### File System Integration
\`\`\`bash
# Setup shared directories
mkdir -p ~/omnios-data/{documents,downloads,pictures,music,videos}

# Link Android storage (requires termux-setup-storage)
termux-setup-storage
ln -sf ~/storage/shared/Documents ~/omnios-data/documents
ln -sf ~/storage/shared/Download ~/omnios-data/downloads
ln -sf ~/storage/shared/Pictures ~/omnios-data/pictures
ln -sf ~/storage/shared/Music ~/omnios-data/music
ln -sf ~/storage/shared/Movies ~/omnios-data/videos
\`\`\`

### Notification Bridge
\`\`\`bash
# Install Termux:API for notifications
pkg install termux-api

# Configure notification bridge
cat > ~/omnios-2.0/scripts/notify-bridge.sh &lt;&lt; 'EOF'
#!/bin/bash
# Notification bridge between OmniOS and Android

while IFS= read -r line; do
    if [[ "$line" =~ ^NOTIFY: ]]; then
        message="${line#NOTIFY: }"
        termux-notification --title "OmniOS" --content "$message"
    fi
done &lt; ~/omnios-2.0/var/notifications.pipe
EOF

chmod +x ~/omnios-2.0/scripts/notify-bridge.sh
\`\`\`

### Clipboard Integration
\`\`\`bash
# Setup clipboard sharing
pkg install termux-api

cat > ~/omnios-2.0/scripts/clipboard-sync.sh &lt;&lt; 'EOF'
#!/bin/bash
# Clipboard synchronization

# Export OmniOS clipboard to Android
export_clipboard() {
    if [ -f ~/omnios-2.0/var/clipboard.txt ]; then
        termux-clipboard-set &lt; ~/omnios-2.0/var/clipboard.txt
    fi
}

# Import Android clipboard to OmniOS
import_clipboard() {
    termux-clipboard-get > ~/omnios-2.0/var/clipboard.txt
}

case "$1" in
    "export") export_clipboard ;;
    "import") import_clipboard ;;
    *) echo "Usage: $0 {export|import}" ;;
esac
EOF

chmod +x ~/omnios-2.0/scripts/clipboard-sync.sh
\`\`\`

## Application Integration

### Web Browser Integration
\`\`\`bash
# Setup web browser bridge
cat > ~/omnios-2.0/scripts/browser-bridge.sh &lt;&lt; 'EOF'
#!/bin/bash
# Open URLs in Android browser

if [ "$1" ]; then
    termux-open-url "$1"
else
    echo "Usage: $0 <URL>"
fi
EOF

chmod +x ~/omnios-2.0/scripts/browser-bridge.sh
\`\`\`

### File Manager Integration
\`\`\`bash
# Setup file manager bridge
cat > ~/omnios-2.0/scripts/filemanager-bridge.sh &lt;&lt; 'EOF'
#!/bin/bash
# Open files/directories in Android file manager

if [ -f "$1" ]; then
    termux-open "$1"
elif [ -d "$1" ]; then
    termux-open "$1"
else
    echo "File or directory not found: $1"
fi
EOF

chmod +x ~/omnios-2.0/scripts/filemanager-bridge.sh
\`\`\`

## Debugging and Troubleshooting

### Enable Debug Mode
\`\`\`bash
# Enable debug logging
export OMNIOS_DEBUG=1
export QEMU_LOG="cpu,guest_errors,trace:*"

# Create debug log directory
mkdir -p ~/omnios-2.0/logs

# Start with debug output
./launch-omnios-termux.sh --debug 2>&1 | tee ~/omnios-2.0/logs/debug.log
\`\`\`

### Common Issues and Solutions

#### Issue: QEMU Crashes on Startup
\`\`\`bash
# Check available QEMU targets
qemu-system-i386 -M help

# Try different machine type
export QEMU_MACHINE="isapc"  # For compatibility mode

# Reduce memory if low-RAM device
export QEMU_MEMORY="256M"
\`\`\`

#### Issue: Slow Performance
\`\`\`bash
# Optimize for low-end devices
cat > ~/.omnios-performance &lt;&lt; EOF
QEMU_MEMORY="384M"
QEMU_SMP="1"
ENABLE_KVM=false
DISK_CACHE="none"
AUDIO_ENABLE=false
EOF

source ~/.omnios-performance
\`\`\`

#### Issue: Network Not Working
\`\`\`bash
# Reset network configuration
rm -f ~/omnios-2.0/var/network.conf

# Use host networking
export QEMU_NET="-netdev user,id=net0,hostfwd=tcp::8022-:22 -device rtl8139,netdev=net0"
\`\`\`

#### Issue: Storage Space
\`\`\`bash
# Clean temporary files
rm -rf ~/omnios-2.0/tmp/*
rm -rf ~/omnios-2.0/var/cache/*

# Compress disk image
qemu-img convert -c -O qcow2 omnios.img omnios-compressed.qcow2
mv omnios-compressed.qcow2 omnios.img
\`\`\`

## Advanced Features

### Hardware Acceleration
\`\`\`bash
# Check for hardware virtualization support
if grep -q "vmx\|svm" /proc/cpuinfo; then
    echo "Hardware virtualization supported"
    export ENABLE_KVM=true
else
    echo "Using software emulation"
    export ENABLE_KVM=false
fi
\`\`\`

### GPU Acceleration (Experimental)
\`\`\`bash
# Enable GPU acceleration if supported
pkg install mesa-dev
export QEMU_DISPLAY="-display gtk,gl=on"
export OMNIOS_GPU=true
\`\`\`

### Audio Support
\`\`\`bash
# Setup audio
pkg install pulseaudio

# Configure audio for OmniOS
export QEMU_AUDIO="-audiodev pulse,id=audio0 -device sb16,audiodev=audio0"
\`\`\`

### USB Device Passthrough
\`\`\`bash
# Enable USB passthrough (requires root)
export QEMU_USB="-usb -device usb-host,vendorid=0x1234,productid=0x5678"
\`\`\`

## Automation and Scripting

### Auto-start Service
\`\`\`bash
# Create systemd-style service file
cat > ~/omnios-2.0/scripts/omnios.service &lt;&lt; 'EOF'
#!/bin/bash
# OmniOS auto-start service

PIDFILE="$HOME/omnios-2.0/var/omnios.pid"

start() {
    if [ -f "$PIDFILE" ]; then
        echo "OmniOS is already running"
        return 1
    fi
    
    echo "Starting OmniOS..."
    cd "$HOME/omnios-2.0"
    nohup ./launch-omnios-termux.sh > /dev/null 2>&1 &
    echo $! > "$PIDFILE"
    echo "OmniOS started with PID $(cat $PIDFILE)"
}

stop() {
    if [ ! -f "$PIDFILE" ]; then
        echo "OmniOS is not running"
        return 1
    fi
    
    echo "Stopping OmniOS..."
    kill $(cat "$PIDFILE")
    rm -f "$PIDFILE"
    echo "OmniOS stopped"
}

status() {
    if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
        echo "OmniOS is running (PID: $(cat $PIDFILE))"
    else
        echo "OmniOS is not running"
        rm -f "$PIDFILE"
    fi
}

case "$1" in
    start) start ;;
    stop) stop ;;
    status) status ;;
    restart) stop; sleep 2; start ;;
    *) echo "Usage: $0 {start|stop|status|restart}" ;;
esac
EOF

chmod +x ~/omnios-2.0/scripts/omnios.service
\`\`\`

### Update Management
\`\`\`bash
# Create update script
cat > ~/omnios-2.0/scripts/update-omnios.sh &lt;&lt; 'EOF'
#!/bin/bash
# OmniOS update manager

CURRENT_VERSION=$(cat ~/omnios-2.0/VERSION 2>/dev/null || echo "unknown")
BACKUP_DIR="$HOME/omnios-backups"

check_updates() {
    echo "Checking for updates..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/omnios/omnios-2.0/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
    
    if [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
        echo "Update available: $CURRENT_VERSION -> $LATEST_VERSION"
        return 0
    else
        echo "OmniOS is up to date ($CURRENT_VERSION)"
        return 1
    fi
}

backup_system() {
    echo "Creating backup..."
    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_DIR/omnios-backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
        --exclude="*.log" \
        --exclude="tmp/*" \
        ~/omnios-2.0
    echo "Backup created in $BACKUP_DIR"
}

download_update() {
    echo "Downloading update..."
    cd /tmp
    wget "https://github.com/omnios/omnios-2.0/releases/download/$LATEST_VERSION/omnios-2.0-termux.tar.gz"
    
    if [ $? -eq 0 ]; then
        echo "Update downloaded successfully"
        return 0
    else
        echo "Failed to download update"
        return 1
    fi
}

install_update() {
    echo "Installing update..."
    
    # Stop OmniOS if running
    ~/omnios-2.0/scripts/omnios.service stop
    
    # Backup current installation
    backup_system
    
    # Extract update
    cd ~
    tar -xzf /tmp/omnios-2.0-termux.tar.gz
    
    # Restore user data
    if [ -d "$BACKUP_DIR" ]; then
        cp -r ~/omnios-2.0/userdata/* "$BACKUP_DIR"/omnios-backup-*/userdata/ 2>/dev/null || true
    fi
    
    echo "Update installed successfully"
    echo "New version: $(cat ~/omnios-2.0/VERSION)"
}

case "$1" in
    "check") check_updates ;;
    "install")
        if check_updates; then
            read -p "Install update? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                download_update && install_update
            fi
        fi
        ;;
    "backup") backup_system ;;
    *) echo "Usage: $0 {check|install|backup}" ;;
esac
EOF

chmod +x ~/omnios-2.0/scripts/update-omnios.sh
\`\`\`

## Performance Monitoring

### System Monitor
\`\`\`bash
# Create system monitoring script
cat > ~/omnios-2.0/scripts/monitor-omnios.sh &lt;&lt; 'EOF'
#!/bin/bash
# OmniOS system monitor

show_system_info() {
    echo "=== OmniOS System Information ==="
    echo "Version: $(cat ~/omnios-2.0/VERSION 2>/dev/null || echo 'Unknown')"
    echo "Uptime: $(uptime)"
    echo "Memory Usage: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
    echo "Disk Usage: $(df -h ~ | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
    echo "CPU Load: $(cat /proc/loadavg | cut -d' ' -f1-3)"
    echo
}

show_omnios_status() {
    echo "=== OmniOS Status ==="
    if pgrep -f "qemu.*omnios" > /dev/null; then
        echo "Status: Running"
        QEMU_PID=$(pgrep -f "qemu.*omnios")
        echo "PID: $QEMU_PID"
        echo "Memory: $(ps -p $QEMU_PID -o rss= | awk '{print $1/1024 " MB"}')"
        echo "CPU: $(ps -p $QEMU_PID -o %cpu= | awk '{print $1 "%"}')"
    else
        echo "Status: Stopped"
    fi
    echo
}

show_network_info() {
    echo "=== Network Information ==="
    if command -v termux-wifi-connectioninfo > /dev/null; then
        termux-wifi-connectioninfo
    else
        echo "WiFi info not available (install termux-api)"
    fi
    echo
}

tail_logs() {
    echo "=== Recent Log Entries ==="
    if [ -f ~/omnios-2.0/logs/system.log ]; then
        tail -10 ~/omnios-2.0/logs/system.log
    else
        echo "No log files found"
    fi
}

case "$1" in
    "info") show_system_info ;;
    "status") show_omnios_status ;;
    "network") show_network_info ;;
    "logs") tail_logs ;;
    "all"|"") 
        show_system_info
        show_omnios_status
        show_network_info
        ;;
    *) echo "Usage: $0 {info|status|network|logs|all}" ;;
esac
EOF

chmod +x ~/omnios-2.0/scripts/monitor-omnios.sh
\`\`\`

---

*This guide covers the essential aspects of running OmniOS 2.0 in Termux. For additional support and community contributions, visit the OmniOS GitHub repository and community forums.*
