#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/migrate.sh [--host HOST] [--migrations-dir DIR] [--state-dir DIR]

Runs timestamped shell migrations in filename order and records each applied
migration as a file in the selected state directory.

Examples:
  ./scripts/migrate.sh
  ./scripts/migrate.sh --host deimos
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
host="$(hostname -s 2>/dev/null || hostname)"
migrations_dir=""
state_dir=""

while (($# > 0)); do
  case "$1" in
    --host)
      shift
      host="${1:?missing value for --host}"
      shift
      ;;
    --migrations-dir)
      shift
      migrations_dir="${1:?missing value for --migrations-dir}"
      shift
      ;;
    --state-dir)
      shift
      state_dir="${1:?missing value for --state-dir}"
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

if [[ -z "$migrations_dir" ]]; then
  host_migrations_dir="$repo_root/migrations/system/$host"

  if [[ -d "$host_migrations_dir" ]]; then
    migrations_dir="$host_migrations_dir"
  else
    migrations_dir="$repo_root/migrations/system"
  fi
fi

if [[ -z "$state_dir" ]]; then
  state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix-dotfiles/migrations/system/$host"
fi

if [[ ! -d "$migrations_dir" ]]; then
  echo "Migration directory not found: $migrations_dir" >&2
  exit 1
fi

mkdir -p "$state_dir"

mapfile -t migrations < <(find "$migrations_dir" -maxdepth 1 -type f -name '*.sh' -print | LC_ALL=C sort)

if [[ "${#migrations[@]}" -eq 0 ]]; then
  echo "No migrations found in $migrations_dir"
  exit 0
fi

for migration in "${migrations[@]}"; do
  migration_name="$(basename "$migration")"
  stamp_file="$state_dir/$migration_name"

  if [[ -e "$stamp_file" ]]; then
    echo "skip migration: $migration_name"
    continue
  fi

  echo "run  migration: $migration_name"

  DOTFILES_MIGRATION_NAME="$migration_name" \
  DOTFILES_MIGRATION_REPO_ROOT="$repo_root" \
  DOTFILES_MIGRATION_SCOPE="system" \
  DOTFILES_MIGRATION_HOST="$host" \
  DOTFILES_MIGRATION_STATE_DIR="$state_dir" \
  bash "$migration"

  touch "$stamp_file"
  echo "done migration: $migration_name"
done
