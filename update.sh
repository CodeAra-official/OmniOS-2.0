#!/bin/bash
# OmniOS 2.0 Update Script

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    OmniOS 2.0 Updater                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://github.com/CodeAra-official/OmniOS-2.0.git"
BACKUP_DIR="omnios_backup_$(date +%Y%m%d_%H%M%S)"

# Function to backup current installation
backup_current() {
    echo -e "${YELLOW}Creating backup...${NC}"
    mkdir -p "$BACKUP_DIR"
    
    # Backup important files
    if [ -d "build" ]; then
        cp -r build "$BACKUP_DIR/"
    fi
    
    if [ -f "version.json" ]; then
        cp version.json "$BACKUP_DIR/"
    fi
    
    echo -e "${GREEN}Backup created in: $BACKUP_DIR${NC}"
}

# Function to check git status
check_git() {
    if [ -d ".git" ]; then
        echo -e "${BLUE}Git repository detected${NC}"
        return 0
    else
        echo -e "${YELLOW}Not a git repository${NC}"
        return 1
    fi
}

# Function to update via git
update_git() {
    echo -e "${BLUE}Updating via Git...${NC}"
    
    # Fetch latest changes
    git fetch origin main
    
    # Check for conflicts
    if git diff --quiet HEAD origin/main; then
        echo -e "${GREEN}Already up to date!${NC}"
        return 0
    fi
    
    # Show what will be updated
    echo -e "${CYAN}Changes to be applied:${NC}"
    git log --oneline HEAD..origin/main
    
    read -p "Continue with update? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create backup before update
        backup_current
        
        # Pull changes
        git pull origin main
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Update successful!${NC}"
            return 0
        else
            echo -e "${RED}Update failed!${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Update cancelled${NC}"
        return 1
    fi
}

# Function to download latest version
download_latest() {
    echo -e "${BLUE}Downloading latest version...${NC}"
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        echo -e "${RED}Neither curl nor wget found!${NC}"
        echo "Please install curl or wget to download updates"
        return 1
    fi
    
    # Create backup
    backup_current
    
    # Download latest release
    TEMP_DIR="omnios_temp_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$TEMP_DIR"
    
    echo -e "${YELLOW}Downloading from GitHub...${NC}"
    
    if command -v git &> /dev/null; then
        git clone "$REPO_URL" "$TEMP_DIR"
    elif command -v curl &> /dev/null; then
        curl -L "${REPO_URL}/archive/main.zip" -o "$TEMP_DIR/omnios.zip"
        if command -v unzip &> /dev/null; then
            unzip -q "$TEMP_DIR/omnios.zip" -d "$TEMP_DIR"
            mv "$TEMP_DIR/OmniOS-2.0-main"/* .
        else
            echo -e "${RED}unzip not found! Please install unzip${NC}"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        wget "${REPO_URL}/archive/main.zip" -O "$TEMP_DIR/omnios.zip"
        if command -v unzip &> /dev/null; then
            unzip -q "$TEMP_DIR/omnios.zip" -d "$TEMP_DIR"
            mv "$TEMP_DIR/OmniOS-2.0-main"/* .
        else
            echo -e "${RED}unzip not found! Please install unzip${NC}"
            return 1
        fi
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}Download completed!${NC}"
    return 0
}

# Main update logic
main() {
    echo -e "${BLUE}Checking for updates...${NC}"
    
    if check_git; then
        update_git
    else
        echo -e "${YELLOW}Manual download required${NC}"
        read -p "Download latest version? (y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            download_latest
        else
            echo -e "${CYAN}You can manually download from: ${REPO_URL}${NC}"
            exit 0
        fi
    fi
    
    # Rebuild after update
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}Rebuilding OmniOS 2.0...${NC}"
        chmod +x build.sh
        ./build.sh
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Update and rebuild completed successfully!${NC}"
            echo -e "${CYAN}Run './run-safe.sh' to start OmniOS 2.0${NC}"
        else
            echo -e "${RED}Rebuild failed! Check the build output above.${NC}"
            echo -e "${YELLOW}Your backup is available in: $BACKUP_DIR${NC}"
        fi
    fi
}

# Run main function
main "$@"
