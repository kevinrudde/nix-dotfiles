#!/usr/bin/env bash
set -euo pipefail

# Migration: Configure SDDM display manager
# Host: deimos
#
# Installs the deimos SDDM override and enables SDDM as the system display
# manager. The earlier Hyprland UWSM migration owns the session entry.
# Package installation is handled by systems/deimos/packages.txt before
# migrations run.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

launcher="${repo_root}/systems/deimos/bin/start-hyprland-session.sh"
public_launcher="/usr/local/bin/start-hyprland-deimos-session"
lua_config="${repo_root}/systems/deimos/config/hypr/hyprland.lua"
sddm_config="${repo_root}/systems/deimos/config/sddm/20-deimos.conf"
session_entry="/usr/local/share/wayland-sessions/hyprland-deimos-uwsm.desktop"

if ! command -v sddm >/dev/null 2>&1; then
  echo "sddm is not installed. Run scripts/rebuild-system.sh so native packages sync before migrations." >&2
  exit 1
fi

if ! command -v weston >/dev/null 2>&1; then
  echo "weston is not installed. SDDM is configured to use weston as its Wayland greeter compositor." >&2
  exit 1
fi

if ! command -v start-hyprland >/dev/null 2>&1; then
  echo "start-hyprland is not installed. It is required by $launcher." >&2
  exit 1
fi

if [[ ! -x "$launcher" ]]; then
  echo "Launcher script is missing or not executable: $launcher" >&2
  exit 1
fi

if [[ ! -x "$public_launcher" ]]; then
  echo "Public session launcher is missing or not executable: $public_launcher" >&2
  echo "Run the earlier deimos migration first: 2026-04-15-210000-bootstrap-hyprland-uwsm-config.sh" >&2
  exit 1
fi

if [[ ! -f "$lua_config" ]]; then
  echo "Hyprland Lua config is missing: $lua_config" >&2
  exit 1
fi

if [[ ! -f "$sddm_config" ]]; then
  echo "SDDM config source is missing: $sddm_config" >&2
  exit 1
fi

bash -n "$launcher"

if [[ ! -f "$session_entry" ]]; then
  echo "Hyprland UWSM session entry is missing: $session_entry" >&2
  echo "Run the earlier deimos migration first: 2026-04-15-210000-bootstrap-hyprland-uwsm-config.sh" >&2
  exit 1
fi

if ! grep -Fxq "Exec=${public_launcher}" "$session_entry"; then
  echo "Hyprland UWSM session entry does not point at the deimos launcher: $session_entry" >&2
  exit 1
fi

if ! grep -Fxq "TryExec=${public_launcher}" "$session_entry"; then
  echo "Hyprland UWSM session entry does not validate against the public launcher: $session_entry" >&2
  exit 1
fi

sudo install -D -m 0644 "$sddm_config" /etc/sddm.conf.d/20-deimos.conf
sudo systemctl enable --force sddm.service
sudo systemctl set-default graphical.target

echo "Verified $public_launcher"
echo "Verified $session_entry"
echo "Installed /etc/sddm.conf.d/20-deimos.conf"
echo "Enabled sddm.service as the display manager"
