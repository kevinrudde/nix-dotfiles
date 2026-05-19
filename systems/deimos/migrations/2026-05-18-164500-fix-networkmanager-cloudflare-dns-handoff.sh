#!/usr/bin/env bash
set -euo pipefail

# Migration: Fix NetworkManager Cloudflare DNS handoff to systemd-resolved
# Host: deimos
#
# The earlier Cloudflare DNS migration wrote a NetworkManager [global-dns]
# section. NetworkManager documents that global DNS overrides per-connection
# DNS, and on deimos that left systemd-resolved without the expected per-link
# DNS after restart. Keep the DNS settings on the Ethernet/Wi-Fi profiles and
# make NetworkManager publish those profile settings to resolved.

host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
  echo "nmcli is not installed. NetworkManager is required for this migration." >&2
  exit 1
fi

if ! command -v resolvectl >/dev/null 2>&1; then
  echo "resolvectl is not installed. systemd-resolved is required for this migration." >&2
  exit 1
fi

networkmanager_config="/etc/NetworkManager/conf.d/90-cloudflare-dns.conf"
tmp_config="$(mktemp)"
trap 'rm -f "$tmp_config"' EXIT

cat > "$tmp_config" <<'EOF'
# Managed by nix-dotfiles: deimos DNS.
[main]
dns=systemd-resolved
EOF

sudo install -D -o root -g root -m 0644 "$tmp_config" "$networkmanager_config"

mapfile -t physical_profile_uuids < <(
  nmcli -t -f UUID,TYPE connection show \
    | awk -F: '$2 == "802-3-ethernet" || $2 == "802-11-wireless" { print $1 }'
)

if [[ "${#physical_profile_uuids[@]}" -eq 0 ]]; then
  echo "No NetworkManager Ethernet or Wi-Fi profiles found" >&2
  exit 1
fi

for uuid in "${physical_profile_uuids[@]}"; do
  sudo nmcli connection modify "$uuid" \
    ipv4.dns "1.1.1.1 1.0.0.1" \
    ipv4.ignore-auto-dns yes \
    ipv4.dns-priority -1000 \
    ipv4.dns-search "~." \
    ipv6.dns "" \
    ipv6.ignore-auto-dns yes \
    ipv6.dns-priority -1000 \
    ipv6.dns-search ""

  echo "Configured Cloudflare DNS on NetworkManager profile $uuid"
done

sudo nmcli general reload conf,dns-full,dns-rc

mapfile -t active_physical_devices < <(
  nmcli -t -f UUID,TYPE,DEVICE connection show --active \
    | awk -F: '$2 == "802-3-ethernet" || $2 == "802-11-wireless" { print $3 }' \
    | LC_ALL=C sort -u
)

reapply_failed=0

for device in "${active_physical_devices[@]}"; do
  if [[ -z "$device" ]]; then
    continue
  fi

  sudo resolvectl revert "$device" || true

  if sudo nmcli device reapply "$device"; then
    echo "Reapplied active NetworkManager device $device"
  else
    echo "Could not reapply $device. Reconnect this device or restart NetworkManager to apply DNS." >&2
    reapply_failed=1
  fi
done

if [[ "$reapply_failed" -ne 0 ]]; then
  exit 1
fi

echo "Installed $networkmanager_config without NetworkManager global-dns override"
echo "Configured DNS servers: 1.1.1.1, 1.0.0.1"
