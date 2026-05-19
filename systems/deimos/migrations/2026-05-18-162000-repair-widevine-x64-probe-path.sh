#!/usr/bin/env bash
set -euo pipefail

# Migration: Repair Widevine's Chromium x64 probe path on deimos
# Host: deimos
#
# widevine-installer creates an empty linux_x64/libwidevinecdm.so placeholder.
# Current Chromium-family builds still probe that path when deciding whether
# Widevine exists, so point it at the actual aarch64 CDM instead.

host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

widevine_lib="/var/lib/widevine/libwidevinecdm.so"
widevine_probe_lib="/var/lib/widevine/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so"

if [[ ! -f "$widevine_lib" ]]; then
  echo "Widevine is not installed at $widevine_lib." >&2
  echo "Run scripts/rebuild-system.sh so widevine-installer is installed before migrations." >&2
  exit 1
fi

if [[ -L "$widevine_probe_lib" ]]; then
  sudo ln -sfn "$widevine_lib" "$widevine_probe_lib"
elif [[ -f "$widevine_probe_lib" && ! -s "$widevine_probe_lib" ]]; then
  sudo rm -f "$widevine_probe_lib"
  sudo ln -s "$widevine_lib" "$widevine_probe_lib"
elif [[ -e "$widevine_probe_lib" ]]; then
  if [[ "$(readlink -f "$widevine_probe_lib")" != "$(readlink -f "$widevine_lib")" ]]; then
    echo "Refusing to replace existing non-empty Widevine probe path: $widevine_probe_lib" >&2
    exit 1
  fi
else
  sudo install -d -o root -g root -m 0755 "$(dirname "$widevine_probe_lib")"
  sudo ln -s "$widevine_lib" "$widevine_probe_lib"
fi

echo "Repaired Widevine x64 probe path"
