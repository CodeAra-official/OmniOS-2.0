#!/bin/bash
# OmniOS 2.0 Redmi Device Flash Script

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DEVICE_MODEL=""
FLASH_MODE="dual-boot"
BACKUP_ENABLED="true"
VERIFY_FLASH="true"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                OmniOS 2.0 Redmi Flash Tool                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --device=*)
            DEVICE_MODEL="${1#*=}"
            shift
            ;;
        --mode=*)
            FLASH_MODE="${1#*=}"
            shift
            ;;
        --no-backup)
            BACKUP_ENABLED="false"
            shift
            ;;
        --no-verify)
            VERIFY_FLASH="false"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --device=MODEL    Target device model (e.g., redmi_note12)"
            echo "  --mode=MODE       Flash mode: dual-boot, replace, termux"
            echo "  --no-backup       Skip backup creation"
            echo "  --no-verify       Skip flash verification"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Detect device if not specified
if [ -z "$DEVICE_MODEL" ]; then
    echo -e "${YELLOW}Detecting device model...${NC}"
    DEVICE_MODEL=$(adb shell getprop ro.product.model | tr -d '\r' | sed 's/ /_/g')
    echo -e "${GREEN}Detected: $DEVICE_MODEL${NC}"
fi

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check ADB
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}Error: ADB not found${NC}"
        exit 1
    fi
    
    # Check Fastboot
    if ! command -v fastboot &> /dev/null; then
        echo -e "${RED}Error: Fastboot not found${NC}"
        exit 1
    fi
    
    # Check device connection
    if ! adb devices | grep -q "device$"; then
        echo -e "${RED}Error: No device connected${NC}"
        echo "Please connect your device and enable USB debugging"
        exit 1
    fi
    
    # Check build files
    if [ ! -f "build/OmniOS.img" ]; then
        echo -e "${RED}Error: OmniOS image not found${NC}"
        echo "Please run ./build-enhanced.sh first"
        exit 1
    fi
    
    echo -e "${GREEN}Prerequisites check passed ✓${NC}"
}

# Create backup
create_backup() {
    if [ "$BACKUP_ENABLED" = "true" ]; then
        echo -e "${BLUE}Creating system backup...${NC}"
        
        mkdir -p backups/$(date +%Y%m%d_%H%M%S)
        BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
        
        # Backup boot partition
        adb shell "su -c 'dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img'"
        adb pull /sdcard/boot_backup.img "$BACKUP_DIR/"
        
        # Backup system partition
        adb shell "su -c 'dd if=/dev/block/by-name/system of=/sdcard/system_backup.img'"
        adb pull /sdcard/system_backup.img "$BACKUP_DIR/"
        
        # Backup recovery partition
        adb shell "su -c 'dd if=/dev/block/by-name/recovery of=/sdcard/recovery_backup.img'"
        adb pull /sdcard/recovery_backup.img "$BACKUP_DIR/"
        
        echo -e "${GREEN}Backup created in $BACKUP_DIR ✓${NC}"
    fi
}

# Flash OmniOS
flash_omnios() {
    echo -e "${BLUE}Flashing OmniOS 2.0...${NC}"
    
    case $FLASH_MODE in
        "dual-boot")
            flash_dual_boot
            ;;
        "replace")
            flash_replace
            ;;
        "termux")
            install_termux
            ;;
        *)
            echo -e "${RED}Unknown flash mode: $FLASH_MODE${NC}"
            exit 1
            ;;
    esac
}

# Dual boot installation
flash_dual_boot() {
    echo -e "${YELLOW}Installing OmniOS in dual-boot mode...${NC}"
    
    # Reboot to bootloader
    adb reboot bootloader
    sleep 5
    
    # Flash custom bootloader that supports dual boot
    fastboot flash boot build/omnios-dualboot-bootloader.img
    
    # Create OmniOS partition
    fastboot oem create-partition omnios 2048M
    
    # Flash OmniOS system
    fastboot flash omnios build/OmniOS.img
    
    # Flash OmniOS recovery
    fastboot flash recovery build/omnios-recovery.img
    
    # Set boot menu timeout
    fastboot oem set-boot-timeout 5
    
    echo -e "${GREEN}Dual-boot installation completed ✓${NC}"
    echo -e "${YELLOW}Boot options:${NC}"
    echo -e "  1. Android (default)"
    echo -e "  2. OmniOS 2.0"
}

# Replace Android installation
flash_replace() {
    echo -e "${YELLOW}Replacing Android with OmniOS...${NC}"
    echo -e "${RED}WARNING: This will completely replace Android!${NC}"
    
    read -p "Are you sure? Type 'YES' to continue: " confirm
    if [ "$confirm" != "YES" ]; then
        echo "Installation cancelled"
        exit 1
    fi
    
    # Reboot to bootloader
    adb reboot bootloader
    sleep 5
    
    # Flash OmniOS bootloader
    fastboot flash boot build/omnios-bootloader.img
    
    # Flash OmniOS system
    fastboot flash system build/OmniOS.img
    
    # Flash OmniOS recovery
    fastboot flash recovery build/omnios-recovery.img
    
    # Wipe user data
    fastboot erase userdata
    fastboot erase cache
    
    echo -e "${GREEN}OmniOS installation completed ✓${NC}"
}

# Termux installation
install_termux() {
    echo -e "${YELLOW}Installing OmniOS in Termux environment...${NC}"
    
    # Push OmniOS files to device
    adb push build/OmniOS.img /sdcard/omnios/
    adb push build-termux.sh /sdcard/omnios/
    adb push launch-omnios.sh /sdcard/omnios/
    
    # Install in Termux
    adb shell "am start -n com.termux/.HomeActivity"
    adb shell "input text 'cd /sdcard/omnios && ./build-termux.sh'"
    adb shell "input keyevent 66"  # Enter key
    
    echo -e "${GREEN}Termux installation initiated ✓${NC}"
    echo -e "${YELLOW}Complete the installation in Termux app${NC}"
}

# Verify flash
verify_flash() {
    if [ "$VERIFY_FLASH" = "true" ]; then
        echo -e "${BLUE}Verifying flash...${NC}"
        
        # Reboot device
        fastboot reboot
        sleep 10
        
        # Check if OmniOS boots
        if adb wait-for-device shell "getprop ro.omnios.version" | grep -q "2.0"; then
            echo -e "${GREEN}Flash verification passed ✓${NC}"
        else
            echo -e "${RED}Flash verification failed!${NC}"
            echo -e "${YELLOW}Device may need recovery${NC}"
        fi
    fi
}

# Main execution
main() {
    check_prerequisites
    create_backup
    flash_omnios
    verify_flash
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 FLASH COMPLETED SUCCESSFULLY!               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "${WHITE}Flash Summary:${NC}"
    echo -e "  Device: $DEVICE_MODEL"
    echo -e "  Mode: $FLASH_MODE"
    echo -e "  Backup: $BACKUP_ENABLED"
    echo -e "  Verification: $VERIFY_FLASH"
    
    if [ "$FLASH_MODE" = "dual-boot" ]; then
        echo -e "\n${CYAN}Next Steps:${NC}"
        echo -e "1. Reboot your device"
        echo -e "2. Select OmniOS from boot menu"
        echo -e "3. Complete initial setup"
        echo -e "4. Install additional packages"
    fi
    
    echo -e "\n${YELLOW}Support:${NC}"
    echo -e "  Documentation: docs/redmi-build-guide.md"
    echo -e "  Community: https://forum.omnios.org"
    echo -e "  Issues: https://github.com/omnios/omnios-2.0/issues"
}

# Run main function
main "$@"
