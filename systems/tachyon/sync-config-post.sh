#!/usr/bin/env bash
set -euo pipefail

changed_targets_file="${DOTFILES_SYNC_CHANGED_TARGETS_FILE:?missing changed targets file}"

if ((EUID != 0)) && ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to run host config post-sync actions" >&2
  exit 1
fi

run_as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
}

target_changed() {
  grep -Fxq "$1" "$changed_targets_file"
}

if target_changed /etc/nix/nix.custom.conf; then
  run_as_root systemctl restart nix-daemon.service
  echo "Restarted nix-daemon (nix.custom.conf)"
fi

# Mount options only take effect on a fresh mount, so a changed unit is
# remounted rather than just reloaded.
mount_units=(mnt-bigm2.mount mnt-smallssd.mount)
changed_mount_units=()

for unit in "${mount_units[@]}"; do
  if target_changed "/etc/systemd/system/$unit"; then
    changed_mount_units+=("$unit")
  fi
done

if ((${#changed_mount_units[@]} > 0)); then
  run_as_root systemctl daemon-reload
  echo "Reloaded systemd unit files"

  for unit in "${changed_mount_units[@]}"; do
    if systemctl is-active --quiet "$unit"; then
      run_as_root systemctl restart "$unit"
      echo "Remounted $unit"
    fi
  done
fi
