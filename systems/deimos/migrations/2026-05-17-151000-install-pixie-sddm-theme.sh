#!/usr/bin/env bash
set -euo pipefail

# Migration: Install Pixie SDDM theme
# Host: deimos
#
# Installs the pinned Pixie SDDM v3.0 Qt6 theme and reapplies the deimos SDDM
# override so SDDM selects it.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

theme_name="pixie"
theme_repo="https://github.com/xCaptaiN09/pixie-sddm.git"
theme_ref="v3.0"
theme_commit="12a5f459ebd6d699be42c188c10976c8bb7076d7"
theme_dir="/usr/share/sddm/themes/${theme_name}"
sddm_config="${repo_root}/systems/deimos/config/sddm/20-deimos.conf"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install the Pixie SDDM theme." >&2
  echo "Run scripts/rebuild-system.sh so native packages sync before migrations." >&2
  exit 1
fi

if ! command -v sddm-greeter-qt6 >/dev/null 2>&1; then
  echo "sddm-greeter-qt6 is required for the Pixie SDDM Qt6 theme." >&2
  echo "Run scripts/rebuild-system.sh so native packages sync before migrations." >&2
  exit 1
fi

if command -v rpm >/dev/null 2>&1; then
  missing_packages=()

  for package in qt6-qtdeclarative qt6-qtsvg; do
    if ! rpm -q "$package" >/dev/null 2>&1; then
      missing_packages+=("$package")
    fi
  done

  if [[ "${#missing_packages[@]}" -gt 0 ]]; then
    echo "Missing Fedora packages required by Pixie SDDM: ${missing_packages[*]}" >&2
    echo "Run scripts/rebuild-system.sh so native packages sync before migrations." >&2
    exit 1
  fi
fi

if [[ ! -f "$sddm_config" ]]; then
  echo "SDDM config source is missing: $sddm_config" >&2
  exit 1
fi

if ! grep -Fxq "Current=${theme_name}" "$sddm_config"; then
  echo "SDDM config does not select the Pixie theme: $sddm_config" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
theme_src="${tmp_dir}/pixie-sddm"

git clone --depth 1 --branch "$theme_ref" "$theme_repo" "$theme_src"

actual_commit="$(git -C "$theme_src" rev-parse HEAD)"
if [[ "$actual_commit" != "$theme_commit" ]]; then
  echo "Pixie SDDM $theme_ref resolved to unexpected commit: $actual_commit" >&2
  echo "Expected: $theme_commit" >&2
  exit 1
fi

theme_files=(
  assets
  components
  Main.qml
  metadata.desktop
  theme.conf
  LICENSE
)

for file in "${theme_files[@]}"; do
  if [[ ! -e "$theme_src/$file" ]]; then
    echo "Theme source is missing required file: $file" >&2
    exit 1
  fi
done

sudo rm -rf "$theme_dir"
sudo install -d -m 0755 "$theme_dir"
sudo cp -a "${theme_files[@]/#/${theme_src}/}" "$theme_dir/"
sudo chmod -R a+rX "$theme_dir"
sudo install -D -m 0644 "$sddm_config" /etc/sddm.conf.d/20-deimos.conf

echo "Installed Pixie SDDM $theme_ref at $theme_commit"
echo "Installed $theme_dir"
echo "Installed /etc/sddm.conf.d/20-deimos.conf"
echo "Preview with: sddm-greeter-qt6 --test-mode --theme $theme_dir"
