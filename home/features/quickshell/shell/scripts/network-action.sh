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
  wifi-power)
    state="${2:-}"
    [[ "$state" == "on" || "$state" == "off" ]] || exit 2
    nmcli radio wifi "$state"
    ;;
  set-dns)
    connection="${2:-}"
    provider="${3:-}"
    custom="${4:-}"

    [[ -n "$connection" ]] || exit 2

    case "$provider" in
      dhcp)
        nmcli connection modify "$connection" ipv4.ignore-auto-dns no ipv4.dns ""
        ;;
      cloudflare)
        nmcli connection modify "$connection" ipv4.ignore-auto-dns yes ipv4.dns "1.1.1.1 1.0.0.1"
        ;;
      google)
        nmcli connection modify "$connection" ipv4.ignore-auto-dns yes ipv4.dns "8.8.8.8 8.8.4.4"
        ;;
      custom)
        [[ -n "$custom" ]] || exit 2
        nmcli connection modify "$connection" ipv4.ignore-auto-dns yes ipv4.dns "$custom"
        ;;
      *)
        exit 2
        ;;
    esac

    # ipv4.dns only takes effect on the running connection after a
    # reactivation — a brief link blip, the same tradeoff a forced Wi-Fi band
    # would have.
    nmcli connection up "$connection"
    ;;
  *)
    exit 2
    ;;
esac
