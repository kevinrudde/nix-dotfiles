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

any_target_changed() {
  local target
  for target in "$@"; do
    if target_changed "$target"; then
      return 0
    fi
  done
  return 1
}

systemd_unit_changes=(
  /etc/systemd/system/logid.service.d/override.conf
  /etc/systemd/system/logid-restart.service
)

if any_target_changed "${systemd_unit_changes[@]}"; then
  run_as_root systemctl daemon-reload
  echo "Reloaded systemd unit files"
fi

if target_changed /etc/udev/rules.d/90-logid-restart.rules; then
  run_as_root udevadm control --reload
  run_as_root udevadm trigger --subsystem-match=hid --action=add
  echo "Reloaded udev rules"
fi

if systemctl cat logid.service >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet logid.service; then
    run_as_root systemctl enable logid.service
    echo "Enabled logid.service"
  fi

  if any_target_changed /etc/logid.cfg /etc/systemd/system/logid.service.d/override.conf; then
    run_as_root systemctl restart logid.service
    echo "Restarted logid.service"
  fi
fi
