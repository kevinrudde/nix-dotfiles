#!/usr/bin/env bash
set -euo pipefail

# Migration: Configure LogiOps for Logitech MX Master 3S
# Host: deimos
#
# Installs the checked-in logid configuration and enables the LogiOps daemon.
# Package installation is handled by systems/deimos/packages.txt before
# migrations run.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

logid_config="${repo_root}/systems/deimos/config/logid/logid.cfg"

if ! command -v logid >/dev/null 2>&1; then
  echo "logid is not installed. Run scripts/rebuild-system.sh so native packages sync before migrations." >&2
  exit 1
fi

if [[ ! -f "$logid_config" ]]; then
  echo "LogiOps config source is missing: $logid_config" >&2
  exit 1
fi

sudo install -D -m 0644 "$logid_config" /etc/logid.cfg

# Work around the logiops/udev startup race: logid can lose the race for
# /dev/hidraw* on boot/resume and bail with
# "Failed to add device /dev/hidrawN after 5 tries. Treating as failure".
# Auto-restart until the hidraw node is ready instead of needing a manual
# `systemctl restart logid`.
tmp_override="$(mktemp)"
trap 'rm -f "$tmp_override"' EXIT

cat > "$tmp_override" <<'EOF'
[Service]
Restart=on-failure
RestartSec=2
StartLimitBurst=10
StartLimitIntervalSec=60
EOF

sudo install -D -m 0644 "$tmp_override" /etc/systemd/system/logid.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl enable logid.service

if sudo systemctl is-active --quiet logid.service; then
  sudo systemctl restart logid.service
else
  sudo systemctl start logid.service
fi

echo "Installed /etc/logid.cfg"
echo "Installed /etc/systemd/system/logid.service.d/override.conf"
echo "Enabled logid.service"
