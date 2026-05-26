#!/usr/bin/env bash
set -euo pipefail

# Always-run, idempotent host state. Invoked from rebuild-system.sh after
# sync-host-config.sh. Use this for actions that are safe to re-run every
# rebuild (systemctl enable, idempotent symlink farms, ...). Anything that
# only makes sense once still belongs in a migration.

if ((EUID != 0)) && ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to apply host state" >&2
  exit 1
fi

run_as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
}

# Make $link a symlink to $target. Replaces an empty placeholder file
# (widevine-installer drops one at the Chromium x64 probe path).
ensure_symlink() {
  local target="$1"
  local link="$2"

  if [[ ! -e "$target" ]]; then
    echo "ensure_symlink: missing target $target" >&2
    return 1
  fi

  if [[ -L "$link" ]]; then
    run_as_root ln -sfn "$target" "$link"
    return
  fi

  if [[ -f "$link" && ! -s "$link" ]]; then
    run_as_root rm -f "$link"
    run_as_root ln -s "$target" "$link"
    return
  fi

  if [[ -e "$link" ]]; then
    if [[ "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]; then
      return
    fi
    echo "ensure_symlink: refusing to replace non-symlink $link" >&2
    return 1
  fi

  run_as_root ln -s "$target" "$link"
}

# Widevine: widevine-installer puts the aarch64 CDM under /var/lib/widevine,
# but Chromium-family browsers expect it at their own Chrome-layout paths,
# and Chromium still probes a linux_x64 placeholder when deciding whether
# Widevine exists. Point everything at the real CDM.
widevine_dir="/var/lib/widevine/WidevineCdm"
widevine_lib="/var/lib/widevine/libwidevinecdm.so"

if [[ -d "$widevine_dir" && -f "$widevine_lib" ]]; then
  ensure_symlink "$widevine_lib" "$widevine_dir/_platform_specific/linux_x64/libwidevinecdm.so"

  run_as_root install -d -o root -g root -m 0755 /opt/google/chrome
  ensure_symlink "$widevine_dir" /opt/google/chrome/WidevineCdm
  ensure_symlink "$widevine_lib" /opt/google/chrome/libwidevinecdm.so

  if [[ -d /usr/aarch64/opera-stable ]]; then
    ensure_symlink "$widevine_dir" /usr/aarch64/opera-stable/WidevineCdm
  fi

  if [[ -d /opt/helium ]]; then
    ensure_symlink "$widevine_dir" /opt/helium/WidevineCdm
    ensure_symlink "$widevine_lib" /opt/helium/libwidevinecdm.so
  fi
fi

# Docker Engine: enable the service and put the active user in the docker
# group so they can talk to /var/run/docker.sock without sudo. Packages come
# from the docker-ce DNF repo in fedora-packages-sync.
if command -v docker >/dev/null 2>&1; then
  target_user="${SUDO_USER:-$(id -un)}"

  if [[ "$target_user" == "root" ]]; then
    echo "apply-system-state: refusing to add root to the docker group" >&2
    exit 1
  fi

  run_as_root systemctl enable --now docker.service
  run_as_root systemctl enable --now containerd.service

  if ! getent group docker >/dev/null; then
    run_as_root groupadd docker
  fi

  if ! id -nG "$target_user" | tr ' ' '\n' | grep -Fxq docker; then
    run_as_root usermod -aG docker "$target_user"
    echo "Added '$target_user' to the docker group. Log out and back in (or run 'newgrp docker') for it to take effect."
  fi
fi

# SDDM display manager: enable the service and set graphical.target as the
# boot default. /etc/sddm.conf.d/20-deimos.conf comes from rootfs.
if command -v sddm >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet sddm.service; then
    run_as_root systemctl enable --force sddm.service
    echo "Enabled sddm.service"
  fi

  if [[ "$(systemctl get-default)" != "graphical.target" ]]; then
    run_as_root systemctl set-default graphical.target
    echo "Set default target to graphical.target"
  fi
fi

# Cloudflare DNS via NetworkManager per-profile settings. The conf.d file in
# rootfs hands resolution off to systemd-resolved; here we publish the
# Cloudflare resolvers into every ethernet/wifi profile so resolved picks them
# up. Skip-if-already-configured so re-runs are no-ops.
if command -v nmcli >/dev/null 2>&1; then
  expected_dns=$'ipv4.dns:1.1.1.1,1.0.0.1\nipv4.ignore-auto-dns:yes\nipv4.dns-priority:-1000\nipv4.dns-search:~.\nipv6.dns:\nipv6.ignore-auto-dns:yes\nipv6.dns-priority:-1000\nipv6.dns-search:'

  mapfile -t physical_uuids < <(
    nmcli -t -f UUID,TYPE connection show \
      | awk -F: '$2 == "802-3-ethernet" || $2 == "802-11-wireless" { print $1 }'
  )

  changed_uuids=()
  for uuid in "${physical_uuids[@]}"; do
    actual_dns="$(nmcli -t -f ipv4.dns,ipv4.ignore-auto-dns,ipv4.dns-priority,ipv4.dns-search,ipv6.dns,ipv6.ignore-auto-dns,ipv6.dns-priority,ipv6.dns-search connection show "$uuid")"
    if [[ "$actual_dns" == "$expected_dns" ]]; then
      continue
    fi

    run_as_root nmcli connection modify "$uuid" \
      ipv4.dns "1.1.1.1 1.0.0.1" \
      ipv4.ignore-auto-dns yes \
      ipv4.dns-priority -1000 \
      ipv4.dns-search "~." \
      ipv6.dns "" \
      ipv6.ignore-auto-dns yes \
      ipv6.dns-priority -1000 \
      ipv6.dns-search ""
    changed_uuids+=("$uuid")
    echo "Applied Cloudflare DNS to NetworkManager profile $uuid"
  done

  if (( ${#changed_uuids[@]} > 0 )); then
    run_as_root nmcli general reload conf,dns-full,dns-rc

    mapfile -t active_changed_devices < <(
      printf '%s\n' "${changed_uuids[@]}" \
        | while read -r uuid; do
            nmcli -t -f GENERAL.DEVICES connection show "$uuid" 2>/dev/null \
              | awk -F: 'NF > 1 { print $2 }'
          done \
        | LC_ALL=C sort -u
    )

    for device in "${active_changed_devices[@]}"; do
      [[ -z "$device" || "$device" == "--" ]] && continue
      if ! run_as_root nmcli device reapply "$device"; then
        echo "Could not reapply $device; reconnect it to apply DNS" >&2
      fi
    done
  fi
fi

# 1Password permission repair. /opt/1Password is populated by the
# install-1password-linux-arm64 migration, which also runs upstream's
# after-install.sh once; here we maintain the SUID/SGID bits + onepassword
# group on every rebuild so they survive package updates and stay consistent.
# The JSON browser manifests + custom_allowed_browsers live in rootfs.
onepassword_dir="/opt/1Password"

if [[ -d "$onepassword_dir" ]]; then
  run_as_root chown -R root:root "$onepassword_dir"

  if [[ -e "$onepassword_dir/chrome-sandbox" ]]; then
    run_as_root chmod 4755 "$onepassword_dir/chrome-sandbox"
  fi

  if [[ -e "$onepassword_dir/1Password-BrowserSupport" ]]; then
    if ! getent group onepassword >/dev/null 2>&1; then
      run_as_root groupadd --system onepassword
    fi
    run_as_root chown root:onepassword "$onepassword_dir/1Password-BrowserSupport"
    run_as_root chmod 2755 "$onepassword_dir/1Password-BrowserSupport"
  fi
fi
