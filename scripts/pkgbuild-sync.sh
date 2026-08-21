#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/pkgbuild-sync.sh [--host HOST] [--repo DIR] [--force]

Builds and installs vendored PKGBUILDs from systems/<host>/pkgbuilds/*/ with
makepkg. A package is skipped when the installed pkgver-pkgrel already matches
the vendored one, so this is a no-op on a normal rebuild. Use this lane only for
packages that exist neither in the official repos nor the AUR; anything paru can
resolve belongs in packages.txt instead.

Dependencies are NOT resolved here -- makepkg runs without -s so it never
reaches for Arch's stock package when a Cachy equivalent is already installed.
List every dependency in packages.txt so paru-sync.sh installs it first.
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
host="$(hostname -s 2>/dev/null || hostname)"
force=0

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
    --force)
      force=1
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

pkgbuilds_dir="$repo_root/systems/$host/pkgbuilds"

if [[ ! -d "$pkgbuilds_dir" ]]; then
  echo "No vendored PKGBUILDs found for host '$host'"
  exit 0
fi

shopt -s nullglob
pkgbuild_dirs=("$pkgbuilds_dir"/*/)
shopt -u nullglob

if ((${#pkgbuild_dirs[@]} == 0)); then
  echo "No vendored PKGBUILDs found for host '$host'"
  exit 0
fi

if ((EUID == 0)); then
  echo "pkgbuild-sync must not run as root; makepkg refuses to build as root" >&2
  exit 1
fi

for tool in makepkg pacman; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool is required to build vendored PKGBUILDs" >&2
    exit 1
  fi
done

# pkgname/pkgver/pkgrel are plain assignments at the top of every PKGBUILD we
# vendor, so read them rather than sourcing the file, which would run arbitrary
# build logic just to answer "is it already current?".
read_field() {
  local file="$1" field="$2"
  sed -n "s/^${field}=['\"]\?\([^'\"#]*\)['\"]\?[[:space:]]*\$/\1/p" "$file" | head -1
}

for pkgbuild_dir in "${pkgbuild_dirs[@]}"; do
  pkgbuild_dir="${pkgbuild_dir%/}"
  pkgbuild="$pkgbuild_dir/PKGBUILD"

  if [[ ! -f "$pkgbuild" ]]; then
    echo "Skipping $pkgbuild_dir: no PKGBUILD"
    continue
  fi

  pkgname="$(read_field "$pkgbuild" pkgname)"
  pkgver="$(read_field "$pkgbuild" pkgver)"
  pkgrel="$(read_field "$pkgbuild" pkgrel)"

  if [[ -z "$pkgname" || -z "$pkgver" || -z "$pkgrel" ]]; then
    echo "Could not read pkgname/pkgver/pkgrel from $pkgbuild" >&2
    exit 1
  fi

  want="$pkgver-$pkgrel"
  have="$(pacman -Q "$pkgname" 2>/dev/null | awk '{print $2}' || true)"

  if ((force == 0)) && [[ "$have" == "$want" ]]; then
    echo "Current $pkgname $want"
    continue
  fi

  if [[ -n "$have" ]]; then
    echo "Rebuilding $pkgname: installed $have, vendored $want"
  else
    echo "Building $pkgname $want"
  fi

  # Build in a scratch copy so the repo working tree never collects src/, pkg/
  # or built tarballs.
  build_dir="$(mktemp -d "${TMPDIR:-/tmp}/pkgbuild-sync-$pkgname.XXXXXX")"
  trap 'rm -rf "$build_dir"' EXIT
  cp -a "$pkgbuild_dir"/. "$build_dir/"

  (cd "$build_dir" && makepkg -fi --noconfirm --needed)

  rm -rf "$build_dir"
  trap - EXIT

  echo "Installed $pkgname $want"
done
