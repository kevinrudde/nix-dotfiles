#!/usr/bin/env bash
set -euo pipefail

# Always-run, idempotent host state. Invoked from rebuild-system.sh after
# sync-host-config.sh.

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

# shellcheck source=../shared/apply-system-state-common.sh
source "$repo_root/systems/shared/apply-system-state-common.sh"

# greetd display manager: /etc/greetd/config.toml comes from rootfs and points
# at the shared Hyprland session launcher directly.
if command -v greetd >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet greetd.service; then
    run_as_root systemctl enable greetd.service
    echo "Enabled greetd.service"
  fi
fi

# Data drives: unit files ship via rootfs/, enabling is a state op.
for unit in mnt-bigm2.mount mnt-smallssd.mount; do
  if ! systemctl is-enabled --quiet "$unit"; then
    run_as_root systemctl enable --now "$unit"
    echo "Enabled $unit"
  fi
done

# Default shell: fish, owned by home-manager's features/shell. Skipped until
# home-manager has run at least once on this host.
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
