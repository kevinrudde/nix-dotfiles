#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/new-migration.sh [--host HOST] [--description TEXT]

Creates a new host migration from the checked-in template.
If arguments are omitted, the script prompts for them interactively.
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
template_path="$repo_root/migrations/.templates/host-migration.sh.template"

host=""
description=""

while (($# > 0)); do
  case "$1" in
    --host)
      shift
      host="${1:?missing value for --host}"
      shift
      ;;
    --description)
      shift
      description="${1:?missing value for --description}"
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

default_host="$(hostname -s 2>/dev/null || hostname)"

if [[ -z "$host" ]]; then
  read -r -p "Hostname [$default_host]: " host
  host="${host:-$default_host}"
fi

if [[ -z "$description" ]]; then
  read -r -p "Migration description: " description
fi

if [[ -z "$host" ]]; then
  echo "Hostname must not be empty" >&2
  exit 1
fi

if [[ -z "$description" ]]; then
  echo "Description must not be empty" >&2
  exit 1
fi

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
}

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

slug="$(slugify "$description")"

if [[ -z "$slug" ]]; then
  echo "Description must contain at least one letter or number" >&2
  exit 1
fi

timestamp="$(date '+%Y-%m-%d-%H%M%S')"
target_dir="$repo_root/systems/$host/migrations"
target_path="$target_dir/$timestamp-$slug.sh"

if [[ ! -f "$template_path" ]]; then
  echo "Template not found: $template_path" >&2
  exit 1
fi

mkdir -p "$target_dir"

description_escaped="$(escape_sed "$description")"
host_escaped="$(escape_sed "$host")"

sed \
  -e "s/__DESCRIPTION__/$description_escaped/g" \
  -e "s/__HOST__/$host_escaped/g" \
  "$template_path" > "$target_path"

chmod +x "$target_path"

echo "Created migration: $target_path"
