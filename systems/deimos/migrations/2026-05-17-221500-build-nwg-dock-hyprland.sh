#!/usr/bin/env bash
set -euo pipefail

# Migration: Build and install nwg-dock-hyprland from upstream source
# Host: deimos
#
# Fedora 44 does not package nwg-dock-hyprland, so build it against Fedora's
# native GTK / gtk-layer-shell libraries and install it under /usr/local.
# Build dependencies are installed from systems/deimos/packages.txt first.

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

version="0.4.9"
archive_url="https://github.com/nwg-piotr/nwg-dock-hyprland/archive/refs/tags/v${version}.tar.gz"
install_bin="/usr/local/bin/nwg-dock-hyprland"
data_dir="/usr/local/share/nwg-dock-hyprland"
go_cmd="/usr/bin/go"

for command in curl install pkg-config sudo tar; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "$command is required to build and install nwg-dock-hyprland." >&2
    exit 1
  fi
done

if [[ ! -x "$go_cmd" ]]; then
  echo "$go_cmd is required to build nwg-dock-hyprland. Run rebuild-system so Fedora packages sync first." >&2
  exit 1
fi

if [[ -x "$install_bin" && -d "${data_dir}/images" ]]; then
  installed_version="$("$install_bin" -v 2>/dev/null || true)"
  if [[ "$installed_version" == *" ${version}" ]]; then
    echo "nwg-dock-hyprland ${version} is already installed at ${install_bin}"
    exit 0
  fi
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

archive_file="${tmp_dir}/nwg-dock-hyprland-${version}.tar.gz"
extract_dir="${tmp_dir}/extract"

curl -fL --proto '=https' --tlsv1.2 -o "$archive_file" "$archive_url"
install -d -m 0755 "$extract_dir"
tar -xzf "$archive_file" -C "$extract_dir"

source_dir="${extract_dir}/nwg-dock-hyprland-${version}"

if [[ ! -f "${source_dir}/go.mod" ]]; then
  echo "nwg-dock-hyprland source archive did not contain go.mod at ${source_dir}" >&2
  exit 1
fi

if [[ ! -d "${source_dir}/images" || ! -f "${source_dir}/config/style.css" ]]; then
  echo "nwg-dock-hyprland source archive is missing runtime assets." >&2
  exit 1
fi

echo "Building nwg-dock-hyprland ${version} from ${source_dir}"
echo "Using go.mod: ${source_dir}/go.mod"
echo "gotk4 CGO bindings can take 15+ minutes on ARM64."
env CGO_ENABLED=1 GO111MODULE=on "$go_cmd" -C "$source_dir" build -v -trimpath -buildmode=pie -o "${tmp_dir}/nwg-dock-hyprland" .

sudo install -D -m 0755 "${tmp_dir}/nwg-dock-hyprland" "$install_bin"
sudo install -d -m 0755 "${data_dir}/images"
sudo install -m 0644 "${source_dir}/config/style.css" "${data_dir}/style.css"
sudo cp -R "${source_dir}/images/." "${data_dir}/images/"
sudo chmod -R a+rX "$data_dir"

echo "Installed nwg-dock-hyprland ${version} to ${install_bin}"
echo "Installed runtime assets to ${data_dir}"
