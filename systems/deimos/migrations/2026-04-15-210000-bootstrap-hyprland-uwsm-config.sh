#!/usr/bin/env bash
set -euo pipefail

# Migration: Install Hyprland UWSM session entry
# Host: deimos
#
# Installs a system-wide Wayland session entry that starts Hyprland through the
# checked-in launcher script in this repository.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
launcher="${repo_root}/systems/deimos/bin/start-hyprland-session.sh"
session_entry="/usr/local/share/wayland-sessions/hyprland-deimos-uwsm.desktop"
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

if [[ ! -x "$launcher" ]]; then
  echo "Launcher script is missing or not executable: $launcher" >&2
  exit 1
fi

cat >"$tmp_file" <<EOF
[Desktop Entry]
Name=Hyprland (UWSM, deimos)
Comment=Hyprland session managed by Universal Wayland Session Manager
Exec=${launcher}
Type=Application
DesktopNames=Hyprland
EOF

sudo install -D -m 0644 "$tmp_file" "$session_entry"
echo "Installed $session_entry"
echo "Select 'Hyprland (UWSM, deimos)' in your display manager."
