# OmniOS 2.0 - Advanced Operating System

## Quick Start

### 1. Install Dependencies
\`\`\`bash
chmod +x install-dependencies.sh
./install-dependencies.sh
\`\`\`

### 2. Build OmniOS
\`\`\`bash
chmod +x build.sh
./build.sh
\`\`\`

### 3. Run OmniOS
The build script will automatically launch OmniOS in QEMU. If you need to run it manually:

\`\`\`bash
# Standard run
qemu-system-i386 -boot c -m 256 -drive format=raw,file=build/OmniOS.img,if=floppy

# Text mode (for headless systems)
qemu-system-i386 -boot c -m 256 -drive format=raw,file=build/OmniOS.img,if=floppy -nographic
\`\`\`

## Build Options

### Standard Build
\`\`\`bash
./build.sh
\`\`\`

### Termux Build (Android)
\`\`\`bash
./build-termux.sh
./launch-omnios.sh
\`\`\`

### Debug Build
\`\`\`bash
./build-debug.sh
./launch-debug.sh
\`\`\`

## Troubleshooting

### Permission Denied
\`\`\`bash
chmod +x *.sh
\`\`\`

### Missing Dependencies
\`\`\`bash
./install-dependencies.sh
\`\`\`

### GUI Issues (gtk initialization failed)
Use text mode:
\`\`\`bash
qemu-system-i386 -boot c -m 256 -drive format=raw,file=build/OmniOS.img,if=floppy -nographic
\`\`\`

### Clean Build
\`\`\`bash
./clean.sh
./build.sh
\`\`\`

## Features

- **Enhanced Bootloader**: FAT12 filesystem support
- **Advanced Kernel**: Multi-application framework
- **Rich UI**: 16-color text interface with window management
- **Core Applications**: Setup, Notepad, File Manager, Settings
- **Termux Compatible**: Runs on Android devices
- **Debug Support**: Comprehensive debugging tools

## System Requirements

- **Minimum**: 256MB RAM, x86 processor
- **Recommended**: 512MB RAM, modern x86/x64 processor
- **Termux**: Android 7.0+, 3GB RAM

## Documentation

- [Installation Guide](docs/OmniOS-2.0-Features.md)
- [Redmi Device Guide](docs/Redmi-Installation-Guide.md)
- [Termux Compatibility](docs/Termux-Compatibility.md)

## Support

For issues and support:
1. Check the troubleshooting section above
2. Review the documentation in the `docs/` directory
3. Create an issue with detailed error information

---

**OmniOS 2.0** - Advanced Operating System for Modern Computing
