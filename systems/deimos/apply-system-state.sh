#!/usr/bin/env bash
set -euo pipefail

# Always-run, idempotent host state. Invoked from rebuild-system.sh after
# sync-host-config.sh. Use this for actions that are safe to re-run every
# rebuild (systemctl enable, idempotent symlink farms, ...). Anything that
# only makes sense once still belongs in a migration.

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

# shellcheck source=../shared/apply-system-state-common.sh
source "$repo_root/systems/shared/apply-system-state-common.sh"

# Make $link a symlink to $target. Replaces an empty placeholder file
# (widevine-installer drops one at the Chromium x64 probe path).
ensure_symlink() {
  local target="$1"
  local link="$2"

  if [[ ! -e "$target" ]]; then
    echo "ensure_symlink: missing target $target" >&2
    return 1
  fi

  if [[ -L "$link" ]]; then
    run_as_root ln -sfn "$target" "$link"
    return
  fi

  if [[ -f "$link" && ! -s "$link" ]]; then
    run_as_root rm -f "$link"
    run_as_root ln -s "$target" "$link"
    return
  fi

  if [[ -e "$link" ]]; then
    if [[ "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]; then
      return
    fi
    echo "ensure_symlink: refusing to replace non-symlink $link" >&2
    return 1
  fi

  run_as_root ln -s "$target" "$link"
}

# Widevine: widevine-installer puts the aarch64 CDM under /var/lib/widevine,
# but Chromium-family browsers expect it at their own Chrome-layout paths,
# and Chromium still probes a linux_x64 placeholder when deciding whether
# Widevine exists. Point everything at the real CDM.
widevine_dir="/var/lib/widevine/WidevineCdm"
widevine_lib="/var/lib/widevine/libwidevinecdm.so"

if [[ -d "$widevine_dir" && -f "$widevine_lib" ]]; then
  ensure_symlink "$widevine_lib" "$widevine_dir/_platform_specific/linux_x64/libwidevinecdm.so"

  run_as_root install -d -o root -g root -m 0755 /opt/google/chrome
  ensure_symlink "$widevine_dir" /opt/google/chrome/WidevineCdm
  ensure_symlink "$widevine_lib" /opt/google/chrome/libwidevinecdm.so

  if [[ -d /usr/aarch64/opera-stable ]]; then
    ensure_symlink "$widevine_dir" /usr/aarch64/opera-stable/WidevineCdm
  fi

  if [[ -d /opt/helium ]]; then
    ensure_symlink "$widevine_dir" /opt/helium/WidevineCdm
    ensure_symlink "$widevine_lib" /opt/helium/libwidevinecdm.so
  fi
fi

# SDDM display manager: enable the service and set graphical.target as the
# boot default. /etc/sddm.conf.d/20-deimos.conf comes from rootfs.
if command -v sddm >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet sddm.service; then
    run_as_root systemctl enable --force sddm.service
    echo "Enabled sddm.service"
  fi

  if [[ "$(systemctl get-default)" != "graphical.target" ]]; then
    run_as_root systemctl set-default graphical.target
    echo "Set default target to graphical.target"
  fi
fi
