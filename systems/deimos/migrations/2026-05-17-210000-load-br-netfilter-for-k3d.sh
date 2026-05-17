#!/usr/bin/env bash
set -euo pipefail

# Migration: Load br_netfilter and enable bridge netfilter sysctls for k3d
# Host: deimos
#
# Fedora Asahi Remix (ARM64) does not auto-load br_netfilter. Without it,
# packets routed across the Docker bridge bypass the iptables NAT rules that
# kube-proxy installs for Service ClusterIPs. Symptom: pods can reach other
# pods by IP, but Service ClusterIPs (e.g. 10.43.0.10 / kube-dns) time out,
# which breaks in-cluster DNS and prevents ztunnel from reaching istiod XDS
# on :15012.

host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

module_path="/lib/modules/$(uname -r)/kernel/net/bridge/br_netfilter.ko"
if [[ ! -f "$module_path" ]]; then
  echo "br_netfilter module is not present at $module_path" >&2
  echo "Verify the running kernel ships the module before re-running this migration." >&2
  exit 1
fi

if ! lsmod | awk '{print $1}' | grep -Fxq br_netfilter; then
  sudo modprobe br_netfilter
fi

sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1

modules_load_file="/etc/modules-load.d/k3d.conf"
tmp_modules_load="$(mktemp)"
sysctl_file="/etc/sysctl.d/99-k3d.conf"
tmp_sysctl="$(mktemp)"
trap 'rm -f "$tmp_modules_load" "$tmp_sysctl"' EXIT

cat > "$tmp_modules_load" <<'EOF'
br_netfilter
EOF

cat > "$tmp_sysctl" <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo install -D -m 0644 "$tmp_modules_load" "$modules_load_file"
sudo install -D -m 0644 "$tmp_sysctl" "$sysctl_file"

echo "Loaded br_netfilter and set bridge netfilter sysctls"
echo "Installed $modules_load_file"
echo "Installed $sysctl_file"
