# OmniOS 2.0 Build Guide for Redmi Devices

## Overview
This guide provides detailed instructions for building and deploying OmniOS 2.0 on Redmi devices, including setup, compilation, and flashing procedures.

## Prerequisites

### Hardware Requirements
- **Redmi Device**: Note 11/12 series or newer
- **RAM**: Minimum 4GB, Recommended 6GB+
- **Storage**: 8GB free space
- **USB Cable**: High-quality USB-C cable
- **PC/Laptop**: For building and flashing

### Software Requirements
- **ADB & Fastboot**: Latest Android SDK Platform Tools
- **Termux**: Latest version from F-Droid
- **Build Tools**: GCC, NASM, Make, Git
- **QEMU**: For testing before deployment

## Build Environment Setup

### 1. Install Build Dependencies

#### On Ubuntu/Debian:
\`\`\`bash
sudo apt update
sudo apt install -y build-essential nasm qemu-system-x86 mtools git curl jq
sudo apt install -y android-tools-adb android-tools-fastboot
\`\`\`

#### On Termux (Android):
\`\`\`bash
pkg update && pkg upgrade
pkg install -y nasm gcc qemu-system-i386 mtools git curl jq
pkg install -y android-tools
\`\`\`

### 2. Clone OmniOS Repository
\`\`\`bash
git clone https://github.com/omnios/omnios-2.0.git
cd omnios-2.0
chmod +x *.sh
\`\`\`

### 3. Configure Build Environment
\`\`\`bash
# Set target device
export OMNIOS_TARGET="redmi"
export OMNIOS_ARCH="arm64"
export OMNIOS_DEVICE_MODEL="redmi_note12"

# Configure build options
export OMNIOS_BUILD_TYPE="release"
export OMNIOS_ENABLE_WIFI="true"
export OMNIOS_ENABLE_BLUETOOTH="true"
\`\`\`

## Building OmniOS 2.0

### 1. Standard Build Process
\`\`\`bash
# Run enhanced build script
./build-enhanced.sh

# Verify build
ls -la build/OmniOS.img
\`\`\`

### 2. Redmi-Specific Build
\`\`\`bash
# Create Redmi-specific build
./build-redmi.sh --device=note12 --arch=arm64

# This creates:
# - build/OmniOS-redmi.img (System image)
# - build/omnios-boot.img (Boot image)
# - build/omnios-recovery.img (Recovery image)
\`\`\`

### 3. Build Verification
\`\`\`bash
# Test in QEMU before flashing
./test-redmi-build.sh

# Check build integrity
./verify-build.sh
\`\`\`

## Device Preparation

### 1. Enable Developer Options
1. Go to **Settings** → **About Phone**
2. Tap **MIUI Version** 7 times
3. Go back to **Settings** → **Additional Settings** → **Developer Options**
4. Enable **USB Debugging**
5. Enable **OEM Unlocking**

### 2. Unlock Bootloader
\`\`\`bash
# Boot to fastboot mode
adb reboot bootloader

# Unlock bootloader (requires Mi Unlock Tool)
fastboot oem unlock

# Verify unlock status
fastboot oem device-info
\`\`\`

### 3. Install Custom Recovery (Optional)
\`\`\`bash
# Flash TWRP recovery
fastboot flash recovery twrp-redmi-note12.img

# Boot to recovery
fastboot boot twrp-redmi-note12.img
\`\`\`

## Flashing OmniOS 2.0

### Method 1: Direct Flash (Recommended)
\`\`\`bash
# Create flash script
./create-flash-script.sh --device=redmi_note12

# Flash OmniOS
./flash-omnios-redmi.sh

# The script will:
# 1. Backup current system
# 2. Flash OmniOS bootloader
# 3. Flash OmniOS system
# 4. Configure dual-boot (optional)
\`\`\`

### Method 2: Termux Installation
\`\`\`bash
# Install in Termux environment
./install-termux-redmi.sh

# This creates a virtualized OmniOS environment
# that runs alongside Android
\`\`\`

### Method 3: Dual Boot Setup
\`\`\`bash
# Setup dual boot with Android
./setup-dualboot-redmi.sh

# Choose boot option:
# 1. Android (default)
# 2. OmniOS 2.0
\`\`\`

## Post-Installation Configuration

### 1. First Boot Setup
1. Power on device
2. OmniOS Setup Wizard will start
3. Configure:
   - Language and Region
   - WiFi Connection
   - User Account
   - System Settings

### 2. Install Core Applications
\`\`\`bash
# Connect via ADB
adb connect <device_ip>

# Install core apps
adb push build/packages/*.opi /system/packages/
adb shell "omnios-pkg install core-apps.opi"
\`\`\`

### 3. Configure Hardware Drivers
\`\`\`bash
# Install Redmi-specific drivers
adb shell "omnios-pkg install redmi-drivers.opi"

# Configure WiFi
adb shell "omnios-wifi configure"

# Configure Bluetooth
adb shell "omnios-bluetooth setup"
\`\`\`

## Troubleshooting

### Common Issues

#### Build Fails with "Permission Denied"
\`\`\`bash
chmod +x *.sh
sudo chown -R $USER:$USER .
\`\`\`

#### Device Not Detected
\`\`\`bash
# Check ADB connection
adb devices

# Restart ADB server
adb kill-server
adb start-server

# Check USB debugging
adb shell getprop ro.debuggable
\`\`\`

#### Boot Loop After Flash
\`\`\`bash
# Boot to recovery
fastboot boot recovery.img

# Restore from backup
adb shell "restore-android-backup.sh"

# Or reflash stock ROM
fastboot flash system stock-rom.img
\`\`\`

#### WiFi Not Working
\`\`\`bash
# Check driver status
adb shell "omnios-driver status wifi"

# Reinstall WiFi driver
adb shell "omnios-pkg reinstall wifi-driver.opi"

# Reset network settings
adb shell "omnios-network reset"
\`\`\`

### Advanced Troubleshooting

#### Enable Debug Mode
\`\`\`bash
# Build with debug symbols
./build-enhanced.sh --debug --verbose

# Enable kernel debugging
echo "debug=1" >> build/system.cfg

# View system logs
adb shell "omnios-log view"
\`\`\`

#### Recovery Mode
\`\`\`bash
# Boot to OmniOS recovery
fastboot boot build/omnios-recovery.img

# Recovery options:
# 1. Factory Reset
# 2. Install from USB
# 3. Backup/Restore
# 4. System Repair
\`\`\`

## Performance Optimization

### 1. Memory Optimization
\`\`\`bash
# Configure memory settings
echo "memory_limit=2048M" >> build/system.cfg
echo "swap_enabled=true" >> build/system.cfg
echo "zram_enabled=true" >> build/system.cfg
\`\`\`

### 2. CPU Optimization
\`\`\`bash
# Set CPU governor
echo "cpu_governor=performance" >> build/system.cfg
echo "cpu_cores=8" >> build/system.cfg
\`\`\`

### 3. Storage Optimization
\`\`\`bash
# Enable compression
echo "filesystem_compression=true" >> build/system.cfg
echo "trim_enabled=true" >> build/system.cfg
\`\`\`

## Backup and Recovery

### Create System Backup
\`\`\`bash
# Backup current Android system
./backup-android-system.sh

# Backup OmniOS installation
./backup-omnios-system.sh
\`\`\`

### Restore System
\`\`\`bash
# Restore Android
./restore-android-system.sh

# Restore OmniOS
./restore-omnios-system.sh
\`\`\`

## Updates and Maintenance

### Update OmniOS
\`\`\`bash
# Check for updates
adb shell "omnios-update check"

# Download and install updates
adb shell "omnios-update install"

# Reboot to apply updates
adb shell "reboot"
\`\`\`

### Package Management
\`\`\`bash
# List installed packages
adb shell "omnios-pkg list"

# Install new package
adb shell "omnios-pkg install package.opi"

# Remove package
adb shell "omnios-pkg remove package_name"

# Update all packages
adb shell "omnios-pkg update-all"
\`\`\`

## Support and Community

### Getting Help
- **Documentation**: /docs/
- **Community Forum**: https://forum.omnios.org
- **Issue Tracker**: https://github.com/omnios/omnios-2.0/issues
- **Telegram**: @OmniOSRedmi

### Contributing
\`\`\`bash
# Setup development environment
./setup-dev-env.sh

# Create feature branch
git checkout -b feature/new-feature

# Submit pull request
git push origin feature/new-feature
\`\`\`

---

**Warning**: Flashing custom firmware may void your warranty and can potentially brick your device. Proceed at your own risk and ensure you have proper backups.

**Note**: This guide is specific to Redmi devices. For other devices, refer to the general installation guide.
