#!/usr/bin/env bash
set -euo pipefail

COPR_REPOS=(
  sneexy/zen-browser
  wezfurlong/wezterm-nightly
  solopasha/hyprland
)

PACKAGES=(
  zen-browser
  wezterm
  hyprland
  sddm
  tuned
  tuned-ppd
  kitty
  waybar
  hyprpolkitagent
  nautilus
  pavucontrol
  blueman
  NetworkManager-wifi
  nm-connection-editor-desktop
  gvfs
  gvfs-mtp
)

echo "Updating system..."
sudo dnf upgrade -y

for repo in "${COPR_REPOS[@]}"; do
  if [[ -n "$repo" ]]; then
    if dnf repolist enabled 2>/dev/null | grep -q "^$repo"; then
      echo "COPR repo already enabled: $repo"
    else
      echo "Enabling COPR repo: $repo"
      sudo dnf copr enable -y "$repo"
    fi
  fi
done

if [ ${#PACKAGES[@]} -eq 0 ] || [[ -z "${PACKAGES[*]}" ]]; then
  echo "No packages to install."
else
  missing_packages=()
  for pkg in "${PACKAGES[@]}"; do
    if [[ -n "$pkg" ]] && ! rpm -q "$pkg" &>/dev/null; then
      missing_packages+=("$pkg")
    fi
  done

  if [ ${#missing_packages[@]} -eq 0 ]; then
    echo "All packages already installed."
  else
    echo "Installing missing packages: ${missing_packages[*]}"
    sudo dnf install -y "${missing_packages[@]}"
  fi
fi

echo "Done."
