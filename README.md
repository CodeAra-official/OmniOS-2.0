# OmniOS 2.0 Enhanced Command Edition

## Overview
OmniOS 2.0 Enhanced Command Edition is a professional operating system with a complete command set for modern computing needs. This edition includes 20+ commands covering file operations, media control, network functions, and system administration.

## Complete Command Set

### Basic Commands
- `help` - Show complete command reference
- `ls` - List files and directories with type indicators
- `cd <directory>` - Change directory (supports .. and /)
- `exit` - Exit current application
- `off` - Shutdown system safely

### File Operations
- `add <filename>` - Add new file or folder
- `delete <filename>` - Delete file or folder (with confirmation)
- `move <source> <dest>` - Move files/folders
- `cut <filename>` - Cut file to clipboard
- `copy <filename>` - Copy file to clipboard

### System Commands
- `install <package>` - Install software packages
- `set <option>` - Configure system settings (color, time, language)
- `admin` - Toggle administrator mode
- `retry` - Retry last command
- `back` - Go back/parent directory
- `go <location>` - Navigate to specific location

### Media & Network
- `play <filename>` - Play media files
- `stop` - Stop media playback
- `download <url>` - Download files from internet

### Applications
- `open notepad` - Text editor with full editing capabilities
- `open settings` - System configuration panel
- `open files` - Advanced file manager
- `open terminal` - Enhanced terminal mode

## Features

### Professional Interface
- Blue professional theme
- Color-coded output (green=success, red=error, yellow=warning)
- Admin mode indicator
- Enhanced prompts and status messages

### File System
- Directory support with proper navigation
- File type indicators (d=directory, -=file)
- Parent directory navigation (..)
- Root directory support

### System Administration
- Admin mode with elevated privileges
- System configuration management
- Package installation system
- Network connectivity

### Built-in Applications
- **Notepad**: Full-featured text editor
- **Settings**: System configuration (Display, System Info, Network)
- **File Manager**: Directory browsing and file operations
- **Terminal**: Advanced command mode

## Building and Running

### Quick Start
\`\`\`bash
# Build and run immediately
./build.sh --run

# Or step by step
make all
make run
\`\`\`

### Build Requirements
- NASM assembler
- mtools (FAT filesystem tools)
- QEMU (for testing)

### Install Dependencies
\`\`\`bash
# Ubuntu/Debian
sudo apt-get install nasm mtools qemu-system-x86

# Or use automated installer
make install-deps
\`\`\`

## Usage Examples

### Basic Navigation
\`\`\`
OmniOS > help                    # Show all commands
OmniOS > ls                      # List current directory
OmniOS > cd system              # Change to system directory
OmniOS > cd ..                  # Go to parent directory
OmniOS > cd /                   # Go to root directory
\`\`\`

### File Operations
\`\`\`
OmniOS > add myfile.txt         # Create new file
OmniOS > copy myfile.txt        # Copy to clipboard
OmniOS > delete oldfile.txt     # Delete file (with confirmation)
OmniOS > move file.txt /system  # Move file to system directory
\`\`\`

### System Administration
\`\`\`
OmniOS > admin                  # Toggle admin mode
[ADMIN] OmniOS > set color      # Change color scheme
[ADMIN] OmniOS > install app    # Install new application
[ADMIN] OmniOS > admin          # Exit admin mode
\`\`\`

### Media and Network
\`\`\`
OmniOS > download http://example.com/file.zip  # Download file
OmniOS > play music.wav         # Play audio file
OmniOS > stop                   # Stop playback
\`\`\`

### Applications
\`\`\`
OmniOS > open notepad           # Launch text editor
OmniOS > open settings          # System configuration
OmniOS > open files             # File manager
OmniOS > open terminal          # Advanced terminal
\`\`\`

## System Architecture

### Memory Layout
- `0x7C00-0x7DFF`: Bootloader
- `0x1000-0x8000`: Enhanced Kernel
- `0x8000+`: System data, buffers, and applications

### File System
- FAT12 compatible
- Directory structure support
- File type detection
- Clipboard functionality

### Color Scheme
- **Blue Background**: Professional appearance
- **White Text**: Normal output
- **Green Text**: Success messages
- **Red Text**: Error messages and admin mode
- **Yellow Text**: Warning messages

## Technical Specifications

### System Requirements
- **Processor**: x86 compatible (486 or higher)
- **Memory**: 1 MB RAM minimum
- **Storage**: 1.44 MB floppy disk or equivalent
- **Display**: VGA compatible display adapter

### Enhanced Features
- 20+ complete commands
- Professional color scheme
- Admin mode with privileges
- File operations with clipboard
- Media player functionality
- Network download capability
- Built-in applications suite
- Enhanced error handling
- Command history and retry
- Directory navigation

## Development

### Project Structure
\`\`\`
omnios-2.0/
├── src/
│   ├── boot/
│   │   └── bootloader.asm      # Enhanced bootloader
│   └── kernel/
│       ├── kernel.asm          # Main kernel with all commands
│       ├── print.asm           # Color printing functions
│       ├── filesystem.asm      # File system operations
│       └── network.asm         # Network functions
├── build/                      # Build output directory
├── Makefile                    # Enhanced build system
├── build.sh                    # Build script
└── README.md                   # This file
\`\`\`

### Build Targets
- `make all` - Build complete enhanced system
- `make run` - Build and run in QEMU
- `make clean` - Clean build files
- `make report` - Generate detailed build report
- `make help` - Show all available targets

## Version Information
- **Version**: 2.0.0 Enhanced Command Edition
- **Codename**: Phoenix Enhanced
- **Release Date**: January 2025
- **Architecture**: x86 16-bit
- **Commands**: 20+ complete command set

## License
OmniOS 2.0 Enhanced Command Edition is released under the MIT License.

## Support
For issues, questions, or contributions:
- Review the complete command reference with `help`
- Check the build report for system details
- Test all commands in the enhanced environment

---

**OmniOS 2.0 Enhanced Command Edition - Professional Operating System with Complete Command Set**
\`\`\`

\`\`\`shellscript file="run.sh"
#!/bin/bash
# OmniOS 2.0 Enhanced Edition Run Script

if [ ! -f "build/omnios.img" ]; then
    echo "OmniOS Enhanced Edition image not found. Building..."
    ./build.sh
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Starting OmniOS 2.0 Enhanced Edition           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Enhanced Command Set Available:"
echo "• Basic: help ls cd install open set admin exit off"
echo "• Files: add delete move cut copy"
echo "• Media: play stop"
echo "• Network: download go retry back"
echo ""
echo "Starting system..."

qemu-system-i386 -drive format=raw,file=build/omnios.img,if=floppy -boot a
