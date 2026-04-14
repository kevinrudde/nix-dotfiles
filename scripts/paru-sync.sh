#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/paru-sync.sh [--host HOST] [--repo DIR]

Installs host-specific native packages listed in systems/<host>/packages.txt
using paru.
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
host="$(hostname -s 2>/dev/null || hostname)"

while (($# > 0)); do
  case "$1" in
    --host)
      shift
      host="${1:?missing value for --host}"
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

packages_file="$repo_root/systems/$host/packages.txt"

if [[ ! -f "$packages_file" ]]; then
  echo "No paru package list found for host '$host' at $packages_file"
  exit 0
fi

if ! command -v paru >/dev/null 2>&1; then
  echo "paru is required to install packages from $packages_file" >&2
  exit 1
fi

mapfile -t packages < <(sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$packages_file")

if [[ "${#packages[@]}" -eq 0 ]]; then
  echo "No packages listed in $packages_file"
  exit 0
fi

echo "Installing host packages for '$host' via paru"
paru -S --needed --noconfirm "${packages[@]}"
