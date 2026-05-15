#!/usr/bin/env bash
set -euo pipefail

lock_dir="${XDG_RUNTIME_DIR:-/tmp}/deimos-power-button-action.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$lock_dir"' EXIT

hyprctl dispatch dpms on >/dev/null 2>&1 || true

if pgrep -x hyprlock >/dev/null 2>&1; then
  exit 0
fi

if command -v uwsm >/dev/null 2>&1; then
  uwsm app -- hyprlock
  exit 0
fi

hyprlock
