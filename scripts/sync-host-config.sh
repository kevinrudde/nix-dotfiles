#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/sync-host-config.sh [--host HOST] [--repo DIR]

Installs files from systems/<host>/rootfs into / and then runs an optional
systems/<host>/sync-config-post.sh hook.
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

rootfs_dir="$repo_root/systems/$host/rootfs"
post_sync_script="$repo_root/systems/$host/sync-config-post.sh"

if [[ ! -d "$rootfs_dir" ]]; then
  echo "No host rootfs config tree found for '$host'"
  exit 0
fi

if ((EUID != 0)) && ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to install root-owned host config files" >&2
  exit 1
fi

run_as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
}

install_rootfs_file() {
  local source_file="$1"
  local relative_path="${source_file#"$rootfs_dir"/}"
  local target_file="/$relative_path"
  local mode

  if [[ -d "$target_file" && ! -L "$target_file" ]]; then
    echo "$target_file is a directory, refusing to replace it" >&2
    exit 1
  fi

  mode="$(stat -Lc '%a' "$source_file")"

  if [[ -f "$target_file" && ! -L "$target_file" ]] && cmp -s "$source_file" "$target_file"; then
    run_as_root chown root:root "$target_file"
    run_as_root chmod "$mode" "$target_file"
    echo "Current $target_file"
    return 1
  fi

  if [[ -L "$target_file" ]]; then
    run_as_root rm -f "$target_file"
  fi

  run_as_root install -D -o root -g root -m "$mode" "$source_file" "$target_file"
  echo "Installed $target_file"
  return 0
}

changed_targets=()

while IFS= read -r source_file; do
  if install_rootfs_file "$source_file"; then
    changed_targets+=("/${source_file#"$rootfs_dir"/}")
  fi
done < <(find "$rootfs_dir" \( -type f -o -type l \) -print | LC_ALL=C sort)

if [[ -f "$post_sync_script" ]]; then
  changed_targets_file="$(mktemp)"
  trap 'rm -f "$changed_targets_file"' EXIT
  printf '%s\n' "${changed_targets[@]}" > "$changed_targets_file"

  DOTFILES_SYNC_REPO_ROOT="$repo_root" \
  DOTFILES_SYNC_HOST="$host" \
  DOTFILES_SYNC_CHANGED_TARGETS_FILE="$changed_targets_file" \
  bash "$post_sync_script"
fi
