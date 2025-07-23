# OmniOS 2.0 Professional Edition

A comprehensive 16-bit operating system with modern features, professional design, and enhanced user experience.

## 🌟 Key Features

### Core System Features
- **Professional Design**: Clean black background with optimized color schemes
- **Initial Setup System**: First-boot configuration wizard
- **User Authentication**: Secure login system with password protection
- **Administrative Mode**: Elevated privileges for system management
- **Factory Reset**: Complete system restoration capability

### Enhanced User Interface
- **Multiple Color Themes**: 
  - Default (Professional Black/White)
  - Matrix (Terminal Green/Black)
  - High Contrast (Maximum Readability)
- **Comprehensive Help System**: Detailed command documentation
- **Interactive Settings Menu**: Centralized system configuration
- **Professional Command Interface**: Enhanced command processing

### System Management
- **WiFi Configuration**: Network setup and management
- **User Management**: Account settings and administration
- **Application Management**: System application control
- **Theme Customization**: Real-time color scheme switching
- **System Information**: Detailed version and status display

### Build System Features
- **Color-Coded Output**: Professional build feedback
- **Comprehensive Error Handling**: Detailed error reporting
- **Dependency Checking**: Automatic tool verification
- **Multi-Platform Support**: Linux, macOS, and Windows compatibility

## 🚀 Quick Start

