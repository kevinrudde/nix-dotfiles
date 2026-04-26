#!/usr/bin/env bash
set -euo pipefail

# Migration: Point Kraken liquid fan curve service at dotfiles script
# Host: cachy
#
# Rewrites the existing systemd unit to execute the checked-in script through
# /etc/nix-dotfiles/env instead of a copied /usr/local/bin snapshot.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
host="${DOTFILES_MIGRATION_HOST:?missing host}"
script_path="$repo_root/systems/cachy/bin/kraken-liquid-fan-curve.sh"
unit_src="$repo_root/systems/cachy/config/systemd/kraken-liquid-fan-curve.service"
env_path="/etc/nix-dotfiles/env"
unit_path="/etc/systemd/system/kraken-liquid-fan-curve.service"

if [[ "$host" != "cachy" ]]; then
  echo "This migration is for cachy, but the active host is $host" >&2
  exit 1
fi

if [[ ! -x "$script_path" ]]; then
  echo "Source script is missing or not executable: $script_path" >&2
  exit 1
fi

if [[ ! -f "$unit_src" ]]; then
  echo "Source unit not found: $unit_src" >&2
  exit 1
fi

tmp_env="$(mktemp)"
trap 'rm -f "$tmp_env"' EXIT

cat > "$tmp_env" <<EOF
DOTFILES_REPO_ROOT=$repo_root
EOF

sudo install -Dm644 "$tmp_env" "$env_path"
sudo install -Dm644 "$unit_src" "$unit_path"
sudo systemctl daemon-reload
sudo systemctl enable kraken-liquid-fan-curve.service
sudo systemctl restart kraken-liquid-fan-curve.service

echo "Updated kraken-liquid-fan-curve.service to use $script_path"
