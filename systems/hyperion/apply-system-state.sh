#!/usr/bin/env bash
set -euo pipefail

# Always-run, idempotent host state. Invoked from rebuild-system.sh after
# sync-host-config.sh. Use this for actions that are safe to re-run every
# rebuild (systemctl enable, idempotent symlink farms, ...). Anything that
# only makes sense once still belongs in a migration.

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

# shellcheck source=../shared/apply-system-state-common.sh
source "$repo_root/systems/shared/apply-system-state-common.sh"

# greetd display manager: enable the service. /etc/greetd/config.toml comes
# from rootfs and points at the shared Hyprland session launcher directly,
# so there's no wayland-sessions .desktop / graphical.target dance here —
# greetd owns the tty it's enabled on.
if command -v greetd >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet greetd.service; then
    run_as_root systemctl enable greetd.service
    echo "Enabled greetd.service"
  fi
fi

# Default shell: fish (config and binary both owned by home-manager's
# features/shell, which puts it in the nix profile). Idempotent; skipped
# until home-manager has run at least once on this host.
target_user="kevin"
target_shell="/home/kevin/.nix-profile/bin/fish"

if [ -x "$target_shell" ]; then
  if ! grep -qxF "$target_shell" /etc/shells 2>/dev/null; then
    printf '%s\n' "$target_shell" | run_as_root tee -a /etc/shells >/dev/null
    echo "Added $target_shell to /etc/shells"
  fi

  current_shell="$(getent passwd "$target_user" | cut -d: -f7)"
  if [ "$current_shell" != "$target_shell" ]; then
    run_as_root usermod -s "$target_shell" "$target_user"
    echo "Set $target_user's login shell to $target_shell"
  fi
fi
