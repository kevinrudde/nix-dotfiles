#!/usr/bin/env bash

# nix-dotfiles System Update Script
# Comprehensive update workflow for Determinate Systems Nix + nix-darwin/NixOS

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}===${NC} $1 ${BLUE}===${NC}"
}

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        log_error "Unsupported platform: $OSTYPE"
        exit 1
    fi
}

# Check if we're in the dotfiles directory
check_directory() {
    if [[ ! -f "flake.nix" ]]; then
        log_error "Must be run from the nix-dotfiles directory (where flake.nix exists)"
        exit 1
    fi
}

# Step 1: Check System Health
check_system_health() {
    log_step "Step 1: Checking System Health"
    
    log_info "Checking Determinate Systems daemon status..."
    if ! sudo determinate-nixd status; then
        log_error "Determinate Systems daemon is not healthy"
        log_info "Try restarting with: sudo launchctl kickstart -k system/org.nixos.nix-daemon"
        exit 1
    fi
    
    log_info "Validating current configuration..."
    if ! nix flake check; then
        log_error "Configuration validation failed"
        log_info "Fix configuration errors before proceeding"
        exit 1
    fi
    
    log_success "System health check passed"
}

# Step 2: Update Determinate Systems
update_determinate() {
    log_step "Step 2: Updating Determinate Systems"
    
    log_info "Checking current Determinate Nix version..."
    current_version=$(determinate-nixd version 2>/dev/null || echo "unknown")
    log_info "Current version: $current_version"
    
    log_info "Upgrading Determinate Nix to latest version..."
    if sudo determinate-nixd upgrade; then
        log_success "Determinate Systems upgraded successfully"
        
        # Check new version
        new_version=$(determinate-nixd version 2>/dev/null || echo "unknown")
        log_info "New version: $new_version"
        
        # Verify upgrade
        log_info "Verifying upgrade completed successfully..."
        if sudo determinate-nixd status; then
            log_success "Determinate Systems is healthy after upgrade"
        else
            log_error "Determinate Systems daemon issues after upgrade"
            exit 1
        fi
    else
        log_warning "Determinate Systems upgrade failed or not needed"
        # Continue anyway as this might not be critical
    fi
}

# Step 3: Update Configuration
update_configuration() {
    log_step "Step 3: Updating Configuration"
    
    log_info "Updating flake inputs to latest versions..."
    if nix flake update; then
        log_success "Flake inputs updated successfully"
    else
        log_error "Failed to update flake inputs"
        exit 1
    fi
    
    log_info "Validating updated configuration..."
    if nix flake check; then
        log_success "Updated configuration is valid"
    else
        log_error "Updated configuration validation failed"
        log_info "You may need to fix compatibility issues with updated inputs"
        exit 1
    fi
}

# Step 4: Apply Changes
apply_changes() {
    local platform=$1
    log_step "Step 4: Applying Changes"
    
    case $platform in
        "darwin")
            log_info "Applying macOS configuration changes..."
            if sudo darwin-rebuild switch --flake ~/.config/nix-dotfiles/ --show-trace; then
                log_success "macOS configuration applied successfully"
            else
                log_error "Failed to apply macOS configuration"
                log_info "You can rollback with: sudo nix-env --rollback --profile /nix/var/nix/profiles/system"
                exit 1
            fi
            ;;
        "linux")
            log_info "Applying Linux configuration changes..."
            if sudo nixos-rebuild switch --flake ~/.config/nix-dotfiles/ --show-trace; then
                log_success "Linux configuration applied successfully"
            else
                log_error "Failed to apply Linux configuration"
                log_info "You can rollback with: sudo nix-env --rollback --profile /nix/var/nix/profiles/system"
                exit 1
            fi
            ;;
        *)
            log_error "Unknown platform: $platform"
            exit 1
            ;;
    esac
}

# Step 5: Verify System Health
verify_system_health() {
    log_step "Step 5: Verifying System Health"
    
    log_info "Confirming Determinate Systems is healthy..."
    if sudo determinate-nixd status; then
        log_success "Determinate Systems is healthy"
    else
        log_warning "Determinate Systems status check failed"
        log_info "System may still be functional, but check daemon logs"
    fi
    
    log_info "Checking current system generation..."
    if sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -3; then
        log_success "System generation information displayed above"
    else
        log_warning "Could not retrieve system generation information"
    fi
    
    log_success "System update completed successfully!"
    log_info "Test your applications and tools to ensure everything works correctly"
}

# Cleanup old generations
cleanup_generations() {
    log_step "Cleanup: Removing Old Generations"
    
    log_info "Cleaning up old generations (keeping last 7 days)..."
    if nix-collect-garbage --delete-older-than 7d; then
        log_success "Old generations cleaned up"
    else
        log_warning "Generation cleanup failed (non-critical)"
    fi
}

# Main function
main() {
    echo -e "${GREEN}🚀 nix-dotfiles System Update${NC}"
    echo -e "${BLUE}Comprehensive update workflow for Determinate Systems Nix + nix-darwin/NixOS${NC}\n"
    
    # Pre-flight checks
    check_directory
    local platform=$(detect_platform)
    log_info "Detected platform: $platform"
    
    # Ask for confirmation
    read -p "Do you want to proceed with the system update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled by user"
        exit 0
    fi
    
    # Execute update workflow
    check_system_health
    update_determinate
    update_configuration
    apply_changes "$platform"
    verify_system_health
    
    # Optional cleanup
    read -p "Do you want to clean up old generations? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_generations
    fi
    
    echo -e "\n${GREEN}✅ System update completed successfully!${NC}"
    echo -e "${BLUE}Your nix-dotfiles configuration is now up to date.${NC}"
}

# Handle script arguments
case "${1:-}" in
    "--help" | "-h")
        echo "nix-dotfiles System Update Script"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --dry-run     Show what would be done without executing"
        echo
        echo "This script performs a comprehensive system update:"
        echo "1. Check system health"
        echo "2. Update Determinate Systems Nix"
        echo "3. Update flake inputs"
        echo "4. Apply configuration changes"
        echo "5. Verify system health"
        exit 0
        ;;
    "--dry-run")
        echo "DRY RUN: Would perform the following steps:"
        echo "1. Check Determinate Systems daemon status"
        echo "2. Upgrade Determinate Nix to latest version"
        echo "3. Update flake inputs (nix flake update)"
        echo "4. Apply configuration changes (darwin-rebuild/nixos-rebuild)"
        echo "5. Verify system health"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac 