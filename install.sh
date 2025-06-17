#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "darwin"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            print_error "Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac
}

# Check if Nix is installed
check_nix() {
    if ! command -v nix &> /dev/null; then
        print_error "Nix is not installed!"
        print_step "Please install Nix first using the Determinate Systems installer:"
        echo "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
        exit 1
    fi
    print_success "Nix is installed"
}

# Install on macOS
install_darwin() {
    print_step "Installing nix-dotfiles for macOS..."
    
    if ! command -v darwin-rebuild &> /dev/null; then
        print_step "Running initial nix-darwin setup..."
        nix run nix-darwin -- switch --flake ~/.config/nix-dotfiles#zoidberg
    else
        print_step "Rebuilding Darwin configuration..."
        darwin-rebuild switch --flake ~/.config/nix-dotfiles#zoidberg --show-trace
    fi
    
    print_success "macOS configuration applied!"
}

# Install on Linux
install_linux() {
    print_step "Installing nix-dotfiles for Linux..."
    
    # Check if this is NixOS or standalone Home Manager
    if [ -f /etc/nixos/configuration.nix ]; then
        print_step "Detected NixOS, using nixos-rebuild..."
        sudo nixos-rebuild switch --flake ~/.config/nix-dotfiles#linux-example --show-trace
    else
        print_step "Using standalone Home Manager..."
        nix run home-manager -- switch --flake ~/.config/nix-dotfiles#C.Hessel
    fi
    
    print_success "Linux configuration applied!"
}

# Main installation function
main() {
    local platform="${1:-$(detect_platform)}"
    
    print_step "Detected platform: $platform"
    
    # Check prerequisites
    check_nix
    
    # Ensure we're in the right directory
    if [ ! -f "flake.nix" ]; then
        print_error "Not in nix-dotfiles directory! Please run this script from ~/.config/nix-dotfiles"
        exit 1
    fi
    
    # Install based on platform
    case "$platform" in
        darwin|macos|osx)
            install_darwin
            ;;
        linux|nixos)
            install_linux
            ;;
        *)
            print_error "Unknown platform: $platform"
            print_step "Supported platforms: darwin, linux"
            exit 1
            ;;
    esac
    
    print_success "Installation complete!"
    print_step "You may need to restart your shell or terminal to see all changes."
}

# Show usage
usage() {
    echo "Usage: $0 [PLATFORM]"
    echo ""
    echo "PLATFORM can be:"
    echo "  darwin, macos, osx - for macOS systems"
    echo "  linux, nixos       - for Linux systems"
    echo ""
    echo "If no platform is specified, it will be auto-detected."
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 