### Prerequisites
\`\`\`bash
# Ubuntu/Debian
sudo apt-get install nasm qemu-system-x86

# CentOS/RHEL
sudo yum install nasm qemu-kvm

# macOS
brew install nasm qemu

# Arch Linux
sudo pacman -S nasm qemu
\`\`\`

### Building OmniOS
\`\`\`bash
# Clone the repository
git clone <repository-url>
cd omnios-2.0

# Make build script executable
chmod +x build.sh

# Build the system
./build.sh
\`\`\`

### Running OmniOS
\`\`\`bash
# Standard mode (GUI)
./run.sh

# Text mode
./run-text.sh

# Safe mode (debugging)
./run-safe.sh
\`\`\`

## 📋 System Requirements

### Development Environment
- **NASM Assembler**: Version 2.13 or higher
- **QEMU Emulator**: Version 2.5 or higher (for testing)
- **Unix-like OS**: Linux, macOS, or WSL on Windows
- **Disk Space**: Minimum 50MB for build environment

### Target Hardware
- **Architecture**: x86 (16-bit Real Mode)
- **Memory**: Minimum 640KB RAM
- **Storage**: 1.44MB floppy disk or USB drive
- **Display**: VGA-compatible display adapter

## 🎯 First Boot Experience

### Initial Setup Process
1. **System Detection**: Automatic first-boot detection
2. **User Account Creation**: Username and password setup
3. **Network Configuration**: WiFi setup and connection
4. **Theme Selection**: Choose your preferred color scheme
5. **Setup Completion**: System ready for use

### Subsequent Boots
- **Login Screen**: Secure authentication required
- **Desktop Environment**: Professional interface with system status
- **Command Interface**: Full access to system features

## 💻 Command Reference

### Basic Commands
- `help` - Display comprehensive command help
- `clear` - Clear screen and refresh desktop
- `version` - Show system version and build information
- `theme` - Change color scheme interactively
- `logout` - Return to login screen
- `exit` - Shutdown system

### System Commands
- `settings` - Open comprehensive settings menu
- `admin` - Toggle administrator mode
- `users` - User account management
- `apps` - Application management interface

### Network Commands
- `wifi` - WiFi configuration and network management

### Administrative Commands (Admin Mode Required)
- `factory` - Factory reset system to defaults

## ⚙️ Settings Menu Options

### 1. WiFi Configuration
- Network scanning and detection
- Connection management
- Signal strength monitoring
- Security configuration

### 2. User Management
- Account information display
- Password management
- Administrative status
- User preferences

### 3. Application Management
- Installed application listing
- Application configuration
- System tool management
- Feature toggles

### 4. Admin Mode Toggle
- Secure privilege elevation
- Administrative access control
- System-level operations
- Security management

### 5. Color Theme Selection
- Real-time theme switching
- Professional color schemes
- Accessibility options
- Custom theme support

### 6. Factory Reset
- Complete system restoration
- Data erasure warning
- Confirmation process
- Automatic system restart

## 🎨 Color Themes

### Default Theme (Professional)
- **Background**: Black
- **Text**: Light Gray/White
- **Accents**: Cyan, Green, Yellow
- **Errors**: Red
- **Use Case**: Professional environments, general use

### Matrix Theme (Retro)
- **Background**: Black
- **Text**: Green
- **Accents**: Bright Green
- **Errors**: Red
- **Use Case**: Terminal enthusiasts, retro computing

### High Contrast Theme (Accessibility)
- **Background**: Black
- **Text**: Bright White
- **Accents**: High contrast colors
- **Errors**: Bright Red
- **Use Case**: Accessibility, low vision users

## 🔧 Build System Details

### Color-Coded Build Output
- **🔵 [INFO]**: General information messages
- **🟢 [SUCCESS]**: Successful operations
- **🟡 [WARNING]**: Non-critical warnings
- **🔴 [ERROR]**: Critical errors requiring attention

### Build Process Steps
1. **Dependency Checking**: Verify required tools
2. **Environment Setup**: Create build directories
3. **Source Validation**: Check source file integrity
4. **Bootloader Assembly**: Compile bootloader code
5. **Kernel Assembly**: Compile kernel code
6. **Image Creation**: Generate bootable disk image
7. **Verification**: Validate final image
8. **Summary**: Display build results

### Build Artifacts
- `build/bootloader.bin` - Assembled bootloader (512 bytes)
- `build/kernel.bin` - Assembled kernel (12KB)
- `build/omnios.img` - Temporary build image
- `omnios.img` - Final bootable image (1.44MB)

## 🚀 Advanced Usage

### Custom Installation
\`\`\`bash
# Flash to USB drive (replace /dev/sdX with your device)
sudo dd if=omnios.img of=/dev/sdX bs=512 status=progress

# Flash to floppy disk
sudo dd if=omnios.img of=/dev/fd0 bs=512
\`\`\`

### Development Mode
\`\`\`bash
# Build with debug information
./build-debug.sh

# Enhanced build with additional features
./build-enhanced.sh

# Termux compatibility build
./build-termux.sh
\`\`\`

### System Maintenance
\`\`\`bash
# Clean build artifacts
./clean.sh

# Verify build integrity
./verify-build.sh

# Update system components
./update.sh
\`\`\`

## 🔒 Security Features

### Authentication System
- **Secure Login**: Password-protected user accounts
- **Admin Mode**: Elevated privilege system
- **Session Management**: Automatic logout capabilities
- **Factory Reset Protection**: Admin-only system reset

### Data Protection
- **Password Masking**: Hidden password input
- **Secure Storage**: Protected credential storage
- **Access Control**: Role-based system access
- **Audit Trail**: System operation logging

## 🐛 Troubleshooting

### Common Build Issues
1. **Missing NASM**: Install NASM assembler
2. **Permission Denied**: Make scripts executable with `chmod +x`
3. **QEMU Not Found**: Install QEMU for testing
4. **Disk Space**: Ensure adequate free space

### Runtime Issues
1. **Boot Failure**: Verify image integrity
2. **Setup Loop**: Check first-boot flag
3. **Login Issues**: Verify password entry
4. **Display Problems**: Try different color themes

### Recovery Options
1. **Factory Reset**: Use admin mode factory reset
2. **Safe Mode**: Boot with `./run-safe.sh`
3. **Rebuild**: Clean build with `./clean.sh && ./build.sh`
4. **Manual Recovery**: Flash fresh image to device

## 📈 Version History

### Version 2.0.0 (Current)
- Professional black background design
- Complete feature integration
- Enhanced build system with color coding
- Comprehensive settings menu
- Factory reset capability
- Multiple color theme support
- Improved error handling and user feedback

### Previous Versions
- Version 1.x: Basic functionality and core features
- Version 0.x: Initial development and prototyping

## 🤝 Contributing

### Development Guidelines
1. Follow existing code style and conventions
2. Test all changes thoroughly
3. Update documentation for new features
4. Ensure backward compatibility
5. Use professional color schemes (avoid blue backgrounds)

### Reporting Issues
1. Provide detailed error descriptions
2. Include build environment information
3. Attach relevant log files
4. Specify reproduction steps

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- NASM Development Team for the excellent assembler
- QEMU Project for emulation capabilities
- Open Source Community for inspiration and support
- Contributors and testers for feedback and improvements

---

**OmniOS 2.0 Professional Edition** - A modern approach to classic computing with professional design and enhanced functionality.
