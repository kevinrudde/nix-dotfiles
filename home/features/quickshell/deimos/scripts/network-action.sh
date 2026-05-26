#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"

case "$action" in
  scan)
    nmcli dev wifi rescan
    ;;
  connect)
    ssid="${2:-}"
    connection="${3:-}"
    security="${4:-}"
    password="${5:-}"

    [[ -n "$ssid" ]] || exit 2

    if [[ -n "$connection" ]]; then
      nmcli connection up id "$connection"
    elif [[ -z "$security" ]]; then
      nmcli device wifi connect "$ssid"
    elif [[ -n "$password" ]]; then
      nmcli device wifi connect "$ssid" password "$password"
    else
      notify-send "Wi-Fi" "Password required for ${ssid}"
      exit 2
    fi
    ;;
  *)
    exit 2
    ;;
esac
