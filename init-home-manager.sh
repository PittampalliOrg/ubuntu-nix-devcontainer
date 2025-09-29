#!/bin/bash
# Initialize home-manager configuration in the container

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Initializing home-manager configuration...${NC}"

# Source Nix environment
if [ -f ~/.nix-profile/etc/profile.d/nix.sh ]; then
    . ~/.nix-profile/etc/profile.d/nix.sh
elif [ -f /home/node/.nix-profile/etc/profile.d/nix.sh ]; then
    . /home/node/.nix-profile/etc/profile.d/nix.sh
else
    echo -e "${RED}Error: Nix environment not found!${NC}"
    exit 1
fi

# Remove conflicting files
echo -e "${YELLOW}Removing conflicting shell configuration files...${NC}"
rm -f ~/.bashrc ~/.profile ~/.bash_profile 2>/dev/null || true

# Check if home-manager is installed
if ! command -v home-manager &> /dev/null; then
    echo -e "${YELLOW}Installing home-manager...${NC}"
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-env -iA nixpkgs.home-manager
fi

# Run home-manager with the flake configuration
echo -e "${YELLOW}Applying home-manager configuration from github:vpittamp/nixos-config#code...${NC}"
nix run home-manager -- switch --flake github:vpittamp/nixos-config#code --impure || {
    echo -e "${RED}Warning: home-manager switch failed!${NC}"
    echo "You may need to:"
    echo "  1. Check your internet connection"
    echo "  2. Verify the flake repository is accessible"
    echo "  3. Ensure you have proper GitHub access"
    exit 1
}

# Mark as initialized
touch ~/.home-manager-initialized

echo -e "${GREEN}✅ Home-manager configuration applied successfully!${NC}"
echo ""
echo "To use the new configuration:"
echo "  1. Exit and re-enter the shell, or"
echo "  2. Run: source ~/.bashrc"