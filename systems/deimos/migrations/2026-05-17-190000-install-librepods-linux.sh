#!/usr/bin/env bash
set -euo pipefail

# Migration: Install LibrePods Linux from the pinned vendored source release
# Host: deimos
#
# Builds LibrePods natively on Fedora Asahi so the installed binary matches
# this host's aarch64 architecture. Package installation is handled by
# systems/deimos/packages.txt before migrations run.

host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

case "$(uname -m)" in
  aarch64|arm64)
    ;;
  *)
    echo "This migration expects an ARM64 Linux host, got: $(uname -m)" >&2
    exit 1
    ;;
esac

version="0.1.0"
release_tag="linux-v${version}"
archive_url="https://github.com/kavishdevar/librepods/releases/download/${release_tag}/librepods-v${version}-source.tar.gz"
install_dir="/opt/librepods"
desktop_file="/usr/local/share/applications/me.kavishdevar.librepods.desktop"
icon_file="/usr/local/share/icons/hicolor/256x256/apps/me.kavishdevar.librepods.png"

for command in cargo curl install pkg-config sudo tar; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "$command is required to build and install LibrePods." >&2
    exit 1
  fi
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

archive_file="${tmp_dir}/librepods-v${version}-source.tar.gz"
extract_dir="${tmp_dir}/extract"

curl -fL --proto '=https' --tlsv1.2 -o "$archive_file" "$archive_url"
install -d -m 0755 "$extract_dir"
tar -xzf "$archive_file" -C "$extract_dir"

source_dir="${extract_dir}/librepods-v${version}"

if [[ ! -f "${source_dir}/Cargo.toml" ]]; then
  echo "LibrePods source archive did not contain Cargo.toml at ${source_dir}" >&2
  exit 1
fi

if [[ ! -d "${source_dir}/vendor" ]]; then
  echo "LibrePods source archive is missing vendored Cargo dependencies." >&2
  exit 1
fi

(
  cd "$source_dir"
  cargo build --release --locked
)

sudo install -D -m 0755 "${source_dir}/target/release/librepods" "${install_dir}/librepods"
sudo ln -sfn "${install_dir}/librepods" /usr/local/bin/librepods

if [[ -f "${source_dir}/assets/me.kavishdevar.librepods.desktop" ]]; then
  sudo install -D -m 0644 "${source_dir}/assets/me.kavishdevar.librepods.desktop" "$desktop_file"
fi

if [[ -f "${source_dir}/assets/icon.png" ]]; then
  sudo install -D -m 0644 "${source_dir}/assets/icon.png" "$icon_file"
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  sudo gtk-update-icon-cache -q /usr/local/share/icons/hicolor || true
fi

if systemctl list-unit-files bluetooth.service >/dev/null 2>&1; then
  sudo systemctl enable --now bluetooth.service
fi

echo "Installed LibrePods ${version} to ${install_dir}/librepods"
echo "Installed /usr/local/bin/librepods"
