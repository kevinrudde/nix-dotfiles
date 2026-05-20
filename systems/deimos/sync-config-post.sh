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

if target_changed /etc/logid.cfg && systemctl cat logid.service >/dev/null 2>&1; then
  run_as_root systemctl restart logid.service
  echo "Restarted logid.service"
fi

if target_changed /etc/sddm.conf.d/20-deimos.conf; then
  echo "SDDM will use the updated config after its next restart"
fi
