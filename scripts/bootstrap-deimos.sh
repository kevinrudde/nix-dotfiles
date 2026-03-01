#!/usr/bin/env bash
set -euo pipefail

echo "=== Deimos Fedora Bootstrap ==="
echo "This script will install Nix with flakes and home-manager for Hyprland"
echo ""

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME="$(hostname)"

if [ "$HOSTNAME" != "deimos" ]; then
	hostnamectl set-hostname deimos
fi

if [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
	echo "Error: SOPS age key not found at ~/.config/sops/age/keys.txt"
	echo "Please put your sops key in place before running this script."
	exit 1
fi

echo ""
echo "=== Basic Fedora bootstrap ==="

# System Upgrade
sudo dnf upgrade -y

# Optimize DNF package manager for faster downloads and efficient updates
sudo dnf -y install dnf-plugins-core

# Replace Fedora Flatpak Repo with Flathub for better package management and apps stability
sudo dnf install -y flatpak
flatpak remote-delete fedora --force || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo sudo flatpak repair
flatpak update

# Enable RPM Fusion repositories to access additional software packages and codecs
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf update @core -y

# Install multimedia codecs to enhance multimedia capabilities
# sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y

echo "=== Installing Nix (single-user) ==="
if command -v nix &>/dev/null; then
	echo "Nix already installed"
else
	curl -fsSL https://install.determinate.systems/nix | sh -s -- install
fi

echo ""
echo "=== Sourcing nix ==="
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
	. "$HOME/.nix-profile/etc/profile.d/nix.sh"
else
	. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo ""
echo "=== Activating home-manager ==="
cd "$DOTFILES_DIR"
NIXPKGS_ALLOW_UNFREE=1 nix run home-manager -- switch --flake ~/.config/nix-dotfiles --impure

echo ""
echo "=== Bootstrap complete! ==="
echo "You can now start Hyprland with: Hyprland"
echo "Or reboot and select Hyprland from your display manager"
