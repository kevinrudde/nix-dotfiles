#!/usr/bin/env bash
set -euo pipefail

# Migration: Expose Asahi Widevine to Opera on deimos
# Host: deimos
#
# widevine-installer configures Firefox and Fedora Chromium paths. Opera's
# aarch64 RPM does not consume that Chromium path directly, so provide the
# Chrome/Opera locations it probes without copying the proprietary CDM.

host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

widevine_dir="/var/lib/widevine/WidevineCdm"
widevine_lib="/var/lib/widevine/libwidevinecdm.so"
opera_dir="/usr/aarch64/opera-stable"
chrome_compat_dir="/opt/google/chrome"

if [[ ! -d "$widevine_dir" || ! -f "$widevine_lib" ]]; then
  echo "Widevine is not installed under /var/lib/widevine." >&2
  echo "Run scripts/rebuild-system.sh so widevine-installer is installed before migrations." >&2
  exit 1
fi

if [[ ! -d "$opera_dir" ]]; then
  echo "Opera is not installed at $opera_dir." >&2
  echo "Run scripts/rebuild-system.sh so opera-stable is installed before migrations." >&2
  exit 1
fi

install_symlink() {
  local target="$1"
  local link="$2"

  if [[ ! -e "$target" ]]; then
    echo "Missing Widevine target: $target" >&2
    exit 1
  fi

  if [[ -L "$link" ]]; then
    sudo ln -sfn "$target" "$link"
    return
  fi

  if [[ -f "$link" && ! -s "$link" ]]; then
    sudo rm -f "$link"
    sudo ln -s "$target" "$link"
    return
  fi

  if [[ -e "$link" ]]; then
    if [[ "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]; then
      return
    fi

    echo "Refusing to replace existing non-symlink path: $link" >&2
    exit 1
  fi

  sudo ln -s "$target" "$link"
}

sudo install -d -o root -g root -m 0755 "$chrome_compat_dir"

install_symlink "$widevine_dir" "$chrome_compat_dir/WidevineCdm"
install_symlink "$widevine_lib" "$chrome_compat_dir/libwidevinecdm.so"
install_symlink "$widevine_dir" "$opera_dir/WidevineCdm"
install_symlink "$widevine_lib" "$widevine_dir/_platform_specific/linux_x64/libwidevinecdm.so"

echo "Configured Opera Widevine paths"
