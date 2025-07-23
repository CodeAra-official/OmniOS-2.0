# OmniOS 2.0 - Professional Operating System

## Overview
OmniOS 2.0 is a professional operating system built from scratch with a focus on simplicity, reliability, and performance. This Phoenix Edition represents a complete rewrite with enhanced features and improved stability.

## Features

### Core System
- **Custom Bootloader**: Direct kernel loading without complex boot stages
- **16-bit Kernel**: Optimized for compatibility and performance
- **Professional Interface**: Clean blue-themed user interface
- **Command Line Interface**: Full-featured command processor

### Available Commands
- `help` - Show command reference
- `ls` - List files and directories (FIXED - no more crashes!)
- `cd <directory>` - Change directory
- `open <app>` - Open applications (notepad, settings, files)
- `clear` - Clear screen
- `ver` - Show system version
- `time` - Display current time
- `shutdown` - Shutdown system
- `reboot` - Restart system

### Built-in Applications
- **Notepad**: Simple text editor
- **Settings**: System configuration
- **File Manager**: File and directory management

## System Requirements
- **Processor**: x86 compatible (486 or higher)
- **Memory**: 1 MB RAM minimum
- **Storage**: 1.44 MB floppy disk or equivalent
- **Display**: VGA compatible display adapter

## Building OmniOS 2.0

### Prerequisites
\`\`\`bash
# Ubuntu/Debian
sudo apt-get install nasm qemu-system-x86 mtools

# Or use the automated installer
make install-deps
\`\`\`

### Build Process
\`\`\`bash
# Quick build and run
./build.sh --run

# Or step by step
make all
make run

# Debug mode
make debug
\`\`\`

### Build Targets
- `make all` - Build complete system
- `make bootloader` - Build bootloader only
- `make kernel` - Build kernel only
- `make run` - Build and run in QEMU
- `make clean` - Clean build files

## Usage

### Basic Commands
\`\`\`
OmniOS 2.0 > help          # Show all commands
OmniOS 2.0 > ls            # List files (now working!)
OmniOS 2.0 > cd /          # Change to root directory
OmniOS 2.0 > open notepad  # Open text editor
OmniOS 2.0 > ver           # Show version info
OmniOS 2.0 > time          # Show current time
OmniOS 2.0 > clear         # Clear screen
OmniOS 2.0 > shutdown      # Shutdown system
\`\`\`

### Applications
\`\`\`
OmniOS 2.0 > open notepad   # Text editor
OmniOS 2.0 > open settings  # System settings
OmniOS 2.0 > open files     # File manager
\`\`\`

## Architecture

### System Components
- **Bootloader** (`src/boot/bootloader.asm`) - System initialization
- **Kernel** (`src/kernel/kernel.asm`) - Core system functionality
- **Print System** (`src/kernel/print.asm`) - Text output with colors
- **File System** (`src/kernel/filesystem.asm`) - File management
- **Commands** (`src/kernel/commands.asm`) - Command processing

### Memory Layout
- `0x7C00-0x7DFF`: Bootloader
- `0x1000-0x8000`: Kernel
- `0x8000+`: System data and buffers

## Version Information
- **Version**: 2.0.0
- **Codename**: Phoenix
- **Release Date**: January 2025
- **Language**: English
- **Architecture**: x86 16-bit

## Fixed Issues
- ✅ **ls command crash**: Completely rewritten file system handling
- ✅ **Boot process**: Simplified bootloader eliminates boot failures
- ✅ **Memory management**: Improved buffer handling
- ✅ **Command parsing**: Enhanced command processor
- ✅ **System stability**: Better error handling throughout

## New Features in 2.0
- Professional blue-themed interface
- Enhanced command set with `open`, `cd`, `time`
- Built-in applications (Notepad, Settings, File Manager)
- Improved error messages and help system
- Stable file system operations
- Clean shutdown and reboot functionality

## Development

### Project Structure
\`\`\`
omnios-2.0/
├── src/
│   ├── boot/
│   │   └── bootloader.asm
│   └── kernel/
│       ├── kernel.asm
│       ├── print.asm
│       ├── filesystem.asm
│       └── commands.asm
├── build/
├── Makefile
├── build.sh
├── run.sh
└── README.md
\`\`\`

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License
OmniOS 2.0 is released under the MIT License. See LICENSE file for details.

## Support
For issues, questions, or contributions:
- Create an issue in the repository
- Check the documentation
- Review the source code comments

---

**OmniOS 2.0 Phoenix Edition - Professional Operating System for the Modern Era**
