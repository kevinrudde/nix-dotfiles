#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
address="${2:-}"

case "$action" in
  power)
    state="$(bluetoothctl show 2>/dev/null | awk -F': ' '/^[[:space:]]*Powered:/ { print $2; exit }')"
    if [[ "$state" == "yes" ]]; then
      bluetoothctl power off
    else
      bluetoothctl power on
    fi
    ;;
  scan)
    bluetoothctl --timeout 6 scan on >/dev/null 2>&1 || true
    bluetoothctl --timeout 5 scan off >/dev/null 2>&1 || true
    ;;
  connect)
    [[ -n "$address" ]] || exit 2
    bluetoothctl trust "$address" >/dev/null 2>&1 || true
    bluetoothctl connect "$address"
    ;;
  disconnect)
    [[ -n "$address" ]] || exit 2
    bluetoothctl disconnect "$address"
    ;;
  pair)
    [[ -n "$address" ]] || exit 2
    printf 'agent NoInputNoOutput\ndefault-agent\npair %s\ntrust %s\nconnect %s\n' "$address" "$address" "$address" |
      bluetoothctl --timeout 30
    ;;
  *)
    exit 2
    ;;
esac
