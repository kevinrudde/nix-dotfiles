#!/usr/bin/env bash
# Idempotent root ops shared across every Linux host. Sourced from each
# systems/<host>/apply-system-state.sh, which then adds its own
# display-manager-specific block. Must stay a no-op when state already
# matches; never prompt or invoke sudo on the happy path.

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

# Docker Engine: enable the service and put the active user in the docker
# group so they can talk to /var/run/docker.sock without sudo.
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

# Tailscale: enable the daemon. Distro packages don't reliably auto-enable
# tailscaled on install, so do it here every rebuild.
if command -v tailscale >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet tailscaled.service; then
    run_as_root systemctl enable --now tailscaled.service
    echo "Enabled tailscaled.service"
  fi
fi

# 1Password permission repair. Maintains the SUID/SGID bits + onepassword
# group on every rebuild so they survive package updates and stay
# consistent. The JSON browser manifests + custom_allowed_browsers live in
# each host's rootfs.
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
