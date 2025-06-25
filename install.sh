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
        echo ""
        echo "🖥️  GUI Installer (Recommended):"
        echo "   Download from: https://install.determinate.systems/determinate-pkg/stable/Universal"
        echo ""
        echo "💻 Command Line Alternative:"
        echo "   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
        echo ""
        print_step "After installation, restart your terminal and run this script again."
        exit 1
    fi
    print_success "Nix is installed"
}

# Check Determinate Systems daemon status
check_determinate() {
    if command -v determinate-nixd &> /dev/null; then
        print_success "Determinate Systems Nix detected"
        if sudo determinate-nixd status &> /dev/null; then
            print_success "Determinate daemon is running"
        else
            print_warning "Determinate daemon may have issues"
            print_step "You can check status with: sudo determinate-nixd status"
        fi
    else
        print_warning "Classic Nix installation detected (not Determinate Systems)"
        print_step "Consider upgrading to Determinate Systems for better experience"
    fi
}

# Install on macOS
install_darwin() {
    print_step "Installing nix-dotfiles for macOS..."
    
    if ! command -v darwin-rebuild &> /dev/null; then
        print_step "Running initial nix-darwin setup..."
        if ! nix run nix-darwin -- switch --flake ~/.config/nix-dotfiles#zoidberg; then
            print_error "Initial nix-darwin setup failed!"
            print_step "Troubleshooting steps:"
            echo "  1. Check flake syntax: nix flake check --show-trace"
            echo "  2. Test build: nix build .#darwinConfigurations.zoidberg.system --show-trace"
            echo "  3. Check Determinate daemon: sudo determinate-nixd status"
            echo "  4. Restart daemon: sudo launchctl kickstart -k system/org.nixos.nix-daemon"
            exit 1
        fi
    else
        print_step "Rebuilding Darwin configuration..."
        if ! darwin-rebuild switch --flake ~/.config/nix-dotfiles#zoidberg --show-trace; then
            print_error "Darwin rebuild failed!"
            print_step "Troubleshooting steps:"
            echo "  1. Check flake syntax: nix flake check --show-trace"
            echo "  2. Rollback if needed: sudo nix-env --rollback --profile /nix/var/nix/profiles/system"
            echo "  3. Check Determinate daemon: sudo determinate-nixd status"
            echo "  4. View generations: sudo nix-env --list-generations --profile /nix/var/nix/profiles/system"
            exit 1
        fi
    fi
    
    print_success "macOS configuration applied!"
    
    # Post-installation checks
    if command -v determinate-nixd &> /dev/null; then
        print_step "Running post-installation checks..."
        if sudo determinate-nixd status &> /dev/null; then
            print_success "Determinate Systems daemon is healthy"
        else
            print_warning "Determinate daemon may need attention"
            print_step "Check with: sudo determinate-nixd status"
        fi
    fi
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
    check_determinate
    
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
    
    # Determinate Systems tips
    if command -v determinate-nixd &> /dev/null; then
        echo ""
        print_step "💡 Determinate Systems Tips:"
        echo "  • Check daemon status: sudo determinate-nixd status"
        echo "  • Upgrade Nix: sudo determinate-nixd upgrade"
        echo "  • Check version: determinate-nixd version"
        echo "  • Custom config: /etc/nix/nix.custom.conf (never edit /etc/nix/nix.conf)"
        echo "  • Dotfiles config: hosts/shared/determinate.nix"
    fi
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