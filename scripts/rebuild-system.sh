#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/rebuild-system.sh [--host HOST] [--user USER] [--repo DIR]

Runs host-specific native package sync, migrations, host config sync, and then
applies the matching system/home config for the current platform.
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

sync_linux_native_packages() {
  local os_id=""
  local os_id_like=""

  if [[ -r /etc/os-release ]]; then
    # shellcheck source=/etc/os-release
    . /etc/os-release
    os_id="${ID:-}"
    os_id_like="${ID_LIKE:-}"
  fi

  case " $os_id $os_id_like " in
    *" fedora "*)
      "$repo_root/scripts/fedora-packages-sync.sh" --host "$host" --repo "$repo_root"
      ;;
    *" arch "*|*" cachyos "*)
      "$repo_root/scripts/paru-sync.sh" --host "$host" --repo "$repo_root"
      ;;
    *)
      if command -v dnf5 >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        "$repo_root/scripts/fedora-packages-sync.sh" --host "$host" --repo "$repo_root"
      elif command -v paru >/dev/null 2>&1; then
        "$repo_root/scripts/paru-sync.sh" --host "$host" --repo "$repo_root"
      else
        local packages_file="$repo_root/systems/$host/packages.txt"
        local copr_repos_file="$repo_root/systems/$host/copr-repos.txt"
        local rpm_keys_file="$repo_root/systems/$host/rpm-keys.txt"
        local dnf_repos_dir="$repo_root/systems/$host/dnf-repos"

        if [[ -f "$packages_file" || -f "$copr_repos_file" || -f "$rpm_keys_file" || -d "$dnf_repos_dir" ]]; then
          echo "No supported native package manager found for Linux host '$host'." >&2
          echo "Expected dnf/dnf5 for Fedora or paru for Arch-based hosts." >&2
          exit 1
        fi

        echo "No supported native package manager found; skipping native package sync"
      fi
      ;;
  esac
}

case "$(uname -s)" in
  Linux)
    sync_linux_native_packages
    echo ""
    "$repo_root/scripts/migrate.sh" --host "$host"
    echo ""
    "$repo_root/scripts/sync-host-config.sh" --host "$host" --repo "$repo_root"
    echo ""

    apply_state="$repo_root/systems/$host/apply-system-state.sh"
    if [[ -x "$apply_state" ]]; then
      "$apply_state"
      echo ""
    fi

    if command -v nh >/dev/null 2>&1; then
      nh home switch "$repo_root"
    else
      NIXPKGS_ALLOW_UNFREE=1 nix run home-manager -- switch --flake "$repo_root#$user_name@$host" --impure
    fi
    ;;
  Darwin)
    "$repo_root/scripts/migrate.sh" --host "$host"
    echo ""

    if command -v nh >/dev/null 2>&1; then
      nh darwin switch "$repo_root"
    else
      sudo NIXPKGS_ALLOW_UNFREE=1 nix run nix-darwin -- switch --flake "$repo_root#$host" --show-trace
    fi
    ;;
  *)
    echo "Unsupported operating system: $(uname -s)" >&2
    exit 1
    ;;
esac
