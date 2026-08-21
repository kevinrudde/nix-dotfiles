#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../../.." && pwd)"
host="$(hostname -s 2>/dev/null || hostname)"

lua_config="${repo_root}/systems/${host}/config/hypr/hyprland.lua"

set -a
. "${repo_root}/systems/shared/uwsm/env"
. "${repo_root}/systems/shared/uwsm/env-hyprland"
set +a

# -D/-e pin XDG_SESSION_DESKTOP/XDG_CURRENT_DESKTOP to "Hyprland"; otherwise
# uwsm derives them from this script's name ("start-hyprland") and
# xdg-desktop-portal-hyprland warns "Not running on hyprland".
exec uwsm start -D Hyprland -e -- start-hyprland -- --config "$lua_config"
