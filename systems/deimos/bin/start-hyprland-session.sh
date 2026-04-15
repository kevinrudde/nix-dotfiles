#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../../.." && pwd)"

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
generated_conf="$runtime_dir/hyprland-deimos.conf"

cat >"$generated_conf" <<EOF
source = ${repo_root}/systems/deimos/config/hypr/conf/env.conf
source = ${repo_root}/systems/deimos/config/hypr/conf/input.conf
source = ${repo_root}/systems/deimos/config/hypr/conf/looknfeel.conf
source = ${repo_root}/systems/deimos/config/hypr/conf/rules.conf
source = ${repo_root}/systems/deimos/config/hypr/conf/bindings.conf
source = ${repo_root}/systems/deimos/config/hypr/conf/autostart.conf
source = ${repo_root}/systems/deimos/config/hypr/hosts/deimos.conf
EOF

set -a
. "${repo_root}/systems/deimos/config/uwsm/env"
. "${repo_root}/systems/deimos/config/uwsm/env-hyprland"
set +a

exec uwsm start -- hyprland --config "$generated_conf"
