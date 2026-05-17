#!/usr/bin/env bash
set -euo pipefail

# Migration: Raise inotify limits to stop "too many open files" from fsnotify
# Host: deimos
#
# Fedora ships fs.inotify.max_user_instances = 128, which is easily exhausted
# by k3d (kubelet + containerd + kube-proxy each open several instances),
# Docker, the IDE, and desktop services. When the per-user instance cap is
# hit, inotify_init() returns EMFILE, which Go's fsnotify surfaces as:
#   failed to create fsnotify watcher: too many open files
# Raising max_user_watches too keeps large workspaces (node_modules, Go module
# cache, k8s manifests) from running out of watch descriptors.

host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

sudo sysctl -w fs.inotify.max_user_instances=1024
sudo sysctl -w fs.inotify.max_user_watches=1048576

sysctl_file="/etc/sysctl.d/99-inotify.conf"
tmp_sysctl="$(mktemp)"
trap 'rm -f "$tmp_sysctl"' EXIT

cat > "$tmp_sysctl" <<'EOF'
fs.inotify.max_user_instances = 1024
fs.inotify.max_user_watches = 1048576
EOF

sudo install -D -m 0644 "$tmp_sysctl" "$sysctl_file"

echo "Raised inotify limits (instances=1024, watches=1048576)"
echo "Installed $sysctl_file"
