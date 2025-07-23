#!/bin/bash

# OmniOS 2.0 Update Script
# Updates system from GitHub repository

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITHUB_REPO="https://github.com/CodeAra-official/OmniOS-2.0.git"
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}OmniOS 2.0 Update System${NC}"
echo "=========================="

# Check if git is available
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git is not installed. Please install git to use the update system.${NC}"
    exit 1
fi

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}This is not a git repository.${NC}"
    echo -e "${BLUE}Initializing git repository...${NC}"
    
    # Create backup of current files
    mkdir -p "$BACKUP_DIR"
    cp -r src/ "$BACKUP_DIR/" 2>/dev/null || true
    cp -r docs/ "$BACKUP_DIR/" 2>/dev/null || true
    cp *.sh "$BACKUP_DIR/" 2>/dev/null || true
    cp Makefile "$BACKUP_DIR/" 2>/dev/null || true
    
    echo -e "${GREEN}Backup created in $BACKUP_DIR${NC}"
    
    # Initialize git and add remote
    git init
    git remote add origin "$GITHUB_REPO"
    
    echo -e "${BLUE}Fetching latest version...${NC}"
    git fetch origin main
    git checkout -b main origin/main
    
    echo -e "${GREEN}Repository initialized and updated!${NC}"
    exit 0
fi

# Check current status
echo -e "${BLUE}Checking current status...${NC}"

# Fetch latest changes
git fetch origin main

# Get current and remote commit hashes
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}OmniOS 2.0 is already up to date!${NC}"
    exit 0
fi

echo -e "${YELLOW}Updates available!${NC}"

# Show what will be updated
echo -e "${BLUE}Changes to be applied:${NC}"
git log --oneline HEAD..origin/main

echo ""
read -p "Do you want to proceed with the update? (y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Update cancelled.${NC}"
    exit 0
fi

# Create backup before updating
echo -e "${BLUE}Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"
cp -r src/ "$BACKUP_DIR/" 2>/dev/null || true
cp -r docs/ "$BACKUP_DIR/" 2>/dev/null || true
cp *.sh "$BACKUP_DIR/" 2>/dev/null || true
cp Makefile "$BACKUP_DIR/" 2>/dev/null || true

echo -e "${GREEN}Backup created in $BACKUP_DIR${NC}"

# Perform update
echo -e "${BLUE}Updating OmniOS 2.0...${NC}"

# Stash any local changes
git stash push -m "Auto-stash before update $(date)"

# Pull latest changes
git pull origin main

echo -e "${GREEN}Update completed successfully!${NC}"

# Check if there were stashed changes
if git stash list | grep -q "Auto-stash before update"; then
    echo -e "${YELLOW}Local changes were stashed. To restore them, run:${NC}"
    echo "git stash pop"
fi

echo ""
echo -e "${BLUE}Update Summary:${NC}"
echo "- Backup created in: $BACKUP_DIR"
echo "- Updated to latest version from GitHub"
echo "- Ready to build and run"

echo ""
echo -e "${GREEN}To build and run the updated system:${NC}"
echo "./build.sh"
