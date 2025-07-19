# OmniOS 2.0 Installation Guide for Redmi Devices

## Prerequisites

### Required Tools
- **ADB (Android Debug Bridge)** - Latest version
- **Fastboot** - Latest version  
- **Termux** - Latest version from F-Droid or Play Store
- **OmniOS 2.0 Installation Package** - omnios-2.0-redmi.zip

### Supported Redmi Devices
- Redmi Note 12 Pro+ 5G
- Redmi Note 12 Pro 5G
- Redmi Note 12 5G
- Redmi Note 11 Pro+ 5G
- Redmi Note 11 Pro 5G
- Redmi Note 11 5G
- Redmi 12 5G
- Redmi 11 Prime 5G

## Installation Methods

### Method 1: Termux Installation (Recommended)

#### Step 1: Install Termux
1. Download Termux from F-Droid (recommended) or Google Play Store
2. Open Termux and run initial setup:
\`\`\`bash
pkg update && pkg upgrade
pkg install git wget unzip
\`\`\`

#### Step 2: Download OmniOS 2.0
\`\`\`bash
cd ~
wget https://github.com/omnios/releases/omnios-2.0-termux.tar.gz
tar -xzf omnios-2.0-termux.tar.gz
cd omnios-2.0
\`\`\`

#### Step 3: Install Dependencies
\`\`\`bash
pkg install qemu-system-i386
pkg install nasm
pkg install mtools
\`\`\`

#### Step 4: Build and Run OmniOS
\`\`\`bash
chmod +x build-termux.sh
./build-termux.sh
\`\`\`

#### Step 5: Launch OmniOS
\`\`\`bash
./run-omnios.sh
\`\`\`

### Method 2: Dual Boot Installation (Advanced)

**⚠️ WARNING: This method requires unlocked bootloader and can brick your device if done incorrectly.**

#### Prerequisites for Dual Boot
- Unlocked bootloader
- Custom recovery (TWRP)
- Root access
- 4GB+ free storage space

#### Step 1: Prepare Device
1. Enable Developer Options
2. Enable USB Debugging
3. Enable OEM Unlocking
4. Connect to PC via USB

#### Step 2: Create OmniOS Partition
\`\`\`bash
adb shell
su
fdisk /dev/block/sda
# Create 2GB partition for OmniOS
# Note: Exact commands vary by device
\`\`\`

#### Step 3: Install OmniOS Bootloader
\`\`\`bash
adb push omnios-bootloader.img /sdcard/
adb shell
su
dd if=/sdcard/omnios-bootloader.img of=/dev/block/by-name/boot_b
\`\`\`

#### Step 4: Install OmniOS System
\`\`\`bash
adb push omnios-system.img /sdcard/
adb shell
su
dd if=/sdcard/omnios-system.img of=/dev/block/sda8  # OmniOS partition
\`\`\`

### Method 3: Virtual Machine Installation

#### Step 1: Install Virtualization App
Download one of these Android virtualization apps:
- **Limbo PC Emulator** (Free)
- **VMOS Pro** (Paid)
- **Bochs** (Free)

#### Step 2: Configure Virtual Machine
1. Create new VM with these specs:
   - Architecture: x86
   - RAM: 512MB (minimum), 1GB (recommended)
   - Storage: 2GB
   - Network: NAT

#### Step 3: Install OmniOS
1. Download omnios-2.0-vm.iso
2. Boot VM from ISO
3. Follow on-screen installation instructions

## Termux-Specific Configuration

### Performance Optimization
\`\`\`bash
# Add to ~/.bashrc
export QEMU_OPTS="-cpu max -smp 2 -m 512M -enable-kvm"
export OMNIOS_HOME="/data/data/com.termux/files/home/omnios-2.0"
\`\`\`

### Storage Configuration
\`\`\`bash
# Create OmniOS storage directory
mkdir -p ~/omnios-data/{documents,downloads,apps}

# Mount external storage (if needed)
termux-setup-storage
ln -s ~/storage/shared ~/omnios-data/shared
\`\`\`

### Network Configuration
\`\`\`bash
# Enable WiFi access for OmniOS
pkg install iproute2
# Configure bridge network (requires root)
\`\`\`

## Device-Specific Instructions

### Redmi Note 12 Series
\`\`\`bash
# Specific build configuration
export DEVICE_TYPE="redmi_note12"
export CPU_ARCH="arm64"
export RAM_SIZE="8192"  # 8GB models
\`\`\`

### Redmi Note 11 Series
\`\`\`bash
export DEVICE_TYPE="redmi_note11"
export CPU_ARCH="arm64" 
export RAM_SIZE="6144"  # 6GB models
\`\`\`

### Redmi 12 Series
\`\`\`bash
export DEVICE_TYPE="redmi_12"
export CPU_ARCH="arm64"
export RAM_SIZE="4096"  # 4GB models
\`\`\`

## Troubleshooting

### Common Issues

#### Issue: "Permission Denied" in Termux
**Solution:**
\`\`\`bash
chmod +x *.sh
pkg install termux-api
\`\`\`

#### Issue: QEMU Won't Start
**Solution:**
\`\`\`bash
pkg reinstall qemu-system-i386
# Check if virtualization is supported
cat /proc/cpuinfo | grep "Features"
\`\`\`

#### Issue: Slow Performance
**Solutions:**
1. Increase RAM allocation:
\`\`\`bash
export QEMU_OPTS="-m 1024M"
\`\`\`

2. Enable hardware acceleration:
\`\`\`bash
export QEMU_OPTS="$QEMU_OPTS -enable-kvm"
\`\`\`

3. Use lighter OmniOS configuration:
\`\`\`bash
./configure --minimal --no-gui-effects
\`\`\`

#### Issue: Network Not Working
**Solution:**
\`\`\`bash
# Reset network configuration
termux-setup-storage
pkg install net-tools
ifconfig -a

# Restart QEMU with network
export QEMU_OPTS="$QEMU_OPTS -netdev user,id=net0 -device rtl8139,netdev=net0"
\`\`\`

#### Issue: Boot Failure
**Solution:**
\`\`\`bash
# Check boot logs
dmesg | tail -20

# Rebuild with debug
./build-termux.sh --debug --verbose

# Use recovery mode
./run-omnios.sh --recovery
\`\`\`

#### Issue: Touch Input Not Working
**Solution:**
\`\`\`bash
# Enable touch input mapping
export QEMU_OPTS="$QEMU_OPTS -device usb-tablet"

# For direct hardware access (requires root)
pkg install libevdev
\`\`\`

### Advanced Configuration

#### Custom Kernel Parameters
\`\`\`bash
# Create custom boot config
cat > ~/omnios-2.0/boot.conf &lt;&lt; EOF
memory=512M
cpu_cores=2
enable_sound=true
enable_network=true
enable_usb=true
debug_mode=false
EOF
\`\`\`

#### Performance Tuning
\`\`\`bash
# CPU governor optimization
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Memory optimization
echo 1 > /proc/sys/vm/drop_caches
echo 3 > /proc/sys/vm/drop_caches
\`\`\`

## Security Considerations

### Permissions Setup
\`\`\`bash
# Set proper file permissions
chmod 755 ~/omnios-2.0/
chmod 644 ~/omnios-2.0/config/*
chmod 600 ~/omnios-2.0/keys/*
\`\`\`

### Firewall Configuration
\`\`\`bash
# Basic firewall rules for OmniOS
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -j DROP
\`\`\`

### Data Encryption
\`\`\`bash
# Enable encrypted storage
./omnios-config --enable-encryption
# Set encryption password when prompted
\`\`\`

## Backup and Recovery

### Creating System Backup
\`\`\`bash
# Backup OmniOS installation
tar -czf omnios-backup-$(date +%Y%m%d).tar.gz ~/omnios-2.0/

# Backup user data
tar -czf omnios-userdata-$(date +%Y%m%d).tar.gz ~/omnios-data/
\`\`\`

### Restore from Backup
\`\`\`bash
# Restore system
cd ~
tar -xzf omnios-backup-YYYYMMDD.tar.gz

# Restore user data
tar -xzf omnios-userdata-YYYYMMDD.tar.gz
\`\`\`

### Recovery Mode
\`\`\`bash
# Boot into recovery mode
./run-omnios.sh --recovery

# Reset to factory defaults
./omnios-config --factory-reset
\`\`\`

## Integration with Android

### File Sharing
\`\`\`bash
# Setup shared folders
mkdir -p ~/omnios-data/android-shared
ln -s ~/storage/shared/Documents ~/omnios-data/android-shared/documents
ln -s ~/storage/shared/Downloads ~/omnios-data/android-shared/downloads
\`\`\`

### Notification Integration
\`\`\`bash
# Install notification bridge
pkg install termux-api
# Configure OmniOS to send notifications to Android
echo "notification_bridge=true" >> ~/omnios-2.0/config/system.conf
\`\`\`

### Intent Handling
\`\`\`bash
# Setup Android intent handling
cat > ~/omnios-2.0/scripts/android-intent.sh &lt;&lt; 'EOF'
#!/bin/bash
# Handle Android intents in OmniOS
case "$1" in
    "open_file")
        omnios-app filemanager "$2"
        ;;
    "edit_text")
        omnios-app notepad "$2"
        ;;
    *)
        echo "Unknown intent: $1"
        ;;
esac
EOF
chmod +x ~/omnios-2.0/scripts/android-intent.sh
\`\`\`

## Automation Scripts

### Auto-Start Script
\`\`\`bash
# Create auto-start script
cat > ~/omnios-2.0/autostart.sh &lt;&lt; 'EOF'
#!/bin/bash
# Auto-start OmniOS on Termux launch

# Check if OmniOS should auto-start
if [ -f ~/.omnios-autostart ]; then
    echo "Starting OmniOS 2.0..."
    cd ~/omnios-2.0
    ./run-omnios.sh
fi
EOF

# Enable auto-start
touch ~/.omnios-autostart
echo "source ~/omnios-2.0/autostart.sh" >> ~/.bashrc
\`\`\`

### Update Script
\`\`\`bash
# Create update script
cat > ~/omnios-2.0/update.sh &lt;&lt; 'EOF'
#!/bin/bash
echo "Checking for OmniOS updates..."
wget -q https://github.com/omnios/releases/latest-version.txt
LATEST=$(cat latest-version.txt)
CURRENT=$(cat ~/omnios-2.0/VERSION)

if [ "$LATEST" != "$CURRENT" ]; then
    echo "Update available: $LATEST"
    echo "Current version: $CURRENT"
    read -p "Download update? (y/n): " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        wget https://github.com/omnios/releases/omnios-$LATEST-termux.tar.gz
        echo "Update downloaded. Run ./install-update.sh to apply."
    fi
else
    echo "OmniOS is up to date."
fi
EOF
chmod +x ~/omnios-2.0/update.sh
\`\`\`

## Support and Community

### Getting Help
- **Official Forum**: https://forum.omnios.org
- **Telegram Group**: @OmniOSSupport
- **Discord**: discord.gg/omnios
- **Reddit**: r/OmniOS

### Reporting Issues
\`\`\`bash
# Generate debug information
./omnios-debug-info.sh > debug-report.txt
# Upload debug-report.txt when reporting issues
\`\`\`

### Contributing
\`\`\`bash
# Setup development environment
git clone https://github.com/omnios/omnios-2.0.git
cd omnios-2.0
./setup-dev-env.sh
\`\`\`

## Legal and Disclaimer

**Important Legal Notice:**
- OmniOS installation may void your device warranty
- Dual-boot installation carries risk of device damage
- Always backup your data before installation
- Use at your own risk

**Compatibility Disclaimer:**
- Not all Redmi devices are fully supported
- Some features may not work on all hardware configurations
- Performance varies by device specifications

---

*OmniOS 2.0 Installation Guide v2.0.1*  
*Last Updated: January 2025*  
*For technical support, visit: https://support.omnios.org*
