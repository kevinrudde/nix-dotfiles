#!/usr/bin/env bash
set -euo pipefail

# Migration: Install 1Password native messaging hosts
# Host: deimos
#
# The ARM tarball install does not install browser native messaging manifests.
# Zen is Firefox-based, so it needs the Mozilla native messaging host manifest
# before the trusted-browser allowlist can take effect.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

firefox_native_host_src="$repo_root/systems/deimos/rootfs/usr/lib/mozilla/native-messaging-hosts/com.1password.1password.json"
chromium_native_host_src="$repo_root/systems/deimos/rootfs/etc/chromium/native-messaging-hosts/com.1password.1password.json"
native_host_name="com.1password.1password.json"

for native_host_src in "$firefox_native_host_src" "$chromium_native_host_src"; do
  if [[ ! -f "$native_host_src" ]]; then
    echo "Missing managed 1Password native messaging host manifest: $native_host_src" >&2
    exit 1
  fi
done

for firefox_native_host_dir in \
  /usr/lib/mozilla/native-messaging-hosts \
  /usr/lib64/mozilla/native-messaging-hosts
do
  sudo install -d -o root -g root -m 0755 "$firefox_native_host_dir"
  sudo install -o root -g root -m 0644 \
    "$firefox_native_host_src" \
    "$firefox_native_host_dir/$native_host_name"
done

for chromium_native_host_dir in \
  /etc/chromium/native-messaging-hosts \
  /etc/opt/chrome/native-messaging-hosts
do
  sudo install -d -o root -g root -m 0755 "$chromium_native_host_dir"
  sudo install -o root -g root -m 0644 \
    "$chromium_native_host_src" \
    "$chromium_native_host_dir/$native_host_name"
done

echo "Installed 1Password native messaging host manifests"
