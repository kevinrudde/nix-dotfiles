#!/usr/bin/env bash
set -euo pipefail

# Migration: Configure 1Password Linux integration on deimos
# Host: deimos
#
# Repairs the manual ARM tarball install permissions and installs the managed
# custom browser allowlist used by 1Password's browser support helper.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

custom_browsers_src="$repo_root/systems/deimos/config/1password/custom_allowed_browsers"
custom_browsers_target="/etc/1password/custom_allowed_browsers"
firefox_native_host_src="$repo_root/systems/deimos/config/1password/firefox-native-messaging-host.json"
chromium_native_host_src="$repo_root/systems/deimos/config/1password/chromium-native-messaging-host.json"
native_host_name="com.1password.1password.json"
install_dir="/opt/1Password"

if [[ ! -f "$custom_browsers_src" ]]; then
  echo "Missing managed 1Password browser allowlist: $custom_browsers_src" >&2
  exit 1
fi

for native_host_src in "$firefox_native_host_src" "$chromium_native_host_src"; do
  if [[ ! -f "$native_host_src" ]]; then
    echo "Missing managed 1Password native messaging host manifest: $native_host_src" >&2
    exit 1
  fi
done

if [[ -d "$install_dir" ]]; then
  sudo chown -R root:root "$install_dir"

  if [[ -x "$install_dir/after-install.sh" ]]; then
    sudo "$install_dir/after-install.sh"
  fi

  if [[ -e "$install_dir/chrome-sandbox" ]]; then
    sudo chown root:root "$install_dir/chrome-sandbox"
    sudo chmod 4755 "$install_dir/chrome-sandbox"
  fi

  if [[ -e "$install_dir/1Password-BrowserSupport" ]]; then
    if ! getent group onepassword >/dev/null 2>&1; then
      sudo groupadd --system onepassword
    fi

    sudo chown root:onepassword "$install_dir/1Password-BrowserSupport"
    sudo chmod 2755 "$install_dir/1Password-BrowserSupport"
  fi
else
  echo "1Password install directory not found; skipping permission repair: $install_dir"
fi

sudo install -d -o root -g root -m 0755 /etc/1password
sudo install -o root -g root -m 0644 "$custom_browsers_src" "$custom_browsers_target"

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

echo "Configured 1Password custom browser allowlist and native messaging hosts"
