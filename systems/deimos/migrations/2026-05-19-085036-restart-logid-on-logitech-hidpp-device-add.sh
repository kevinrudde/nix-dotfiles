#!/usr/bin/env bash
set -euo pipefail

# Migration: Restart logid when a Logitech HID++ device appears
# Host: deimos
#
# The MX Master 3S on deimos pairs over Bluetooth, so its /dev/hidraw node is
# created by bluetoothd well after logid.service finishes its 5 startup
# retries. logid logs "Failed to add device /dev/hidrawN after 5 tries.
# Treating as failure." but stays running, so Restart=on-failure never fires
# and the daemon is effectively dead until a manual `systemctl restart logid`.
#
# Fix: a udev rule that activates a oneshot service which try-restarts
# logid.service whenever a logitech-hidpp-device hid node is added. The brief
# sleep gives the kernel time to create the hidraw child of the hid device
# before logid re-enumerates.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

tmp_service="$(mktemp)"
tmp_rule="$(mktemp)"
trap 'rm -f "$tmp_service" "$tmp_rule"' EXIT

cat > "$tmp_service" <<'EOF'
[Unit]
Description=Restart logid after a Logitech HID++ device appears
After=logid.service

[Service]
Type=oneshot
ExecStart=/usr/bin/sleep 1
ExecStart=/usr/bin/systemctl try-restart logid.service
EOF

cat > "$tmp_rule" <<'EOF'
# Restart logid when a Logitech HID++ device (USB or Bluetooth) is added so
# that late-arriving /dev/hidraw nodes (notably Bluetooth-paired devices like
# the MX Master 3S) are picked up without a manual restart.
ACTION=="add", SUBSYSTEM=="hid", DRIVER=="logitech-hidpp-device", TAG+="systemd", ENV{SYSTEMD_WANTS}="logid-restart.service"
EOF

sudo install -D -m 0644 "$tmp_service" /etc/systemd/system/logid-restart.service
sudo install -D -m 0644 "$tmp_rule" /etc/udev/rules.d/90-logid-restart.rules

sudo systemctl daemon-reload
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=hid --action=add

echo "Installed /etc/systemd/system/logid-restart.service"
echo "Installed /etc/udev/rules.d/90-logid-restart.rules"
