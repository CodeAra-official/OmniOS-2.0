#!/bin/bash

# OmniOS 2.0 Enhanced Build Script
# Complete build system with GitHub integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
GITHUB_REPO="https://github.com/CodeAra-official/OmniOS-2.0.git"
BUILD_DIR="build"
VERSION_FILE="version.json"

# Functions
print_banner() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    OmniOS 2.0 Build System                  ║${NC}"
    echo -e "${CYAN}║                Enhanced Command Edition                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    local missing_deps=()
    
    if ! command -v nasm &> /dev/null; then
        missing_deps+=("nasm")
    fi
    
    if ! command -v qemu-system-i386 &> /dev/null; then
        missing_deps+=("qemu-system-x86")
    fi
    
    if ! command -v dd &> /dev/null; then
        missing_deps+=("coreutils")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Missing dependencies: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}Please install missing dependencies and try again.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Dependencies OK${NC}"
}

check_updates() {
    echo -e "${BLUE}Checking for updates...${NC}"
    
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}Not a git repository. Skipping update check.${NC}"
        return 0
    fi
    
    # Fetch latest changes
    git fetch origin main 2>/dev/null || {
        echo -e "${YELLOW}Could not check for updates. Continuing with build...${NC}"
        return 0
    }
    
    # Check if updates are available
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo -e "${YELLOW}Updates available!${NC}"
        read -p "Do you want to update? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Updating OmniOS 2.0...${NC}"
            git pull origin main
            echo -e "${GREEN}Update complete!${NC}"
        fi
    else
        echo -e "${GREEN}OmniOS 2.0 is up to date${NC}"
    fi
}

build_system() {
    echo -e "${BLUE}Building OmniOS 2.0 Enhanced Edition...${NC}"
    
    # Clean previous build
    make clean
    
    # Build system
    make all
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Build completed successfully!${NC}"
        
        # Generate build info
        echo "{" > ${BUILD_DIR}/build-info.json
        echo "  \"version\": \"2.0.0\"," >> ${BUILD_DIR}/build-info.json
        echo "  \"build_date\": \"$(date -Iseconds)\"," >> ${BUILD_DIR}/build-info.json
        echo "  \"build_host\": \"$(hostname)\"," >> ${BUILD_DIR}/build-info.json
        echo "  \"git_commit\": \"$(git rev-parse HEAD 2>/dev/null || echo 'unknown')\"" >> ${BUILD_DIR}/build-info.json
        echo "}" >> ${BUILD_DIR}/build-info.json
        
        return 0
    else
        echo -e "${RED}Build failed!${NC}"
        return 1
    fi
}

run_system() {
    echo -e "${BLUE}Starting OmniOS 2.0...${NC}"
    
    if [ ! -f "${BUILD_DIR}/omnios.img" ]; then
        echo -e "${RED}OmniOS image not found. Please build first.${NC}"
        exit 1
    fi
    
    # Kill any existing processes
    pkill -f "omnios.img" 2>/dev/null || true
    sleep 1
    
    # Run system
    ./run-safe.sh
}

show_help() {
    echo -e "${GREEN}OmniOS 2.0 Build Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 [options]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  --build           Build OmniOS 2.0"
    echo "  --run             Run OmniOS 2.0"
    echo "  --check-updates   Check for updates from GitHub"
    echo "  --no-update       Skip update check"
    echo "  --clean           Clean build files"
    echo "  --help            Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0                Build and run (default)"
    echo "  $0 --build        Build only"
    echo "  $0 --run          Run only"
    echo "  $0 --no-update --build   Build without checking updates"
}

# Main script
main() {
    local check_updates_flag=true
    local build_flag=false
    local run_flag=false
    local clean_flag=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --build)
                build_flag=true
                shift
                ;;
            --run)
                run_flag=true
                shift
                ;;
            --check-updates)
                check_updates
                exit 0
                ;;
            --no-update)
                check_updates_flag=false
                shift
                ;;
            --clean)
                clean_flag=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default behavior if no flags specified
    if [ "$build_flag" = false ] && [ "$run_flag" = false ] && [ "$clean_flag" = false ]; then
        build_flag=true
        run_flag=true
    fi
    
    print_banner
    
    if [ "$clean_flag" = true ]; then
        echo -e "${YELLOW}Cleaning build files...${NC}"
        make clean
        echo -e "${GREEN}Clean complete${NC}"
        exit 0
    fi
    
    check_dependencies
    
    if [ "$check_updates_flag" = true ]; then
        check_updates
    fi
    
    if [ "$build_flag" = true ]; then
        build_system || exit 1
    fi
    
    if [ "$run_flag" = true ]; then
        run_system
    fi
}

# Run main function with all arguments
main "$@"
