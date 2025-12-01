#!/bin/bash
# Zoro Proving Stack Setup Script
# Sets up all submodules and optionally configures stwo-air-infra (private)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Zoro Proving Stack Setup ===${NC}"
echo ""

# Initialize and update submodules
echo -e "${YELLOW}Initializing git submodules...${NC}"
git submodule update --init --recursive

echo -e "${GREEN}Submodules initialized:${NC}"
git submodule status
echo ""

# Create corelib symlink
if [[ ! -L "corelib" ]]; then
    echo -e "${YELLOW}Creating corelib symlink...${NC}"
    ln -sf cairo/corelib corelib
    echo -e "${GREEN}Created: corelib -> cairo/corelib${NC}"
else
    echo -e "${GREEN}corelib symlink already exists${NC}"
fi
echo ""

# Handle stwo-air-infra (private repo - optional)
echo -e "${BLUE}=== stwo-air-infra Setup (Optional) ===${NC}"
echo ""
echo "stwo-air-infra is a private repository from starkware-industries."
echo "It is required for the full proving pipeline but optional for basic usage."
echo ""

if [[ -d "stwo-air-infra/.git" ]]; then
    echo -e "${GREEN}stwo-air-infra already present${NC}"
    echo "  Path: $SCRIPT_DIR/stwo-air-infra"
    echo "  Branch: $(git -C stwo-air-infra branch --show-current 2>/dev/null || echo 'detached')"
    echo ""
elif [[ -n "$STWO_AIR_INFRA_PATH" ]]; then
    # User provided path via environment variable
    echo -e "${YELLOW}Using STWO_AIR_INFRA_PATH: $STWO_AIR_INFRA_PATH${NC}"
    if [[ -d "$STWO_AIR_INFRA_PATH/.git" ]]; then
        ln -sf "$STWO_AIR_INFRA_PATH" stwo-air-infra
        echo -e "${GREEN}Created symlink to existing stwo-air-infra${NC}"
    else
        echo -e "${RED}Error: $STWO_AIR_INFRA_PATH is not a valid git repository${NC}"
        exit 1
    fi
else
    echo "Options to set up stwo-air-infra:"
    echo ""
    echo "  1. If you have access to starkware-industries/stwo-air-infra:"
    echo "     git clone -b brandon/blake2b git@github.com:starkware-industries/stwo-air-infra.git"
    echo ""
    echo "  2. If you have a local clone elsewhere, set STWO_AIR_INFRA_PATH:"
    echo "     export STWO_AIR_INFRA_PATH=/path/to/your/stwo-air-infra"
    echo "     ./setup.sh"
    echo ""
    echo "  3. Skip for now (some features will be unavailable)"
    echo ""

    read -p "Attempt to clone from starkware-industries? [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cloning stwo-air-infra (branch: brandon/blake2b)...${NC}"
        if git clone -b brandon/blake2b git@github.com:starkware-industries/stwo-air-infra.git; then
            echo -e "${GREEN}Successfully cloned stwo-air-infra${NC}"
        else
            echo -e "${RED}Failed to clone. You may not have access to this private repository.${NC}"
            echo "Continuing without stwo-air-infra..."
        fi
    else
        echo -e "${YELLOW}Skipping stwo-air-infra setup${NC}"
        echo "You can set it up later by running this script again."
    fi
fi

echo ""
echo -e "${BLUE}=== Build Instructions ===${NC}"
echo ""
echo "To build all components, run:"
echo "  make cairo-build        # Build Cairo compiler"
echo "  make cairo-vm-build     # Build Cairo VM"
echo "  make stwo-cairo-build   # Build Stwo prover"
if [[ -d "stwo-air-infra/.git" ]]; then
echo "  make stwo-air-infra-build  # Build AIR infrastructure"
fi
echo ""
echo "Or build everything:"
echo "  make all"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
