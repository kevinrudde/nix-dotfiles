#!/usr/bin/env bash
set -euo pipefail

# Migration: Repair SDDM Hyprland session entry
# Host: deimos
#
# Replaces the earlier session entry that pointed TryExec at the dotfiles
# checkout. The SDDM greeter user cannot traverse /home/kevin when it is 0700,
# so the desktop entry must validate against a public launcher path.

repo_root="${DOTFILES_MIGRATION_REPO_ROOT:?missing repo root}"
host="${DOTFILES_MIGRATION_HOST:?missing host}"

if [[ "$host" != "deimos" ]]; then
  echo "This migration is for deimos, but the active host is $host" >&2
  exit 1
fi

launcher="${repo_root}/systems/deimos/bin/start-hyprland-session.sh"
public_launcher="/usr/local/bin/start-hyprland-deimos-session"
session_entry="/usr/local/share/wayland-sessions/hyprland-deimos-uwsm.desktop"
tmp_launcher="$(mktemp)"
tmp_session_entry="$(mktemp)"
trap 'rm -f "$tmp_launcher" "$tmp_session_entry"' EXIT

if [[ ! -x "$launcher" ]]; then
  echo "Launcher script is missing or not executable: $launcher" >&2
  exit 1
fi

bash -n "$launcher"

cat >"$tmp_launcher" <<EOF
#!/usr/bin/env bash
set -euo pipefail

exec "${launcher}" "\$@"
EOF

cat >"$tmp_session_entry" <<EOF
[Desktop Entry]
Name=Hyprland (UWSM, deimos)
Comment=Hyprland session managed by Universal Wayland Session Manager
TryExec=${public_launcher}
Exec=${public_launcher}
Type=Application
DesktopNames=Hyprland
EOF

sudo install -D -m 0755 "$tmp_launcher" "$public_launcher"
sudo install -D -m 0644 "$tmp_session_entry" "$session_entry"

echo "Installed $public_launcher"
echo "Repaired $session_entry"
