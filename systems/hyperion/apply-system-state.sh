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

# DNS: hand /etc/resolv.conf to systemd-resolved. NetworkManager is pinned
# to dns=systemd-resolved + rc-manager=unmanaged by
# rootfs/etc/NetworkManager/conf.d/10-dns-resolved.conf, so it leaves the
# symlink alone and the search list resolved publishes includes the domains
# tailscaled programs onto tailscale0. Without this tailscaled reports
# resolv-conf-mode=foreign and warns that resolved and NetworkManager are
# wired together incorrectly (https://tailscale.com/s/resolved-nm).
resolved_stub="/run/systemd/resolve/stub-resolv.conf"

if ! systemctl is-enabled --quiet systemd-resolved.service; then
  run_as_root systemctl enable --now systemd-resolved.service
  echo "Enabled systemd-resolved.service"
fi

if [ "$(readlink /etc/resolv.conf 2>/dev/null || true)" != "$resolved_stub" ]; then
  run_as_root ln -sfn "$resolved_stub" /etc/resolv.conf
  echo "Pointed /etc/resolv.conf at $resolved_stub"
fi

# Power management daemons. thermald handles thermal/DPTF control; intel-lpmd
# watches the CPU's workload-type hints and confines tasks to a core subset
# when the silicon reports an idle workload. Neither fights
# power-profiles-daemon -- PPD's Conflicts= covers only
# tuned/tlp/auto-cpufreq/system76-power, and intel-lpmd reads PPD's active
# profile rather than overriding it.
#
# Both ship as Type=dbus units with SuccessExitStatus=2, which is the exit
# path they take on hardware they don't support. Enabling them on a host that
# turns out to be unsupported is therefore inert, not a restart loop -- so the
# unit-exists guard is all the gating this needs.
for unit in thermald.service intel_lpmd.service; do
  if systemctl cat "$unit" >/dev/null 2>&1; then
    if ! systemctl is-enabled --quiet "$unit"; then
      run_as_root systemctl enable --now "$unit"
      echo "Enabled $unit"
    fi
  fi
done

# Intel IPU7 camera: re-assert what intel-ipu7-camera's pacman install
# scriptlet does. The scriptlet only fires on install/upgrade, so a plain
# reinstall or a manually disabled unit would otherwise stay that way. The
# service chain is intel-ipu7-camera.service -> camera-init.service (loads
# intel_cvs, then ov08x40, then v4l2loopback) -> v4l2-relayd@ipu7.service,
# which republishes the ISP output as /dev/video50. Only that loopback node is
# meant to be user-visible; the raw ISYS nodes stay hidden by udev + a
# WirePlumber drop-in shipped in the package.
if systemctl cat intel-ipu7-camera.service >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet intel-ipu7-camera.service; then
    run_as_root systemctl enable intel-ipu7-camera.service
    echo "Enabled intel-ipu7-camera.service"
  fi

  # camera-init and v4l2-relayd are started by intel-ipu7-camera.service after
  # graphical.target, never enabled on their own -- enabling them would race
  # the ownership handover from the vision-sensing controller at boot.
  for unit in camera-init.service v4l2-relayd@ipu7.service; do
    if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
      run_as_root systemctl disable "$unit"
      echo "Disabled $unit (started by intel-ipu7-camera.service instead)"
    fi
  done

  if ! id -nG "$target_user" | tr ' ' '\n' | grep -Fxq video; then
    run_as_root usermod -aG video "$target_user"
    echo "Added $target_user to the video group"
  fi
fi

# Crash capture: archive kernel panic records out of pstore. The efi pstore
# backend (pstore.backend=efi, set in rootfs/etc/default/limine) writes the
# tail of the log to EFI NVRAM on panic, where it survives a power cut. This
# unit moves those records to /var/lib/systemd/pstore/<timestamp>/ on the next
# boot and clears the pstore area, which also matters because NVRAM space is
# small -- left uncleared, the first capture would block the second.
if systemctl cat systemd-pstore.service >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet systemd-pstore.service; then
    run_as_root systemctl enable systemd-pstore.service
    echo "Enabled systemd-pstore.service"
  fi
fi
