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

# logind has no ExecReload, so the lid policy only lands on a restart. That is
# safe to do under a live graphical session: the unit carries a
# FileDescriptorStoreMax, so the session's device fds survive the bounce.
if target_changed /etc/systemd/logind.conf.d/10-lid.conf; then
  run_as_root systemctl restart systemd-logind.service
  echo "Restarted systemd-logind (lid policy)"
fi

if target_changed /etc/NetworkManager/conf.d/10-dns-resolved.conf; then
  run_as_root systemctl reload NetworkManager.service
  echo "Reloaded NetworkManager"
fi

# k3d needs bridged traffic to pass through iptables for Kubernetes Service
# ClusterIPs to work from pods. modprobe here makes it live immediately
# instead of waiting for the next reboot's systemd-modules-load pass.
if target_changed /etc/modules-load.d/k3d.conf; then
  run_as_root modprobe br_netfilter
  echo "Loaded br_netfilter"
fi

if target_changed /etc/sysctl.d/99-k3d.conf; then
  run_as_root sysctl --system >/dev/null
  echo "Applied k3d sysctl settings"
fi
