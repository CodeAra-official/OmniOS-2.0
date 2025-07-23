# OmniOS 2.0 Professional Edition

A complete 16-bit operating system with modern features, professional design, and comprehensive functionality.

## 🚀 Features

### Core System
- **Professional Design**: Clean black background with color-coded interface
- **Initial Setup System**: First-boot wizard for user account and system configuration
- **User Authentication**: Secure login system with password protection
- **Multi-theme Support**: Default, Matrix (Green), and High Contrast themes

### Enhanced Interface
- **Comprehensive Settings Menu**: 6 main configuration categories
- **Administrative Mode**: Elevated privileges with password protection
- **Color-coded Commands**: Professional command-line interface
- **Enhanced Help System**: Detailed documentation for all features

### System Management
- **WiFi Configuration**: Network scanning and connection management
- **User Management**: Account settings and administrative controls
- **Application Management**: System app control and configuration
- **Factory Reset**: Complete system restoration (admin-only)

### Build System
- **Color-coded Build Output**: Professional build process with status indicators
- **Comprehensive Error Handling**: Detailed error reporting and validation
- **Cross-platform Support**: Works on Linux, macOS, and Windows (WSL)
- **Automated Testing**: Built-in verification and validation

## 🛠️ Building OmniOS 2.0

### Prerequisites

**Required Tools:**
- `nasm` - Netwide Assembler for x86 assembly
- `dd` - Disk utility for image creation
- `make` - Build automation (optional)

**Optional Tools:**
- `qemu-system-i386` - For testing the OS
- `git` - For version control

### Installation Commands

