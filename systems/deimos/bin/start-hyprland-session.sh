#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../../.." && pwd)"

lua_config="${repo_root}/systems/deimos/config/hypr/hyprland.lua"

set -a
. "${repo_root}/systems/deimos/config/uwsm/env"
. "${repo_root}/systems/deimos/config/uwsm/env-hyprland"
set +a

exec uwsm start -- start-hyprland -- --config "$lua_config"
