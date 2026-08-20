#!/usr/bin/env bash
set -uo pipefail

network_json() {
  local line device type state connection signal text tooltip connected

  line="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status 2>/dev/null | awk -F: '$3 == "connected" && $2 != "loopback" { print; exit }')"

  if [[ -z "$line" ]]; then
    jq -n '{text: "", tooltip: "Disconnected", connected: false}'
    return 0
  fi

  IFS=: read -r device type state connection <<< "$line"
  connected=true

  case "$type" in
    wifi)
      signal="$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1 == "*" { print $2; exit }')"
      text="${signal:-0}% "
      tooltip="${connection:-$device} (${signal:-0}%)"
      ;;
    ethernet)
      text="󰈀"
      tooltip="${device}: ${connection:-connected}"
      ;;
    *)
      text=""
      tooltip="${device}: ${connection:-connected}"
      ;;
  esac

  jq -n --arg text "$text" --arg tooltip "$tooltip" --argjson connected "$connected" \
    '{text: $text, tooltip: $tooltip, connected: $connected}'
}

jq -n \
  --argjson network "$(network_json)" \
  --arg clock "$(date '+%d %b %H:%M')" \
  '{
    network: $network,
    clock: $clock
  }'
