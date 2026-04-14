#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/rebuild-system.sh [--host HOST] [--user USER] [--repo DIR]

Runs host-specific migrations and then applies the matching system/home config
for the current platform.
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
host="$(hostname -s 2>/dev/null || hostname)"
user_name="$(id -un)"

while (($# > 0)); do
  case "$1" in
    --host)
      shift
      host="${1:?missing value for --host}"
      shift
      ;;
    --user)
      shift
      user_name="${1:?missing value for --user}"
      shift
      ;;
    --repo)
      shift
      repo_root="${1:?missing value for --repo}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$(uname -s)" in
  Linux)
    "$repo_root/scripts/migrate.sh" --host "$host"
    echo ""
    NIXPKGS_ALLOW_UNFREE=1 nix run home-manager -- switch --flake "$repo_root#$user_name@$host" --impure
    ;;
  Darwin)
    "$repo_root/scripts/migrate.sh" --host "$host"
    echo ""

    if command -v darwin-rebuild >/dev/null 2>&1; then
      sudo darwin-rebuild switch --flake "$repo_root#$host" --show-trace
    else
      sudo nix run nix-darwin -- switch --flake "$repo_root#$host" --show-trace
    fi
    ;;
  *)
    echo "Unsupported operating system: $(uname -s)" >&2
    exit 1
    ;;
esac