**Ubuntu/Debian:**
\`\`\`bash
sudo apt-get update
sudo apt-get install nasm qemu-system-x86 build-essential
\`\`\`

**CentOS/RHEL/Fedora:**
\`\`\`bash
sudo dnf install nasm qemu-system-x86 make
# or for older versions:
sudo yum install nasm qemu-kvm make
\`\`\`

**macOS:**
\`\`\`bash
brew install nasm qemu make
\`\`\`

**Arch Linux:**
\`\`\`bash
sudo pacman -S nasm qemu make
\`\`\`

### Building the System

**Quick Build and Run:**
\`\`\`bash
./build.sh
\`\`\`

**Build Options:**
\`\`\`bash
./build.sh --build    # Build only
./build.sh --run      # Run existing build
./build.sh --clean    # Clean and rebuild
./build.sh --check    # Check dependencies
./build.sh --help     # Show help
\`\`\`

**Alternative Build Methods:**
\`\`\`bash
make all              # Build complete system
make run              # Build and run
make clean            # Clean build files
\`\`\`

## 🖥️ Running OmniOS 2.0

### QEMU (Recommended)
\`\`\`bash
# Standard run
./run.sh

# Text mode (no GUI)
./run-text.sh

# Safe mode (fallback display)
./run-safe.sh

# Manual QEMU command
qemu-system-i386 -drive format=raw,file=omnios.img,if=floppy -boot a
\`\`\`

### Physical Hardware
\`\`\`bash
# Flash to USB drive (replace /dev/sdX with your device)
sudo dd if=omnios.img of=/dev/sdX bs=512 status=progress

# Flash to floppy disk
sudo dd if=omnios.img of=/dev/fd0 bs=512
\`\`\`

## 📋 First Boot Experience

### Initial Setup Wizard
1. **System Detection**: Bootloader detects first boot automatically
2. **User Account Creation**: Create username and password
3. **Network Configuration**: Configure WiFi settings
4. **Color Scheme Selection**: Choose visual theme
5. **Setup Completion**: System ready for use

### Subsequent Boots
1. **Login Screen**: Enter username and password
2. **Desktop Environment**: Full system access
3. **Command Interface**: All features available

## 💻 Using OmniOS 2.0

### Basic Commands
\`\`\`
help        - Show comprehensive help menu
clear       - Clear screen and refresh desktop
version     - Show detailed system information
theme       - Change color scheme
logout      - Logout current user
exit        - Shutdown system
\`\`\`

### System Commands
\`\`\`
settings    - Open comprehensive settings menu
admin       - Toggle administrator mode
users       - User management interface
apps        - Application management system
wifi        - WiFi configuration menu
\`\`\`

### Administrative Commands
\`\`\`
factory     - Factory reset system (admin mode required)
\`\`\`

### Settings Menu Options
1. **WiFi Configuration** - Network management
2. **User Management** - Account settings
3. **Application Management** - System apps
4. **Admin Mode Toggle** - Privilege elevation
5. **Color Theme Selection** - Visual customization
6. **Factory Reset** - System restoration

## 🎨 Color Themes

### 1. Default (Professional)
- Black background with white text
- Professional business appearance
- Optimal for productivity

### 2. Matrix (Retro Terminal)
- Black background with green text
- Classic terminal aesthetic
- Nostalgic computing experience

### 3. High Contrast
- Black background with bright white text
- Maximum readability
- Accessibility optimized

## 🔧 Technical Specifications

### System Requirements
- **Architecture**: x86 16-bit Real Mode
- **Memory**: 640KB minimum
- **Storage**: 1.44MB floppy disk or equivalent
- **Display**: VGA compatible, 80x25 text mode

### File Structure
\`\`\`
OmniOS/
├── src/
│   ├── boot/
│   │   └── bootloader.asm    # Enhanced bootloader
│   └── kernel/
│       └── kernel.asm        # Complete kernel
├── build/                    # Build output directory
├── docs/                     # Documentation
├── build.sh                  # Main build script
├── run.sh                    # QEMU runner
├── Makefile                  # Build automation
└── README.md                 # This file
\`\`\`

### Build Output
- `bootloader.bin` - 512-byte bootloader
- `kernel.bin` - Complete kernel (9KB)
- `omnios.img` - Bootable 1.44MB disk image

## 🚨 Troubleshooting

### Common Issues

**Build Errors:**
\`\`\`bash
# Check dependencies
./build.sh --check

# Clean rebuild
./build.sh --clean

# View detailed errors
./build.sh --build 2>&1 | tee build.log
\`\`\`

**Runtime Issues:**
\`\`\`bash
# Use safe mode
./run-safe.sh

# Text mode only
./run-text.sh

# Check QEMU installation
qemu-system-i386 --version
\`\`\`

**Setup Not Appearing:**
- Ensure clean build: `./build.sh --clean`
- Verify first boot detection in bootloader
- Check disk image integrity

### Getting Help

1. **Check Build Report**: `./build.sh --report`
2. **Validate Environment**: `./build.sh --check`
3. **Review Logs**: Check build output for errors
4. **Test Components**: Build individual components

## 🔒 Security Features

### User Authentication
- Password-protected login system
- Secure credential storage
- Session management

### Administrative Controls
- Elevated privilege system
- Password-protected admin mode
- Restricted administrative commands

### System Protection
- Factory reset protection (admin-only)
- Secure boot process
- Data validation and verification

## 🌟 Advanced Features

### Professional Build System
- **Color-coded Output**: Status indicators for all operations
- **Comprehensive Validation**: Source file and dependency checking
- **Error Handling**: Detailed error reporting and recovery
- **Cross-platform**: Works on multiple operating systems

### Enhanced User Experience
- **Professional Interface**: Clean, modern design
- **Intuitive Navigation**: Easy-to-use menu systems
- **Comprehensive Help**: Built-in documentation
- **Accessibility**: High contrast and readable fonts

## 📈 Development

### Architecture Overview
- **Bootloader**: First-stage loader with setup detection
- **Kernel**: Complete operating system kernel
- **File System**: Custom setup flag management
- **User Interface**: Text-based with color support

### Key Components
1. **Boot Process**: Enhanced bootloader with first-boot detection
2. **Setup System**: Comprehensive initial configuration
3. **Authentication**: Secure user login system
4. **Command Interface**: Professional command-line environment
5. **Settings Management**: Complete system configuration

### Code Quality
- **Assembly Language**: Optimized x86 assembly code
- **Error Handling**: Comprehensive error checking
- **Documentation**: Detailed code comments
- **Testing**: Built-in validation and verification

## 📄 License

OmniOS 2.0 Professional Edition - Educational and Research Use

This operating system is designed for educational purposes and research into operating system development. Feel free to study, modify, and learn from the code.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Guidelines
1. Follow existing code style and conventions
2. Test all changes thoroughly
3. Update documentation as needed
4. Ensure cross-platform compatibility

## 📞 Support

For support and questions:
1. Check the troubleshooting section above
2. Review the comprehensive help system (`help` command)
3. Examine build logs and error messages
4. Test with different configurations

---

**OmniOS 2.0 Professional Edition** - A complete, modern operating system experience in 16-bit assembly language.
